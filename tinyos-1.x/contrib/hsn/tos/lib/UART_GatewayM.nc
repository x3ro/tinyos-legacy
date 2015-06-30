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
 * Authors:     Mark Yarvis
 *
 */

#ifndef GATEWAY_DROP_BAD_CRC
#define GATEWAY_DROP_BAD_CRC 1
#endif

module UART_GatewayM {
   provides {
      interface StdControl as Control;
      interface ReceiveMsg as DeliverMsg[uint8_t amid];
   }

   uses {
      interface ReceiveMsg;  // receive from uart
      interface SendMsg[uint8_t id]; // send to radio
      interface StdControl as UART_Control;
      interface Leds;
   }
}

implementation {
   TOS_Msg buffer;
   TOS_MsgPtr msg;
   bool sendPending;

   command result_t Control.init() {
      msg = &buffer;
      sendPending = FALSE;
      return call UART_Control.init();
   }

   command result_t Control.start() {
      return call UART_Control.start();
   }

   command result_t Control.stop() {
      return call UART_Control.stop();
   }

   task void forwardMessage() {
      if (! sendPending) {
         return;
      }

      if (! call SendMsg.send[msg->type](msg->addr, msg->length - SHOP_HEADER_LEN, msg)) {
         sendPending = FALSE;
      }
   }

   default event TOS_MsgPtr DeliverMsg.receive[uint8_t amid](TOS_MsgPtr m) {
      TOS_MsgPtr retval = m;
      if (!sendPending) {
         retval = msg;
         msg = m;
         if (post forwardMessage()) {
            sendPending = TRUE;
         }
      }
      return retval;
   }

   event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr incoming) {
      return signal DeliverMsg.receive[incoming->type](incoming);
   }

   event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr sent, result_t success) {
      if (msg == sent) {
         sendPending = FALSE;
      }

      return SUCCESS;
   }
}
