#include "stepper_motor.h"

static long currentPosSteps = 0;   // absolute position in steps from HOME
static int  currentSlot     = SLOT_UNKNOWN;

// ─── private helpers ───────────────────────────────────────────────

static void _pulse(unsigned int delayUs) {
  digitalWrite(PUL_PIN, HIGH);
  delayMicroseconds(STEP_PULSE_US);
  digitalWrite(PUL_PIN, LOW);
  delayMicroseconds(delayUs);
}

static void _move(long steps, bool clockwise) {
  if (steps <= 0) return;

  bool dirHigh = clockwise ^ INVERT_DIR;
  digitalWrite(DIR_PIN, dirHigh ? HIGH : LOW);
  delayMicroseconds(5); // DIR setup time before stepping

  if (STEPPER_DEBUG) {
    Serial.print("[STEPPER] Direction: ");
    Serial.println(clockwise ? "CLOCKWISE" : "COUNTER-CLOCKWISE");
    Serial.print("[STEPPER] Steps to move: ");
    Serial.println(steps);
  }

  for (long i = 0; i < steps; i++) {
    _pulse(STEP_DELAY_US);
    yield(); // keep the ESP8266 watchdog / WiFi stack happy

    if (STEPPER_DEBUG && i > 0 && i % 200 == 0) {
      Serial.print("[STEPPER] ...step ");
      Serial.print(i);
      Serial.print(" / ");
      Serial.println(steps);
    }
  }

  currentPosSteps += clockwise ? steps : -steps;

  if (STEPPER_DEBUG) Serial.println("[STEPPER] Move complete");
}

// ─── public API ────────────────────────────────────────────────────

void stepper_setup() {
  pinMode(PUL_PIN, OUTPUT);
  pinMode(DIR_PIN, OUTPUT);
  // ENA not used: driver is enabled by default with ENA+/ENA- unconnected.

  digitalWrite(PUL_PIN, LOW);
  digitalWrite(DIR_PIN, LOW);

  currentSlot = SLOT_UNKNOWN;
  currentPosSteps = 0;

  if (STEPPER_DEBUG) {
    Serial.println("=== [STEPPER] NEMA 17 Initialized (no ENA) ===");
    Serial.print("[STEPPER] PUL: "); Serial.println(PUL_PIN);
    Serial.print("[STEPPER] DIR: "); Serial.println(DIR_PIN);
    Serial.println("[STEPPER] Starting at HOME (UNKNOWN slot)");
  }
}

void stepper_rotateToSlot(int slotNumber) {
  if (STEPPER_DEBUG) {
    Serial.print("[STEPPER] >>> Rotating to slot ");
    Serial.println(slotNumber);
  }

  long targetSteps = 0;
  const char* slotName = "UNKNOWN";

  switch (slotNumber) {
    case SLOT_PLASTIC: targetSteps = SLOT_PLASTIC_STEPS; slotName = "PLASTIC"; break;
    case SLOT_CAN:     targetSteps = SLOT_CAN_STEPS;     slotName = "CAN";     break;
    case SLOT_UNKNOWN:
      // Default: UNKNOWN stays at HOME, the NEMA does not run.
      if (STEPPER_DEBUG) Serial.println("[STEPPER] UNKNOWN slot: NEMA does not move");
      return;
    default:
      if (STEPPER_DEBUG) Serial.println("[STEPPER] ERROR: Unknown slot number");
      return;
  }

  long stepsNeeded = targetSteps - currentPosSteps;
  bool cw = (stepsNeeded >= 0);
  long absSteps = labs(stepsNeeded);

  if (absSteps == 0) {
    if (STEPPER_DEBUG) Serial.println("[STEPPER] Already at target, skipping");
    currentSlot = slotNumber;
    return;
  }

  if (STEPPER_DEBUG) {
    Serial.print("[STEPPER] Target: "); Serial.println(slotName);
    Serial.print("[STEPPER] Steps needed: "); Serial.println(absSteps);
  }

  _move(absSteps, cw);
  currentSlot = slotNumber;

  if (STEPPER_DEBUG) {
    Serial.print("[STEPPER] Now at slot: "); Serial.println(slotName);
  }
}

void stepper_home() {
  if (STEPPER_DEBUG) Serial.println("[STEPPER] >>> Returning HOME");

  if (currentSlot == SLOT_UNKNOWN) {
    if (STEPPER_DEBUG) Serial.println("[STEPPER] Already HOME");
    return;
  }

  // Use a dedicated return-step count per slot instead of assuming
  // the trip back is identical to the trip out (accounts for backlash).
  long stepsBack = 0;
  switch (currentSlot) {
    case SLOT_PLASTIC: stepsBack = HOME_FROM_PLASTIC_STEPS; break;
    case SLOT_CAN:     stepsBack = HOME_FROM_CAN_STEPS;     break;
    default: stepsBack = labs(currentPosSteps); break; // fallback safety
  }

  bool cw = (currentPosSteps < 0); // move back toward 0, same direction logic as before

  if (STEPPER_DEBUG) {
    Serial.print("[STEPPER] Steps back: "); Serial.println(stepsBack);
  }

  _move(stepsBack, cw);
  currentSlot = SLOT_UNKNOWN;
  currentPosSteps = 0;   // always resync to exactly 0 at HOME after homing

  if (STEPPER_DEBUG) Serial.println("[STEPPER] HOME reached");
}