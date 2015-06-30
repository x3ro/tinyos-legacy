// $Id: CountDualC.nc,v 1.1.1.1 2007/11/05 19:08:58 jpolastre Exp $

/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#include "../CountMsg.h"

/**
 * CountDual: If the mote id is 1, count to the leds and send it over the
 * radio.  Otherwise, receive the count from the radio and display it on the
 * leds.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
configuration CountDualC {
}
implementation {
  components Main;
  components CountDualP;
  components new TimerMilliC();
  components GenericComm;
  components LedsC;
  
  Main.StdControl -> CountDualP;

  CountDualP.Timer -> TimerMilliC;
  CountDualP.SendMsg -> GenericComm.SendMsg[AM_COUNTMSG];
  CountDualP.ReceiveMsg -> GenericComm.ReceiveMsg[AM_COUNTMSG];
  CountDualP.Leds -> LedsC.Leds;
}

