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
 * @modified 3/9/06
 *
 * @author Joe Polastre <joe@polastre.com>
 * @author Arsalan Tavakoli <arsalan@cs.berkeley.edu>
 * @author Sukun Kim <binetude@cs.berkeley.edu>
 */
includes AM;

configuration GenericComm {
  provides {
    interface SplitControl as Control;
    interface SPSend[uint8_t id];
    interface SPSendQueue[uint8_t id];
    interface SPReceive[uint8_t id];
  }
}
implementation {
  components SPC as SPConfig,
    RadioCRCPacket,
    UARTAdaptorM as UART,
    UARTFramedPacket as UARTPacket,
    LedsC;

  Control = SPConfig.Control;
  SPSend = SPConfig.SPSend;
  SPSendQueue = SPConfig.SPSendQueue;
  SPReceive = SPConfig.SPReceive;

  SPConfig.UARTControl -> UART.StdControl;
  SPConfig.UARTSend -> UART.Send;
  SPConfig.UARTReceive -> UART.Receive;
  
  SPConfig.RadioControl -> RadioCRCPacket.Control;
  SPConfig.RadioSend -> RadioCRCPacket.Send;
  SPConfig.RadioReceive -> RadioCRCPacket.Receive;
  
  SPConfig.LinkEstimator -> RadioCRCPacket;
  SPConfig.SPLinkAdaptor -> RadioCRCPacket;

  UART.LowerControl -> UARTPacket.Control;
  UART.LowerSend -> UARTPacket.Send;
  UART.LowerReceive -> UARTPacket.Receive;
  UART.SPNeighbor -> SPConfig.SPNeighbor;
  UART.Leds -> LedsC;
}
