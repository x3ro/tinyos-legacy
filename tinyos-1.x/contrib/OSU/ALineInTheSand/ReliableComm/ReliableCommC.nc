/**
 * Copyright (c) 2003 - The Ohio State University.
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

includes ReliableCommMsg;

configuration ReliableCommC {
  provides {
    interface StdControl;
    interface ReliableSendMsg[uint8_t id];
    interface ReliableReceiveMsg[uint8_t id];
    //interface QueueControl;
  }
}

implementation {
  components ReliableCommM,  RadioCRCPacket, TimerC, RandomLFSR, CC1000ControlM, LedsC as Leds; 

  StdControl = ReliableCommM;

  ReliableSendMsg = ReliableCommM.ReliableSendMsg;
  ReliableReceiveMsg = ReliableCommM.ReliableReceiveMsg; 

  ReliableCommM.RadioControl -> RadioCRCPacket.Control;
  ReliableCommM.BareSendMsg -> RadioCRCPacket.Send;
  ReliableCommM.ReceiveMsg -> RadioCRCPacket.Receive;

  ReliableCommM.TimerControl -> TimerC.StdControl;   
  ReliableCommM.Timer -> TimerC.Timer[unique("Timer")];

  ReliableCommM.Random -> RandomLFSR;

  ReliableCommM.CC1000Control -> CC1000ControlM; 

  ReliableCommM.Leds -> Leds; 
}
