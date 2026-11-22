/*
 * ============================================================================
 *  ESP32-CAM Smart Recycling Classifier  (commented version)
 * ============================================================================
 *  BIG PICTURE - what happens, in order:
 *
 *   1. DETECT   : HC-SR04 ultrasonic sensor measures distance. If something is
 *                 inside the chamber (MIN..MAX cm), an item is "present".
 *   2. CAPTURE  : ESP32-CAM takes one JPEG photo.
 *   3. CLASSIFY : The JPEG is POSTed to classify.php on your PHP server, which
 *                 asks Google Gemini what the item is and returns JSON.
 *   4. SORT     : The label (plastic bottle / can / unknown) reaches the
 *                 ESP8266, which moves the machine to sort the item.
 *                 (Normally classify.php forwards it; this file only sends it
 *                  directly as a fail-safe.)
 *
 *  The ESP32 itself does NOT recognise anything - it only detects, captures,
 *  uploads, and relays the answer.
 * ============================================================================
 */

#include <Arduino.h>
#include <WiFi.h>
#include <WebServer.h>
#include <HTTPClient.h>
#include "esp_camera.h"

/* ---------------- USER CONFIG ---------------- */
const char *WIFI_SSID     = "OPPO A58 772A";
const char *WIFI_PASSWORD = "123456789";

// ESP8266 (machine side) - receives the result at /update?label=...&confidence=...
const char *ESP8266_IP = "10.149.200.11";

// PHP server that receives the JPEG and asks Gemini (classify.php).
// Must send the same key that is set as 'device_key' in the PHP config.php.
const char *CLASSIFY_URL = "http://10.149.200.62/trash2cash/php/classify.php";
const char *DEVICE_KEY   = "make_up_a_long_random_string";
#define CLASSIFY_TIMEOUT_MS 20000   // Gemini usually answers in 1-3 s

#define CAM_FRAME_SIZE   FRAMESIZE_QVGA   // 320x240 - used for the live stream and for classification
#define CAM_JPEG_QUALITY 12                // lower number = higher quality (0-63)

/* ---------------- ULTRASONIC (HC-SR04) ----------------
   Wiring:  VCC -> 5V,  GND -> GND,  TRIG -> GPIO 14,
            ECHO -> 1k ohm -> GPIO 13 -> 2k ohm -> GND   (voltage divider, ECHO is 5V!)  */
#define TRIG_PIN 14
#define ECHO_PIN 13

// An object is "present" when the distance is between MIN and MAX (cm).
// Set MAX a bit LESS than the empty-chamber distance you see in the Serial Monitor.
#define OBJECT_MAX_CM   15.0f
#define OBJECT_MIN_CM    2.0f     // HC-SR04 is unreliable below ~2 cm

#define CHECK_INTERVAL_MS  100    // how often to check the sensor
#define SETTLE_MS          400    // wait for the item to stop moving before capturing
#define COOLDOWN_MS       2500    // minimum gap between two classifications
#define ECHO_TIMEOUT_US  15000UL  // ~2.5 m max range; shorter = faster when nothing is in front

// 1 = print the live range to the Serial Monitor (115200 baud)
#define PRINT_RANGE          1
#define PRINT_INTERVAL_MS  300

// 1 = CALIBRATION: only print the range, never capture or classify.
// Use this to find your OBJECT_MAX_CM, then set it back to 0.
#define CALIBRATION_MODE     0

/* ---------------- Camera pins (AI-Thinker) ---------------- */
// These tell the camera driver which ESP32 GPIO connects to which camera signal.
// They are fixed by the AI-Thinker board design - do not change them.
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27
#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

/* ---------------- GLOBAL OBJECTS AND SHARED STATE ---------------- */

WebServer server(80);       // control server: page, /classify
WebServer streamServer(81); // dedicated stream server: /stream

// Guards esp_camera_fb_get() calls, since the stream task (core 0) and
// classification (core 1) both use the camera driver.
// MUTEX = a "key": whoever holds it may touch the camera, the other waits.
SemaphoreHandle_t camMutex;
TaskHandle_t streamTaskHandle = NULL;

// Latest classification result, shared with the web page JSON.
String lastLabel = "waiting...";
float  lastConfidence = 0.0f;
unsigned long lastClassifyMs = 0;

// Latest ultrasonic reading (999 = no echo / nothing in range).
float lastDistCm = 999.0f;

