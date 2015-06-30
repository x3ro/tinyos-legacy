// $Id: MultiHopRouter.nc,v 1.13 2004/02/19 21:50:07 whong Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Philip Levis
 * Revision:		$Id: MultiHopRouter.nc,v 1.13 2004/02/19 21:50:07 whong Exp $
 *
 */

/**
 * @author Philip Levis
 */


includes MultiHop;

configuration MultiHopRouter {
  
  provides {
    interface StdControl;
    // The interface are as parameterised by the active message id
	// only the 10 active message ids defined MultiHop.h are supported.
    interface Receive[uint8_t id];
    interface Intercept[uint8_t id];
    interface Intercept as Snoop[uint8_t id];
    interface Send[uint8_t id];
    interface RouteControl;
  }

  uses {
    interface ReceiveMsg[uint8_t id];
  }

}

implementation {
  
#ifdef OLD_ROUTING
  components MultiHopRouteM, GenericCommPromiscuous as Comm, 
    QueuedSend, TimerC, RandomLFSR, 
	LedsC, NoLeds;

  Send = MultiHopRouteM;
  Intercept = MultiHopRouteM.Intercept;
  Snoop = MultiHopRouteM.Snoop;
  Receive = MultiHopRouteM;

  StdControl = MultiHopRouteM;
  RouteControl = MultiHopRouteM;

  ReceiveMsg = MultiHopRouteM;

  MultiHopRouteM.SubControl -> QueuedSend.StdControl;
  MultiHopRouteM.CommStdControl -> Comm;
  MultiHopRouteM.CommControl -> Comm;

  //MultiHopRouteM.ReceiveMsg -> Comm.ReceiveMsg;
  MultiHopRouteM.SendMsg -> QueuedSend.SendMsg;

  MultiHopRouteM.Random -> RandomLFSR;
  MultiHopRouteM.Leds -> LedsC;
  MultiHopRouteM.Timer -> TimerC.Timer[unique("Timer")];
#else
  // Uncomment for use with mh6
  components MultiHopEngineM, MultiHopLEPSM, GenericCommPromiscuous as Comm, 
    QueuedSend, 
#ifdef USE_WATCHDOG
	WDTC,
#endif
	TimerC;

  StdControl = MultiHopEngineM;
  Receive = MultiHopEngineM;
  Send = MultiHopEngineM;
  Intercept = MultiHopEngineM.Intercept;
  Snoop = MultiHopEngineM.Snoop;
  RouteControl = MultiHopEngineM;

  ReceiveMsg = MultiHopEngineM;

  MultiHopEngineM.SubControl -> QueuedSend.StdControl;
  MultiHopEngineM.SubControl -> MultiHopLEPSM.StdControl;
  MultiHopEngineM.CommStdControl -> Comm;
  MultiHopEngineM.CommControl -> Comm;
  MultiHopEngineM.RouteSelectCntl -> MultiHopLEPSM.RouteControl;
  MultiHopEngineM.RouteSelect -> MultiHopLEPSM;


  MultiHopEngineM.SendMsg -> QueuedSend.SendMsg;
  
  MultiHopLEPSM.Timer -> TimerC.Timer[unique("Timer")];  
  MultiHopLEPSM.ReceiveMsg -> Comm.ReceiveMsg[AM_MULTIHOPMSG];
  MultiHopLEPSM.Snoop -> MultiHopEngineM.Snoop;
  MultiHopLEPSM.SendMsg -> QueuedSend.SendMsg[AM_MULTIHOPMSG];
#ifdef USE_WATCHDOG
  MultiHopLEPSM.PoochHandler -> WDTC.StdControl;
  MultiHopLEPSM.WDT -> WDTC.WDT;
#endif
#endif
}
