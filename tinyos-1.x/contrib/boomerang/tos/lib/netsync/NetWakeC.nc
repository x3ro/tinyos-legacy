/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
#include "NetWake.h"

/**
 * A network-wide wakeup service.  This service controls the wakeup of
 * an entire network at once, with parameters given by a base station
 * and flooded through the network using a Trickle-like protocol.
 * The wakeup cannot be changed if the period is already active (in
 * other words, if the current time is after the start time but before
 * the stop time).  Otherwise, a new schedule may be installed prior to
 * or after the current schedule is executed.
 * <p>
 * NetWakeC is coupled with NetSyncC and should not be used independently.
 * No component should ever need to include NetWakeC nor should any
 * component wire to NetWakeC.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration NetWakeC {
}
implementation {
  components NetWakeM as Impl
    , NetSyncC
    , SPC
    , Counter32khzC
    , new TimerMilliC() as TimerTauC
    , new TimerMilliC() as TimerIC
    , RandomC
    ;

  Impl.ReceiveMsg -> SPC.ReceiveMsg[AM_NETWAKEMSG];
  Impl.SPSend -> SPC.SPSend[AM_NETWAKEMSG];

  Impl.GlobalTime -> NetSyncC;
  Impl.LocalTime -> Counter32khzC;
  Impl.SPNeighbor -> SPC.SPNeighbor[unique("SPNeighbor")];

  Impl.TimerTau -> TimerTauC;
  Impl.TimerI -> TimerIC;

  Impl.Random -> RandomC;

}