/* ============================================================================
 *  initCamera()
 *  Called ONCE from setup().
 *  Fills in a camera_config_t (pins, clock, JPEG format, size, quality, frame
 *  buffers) and hands it to the esp_camera driver.
 *  Returns true if the camera started, false if it failed (wiring/power issue).
 * ============================================================================ */
bool initCamera() {
  camera_config_t config = {};              // start with everything zeroed

  // Which hardware timer/channel generates the camera's clock signal (XCLK)
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer   = LEDC_TIMER_0;

  // 8 data lines (D0-D7) that carry the picture data from camera to ESP32
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;

  // Clock and sync lines
  config.pin_xclk = XCLK_GPIO_NUM;          // clock the ESP32 gives the camera
  config.pin_pclk = PCLK_GPIO_NUM;          // clock the camera gives back (per pixel)
  config.pin_vsync = VSYNC_GPIO_NUM;        // marks the start of a new frame
  config.pin_href = HREF_GPIO_NUM;          // marks a valid row of pixels

  // SCCB = camera's I2C-style control bus (used to send settings to the sensor)
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;

  config.pin_pwdn = PWDN_GPIO_NUM;          // power-down pin of the camera
  config.pin_reset = RESET_GPIO_NUM;        // -1 = not connected
  config.xclk_freq_hz = 20000000;           // 20 MHz camera clock

  // The camera compresses to JPEG itself, so the ESP32 gets small files
  // that are quick to upload to the server.
  config.pixel_format = PIXFORMAT_JPEG;
  config.frame_size = CAM_FRAME_SIZE;       // 320x240
  config.jpeg_quality = CAM_JPEG_QUALITY;   // 12 (lower number = better quality)

  // PSRAM = the extra external RAM on the ESP32-CAM.
  if (psramFound()) {
    config.fb_count = 2;                          // 2 buffers: one fills while you use the other
    config.grab_mode = CAMERA_GRAB_LATEST;        // always give me the newest frame
    config.fb_location = CAMERA_FB_IN_PSRAM;
  } else {
    config.fb_count = 1;                          // not enough memory for 2 buffers
    config.grab_mode = CAMERA_GRAB_WHEN_EMPTY;
    config.fb_location = CAMERA_FB_IN_DRAM;
  }

  return esp_camera_init(&config) == ESP_OK;
}

/* ============================================================================
 *  ULTRASONIC SECTION  -  STEP 1: DETECT
 * ============================================================================ */

/* ----------------------------------------------------------------------------
 *  readDistanceCm()
 *  Takes ONE raw measurement from the HC-SR04.
 *  How the HC-SR04 works:
 *     - A 10 microsecond HIGH pulse on TRIG makes it send an ultrasonic burst.
 *     - ECHO then goes HIGH and stays HIGH until the sound bounces back.
 *     - The HIGH time = round-trip travel time of the sound.
 *  Returns: distance in cm, or -1 if no echo came back before the timeout.
 * ---------------------------------------------------------------------------- */
float readDistanceCm() {
  // Clean LOW first, so the 10 us pulse starts from a known state
  digitalWrite(TRIG_PIN, LOW);  delayMicroseconds(2);
  // 10 us trigger pulse -> sensor fires the sound burst
  digitalWrite(TRIG_PIN, HIGH); delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  // Measure how long (in microseconds) ECHO stays HIGH.
  // Gives up after ECHO_TIMEOUT_US and returns 0 (nothing detected).
  unsigned long d = pulseIn(ECHO_PIN, HIGH, ECHO_TIMEOUT_US);
  if (d == 0) return -1.0f;

  // Sound travels about 0.0343 cm per microsecond.
  // Divide by 2 because the time covers the trip OUT and BACK.
  return d * 0.0343f / 2.0f;
}

/* ----------------------------------------------------------------------------
 *  objectPresent()
 *  Makes the sensor reading reliable, then answers: "is an item in the chamber?"
 *   1. Takes 3 readings (20 ms apart). "No echo" is stored as 999 cm.
 *   2. Sorts the 3 values (three compare-and-swap steps).
 *   3. Uses the MIDDLE one (the median), so a single bad reading is ignored.
 *   4. Saves it in lastDistCm (used by the Serial prints and the web page).
 *  Returns true only when the distance is between OBJECT_MIN_CM and OBJECT_MAX_CM.
 * ---------------------------------------------------------------------------- */
