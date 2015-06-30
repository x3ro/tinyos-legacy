/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
#ifndef _H_sensorboard_h
#define _H_sensorboard_h

#include "msp430hardware.h"

// sensorboard dependent connection of AD524X shutdown pin
TOSH_ASSIGN_PIN(AD524X_SD, 3, 5);

// Accel interrupt pin
TOSH_ASSIGN_PIN(ACCEL_INT, 2, 3);

// Microphone interrupt pin
TOSH_ASSIGN_PIN(MIC_INT, 2, 6);

#endif
