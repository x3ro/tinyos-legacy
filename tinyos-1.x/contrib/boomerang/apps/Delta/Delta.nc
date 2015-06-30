/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#include "Delta.h"

/** 
 * The Delta application is an example of a multihop data collection
 * system.  By installing Delta on Moteiv's motes, the devices will
 * sample their internal temperature sensor and report readings using
 * a Multihop/Mesh topology.  Compile and install using:
 * <p>
 *  <tt>make tmote</tt><br>
 *  <tt>make tmote install</tt>
 * <p>
 * Delta supports Tmote Sky and Tmote Invent.  Compile for Tmote Invent
 * using:
 * <p>
 *  <tt>make tmoteinvent</tt><br>
 *  <tt>make tmoteinvent install</tt>
 * <p>
 * Delta also supports low power operation using Moteiv's low power
 * synchronization software.  The default duty cycle of Moteiv's low
 * power networks is 5%.  To compile Delta with low power duty
 * cycling, use the following command:
 * <p>
 *  <tt>make tmote lowpower</tt>
 * <p>
 * The duty cycle for Delta is configurable at compile time.  By
 * specifying a value to the lowpower option, you can change the duty
 * cycle.  For example, to specify a duty cycle of 2%, compile with:
 * <p>
 *  <tt>make tmote lowpower,2</tt>
 * <p>
 * After installing Delta on Moteiv motes, you have two options for the
 * base station mote.
 * <p>
 * <b>Option 1:</b>
 * <p>
 * The base station is installed with address 0 using the following command:
 * <p>
 *  <tt>make tmote reinstall,0</tt>
 * <p>
 * Any node with address 0 automatically configures itself to be the
 * base station.  You can run any application to acquire data from
 * node 0, such as Trawler (described below) or Listen (java
 * net.tinyos.tools.Listen).
 * <p>
 * <b>Option 2:</b>
 * <p>
 * Any node with USB may be used as the base station, but it must
 * first be informed by the PC that it is a base station.  This
 * procedure is completed by the Trawler java application.  If your
 * mote is connected on communications port COM5, start the Trawler
 * application with the command:
 * <p>
 *  <tt>MOTECOM=serial@COM5:tmote java com.moteiv.trawler.Trawler</tt>
 * <p>
 * Trawler will start, communicate with the mote connected to the PC,
 * and start building the Multihop network.
 * <p>
 * <b>NOTE:</b> For nodes with addresses that are not 0, they will cease
 * acting as the base station as soon as the Trawler application is
 * closed or terminated.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration Delta {
}
implementation {
  components Main;
  components MultiHop
    , DeltaM as Impl
    , TimerC
    , LedsC
    , DemoSensorC
    ;

  Main.StdControl -> MultiHop;
  Main.StdControl -> TimerC;
  Main.StdControl -> DemoSensorC;
  Main.StdControl -> Impl;

  // periodically sample a sensor
  Impl.Timer -> TimerC.Timer[unique("Timer")];
  Impl.TimerBlink -> TimerC.Timer[unique("Timer")];
  Impl.ADC -> DemoSensorC;

  // send data messages
  Impl.SendDeltaMsg -> MultiHop.Send[AM_DELTAMSG];

  // monitor traffic being forwarded
  Impl.SnoopDeltaMsg -> MultiHop.Intercept[AM_DELTAMSG];

  // get statistics about current operation
  Impl.RouteControl -> MultiHop;
  Impl.RouteStatistics -> MultiHop;

  // pretty LEDs
  Impl.Leds -> LedsC;

}
