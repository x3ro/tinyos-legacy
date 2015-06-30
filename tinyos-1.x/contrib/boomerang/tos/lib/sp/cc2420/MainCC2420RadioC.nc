/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Overrides the default MainCC2420RadioC in lib/CC2420Radio so that
 * SP is the only entity that controls the radio.
 * <p>
 * This is an internal component, please do not modify.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
configuration MainCC2420RadioC {
}
implementation {
  // CC2420 is under direct control of SP
}

