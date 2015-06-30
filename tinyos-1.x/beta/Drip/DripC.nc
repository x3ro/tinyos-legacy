//$Id: DripC.nc,v 1.5 2005/06/14 18:19:35 gtolle Exp $

/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

includes Drip;

/**
 *
 * Drip provides an epidemic dissemination service for single messages.
 * <p>
 * Drip messages are identified using a standard Active Message ID.
 * <p>
 * Incoming messages are received on the Receive interface.
 * <p>
 * Each client of Drip is responsible for caching the message received
 * on the Receive interface, and providing it to the Drip interface
 * when retransmission is necessary.
 * <p>
 * Here is an example wiring you can use with Drip:
 * <p>
 * <tt>
 * TestDripM.ReceiveDrip -> DripC.Receive[AM_TESTDRIPMSG];<br>
 * TestDripM.Drip -> DripC.Drip[AM_TESTDRIPMSG];<br>
 * DripC.DripState[AM_TESTDRIPMSG] -> DripStateC.DripState[unique("DripState")];<br>
 * </tt>
 * <p>
 * @author Gilman Tolle <get@cs.berkeley.edu>
 */

configuration DripC {
  provides {
    interface StdControl;
    interface Receive[uint8_t id];
    interface Drip[uint8_t id];
  }
  uses {
    interface DripState[uint8_t id];
  }
}

implementation {
  components 
    DripM, 
    DripStateC,
    GenericComm as Comm, 
    WakeupCommC,
    TimerC, 
    RandomLFSR, 
    LedsC as Leds;

  StdControl = DripM;
  Receive = DripM.Receive;
  Drip = DripM;
  DripState = DripM;
  
  DripM.SubControl -> Comm;
  DripM.SubControl -> TimerC;
  DripM.SubControl -> DripStateC;

  DripM.DripStateMgr -> DripStateC.DripStateMgr;

  DripM.ReceiveMsg -> Comm.ReceiveMsg[AM_DRIPMSG];
  DripM.SendMsg -> Comm.SendMsg[AM_DRIPMSG];

  DripM.WakeupSendMsg -> WakeupCommC.SendMsg[AM_DRIPMSG];

  DripM.SendTimer -> TimerC.Timer[unique("Timer")];

  DripM.Leds -> Leds;
  
  DripM.Random -> RandomLFSR;
}

