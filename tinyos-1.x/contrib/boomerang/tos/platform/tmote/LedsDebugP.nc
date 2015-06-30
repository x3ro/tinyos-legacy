/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#include "LedsDebug.h"

/**
 * Creates functions that can simply be used that does not require
 * wiring.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
module LedsDebugP {
  uses interface Leds;
}
implementation
{
  void leds_red_on() __attribute__((C)) { call Leds.redOn(); }
  void leds_red_off() __attribute__((C)) { call Leds.redOff(); }
  void leds_red_toggle() __attribute__((C)) { call Leds.redToggle(); }

  void leds_green_on() __attribute__((C)) { call Leds.greenOn(); }
  void leds_green_off() __attribute__((C)) { call Leds.greenOff(); }
  void leds_green_toggle() __attribute__((C)) { call Leds.greenToggle(); }

  void leds_yellow_on() __attribute__((C)) { call Leds.yellowOn(); }
  void leds_yellow_off() __attribute__((C)) { call Leds.yellowOff(); }
  void leds_yellow_toggle() __attribute__((C)) { call Leds.yellowToggle(); }

  void leds_set(int n) __attribute__((C)) { call Leds.set(n); }

}