bool objectPresent() {
  float r[3];
  for (int i = 0; i < 3; i++) {
    float d = readDistanceCm();
    r[i] = (d < 0) ? 999.0f : d;     // no echo = nothing close
    delay(20);                        // short pause so echoes don't overlap
  }

  // Tiny sorting network: after these 3 lines r[0] <= r[1] <= r[2]
  if (r[0] > r[1]) { float t = r[0]; r[0] = r[1]; r[1] = t; }
  if (r[1] > r[2]) { float t = r[1]; r[1] = r[2]; r[2] = t; }
  if (r[0] > r[1]) { float t = r[0]; r[0] = r[1]; r[1] = t; }

  lastDistCm = r[1];                 // the median
  return lastDistCm >= OBJECT_MIN_CM && lastDistCm <= OBJECT_MAX_CM;
}

/* ============================================================================
 *  CLASSIFICATION SECTION  (PHP server -> Gemini)
 * ============================================================================ */

/* ----------------------------------------------------------------------------
 *  normalizeLabel()
 *  Converts whatever label the server sent into one of the exact names the
 *  ESP8266 understands: "plastic bottle", "can", or "unknown".
 *  Steps: lowercase it, then look for keywords with indexOf().
 *  NOTE: the "can" test matches ANY label containing the letters "can"
 *        (e.g. "scan"), so keep your server labels simple.
 *  NOTE: this version returns "plastic bottle" (with a space). Make sure the
 *        ESP8266 /update handler compares against that exact text.
 * ---------------------------------------------------------------------------- */
String normalizeLabel(const String &raw) {
  String s = raw;
  s.toLowerCase();
  if (s.indexOf("plastic_bottle") >= 0) return "plastic_bottle";
  if (s.indexOf("can") >= 0)     return "can";
  return "unknown";
}

/* ----------------------------------------------------------------------------
 *  urlEncode()
 *  Makes text safe to put inside a URL. Letters, digits and - _ . stay as is;
 *  everything else (including spaces) becomes %XX.
 *  Example: "plastic bottle" -> "plastic%20bottle"
 * ---------------------------------------------------------------------------- */
String urlEncode(const String &in) {
  String out;
  const char *hex = "0123456789ABCDEF";
  for (size_t i = 0; i < in.length(); i++) {
    char c = in[i];
    if (isalnum((unsigned char)c) || c == '-' || c == '_' || c == '.') {
      out += c;                                   // safe character, keep it
    } else {
      out += '%';                                 // unsafe: write % + 2 hex digits
      out += hex[((unsigned char)c) >> 4];        // high 4 bits
      out += hex[((unsigned char)c) & 0x0F];      // low 4 bits
    }
  }
  return out;
}

/* ----------------------------------------------------------------------------
 *  sendResultToESP8266()                                   STEP 4: SORT (direct)
 *  Sends the result straight to the ESP8266 with an HTTP GET:
 *      http://<ESP8266_IP>/update?label=<label>&confidence=<0.000>
 *  The ESP8266 reads "label" and moves the sorting mechanism.
 *  In normal operation classify.php does this, so this function is only called
 *  as a fail-safe from classifyOnTrigger().
 * ---------------------------------------------------------------------------- */
void sendResultToESP8266(const String &label, float confidence) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected, skipping send to ESP8266");
    return;
  }

  HTTPClient http;
  // Build the full URL; confidence is printed with 3 decimals
  String url = "http://" + String(ESP8266_IP) + "/update?label=" + urlEncode(label) +
               "&confidence=" + String(confidence, 3);

  http.begin(url);
  http.setTimeout(1000);          // ESP8266 is on the local network, 1 s is plenty
  int httpCode = http.GET();      // positive = got an HTTP reply, negative = error

  if (httpCode > 0) {
    Serial.printf("Sent OK (HTTP %d): %s\n", httpCode, http.getString().c_str());
  } else {
    Serial.printf("Failed to send to ESP8266: %s\n", http.errorToString(httpCode).c_str());
  }
  http.end();                     // always close the connection
}

/* ----------------------------------------------------------------------------
 *  classifyViaServer()                          STEPS 2 + 3: CAPTURE + CLASSIFY
 *  Does the whole "photo -> Gemini -> answer" job once.
 *    1. Take the camera mutex (the live stream also uses the camera).
 *    2. Grab one JPEG frame from the camera.
 *    3. POST the raw JPEG to classify.php with the secret device key.
 *    4. Read the JSON reply and pull out "label" and "confidence".
 *  Returns true on success; labelOut / confOut receive the answer.
 *  Returns false on ANY failure (no WiFi, camera busy, server error, bad JSON).
 * ---------------------------------------------------------------------------- */
