/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Platform initialization code for Tmote platforms.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
configuration PlatformC {
  provides interface Init;
  uses interface Init as ArbiterInits;
}
implementation {
  components Main;
  components PlatformP;
  components HPLInitC;
  components MSP430DCOCalibC; //periodic recalibration of the DCO
#ifdef MOTEIV_LOWPOWER
  components NetSyncC;
#endif

  Init = PlatformP;
  ArbiterInits = PlatformP;

  PlatformP.hplInit -> HPLInitC;
}

