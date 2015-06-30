/*			
 *
 *
 * "Copyright (c) 2002-2005 The Regents of the University  of California.  
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
/*
 *
 *	Buffer Management with SlackerQueues
 *
 * Author:	Barbara Hohlt
 * Project:   	FPS	
 *
 * This component illustrates how to implement buffer management
 * and forwarding queues for multihop using SlackerQueues.
 *
 */

includes FPS;

configuration MultiHop {
  provides {
    interface StdControl as Control;
    interface Send as Send;
    interface Send as SendApp;
    interface ActiveNotify as ActiveNotify;
    interface Receive;
  }
}

implementation
{
  
  components GenericComm, MultiHopSend, MultiHopRoute ;
  components MultiHopRouteSelect, SlackerQueueM, TimerC, LedsC ;

  Send = MultiHopSend.Send;
  SendApp = MultiHopSend.SendApp;
  Control = MultiHopRoute;
  Receive = MultiHopRoute;
  ActiveNotify = MultiHopSend;
  

  MultiHopRoute.SubControl -> GenericComm.Control;
  MultiHopRoute.SubControl -> MultiHopSend.Control;
  MultiHopRoute.SubControl -> SlackerQueueM.Control;
  MultiHopSend.SubControl -> TimerC.StdControl;
  MultiHopSend.Leds -> LedsC;
  
  MultiHopSend.SendMsg -> GenericComm.SendMsg[AM_FPSMSG];
  MultiHopSend.Timer0 -> TimerC.Timer[unique("Timer")];
  MultiHopSend.RouteSelect -> MultiHopRouteSelect.RouteSelect;

  MultiHopSend.Queue -> SlackerQueueM;

  MultiHopRoute.Send -> MultiHopSend.Send;
  MultiHopRoute.ReceiveMsg -> GenericComm.ReceiveMsg[AM_FPSMSG];

  MultiHopRoute.Queue -> SlackerQueueM;
}
