/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
#include "sp.h"
#include "sp_cc2420.h"

/**
 * Wrapper configuration that ties together the necessary items for SP
 * to effectively interact with the link protocol.
 * <p>
 * Includes the necessary primitives for running on the CC2420 transceiver.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration LinkRadio {
  provides {
    interface StdControl;
    interface SPSend;
    interface SPLinkStats;
    interface SPLinkEvents;
    interface SPInterface;
    interface TimeStamping<T32khz, uint32_t>;
    interface ReceiveMsg as Receive @exactlyonce();
  }
  uses {
    interface ObjectPool<sp_message_t> as Pool;
    interface ObjectPoolEvents<sp_message_t> as PoolEvents;
  }
}
implementation {
  components CC2420RadioC
    , CC2420SynchronizedC
    , CC2420TimeStampingC
    ;

  StdControl = CC2420SynchronizedC;
  SPSend = CC2420SynchronizedC;
  SPLinkStats = CC2420SynchronizedC;
  SPLinkEvents = CC2420SynchronizedC;
  SPInterface = CC2420SynchronizedC;

  Pool = CC2420SynchronizedC;
  PoolEvents = CC2420SynchronizedC;

  TimeStamping = CC2420TimeStampingC;

  Receive = CC2420RadioC;

}
