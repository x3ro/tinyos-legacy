/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * This is an internal component that controls the initialization order
 * of Deluge.  Please do not modify.
 */
configuration MainDelugeC {
}
implementation {
  components MainDelugeP;
  components DelugeM;
  components CC2420RadioC;

  MainDelugeP.DelugeControl -> DelugeM;
  MainDelugeP.RadioControl -> CC2420RadioC;
}

