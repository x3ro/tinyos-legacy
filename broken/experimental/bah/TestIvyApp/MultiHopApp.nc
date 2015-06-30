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
 *	   Application Side Component
 *
 *
 * Author:	Barbara Hohlt
 * Project: 	Ivy 
 *
 */

includes IvyNet;

configuration MultiHopApp {
  provides {
    interface StdControl as Control;
    interface Send as Send;
    interface ActiveNotify as ActiveNotify;
  }
}

implementation
{
  
  components GenericComm, AppScheduler;
  components MultiHopSendApp, MultiHopRouteSelectApp ;
  components SlackerQueueM, TimerC, LedsC, RandomLFSR ;

  Send = MultiHopSendApp;
  Control = MultiHopSendApp;
  ActiveNotify = MultiHopSendApp;
  

  MultiHopSendApp.CommControl -> GenericComm.Control;
  MultiHopSendApp.SubControl -> AppScheduler.Control;
  MultiHopSendApp.SubControl -> MultiHopRouteSelectApp.Control;
  AppScheduler.SubControl -> TimerC.StdControl;
  MultiHopSendApp.Leds -> LedsC;
  MultiHopRouteSelectApp.Random -> RandomLFSR;
  
  MultiHopSendApp.SendMsg -> GenericComm.SendMsg[AM_IVYMSG];
  MultiHopSendApp.PowerMode -> AppScheduler.PowerModeSend;
  
  AppScheduler.Timer0 -> TimerC.Timer[unique("Timer")];
  AppScheduler.Timer1 -> TimerC.Timer[unique("Timer")];
  AppScheduler.Leds -> LedsC;
  AppScheduler.ReceiveAdv -> GenericComm.ReceiveMsg[AM_IVYADV];
  AppScheduler.SendReq -> GenericComm.SendMsg[AM_IVYREQ];
  AppScheduler.ReceiveAck -> GenericComm.ReceiveMsg[AM_IVYACK];
  AppScheduler.bestCandidate -> MultiHopRouteSelectApp;

  MultiHopSendApp.Queue -> SlackerQueueM;
}
