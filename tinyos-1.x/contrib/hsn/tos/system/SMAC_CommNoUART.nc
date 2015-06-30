/*                                                                      tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *
 */
/*                                                                      tab:4
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
 */
/*                                                                      tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */
/*
 * Authors:	Jason Hill, David Gay, Philip Levis, Mark Yarvis, York Liu
 *
 */

includes SMACWrapperMsg;

configuration SMAC_CommNoUART
{
  provides {
    interface StdControl as Control;
    interface CommControl;

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
  components AMPromiscuous as AM,
    SMACWrapper as RadioPacket, 
    SMAC,
    NoUART as UARTPacket,
    NoCRCPacket as UARTRawBytes,
    NoLeds as Leds, InjectMsg,
    TimerC, ClockC, HPLPowerManagementM;

  UARTSendRawBytes = UARTRawBytes.SendVarLenPacket;
  
  Control = AM.Control;
  CommControl = AM.CommControl;
  SendMsg = AM.SendMsg;
  ReceiveMsg = AM.ReceiveMsg;
  sendDone = AM.sendDone;

  activity = AM.activity;
  AM.TimerControl -> TimerC.StdControl;
  AM.ActivityTimer -> TimerC.Timer[unique("Timer")];
  
  AM.UARTControl -> UARTPacket.Control;
  AM.UARTSend -> UARTPacket.Send;
  AM.UARTReceive -> UARTPacket.Receive;
  //AM.UARTReceive -> InjectMsg.UARTReceiveMsg; // for nido

  AM.RadioControl -> RadioPacket.Control;
  AM.RadioSend -> RadioPacket.Send;
  AM.RadioReceive -> RadioPacket.Receive;
  AM.PowerManagement -> HPLPowerManagementM.PowerManagement;
  //AM.RadioReceive -> InjectMsg.RadioReceiveMsg; // for nido

  AM.Leds -> Leds;

  RadioPacket.MACControl -> SMAC;
  RadioPacket.MACComm -> SMAC;
}

