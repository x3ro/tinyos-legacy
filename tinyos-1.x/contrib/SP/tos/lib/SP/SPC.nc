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

/**
 * @modified 3/8/06
 *
 * @author Arsalan Tavakoli <arsalan@cs.berkeley.edu>
 * @author Sukun Kim <binetude@cs.berkeley.edu>
 */
configuration SPC {
  provides {
    interface SplitControl as Control;
    interface SPSend[uint8_t id];
    interface SPSendQueue[uint8_t id];
    interface SPReceive[uint8_t id];
    interface SPNeighbor;
  }
  uses {
    interface SplitControl as RadioControl;
    interface SendSP as RadioSend;
    interface ReceiveSP as RadioReceive;

    interface StdControl as UARTControl;
    interface SendSP as UARTSend;
    interface ReceiveSP as UARTReceive;

    interface LinkEstimator;
    interface SPLinkAdaptor;
  }
}
implementation {
  components SPM as SPImpl, TimerC, LedsC;

  Control = SPImpl.Control;
  SPReceive = SPImpl.SPReceive;
  SPSend = SPImpl.SPSend;
  SPSendQueue = SPImpl.SPSendQueue;
  SPNeighbor = SPImpl.SPNeighbor;

  RadioControl = SPImpl.RadioControl;
  RadioSend = SPImpl.RadioSend;
  RadioReceive = SPImpl.RadioReceive;

  UARTControl = SPImpl.UARTControl;
  UARTSend = SPImpl.UARTSend;
  UARTReceive = SPImpl.UARTReceive;

  LinkEstimator = SPImpl.LinkEstimator;
  SPLinkAdaptor = SPImpl;

  SPImpl.TimerControl -> TimerC;
  SPImpl.EvictionTimer -> TimerC.Timer[unique("Timer")];
  SPImpl.Time -> TimerC.LocalTime;
  SPImpl.Leds -> LedsC;
}
