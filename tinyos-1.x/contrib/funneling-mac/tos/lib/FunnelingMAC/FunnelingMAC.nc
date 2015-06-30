/* Copyright (c) 2007 Dartmouth SensorLab.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * paragraph and the author appear in all copies of this software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

/* The funneling-MAC code.
 *
 * Authors: Gahng-Seop Ahn   <ahngang@ee.columbia.edu>,
 *          Emiliano Miluzzo <miluzzo@cs.dartmouth.edu>.
 */

includes FunnelingMAC;

configuration FunnelingMAC {
  provides {
    interface StdControl;
    interface SendMsg[uint8_t id];
    interface RouteManagement;
    interface SnoopFmac;
    interface Query;
  }
}

implementation { 
  components FunnelingMACM, GenericCommPromiscuous as Comm, 
    QueuedSend, TimerC, LedsC, CC1000ControlM;

  StdControl = FunnelingMACM;
  SendMsg = FunnelingMACM;
  RouteManagement = FunnelingMACM;
  SnoopFmac = FunnelingMACM;
  Query = FunnelingMACM;

  FunnelingMACM.SubControl -> QueuedSend.StdControl;
  FunnelingMACM.CommStdControl -> Comm;
  FunnelingMACM.CommControl -> Comm;
  FunnelingMACM.CC1000Control -> CC1000ControlM;

  FunnelingMACM.ReceiveMsg[AM_BEACON] -> Comm.ReceiveMsg[AM_BEACON];
  FunnelingMACM.ReceiveMsg[AM_SCHEDULE] -> Comm.ReceiveMsg[AM_SCHEDULE];
  FunnelingMACM.ReceiveMsg[AM_QUERY] -> Comm.ReceiveMsg[AM_QUERY];

  FunnelingMACM.SendMsgD -> QueuedSend.SendMsg;
  FunnelingMACM.SendMsgB -> Comm.SendMsg[AM_BEACON];
  FunnelingMACM.SendMsgS -> Comm.SendMsg[AM_SCHEDULE];
  FunnelingMACM.SendMsgQ -> Comm.SendMsg[AM_QUERY];

  FunnelingMACM.Leds -> LedsC;
  FunnelingMACM.TimerBeacon -> TimerC.Timer[unique("Timer")];
  FunnelingMACM.BeaconTimeOut -> TimerC.Timer[unique("Timer")];
  FunnelingMACM.ScheduleTimeOut -> TimerC.Timer[unique("Timer")];
  FunnelingMACM.TimerCSMA -> TimerC.Timer[unique("Timer")];
  FunnelingMACM.TimerCSMAduration -> TimerC.Timer[unique("Timer")];
  FunnelingMACM.TimerCSMArepetitions -> TimerC.Timer[unique("Timer")];
  FunnelingMACM.TimerCSMAsnooped -> TimerC.Timer[unique("Timer")];
  FunnelingMACM.TimerTDMA -> TimerC.Timer[unique("Timer")];
  FunnelingMACM.TimerTDMAduration -> TimerC.Timer[unique("Timer")];
  FunnelingMACM.TimerTDMAremaining -> TimerC.Timer[unique("Timer")];
  FunnelingMACM.VirtualSuperframeRemaining -> TimerC.Timer[unique("Timer")];
  FunnelingMACM.TimerSuperframe -> TimerC.Timer[unique("Timer")];
  FunnelingMACM.TimerWaitForCSMA -> TimerC.Timer[unique("Timer")];
  FunnelingMACM.TimerPattern -> TimerC.Timer[unique("Timer")];
  FunnelingMACM.TimerMargin -> TimerC.Timer[unique("Timer")];
  FunnelingMACM.TimerRandomM -> TimerC.Timer[unique("Timer")];
}
