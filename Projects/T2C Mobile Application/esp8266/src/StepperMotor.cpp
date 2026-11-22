#include "StepperMotor.h"
#include <Arduino.h>

// NOTE: pin order below is IN1, IN3, IN2, IN4 (not 1,2,3,4 in order).
// This matches how the 28BYJ-48's coils need to be energized in sequence -
// using 1,2,3,4 directly will make it buzz/vibrate without turning.
StepperMotor::StepperMotor()
    : _stepper(StepperConfig::STEPS_PER_REV,
               StepperConfig::IN1_PIN,
               StepperConfig::IN3_PIN,
               StepperConfig::IN2_PIN,
               StepperConfig::IN4_PIN) {}

void StepperMotor::begin() {
    _stepper.setSpeed(StepperConfig::MOTOR_SPEED_RPM);
}

void StepperMotor::rotateForwardAndBack() {
    const int stepsFor180 = StepperConfig::STEPS_PER_REV / 2;

    Serial.println("Rotating 180 degrees forward...");
    stepSlowly(stepsFor180);
    Serial.println("Reached 180 degrees. Pausing...");
    delay(StepperConfig::PAUSE_MS);

    Serial.println("Rotating back to start...");
    stepSlowly(-stepsFor180);
    Serial.println("Back at start. Pausing...");
    delay(StepperConfig::PAUSE_MS);
}

void StepperMotor::openGate(int steps) {
    if (StepperConfig::GATE_DEBUG) {
        Serial.print("[GATE] Opening, steps: ");
        Serial.println(steps);
    }
    stepSlowly(StepperConfig::GATE_OPEN_FORWARD ? steps : -steps);
}

void StepperMotor::closeGate(int steps) {
    if (StepperConfig::GATE_DEBUG) Serial.println("[GATE] Closing");
    stepSlowly(StepperConfig::GATE_OPEN_FORWARD ? -steps : steps);
}

// Opens the gate, holds it so the trash falls into the bin, then closes it.
// openSteps <= 0 means the gate stays closed for this class.
void StepperMotor::dropTrash(int openSteps, unsigned long holdMs) {
    if (openSteps <= 0) {
        if (StepperConfig::GATE_DEBUG) Serial.println("[GATE] Stays closed for this class");
        return;
    }

    openGate(openSteps);

    if (StepperConfig::GATE_DEBUG) {
        Serial.print("[GATE] Holding open (ms): ");
        Serial.println(holdMs);
    }
    delay(holdMs);                       // trash falls into the bin

    closeGate(openSteps);
    delay(StepperConfig::GATE_SETTLE_MS);
}

// Steps one motor step at a time instead of one long blocking call.
// Calling yield() after every step lets the ESP8266's background tasks
// (WiFi stack, software watchdog) run, which prevents a Soft WDT reset
// during long rotations.
void StepperMotor::stepSlowly(int totalSteps) {
    int direction = (totalSteps > 0) ? 1 : -1;
    int stepsRemaining = abs(totalSteps);

    for (int i = 0; i < stepsRemaining; i++) {
        _stepper.step(direction);
        yield();
    }
}