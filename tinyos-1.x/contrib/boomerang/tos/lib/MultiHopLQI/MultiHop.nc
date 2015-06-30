// $Id: MultiHop.nc,v 1.1.1.1 2007/11/05 19:11:27 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 *
 */

#include "MultiHop.h"

/**
 * MultiHop routing using LQI on Moteiv's Tmote platforms.
 * <p>
 * This is the main MultiHop configuration.  Simply include MultiHop in
 * your components list, and then send and receive messages using
 * the Send and Intercept interfaces.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */

configuration MultiHop {
  provides {
    interface StdControl;
    interface Send[uint8_t id];
    interface Intercept[uint8_t id];
    interface Intercept as Snoop[uint8_t id];
    interface RouteControl;
    interface RouteStatistics;
  }
}
implementation {
  components MultiHopDataM as DataM
    , MultiHopLQIM as ControlM
    , TimerC
    , SPC as Radio
    , RandomLFSR as Random
    , UartDetectC // to determine who is the base station
#ifdef MHOP_LEDS
    , LedsC
#else
    , NoLeds as LedsC
#endif
    ;

  StdControl = TimerC;
  StdControl = ControlM;
  StdControl = DataM;

  // provided interfaces for sending
  Send = DataM;

  // intercept and/or snoop the data
  Intercept = DataM.Intercept;
  Snoop = DataM.Snoop;

  // Sends and receives messages, then performs second layer dispatch
  DataM.SPSend -> Radio.SPSend[AM_MULTIHOPMSG];
  DataM.SPSendNext -> Radio.SPSendNext[AM_MULTIHOPMSG];
  DataM.ReceiveMsg -> Radio.ReceiveMsg[AM_MULTIHOPMSG];
  DataM.SPMessage -> Radio;

  // Send and receive beacons from other nodes
  ControlM.SPSend -> Radio.SPSend[AM_BEACONMSG];
  ControlM.ReceiveMsg -> Radio.ReceiveMsg[AM_BEACONMSG];

  // Control
  RouteControl = DataM;

  // Statistics
  RouteStatistics = DataM;
  DataM.ControlRStat -> ControlM;
  
  // parent selection and maintainance
  DataM.ControlRC -> ControlM.RouteControl;
  DataM.ControlRSel -> ControlM;

  // internal Timers
  DataM.Timer -> TimerC.TimerMilli[unique("TimerMilli")];
  ControlM.RouteTimer -> TimerC.Timer[unique("Timer")];

  // Base station assignment
  ControlM -> UartDetectC.Connection;

  // Random Number Generator
  ControlM.Random -> Random;

  // LEDs
  DataM.Leds -> LedsC;

}

