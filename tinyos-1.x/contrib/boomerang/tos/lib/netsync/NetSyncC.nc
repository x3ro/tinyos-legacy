/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
#include "NetSync.h"

/**
 * Network-wide synchronization for SP-enabled devices.  NetSyncC enables
 * and maintains network synchronization for devices running the SP
 * link-layer abstraction (exposed by the SPC configuration).
 * <p>
 * To use NetSyncC, simply make your application with the following
 * command using the Moteiv make system for TinyOS: <br>
 * <tt>  make &lt;platform&gt; lowpower </tt>
 * <p>
 * NetSyncC will automatically be included.
 * <p>
 * The network coordinator of the synchronized network is determined by
 * two things: <br>
 * (1) if the TOS_LOCAL_ADDRESS of the node == 0 <br>
 * (2) if the node is connected to a PC and UartDetect has established 
 * a connection
 * <p>
 * NetSyncC includes NetWakeC, a global network wakeup protocol based
 * on Trickle.  NetWakeC is always included, so no component should ever
 * include or wire to NetWakeC other than NetSyncC.
 * <p>
 * <b>IMPORTANT NOTE:</b> Always use NetSyncC by compiling with
 * <tt>make &lt;platform&gt; lowpower</tt>.  Directly wiring to NetSyncC 
 * or to NetWakeC can adversely alter the order of system initialization
 * and produce unpredictable results.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration NetSyncC {
  provides interface GlobalTime<T32khz>;
}
implementation {
  components MainNetSyncC
    , SPC
    , new TimerMilliC() as TimerIC
    , new TimerMilliC() as TimerTauC
    , Counter32khzC
    , UartDetectC
    , NetSyncM as Impl
    , RandomC
    , NetWakeC
#ifdef MOTEIV_NETSYNC_LEDS
    , LedsC
#else
    , NoLeds as LedsC
#endif
    ;

  GlobalTime = Impl.GlobalTime;

  Impl.SPSend -> SPC.SPSend[AM_NETSYNCMSG];
  Impl.SPUtil -> SPC;
  Impl.SPMessage -> SPC;
  Impl -> SPC.SPNeighbor[unique("SPNeighbor")];
  Impl.TimerI -> TimerIC;
  Impl.TimerTau -> TimerTauC;
  Impl.LocalTime -> Counter32khzC;
  Impl.Random -> RandomC;
  Impl.Detect -> UartDetectC;
  Impl.Leds -> LedsC;
  Impl.Receive -> SPC.ReceiveMsg[AM_NETSYNCMSG];
}
