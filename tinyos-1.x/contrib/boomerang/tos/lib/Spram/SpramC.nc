/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#include "Spram.h"

/**
 * Spram - "Spam Ram" or "SP RAM".  Spram disseminates a buffer across
 * a sensor network.  This is an alpha release, currently only one RAM
 * image is supported.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
generic configuration SpramC( uint16_t MaxSizeBytes ) {
  provides interface Init;
  provides interface Spram;
}
implementation {
  components new SpramP( MaxSizeBytes );

  components new BitVectorC( (MaxSizeBytes+SPRAM_BYTES_PER_MSG-1)/SPRAM_BYTES_PER_MSG );
  components RandomC;

  components SPC;

  components new TimerMilliC() as AdvertiseTimerC;
  components new TimerMilliC() as BurstTimerC;
  components new TimerMilliC() as ParentTimerC;
  components new TimerMilliC() as RequestTimerC;
  components CounterMilliC;

  Init = SpramP;
  Spram = SpramP;

  SpramP.PageVector -> BitVectorC;
  SpramP.Random -> RandomC;

  SpramP.DataSend -> SPC.SPSend[AM_SPRAMDATAMSG];
  SpramP.DataReceive -> SPC.SPReceive[AM_SPRAMDATAMSG];

  SpramP.RequestSend -> SPC.SPSend[AM_SPRAMREQUESTMSG];
  SpramP.RequestReceive -> SPC.SPReceive[AM_SPRAMREQUESTMSG];

  SpramP.AdvertiseTimer -> AdvertiseTimerC;
  SpramP.BurstTimer -> BurstTimerC;
  SpramP.ParentTimer -> ParentTimerC;
  SpramP.RequestTimer -> RequestTimerC;
  SpramP.LocalTime -> CounterMilliC;
}

