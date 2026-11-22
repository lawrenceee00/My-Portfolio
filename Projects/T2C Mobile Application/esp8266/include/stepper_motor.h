#pragma once
#include <Arduino.h>

// STEP/DIR driver (TB6600 / DM542 style) - ENA is NOT used.
// Leave ENA+ / ENA- unconnected: the driver stays enabled by default.
#define PUL_PIN   D0   // GPIO16 -> STEP / PUL
#define DIR_PIN   D7   // GPIO13 -> DIR

// NEMA 17 = 200 full steps/rev. Actual steps/rev depends on the driver's
// microstep DIP switch setting — adjust to match your driver's config.
#define MICROSTEPS        1
#define STEPS_PER_REV     (200 * MICROSTEPS)   // 200 at full step, 1600 at 1/8 microstepping

#define STEP_PULSE_US     800  // pulse HIGH width (same timing as your current NemaConfig)
#define STEP_DELAY_US    7000// ADJUST SPEED: time between pulses, lower = faster

// If the NEMA turns the wrong way, flip this between true and false.
#define INVERT_DIR        false

// ─── Slots ──────────────────────────────────────────────────────────
// UNKNOWN is the default and sits at HOME: the NEMA does NOT move for it.
#define SLOT_UNKNOWN      0
#define SLOT_PLASTIC      1
#define SLOT_CAN          2

// ─── Slot calibration ───────────────────────────────────────────────
// Plain step counts from HOME for each slot. Tune these directly while
// calibrating — increase/decrease until the bin lines up physically.
// (At 200 steps/rev: 50 = 90 degrees, 100 = 180 degrees)
#define SLOT_PLASTIC_STEPS    360 // slot 1 — adjust until aligned with PLASTIC bin
#define SLOT_CAN_STEPS       200  // slot 2 — adjust until aligned with CAN bin

// ─── Return-to-HOME calibration ──────────────────────────────────────
// Steps needed to get back to HOME from each slot. Independent from the
// forward SLOT_*_STEPS above because backlash/slack can make the return
// trip need a different count — tune these separately if homing over-
// or undershoots.
#define HOME_FROM_PLASTIC_STEPS   360  // return trip from PLASTIC slot
#define HOME_FROM_CAN_STEPS      200  // return trip from CAN slot

// Pause after the NEMA reaches a bin, before the gate opens (ms)
#define SLOT_SETTLE_MS    300

#define STEPPER_DEBUG     true

void stepper_setup();
void stepper_rotateToSlot(int slotNumber);   // SLOT_UNKNOWN = NEMA does not move
void stepper_home();