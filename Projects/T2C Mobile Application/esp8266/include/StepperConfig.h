#pragma once
#include <Arduino.h>

// ============================================
//  STEPPER CONFIGURATION - adjust these anytime
//  28BYJ-48 stepper wired through a ULN2003 driver board.
//  This stepper is the GATE: it opens so the trash falls into the bin.
// ============================================
namespace StepperConfig {
    // ULN2003 driver board input pins
    const uint8_t IN1_PIN = D1; // GPIO5
    const uint8_t IN2_PIN = D2; // GPIO4
    const uint8_t IN3_PIN = D5; // GPIO14
    const uint8_t IN4_PIN = D6; // GPIO12

    // 28BYJ-48 with its internal gearbox: ~2048 steps = one full 360 degree
    // turn of the output shaft (using the Stepper library's 4-step sequence).
    const int STEPS_PER_REV = 2048;

    // Converts a desired rotation (in degrees) into motor steps, based on
    // STEPS_PER_REV. This is the ONLY place gate-open amounts should be
    // tuned from now on — set degrees below, not raw step counts.
    constexpr int degreesToSteps(float degrees) {
        return (int)(STEPS_PER_REV * (degrees / 360.0f));
    }

    const int MOTOR_SPEED_RPM   = 12;   // rotation speed (higher = faster, less torque)
    const unsigned long PAUSE_MS = 1000; // pause at each end before reversing

    // ─── Gate calibration ────────────────────────────────────────────
    // Direction that OPENS the gate. If it opens the wrong way, flip this.
    const bool GATE_OPEN_FORWARD = true;

    // How far the gate opens for each class, in DEGREES. Tune here.
    // Use 0 to keep the gate CLOSED for that class.
    const float GATE_OPEN_DEGREES_PLASTIC = 180.0f;
    const float GATE_OPEN_DEGREES_CAN     = 180.0f;
    const float GATE_OPEN_DEGREES_UNKNOWN = 180.0f;

    // Derived step counts - don't edit these directly, edit the degrees above.
    const int GATE_OPEN_STEPS_PLASTIC = degreesToSteps(GATE_OPEN_DEGREES_PLASTIC);
    const int GATE_OPEN_STEPS_CAN     = degreesToSteps(GATE_OPEN_DEGREES_CAN);
    const int GATE_OPEN_STEPS_UNKNOWN = degreesToSteps(GATE_OPEN_DEGREES_UNKNOWN);

    // How long the gate stays open for each class (ms), so the trash can fall.
    const unsigned long GATE_HOLD_MS_PLASTIC = 1500;
    const unsigned long GATE_HOLD_MS_CAN     = 1500;
    const unsigned long GATE_HOLD_MS_UNKNOWN = 1500;

    const unsigned long GATE_SETTLE_MS = 300;  // pause after the gate closes

    const bool GATE_DEBUG = true;              // print gate info to Serial
}