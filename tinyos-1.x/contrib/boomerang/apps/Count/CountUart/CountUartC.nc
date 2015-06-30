// $Id: CountUartC.nc,v 1.1.1.1 2007/11/05 19:08:58 jpolastre Exp $

/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * CountUart: Count to the leds and send it over the radio.
 *
 * @author Cory Sharp <info@moteiv.com>
 */

#include "../CountMsg.h"

configuration CountUartC {
}
implementation {
  components Main;
  components CountUartP;
  components new TimerMilliC();
  components GenericComm;
  components LedsC;

  Main.StdControl -> CountUartP;

  CountUartP.Timer -> TimerMilliC;
  CountUartP.SendMsg -> GenericComm.SendMsg[AM_COUNTMSG];
  CountUartP.Leds -> LedsC.Leds;
}

