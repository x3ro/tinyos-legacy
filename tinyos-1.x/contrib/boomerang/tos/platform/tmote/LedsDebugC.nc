/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Creates functions that can simply be used when debugging applications
 * that does not require wiring (just including the LedsDebugC component).
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
configuration LedsDebugC {
}
implementation {
  components LedsDebugP, LedsC;
  LedsDebugP.Leds -> LedsC;
}

