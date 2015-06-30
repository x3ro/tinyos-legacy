/**
 * Copyright (c) 2004 - The Ohio State University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */


/* 
 * Authors: Hongwei Zhang, Anish Arora
 */

includes AM;
includes ReliableComm;
#ifdef LOG_STATE
includes Matchbox;
#endif

configuration ReliableCommC {
  provides {
    interface StdControl;
    interface ReliableSendMsg[uint8_t id];
    interface ReliableReceiveMsg[uint8_t id];
    interface ReliableCommControl;
  }
}

implementation {
  components ReliableCommM,  RadioCRCPacket as RadioComm, GenericComm as UARTComm, //UARTFramedPacket as UARTComm, 
#ifndef TOSSIM_SYSTIME
    CC1000ControlM, OTimeC as TsyncC, 
#else 
    SysTimeC,
#endif
#ifdef USE_MacControl
     CC1000RadioC, 
#endif
#ifdef LOG_STATE
    //ReporterM,
    Matchbox, NoDebug,
#endif
    TimerC, NoLeds as Leds;

  StdControl = ReliableCommM;

  ReliableSendMsg = ReliableCommM.ReliableSendMsg;
  ReliableReceiveMsg = ReliableCommM.ReliableReceiveMsg; 
  ReliableCommControl = ReliableCommM.ReliableCommControl;

  ReliableCommM.RadioControl -> RadioComm.Control;
  ReliableCommM.RadioBareSend -> RadioComm.Send;
  ReliableCommM.ReceiveMsg -> RadioComm.Receive;

  ReliableCommM.UARTControl -> UARTComm.Control;
  //ReliableCommM.UARTBareSend -> UARTComm.Send;
  ReliableCommM.UARTSend -> UARTComm.SendMsg[UART_HANDLER_ID];

  ReliableCommM.TimerControl -> TimerC.StdControl;
  ReliableCommM.Timer -> TimerC.Timer[unique("Timer")];

#ifndef TOSSIM_SYSTIME
  ReliableCommM.CC1000Control -> CC1000ControlM; 
  ReliableCommM.TsyncControl -> TsyncC.StdControl;
  ReliableCommM.Time -> TsyncC; 
#else
  ReliableCommM.SysTime -> SysTimeC;
#endif
#ifdef USE_MacControl
  ReliableCommM.MacControl -> CC1000RadioC;
#endif

  ReliableCommM.Leds -> Leds; 

#ifdef LOG_STATE
  //ReliableCommM.DataLogger -> ReporterM;
  ReliableCommM.MatchboxControl -> Matchbox.StdControl;
  Matchbox.ready -> ReliableCommM.matchboxReady;
  ReliableCommM.FileRead -> Matchbox.FileRead[unique("FileRead")];
  ReliableCommM.FileWrite -> Matchbox.FileWrite[unique("FileRead")];
  Matchbox.Debug -> NoDebug;
#endif
}