bool classifyViaServer(String &labelOut, float &confOut) {
  if (WiFi.status() != WL_CONNECTED) return false;

  // --- CAPTURE ---
  // Wait up to 500 ms for the camera "key". If the stream keeps it, give up.
  if (xSemaphoreTake(camMutex, pdMS_TO_TICKS(500)) != pdTRUE) {
    return false; // stream currently holds the camera
  }
  camera_fb_t *fb = esp_camera_fb_get();   // fb->buf = JPEG bytes, fb->len = size
  xSemaphoreGive(camMutex);                // hand the key back immediately
  if (!fb) return false;                   // capture failed

  // --- SEND TO SERVER (which asks Gemini) ---
  HTTPClient http;
  http.begin(CLASSIFY_URL);
  http.setTimeout(CLASSIFY_TIMEOUT_MS);               // allow time for Gemini
  http.addHeader("Content-Type", "image/jpeg");       // body is a raw JPEG
  http.addHeader("x-device-key", DEVICE_KEY);         // shared secret checked by PHP
  int code = http.POST(fb->buf, fb->len);             // upload the picture
  esp_camera_fb_return(fb);                           // IMPORTANT: give the buffer back
                                                      // to the driver or the camera
                                                      // eventually runs out of buffers

  if (code != 200) {                                  // anything but HTTP 200 = failure
    Serial.printf("Classify server error: HTTP %d (%s)\n", code, http.errorToString(code).c_str());
    http.end();
    return false;
  }

  String body = http.getString();                     // the JSON text from the server
  http.end();

  // --- READ THE ANSWER ---
  // Very small JSON read: {"label":"plastic_bottle","confidence":0.93}
  // (no JSON library: we just search for the text we need)
  int i = body.indexOf("\"label\":\"");               // find  "label":"
  if (i < 0) return false;
  i += 9;                                             // skip past those 9 characters
  int j = body.indexOf('"', i);                       // closing quote of the label
  if (j < 0) return false;
  labelOut = normalizeLabel(body.substring(i, j));    // clean it to our known names

  confOut = 1.0f;                                     // default if confidence is missing
  int c = body.indexOf("\"confidence\":");
  if (c >= 0) confOut = body.substring(c + 13).toFloat();  // 13 = length of "confidence":
  return true;
}

/* ----------------------------------------------------------------------------
 *  classifyOnTrigger()
 *  The "manager" function, called when the ultrasonic sensor says an item is
 *  present.
 *    - Tries classifyViaServer() up to 2 times (300 ms pause between tries).
 *    - If both fail, the item becomes "unknown" with confidence 0, so the
 *      machine REJECTS it (fail-safe: never accept something we couldn't check).
 *    - Saves the result for the web page and prints it to Serial.
 *    - Only on failure does it message the ESP8266 itself, because on success
 *      classify.php has already done that.
 * ---------------------------------------------------------------------------- */
void classifyOnTrigger() {
  String label = "unknown";
  float conf = 0.0f;
  bool ok = false;

  for (int i = 0; i < 2 && !ok; i++) {       // up to 2 attempts
    ok = classifyViaServer(label, conf);
    if (!ok) delay(300);                     // brief pause before retry
  }
  if (!ok) {
    label = "unknown";
    conf = 0.0f;
    Serial.println("Classification failed, sending unknown");
  }

  // Remember the latest result (the web page reads these)
  lastLabel = label;
  lastConfidence = conf;
  lastClassifyMs = millis();
  Serial.printf("Classified: %s (%.2f)\n", label.c_str(), conf);

  // classify.php already forwards the result to the ESP8266 when the server answered.
  // Only send from here when the server could not be reached (fail-safe "unknown").
  // If your PHP server can't reach the ESP8266 (hosted online), set esp8266_ip to ''
  // in config.php and change the next line to: sendResultToESP8266(label, conf);
  if (!ok) sendResultToESP8266(label, conf);
}

/* ============================================================================
 *  WEB UI  (optional viewer, not required for data to flow)
 *  A small page you open in a browser to watch the camera and the result.
 *  The machine works the same with or without it.
 * ============================================================================ */
