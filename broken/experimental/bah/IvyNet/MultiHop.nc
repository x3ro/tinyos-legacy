/*									tab:4
 *
 *
 * "Copyright (c) 2002-2004 The Regents of the University  of California.  
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
 *	Ivy Slackers Multihop Routing
 *	   Network Side Component 
 *
 *
 * Author:	Barbara Hohlt
 * Project: 	Ivy 
 *
 */

includes IvyNet;

configuration MultiHop {
  provides {
    interface StdControl as Control;
    interface Send as Send;
  }
}

implementation
{
  
  components GenericComm, MultiHopSend, MultiHopRoute, PowerScheduler;
  components SlackerQueueM, TimerC, LedsC, RandomLFSR ;

  Send = MultiHopSend;
  Control = MultiHopRoute;
  
  MultiHopRoute.SubControl -> MultiHopSend.Control;

  MultiHopSend.SubControl -> PowerScheduler.Control;
  PowerScheduler.CommControl -> GenericComm.Control;
  PowerScheduler.SubControl -> TimerC.StdControl;
  MultiHopSend.Leds -> LedsC;
  
  MultiHopSend.SendMsg -> GenericComm.SendMsg[AM_IVYMSG];
  MultiHopSend.SendLog -> GenericComm.SendMsg[AM_IVYLOG];
  MultiHopSend.PowerMode -> PowerScheduler.PowerModeSend;
  
  MultiHopRoute.Send -> MultiHopSend;
  MultiHopRoute.PowerMode -> PowerScheduler.PowerModeRoute;
  MultiHopRoute.ReceiveMsg -> GenericComm.ReceiveMsg[AM_IVYMSG];

  PowerScheduler.Timer0 -> TimerC.Timer[unique("Timer")];
  PowerScheduler.Timer1 -> TimerC.Timer[unique("Timer")];
  PowerScheduler.Random -> RandomLFSR;
  PowerScheduler.Leds -> LedsC;
  PowerScheduler.SendAdv -> GenericComm.SendMsg[AM_IVYADV];
  PowerScheduler.ReceiveAdv -> GenericComm.ReceiveMsg[AM_IVYADV];
  PowerScheduler.SendReq -> GenericComm.SendMsg[AM_IVYREQ];
  PowerScheduler.ReceiveReq -> GenericComm.ReceiveMsg[AM_IVYREQ];
  PowerScheduler.SendAck -> GenericComm.SendMsg[AM_IVYACK];
  PowerScheduler.ReceiveAck -> GenericComm.ReceiveMsg[AM_IVYACK];

  MultiHopRoute.Queue -> SlackerQueueM;
  MultiHopSend.Queue -> SlackerQueueM;
}
