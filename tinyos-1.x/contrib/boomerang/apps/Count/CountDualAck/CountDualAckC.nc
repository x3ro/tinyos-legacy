// $Id: CountDualAckC.nc,v 1.1.1.1 2007/11/05 19:08:58 jpolastre Exp $

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
 * CountDualAck: If the mote id is 1, count to the leds and send it over the
 * radio.  The message is sent to a node with id 2.  If the receiver (id 2)
 * acknowledges the message, mote id 1 increments its count.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration CountDualAckC {
}
implementation {
  components Main;
  components CountDualAckP as Impl;
  components new TimerMilliC();
  components SPC;
  components LedsC;
  
  Main.StdControl -> Impl;

  Impl.Timer -> TimerMilliC;
  Impl.SPSend -> SPC.SPSend[AM_COUNTMSG];
  Impl.SPReceive -> SPC.SPReceive[AM_COUNTMSG];
  Impl.Leds -> LedsC.Leds;
}

