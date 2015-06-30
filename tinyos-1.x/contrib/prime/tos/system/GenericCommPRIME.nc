/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 */

configuration GenericCommPRIME
{
  provides {
    interface StdControl as Control;

    interface SendVarLenPacket as UARTSendRawBytes;
    
    // The interface are as parameterised by the active message id
    interface SendMsg[uint8_t id];
    interface ReceiveMsg[uint8_t id];

    // How many packets were received in the past second
    command uint16_t activity();

  }
  uses {
    // signaled after every send completion for components which wish to
    // retry failed sends
    event result_t sendDone();
  }
}
implementation
{
  // CRCPacket should be multiply instantiable. As it is, I have to use
  // RadioCRCPacket for the radio, and UARTNoCRCPacket for the UART to
  // avoid conflicting components of CRCPacket.
  // Tried to use RadioNoCRCPacket instead of RadioCRCPacket but it failed --lin
  components PRIME, 
    RadioCRCPacketPrime as RadioPacket, 
    UARTNoCRCPacket as UARTPacket,
    NoCRCPacket as UARTRawBytes,
    /* NoLeds */ LedsC as Leds, InjectMsg,
    MISH,
    TimerC, ClockC,
    MsgPool,
    RadioTimingC,
    ChannelMonPrimeC,
    RandomLFSR;

  // UARTSendRawBytes is currently not supported in Nido
  UARTSendRawBytes = UARTRawBytes.SendVarLenPacket;
  
  Control = PRIME.Control;
  SendMsg = PRIME.SendMsg;
  ReceiveMsg = PRIME.ReceiveMsg;
  sendDone = PRIME.sendDone;

  activity = PRIME.activity;
  
  PRIME.ActivityTimer -> TimerC.Timer[unique("Timer")];
  PRIME.PrimeTimer -> TimerC.Timer[unique("Timer")];
  PRIME.EffectiveSlotTimer -> TimerC.Timer[unique("Timer")];
  
  PRIME.UARTControl -> UARTPacket.Control;
  PRIME.UARTSend -> UARTPacket.Send;
  PRIME.UARTReceive -> UARTPacket.Receive;
  
  PRIME.RadioSend -> RadioPacket.Send;
  PRIME.RadioControl -> RadioPacket.Control;
  PRIME.RadioReceive -> RadioPacket.Receive;
  PRIME.Pool -> MsgPool.Pool;
  //AMStandard.RadioReceive -> InjectMsg.RadioReceiveMsg; // for nido

  PRIME.Leds -> Leds;
  PRIME.RadioTiming -> RadioTimingC;
  PRIME.ChannelMon -> ChannelMonPrimeC;
  PRIME.Random -> RandomLFSR.Random;
}