const char INDEX_HTML[] PROGMEM = R"HTML(
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>ESP32-CAM Live Classifier</title>
  <style>
    body { font-family: sans-serif; text-align: center; background:#111; color:#eee; }
    .wrap { position: relative; display: inline-block; margin-top: 10px; }
    img { max-width: 90%; border: 2px solid #555; display:block; }
    #result {
      position: absolute; top: 10px; left: 10px;
      background: rgba(0,0,0,0.65); padding: 10px 16px; border-radius: 8px;
      font-size: 20px; font-weight: bold;
    }
    .can { color:#5bf; }
    .plastic { color:#5f8; }
    .unknown { color:#fb5; }
    .background { color:#aaa; }
  </style>
</head>
<body>
  <h2>ESP32-CAM Live Classifier</h2>
  <div class="wrap">
    <img id="live">
    <div id="result">Loading...</div>
  </div>
  <script>
    // The video comes from the stream server on port 81
    document.getElementById('live').src =
      'http://' + window.location.hostname + ':81/stream';

    // Every ~0.9 s ask /classify for the latest label + distance and show it
    function poll() {
      fetch('/classify')
        .then(r => r.json())
        .then(d => {
          var el = document.getElementById('result');
          var dist = (d.distance < 0) ? 'no echo' : d.distance.toFixed(1) + ' cm';
          el.textContent = d.label + ' (' + Math.round(d.confidence * 100) + '%)  |  ' + dist;
          el.className = d.label;
        })
        .catch(() => {})
        .finally(() => setTimeout(poll, 900));
    }
    poll();
  </script>
</body>
</html>
)HTML";

/* ----------------------------------------------------------------------------
 *  handleRoot()  -  answers http://<esp32-ip>/  with the HTML page above.
 * ---------------------------------------------------------------------------- */
void handleRoot() {
  server.send(200, "text/html", INDEX_HTML);
}

/* ----------------------------------------------------------------------------
 *  handleClassify()  -  answers http://<esp32-ip>/classify
 *  Returns the latest label, confidence and distance as JSON, e.g.
 *      {"label":"can","confidence":0.930,"distance":8.2}
 *  distance = -1 means "no echo". The web page polls this every ~0.9 s.
 * ---------------------------------------------------------------------------- */
void handleClassify() {
  float dist = (lastDistCm >= 999.0f) ? -1.0f : lastDistCm;
  String json = "{\"label\":\"" + lastLabel + "\",\"confidence\":" + String(lastConfidence, 3) +
                ",\"distance\":" + String(dist, 1) + "}";
  server.sendHeader("Cache-Control", "no-store");   // never let the browser reuse old data
  server.send(200, "application/json", json);
}

/* ----------------------------------------------------------------------------
 *  handleStream()  -  answers http://<esp32-ip>:81/stream  (live video)
 *  Uses "MJPEG": one long HTTP response that keeps sending JPEG frames, each
 *  separated by a boundary line. The browser shows them as video.
 *  Loop: take mutex -> grab frame -> give mutex -> write frame -> return frame.
 *  It stays inside the while loop for as long as the viewer is connected, which
 *  is why only ONE viewer at a time can watch the stream.
 * ---------------------------------------------------------------------------- */
void handleStream() {
  WiFiClient client = streamServer.client();
  const char *boundary = "frame";

  // Send the HTTP header once; "multipart/x-mixed-replace" = replace the image
  // with each new part that arrives.
  String response = "HTTP/1.1 200 OK\r\n";
  response += "Content-Type: multipart/x-mixed-replace; boundary=" + String(boundary) + "\r\n";
  response += "Access-Control-Allow-Origin: *\r\n\r\n";
  client.print(response);

  while (client.connected()) {
    // Share the camera with classifyViaServer()
    if (xSemaphoreTake(camMutex, pdMS_TO_TICKS(200)) != pdTRUE) {
      continue;                          // camera busy, try again
    }
    camera_fb_t *fb = esp_camera_fb_get();
    xSemaphoreGive(camMutex);

    if (!fb) {
      Serial.println("Stream: capture failed, stopping stream");
      break;
    }

    // One "part" of the multipart response = one JPEG frame
    client.printf("--%s\r\n", boundary);
    client.print("Content-Type: image/jpeg\r\n");
    client.printf("Content-Length: %u\r\n\r\n", fb->len);
    client.write(fb->buf, fb->len);
    client.print("\r\n");

    esp_camera_fb_return(fb);            // give the buffer back to the driver

    if (!client.connected()) break;      // viewer closed the page
  }
}

/* ----------------------------------------------------------------------------
 *  streamTask()
 *  A FreeRTOS task pinned to core 0 that only serves the video server.
 *  Because the stream blocks while someone is watching, it gets its own task so
 *  it never freezes loop() (which runs the sensor and classification on core 1).
 * ---------------------------------------------------------------------------- */
void streamTask(void *param) {
  for (;;) {
    streamServer.handleClient();   // serve any request waiting on port 81
    vTaskDelay(1);                 // yield so the watchdog and other tasks can run
  }
}

/* ============================================================================
 *  setup()  -  runs ONCE at power-on / reset
 * ============================================================================ */
void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("\nESP32-CAM Live Classifier (ultrasonic trigger, PHP + Gemini)");

  // Ultrasonic pins: TRIG is an output we control, ECHO is an input we read
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  digitalWrite(TRIG_PIN, LOW);

  // Start the camera. If it fails (bad ribbon cable / power), stop here.
  if (!initCamera()) {
    Serial.println("Camera init failed. Halting.");
    while (true) delay(1000);
  }
  Serial.println("Camera OK.");

  // Create the mutex BEFORE any task or handler can use it.
  camMutex = xSemaphoreCreateMutex();

  // Connect to WiFi and wait until connected
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  WiFi.setSleep(false);   // keep the radio awake: faster, steadier uploads/stream

  Serial.print("Open this in Chrome on your laptop: http://");
  Serial.println(WiFi.localIP());

#if CALIBRATION_MODE
  Serial.println("*** CALIBRATION MODE: printing range only, no classification ***");
#endif

  // Port 80: the page and the JSON status
  server.on("/", handleRoot);
  server.on("/classify", handleClassify);
  server.begin();

  // Port 81: the live video stream
  streamServer.on("/stream", HTTP_GET, handleStream);
  streamServer.begin();

  // Start the stream task on core 0 (loop() runs on core 1)
  xTaskCreatePinnedToCore(
    streamTask, "streamTask", 8192, NULL, 1, &streamTaskHandle, 0
  );
}

/* ============================================================================
 *  loop()  -  runs forever; this is the "brain" that links all the steps
 *
 *  Decision flow, every pass:
 *    a) Serve any web request (server.handleClient()).
 *    b) Only continue every CHECK_INTERVAL_MS (100 ms).
 *    c) Measure distance -> present / not present.
 *    d) Print range + state changes to Serial (for tuning).
 *    e) CALIBRATION_MODE? stop here.
 *    f) Nothing present -> re-arm and exit.
 *    g) Item present AND armed AND cooldown passed -> wait for it to settle,
 *       re-check, then classifyOnTrigger().
 * ============================================================================ */
void loop() {
  server.handleClient();             // (a) answer browser requests on port 80

  // "static" = these keep their values between calls of loop()
  static bool armed = true;          // true once the previous item has left
  static bool wasPresent = false;    // previous state, to detect changes
  static unsigned long lastCheck = 0, lastDone = 0, lastPrint = 0;

  // (b) Rate limiter: skip this pass if 100 ms haven't passed since last check
  if (millis() - lastCheck < CHECK_INTERVAL_MS) return;
  lastCheck = millis();

  // (c) Measure. This also updates lastDistCm.
  bool present = objectPresent();

  // (d) Print the live range so you can tune OBJECT_MAX_CM.
  if (PRINT_RANGE || CALIBRATION_MODE) {
    if (millis() - lastPrint >= PRINT_INTERVAL_MS) {
      lastPrint = millis();
      if (lastDistCm >= 999.0f) {
        Serial.println("Range: no echo (nothing within range)  -> NO OBJECT");
      } else {
        Serial.printf("Range: %.1f cm  -> %s\n", lastDistCm, present ? "OBJECT" : "no object");
      }
    }
  }

  // (d) Print only when the state changes.
  if (present != wasPresent) {
    if (present) Serial.printf(">>> OBJECT DETECTED (%.1f cm)\n", lastDistCm);
    else         Serial.println(">>> NO OBJECT");
    wasPresent = present;
  }

  // (e) Calibration: only measure and print, never capture or classify
  if (CALIBRATION_MODE) return;      // calibration: never classify

  // (f) Chamber empty: allow the next item and show "background" on the web page
  if (!present) {                    // item gone, so re-arm
    armed = true;
    lastLabel = "background";
    return;
  }

  // (g) An item is there. Classify only if:
  //     - armed        : the previous item has left (one classification per item)
  //     - cooldown     : at least COOLDOWN_MS since the last classification
  if (armed && millis() - lastDone >= COOLDOWN_MS) {
    delay(SETTLE_MS);                // let the item stop moving
    if (objectPresent()) {           // still there, so it's a real item
      classifyOnTrigger();           // capture + POST to PHP/Gemini + send to ESP8266
      armed = false;                 // one classification per item
      lastDone = millis();
    }
  }
}