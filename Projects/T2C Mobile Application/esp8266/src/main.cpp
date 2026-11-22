#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <ESP8266HTTPClient.h>   // lets the ESP8266 call the PHP points server
#include <WiFiClient.h>          // required by HTTPClient on ESP8266
// Keep this order: StepperMotor.h (gate) first, then stepper_motor.h (NEMA).
// stepper_motor.h defines STEPS_PER_REV as a macro, which would clash with the
// gate's StepperConfig::STEPS_PER_REV if it were included first.
#include "StepperMotor.h"       // 28BYJ-48 = the GATE that drops trash into the bin
#include "stepper_motor.h"      // NEMA17 = moves the sorter to the right bin

/* ---------------- WiFi CONFIG ---------------- */
const char *WIFI_SSID     = "OPPO A58 772A";
const char *WIFI_PASSWORD = "123456789";

/* ---------------- POINTS SERVER CONFIG ---------------- */
const char *POINTS_SERVER_HOST = "10.149.200.62";   // PHP server's LAN IP
const int   POINTS_SERVER_PORT = 80;
const char *MACHINE_CODE       = "TCM001";        // must match `machineCode` in `vending_machines`
const char *API_BASE_PATH      = "/trash2cash/php/";

/* ---------------- BEHAVIOR CONFIG ---------------- */
// Ignore plastic/can detections below this confidence.
// "unknown" is NOT filtered by this: it always goes to the unknown bin.
const float MIN_CONFIDENCE = 0.70f;

// After a full sorting sequence finishes, ignore new detections for this long.
const unsigned long COOLDOWN_MS = 5000;

// How long a "yes, a user is connected" answer stays trusted before asking again.
const unsigned long SESSION_CACHE_MS = 3000;

ESP8266WebServer server(80);

StepperMotor gateMotor;       // 28BYJ-48 gate  (settings: StepperConfig.h)
                               // NEMA17 sorter  (settings: stepper_motor.h)

// Set by handleUpdate(), consumed by loop().
String pendingLabel = "";
unsigned long lastActionEndMs = 0;
bool everRan = false;

// Session-gate cache (see hasActiveUserSession()).
bool sessionCacheValid   = false;
bool sessionCacheActive  = false;
unsigned long sessionCacheAtMs = 0;

/* ---------------- HELPERS ---------------- */

// Anything that isn't recognized falls back to SLOT_UNKNOWN (the default).
int labelToSlot(const String &raw) {
  String s = raw;
  s.toLowerCase();
  if (s.indexOf("plastic") >= 0) return SLOT_PLASTIC;
  if (s.indexOf("can") >= 0)     return SLOT_CAN;
  return SLOT_UNKNOWN;
}

int gateStepsForSlot(int slot) {
  if (slot == SLOT_PLASTIC) return StepperConfig::GATE_OPEN_STEPS_PLASTIC;
  if (slot == SLOT_CAN)     return StepperConfig::GATE_OPEN_STEPS_CAN;
  return StepperConfig::GATE_OPEN_STEPS_UNKNOWN;
}

unsigned long gateHoldForSlot(int slot) {
  if (slot == SLOT_PLASTIC) return StepperConfig::GATE_HOLD_MS_PLASTIC;
  if (slot == SLOT_CAN)     return StepperConfig::GATE_HOLD_MS_CAN;
  return StepperConfig::GATE_HOLD_MS_UNKNOWN;
}

// SLOT_UNKNOWN returns "" so no points are awarded for it.
String slotToItemType(int slot) {
  if (slot == SLOT_PLASTIC) return "plastic_bottle";
  if (slot == SLOT_CAN)     return "aluminum_can";
  return "";
}

// Single place that talks to the PHP backend.
String callApi(const String &endpoint, const String &queryString, int &httpCodeOut) {
  httpCodeOut = 0;

  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected, skipping API call");
    return "";
  }

  WiFiClient client;
  HTTPClient http;
  String url = "http://" + String(POINTS_SERVER_HOST) + ":" + String(POINTS_SERVER_PORT) +
               String(API_BASE_PATH) + endpoint + "?" + queryString;

  http.begin(client, url);
  http.setTimeout(2000);
  int httpCode = http.GET();
  httpCodeOut = httpCode;

  String body = "";
  if (httpCode > 0) {
    body = http.getString();
    Serial.printf("API %s (HTTP %d): %s\n", endpoint.c_str(), httpCode, body.c_str());
  } else {
    Serial.printf("API %s failed: %s\n", endpoint.c_str(), http.errorToString(httpCode).c_str());
  }
  http.end();
  return body;
}

