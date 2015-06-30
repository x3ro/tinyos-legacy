// $Id: CountReceiveC.nc,v 1.1.1.1 2007/11/05 19:08:58 jpolastre Exp $

/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * CountReceive: Receive the count from the radio and display it on the leds.
 *
 * @author Cory Sharp <info@moteiv.com>
 */

#include "../CountMsg.h"

configuration CountReceiveC {
}
implementation {
  components Main;
  components CountReceiveP;
  components GenericComm;
  components LedsC;

  Main.StdControl -> CountReceiveP;

  CountReceiveP.ReceiveMsg -> GenericComm.ReceiveMsg[AM_COUNTMSG];
  CountReceiveP.Leds -> LedsC.Leds;
}

