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
 * Authors:     Steve Conner, Jasmeet Chhabra, Mark Yarvis, York Liu, Nandu Kushalnagar
 *
 */

// Note about PromiscuousReceiveMsg
//   Typically, you should hook up either PromiscuousReceiveMsg or ReceiveMsg
//   for a given AM id.  if you hook up both, make sure that
//   PromiscuousReceiveMsg always returns NULL, otherwise ReceiveMsg will
//   not get called.

// #define MESH

configuration SingleHopManager
{
   uses {
      event result_t radioIdle();
#if MESH
      event result_t uartIdle();
#endif
   }
   provides {
      interface StdControl as Control;
      interface SendMsg[uint8_t id];
      interface ReceiveMsg[uint8_t id];
      interface ReceiveMsg as PromiscuousReceiveMsg[uint8_t id];
                                     // see note above
      interface ReceiveMsg as ReceiveBadMsg;
      interface Payload;
      interface SequenceNumber;
      interface SingleHopMsg;
      command void packetLost(); // count a packet as lost
   }
}

implementation {
   components SingleHopManagerM,
#if MESH
              MeshInterfaceM,
              Adjuvant_Settings,

#ifdef NO_UART_FRAMED
              UARTNoCRCPacket as UART,
#else
              UARTFramedNoCRCPacket as UART,
#endif

#endif

#ifdef USE_SMAC
              SMAC_CommNoUART as Comm,
#else
              PromiscuousCommNoUART as Comm,
#endif
              LedsC;

   radioIdle = SingleHopManagerM.radioIdle;
   SingleHopManagerM.RadioControl -> Comm;
   SingleHopManagerM.RadioCommControl -> Comm;
   SingleHopManagerM.RadioSend -> Comm;
   SingleHopManagerM.RadioReceive -> Comm;
   SingleHopManagerM.Leds -> LedsC;
   Payload = SingleHopManagerM.Payload;
   ReceiveBadMsg = SingleHopManagerM.ReceiveBadMsg;
   PromiscuousReceiveMsg = SingleHopManagerM.PromiscuousReceiveMsg;
   SequenceNumber = SingleHopManagerM.SequenceNumber;
   SingleHopMsg = SingleHopManagerM.SingleHopMsg;
   packetLost = SingleHopManagerM.packetLost;

//   radioIdle = Comm.sendDone;

#if MESH
   uartIdle = MeshInterfaceM.uartIdle;

   Control = MeshInterfaceM.Control;
   SendMsg = MeshInterfaceM.SendMsg;
   ReceiveMsg = MeshInterfaceM.ReceiveMsg;
   packetLost = MeshInterfaceM.packetLost;
   PromiscuousReceiveMsg = MeshInterfaceM.PromiscuousReceiveMsg;

   MeshInterfaceM.AdjuvantSettings -> Adjuvant_Settings.AdjuvantSettings;

   MeshInterfaceM.UARTControl -> UART;
   MeshInterfaceM.UARTSend -> UART;
#if !SINK_NODE
// don't hook up if we're the sink, or we'll collide with the UART gateway
   MeshInterfaceM.UARTReceive -> UART;
#endif
   MeshInterfaceM.Leds -> LedsC;

   MeshInterfaceM.SingleHopRadioControl -> SingleHopManagerM.Control;
   MeshInterfaceM.SingleHopRadioSendMsg -> SingleHopManagerM.SendMsg;
   MeshInterfaceM.SingleHopRadioReceiveMsg -> SingleHopManagerM.ReceiveMsg;
#else
   Control = SingleHopManagerM.Control;
   SendMsg = SingleHopManagerM.SendMsg;
   ReceiveMsg = SingleHopManagerM.ReceiveMsg;

#endif
}
