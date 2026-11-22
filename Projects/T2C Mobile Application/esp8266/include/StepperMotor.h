#pragma once
#include <Stepper.h>
#include "StepperConfig.h"

class StepperMotor {
public:
    StepperMotor();

    void begin();                  // sets rotation speed
    void rotateForwardAndBack();   // one full cycle: 180 degrees forward, pause, 180 back, pause

    // Gate helpers (this stepper opens the gate so trash falls into the bin)
    void openGate(int steps);      // opens by the given number of steps
    void closeGate(int steps);     // closes by the same number of steps
    void dropTrash(int openSteps, unsigned long holdMs); // open -> hold -> close (openSteps <= 0 = stay closed)

private:
    Stepper _stepper;
    void stepSlowly(int totalSteps); // steps one at a time with yield() to avoid watchdog resets
};