// Asks the backend whether a user is currently connected on this machine.
// check_session.php must reply with the literal text "ACTIVE" or "INACTIVE".
bool hasActiveUserSession() {
  unsigned long now = millis();
  if (sessionCacheValid && (now - sessionCacheAtMs < SESSION_CACHE_MS)) {
    return sessionCacheActive;
  }

  int httpCode = 0;
  String body = callApi("check_session.php", "machineCode=" + String(MACHINE_CODE), httpCode);
  body.trim();

  bool active = (httpCode == 200 && body == "ACTIVE");

  sessionCacheValid  = true;
  sessionCacheActive = active;
  sessionCacheAtMs   = now;

  if (httpCode != 200) {
    Serial.println("check_session.php unreachable or errored - treating as NO user connected.");
  }
  return active;
}

// Reports a successful deposit so the connected user gets credited.
void reportDeposit(const String &itemType) {
  if (itemType.length() == 0) {
    Serial.println("Unknown item - nothing to report, no points awarded.");
    return;
  }
  int httpCode = 0;
  callApi("record_deposit.php", "machineCode=" + String(MACHINE_CODE) + "&itemType=" + itemType, httpCode);
}

/* ---------------- WEB SERVER HANDLERS ---------------- */

void handleUpdate() {
  if (!server.hasArg("label") || !server.hasArg("confidence")) {
    server.send(400, "text/plain", "Missing label or confidence");
    return;
  }

  String label = server.arg("label");
  float confidence = server.arg("confidence").toFloat();

  // Optional error text from classify.php (e.g. "Gemini quota exceeded (HTTP 429)").
  // The item is still treated as "unknown" and goes to the unknown bin.
  String errorMsg = server.hasArg("error") ? server.arg("error") : "";

  if (errorMsg.length() > 0) {
    Serial.printf("ERROR: %s -> item will go to the UNKNOWN bin\n", errorMsg.c_str());
  } else {
    Serial.printf("Detected: %s (%.2f)\n", label.c_str(), confidence);
  }

  if (label == "background") {
    server.send(200, "text/plain", "IGNORED (background)");
    return;
  }

  // Confidence only matters for real items. "unknown" (including Gemini
  // errors, which arrive as unknown 0.00) always goes to the unknown bin.
  bool isUnknown = (labelToSlot(label) == SLOT_UNKNOWN);
  if (!isUnknown && confidence < MIN_CONFIDENCE) {
    server.send(200, "text/plain", "IGNORED (low confidence)");
    return;
  }

  if (pendingLabel.length() > 0 ||
      (everRan && millis() - lastActionEndMs < COOLDOWN_MS)) {
    server.send(200, "text/plain", "BUSY");
    return;
  }

  // Reply immediately so the PHP server doesn't time out.
  // The session check happens in loop(), after this reply.
  pendingLabel = label;
  server.send(200, "text/plain", "OK");
}

void handleRoot() {
  server.send(200, "text/plain", "ESP8266 receiver is running.");
}

// Full sorting sequence for one label:
//   NEMA -> bin (skipped for UNKNOWN) -> gate opens / holds / closes -> NEMA home -> report points
void runAction(const String &label) {
  int slot = labelToSlot(label);
  Serial.printf("Action for '%s' (slot %d)\n", label.c_str(), slot);

  // 1) NEMA moves the sorter to this class's bin (does nothing for UNKNOWN)
  stepper_rotateToSlot(slot);
  if (slot != SLOT_UNKNOWN) delay(SLOT_SETTLE_MS);

  // 2) Gate opens so the trash falls into the bin, then closes
  gateMotor.dropTrash(gateStepsForSlot(slot), gateHoldForSlot(slot));

  // 3) NEMA returns to HOME (does nothing if already home)
  stepper_home();

  // 4) Tell the backend (no points for unknown)
  reportDeposit(slotToItemType(slot));

  Serial.println("Action done.");
}

void setup() {
  Serial.begin(115200);
  delay(200);
  Serial.println();

  gateMotor.begin();
  stepper_setup();

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  Serial.print("ESP8266 IP address: ");
  Serial.println(WiFi.localIP());
  Serial.print("ESP8266 MAC address: ");
  Serial.println(WiFi.macAddress());
  Serial.println(">>> COPY THIS IP into ESP8266_IP in the ESP32-CAM sketch <<<");

  server.on("/", handleRoot);
  server.on("/update", HTTP_GET, handleUpdate);
  server.begin();
  Serial.println("Server ready, waiting for classifications...");
}

void loop() {
  server.handleClient();

  if (pendingLabel.length() > 0) {
    String label = pendingLabel;
    pendingLabel = "";

    // Only run the machine if a user is connected.
    if (!hasActiveUserSession()) {
      Serial.println("IGNORED (no user connected)");
      return;
    }

    runAction(label);          // blocks while the motors run
    lastActionEndMs = millis();
    everRan = true;
  }
}