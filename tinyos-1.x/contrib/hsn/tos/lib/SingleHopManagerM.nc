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

// TODO:
//    Keep stats
//    Integrate with settings handler (to deliver stats)
//    Add disable send feature (to support network programming)
//    Add address conversion support (new send interface?)

// Note about PromiscuousReceiveMsg
//   Typically, you should hook up either PromiscuousReceiveMsg or ReceiveMsg
//   for a given AM id.  if you hook up both, make sure that 
//   PromiscuousReceiveMsg always returns NULL, otherwise ReceiveMsg will 
//   not get called.

includes WSN_Messages;

module SingleHopManagerM 
{
   provides {
      interface StdControl as Control;
      interface SendMsg[uint8_t id];
      interface ReceiveMsg as PromiscuousReceiveMsg[uint8_t id];
                                     // see note above
      interface ReceiveMsg[uint8_t id];
      interface ReceiveMsg as ReceiveBadMsg;
      interface Payload;
      interface SingleHopMsg;
      interface SequenceNumber;
      interface NetStat;
      command void packetLost(); // count a packet as lost
   }
   uses {
      event result_t radioIdle();
      interface StdControl as RadioControl;
      interface CommControl as RadioCommControl;
      interface SendMsg as RadioSend[uint8_t id];
      interface ReceiveMsg as RadioReceive[uint8_t id];
      interface Payload as SubPayload;
      interface Leds;
   }
}
implementation {
   uint8_t seq;
   uint16_t sentMessages;
   uint16_t receivedMessages;
   uint16_t sentUnicastMessages;
   uint16_t receivedUnicastMessages;
   uint16_t sentBroadcastMessages;
   uint16_t receivedBroadcastMessages;

   command result_t Control.init() {
      seq = 0;
      sentMessages = 0;
      receivedMessages = 0;
      sentUnicastMessages = 0;
      receivedUnicastMessages = 0;
      sentBroadcastMessages = 0;
      receivedBroadcastMessages = 0;
      
      dbg(DBG_BOOT, "Single Hop Manager initialized\n");
#if ! DISABLE_LEDS
      call Leds.init();
#endif
      call RadioControl.init(); // MUST before setPromiscuous
      call RadioCommControl.setCRCCheck(FALSE);
      call RadioCommControl.setPromiscuous(TRUE);
      return SUCCESS;
   }

   command result_t Control.start() {
      return call RadioControl.start();
   }

   command result_t Control.stop() {
      return call RadioControl.stop();
   }

   command uint8_t Payload.linkPayload(TOS_MsgPtr msg, uint8_t** buf) {
      SHop_MsgPtr_u sHopMsg;  // avoid type-punned pointer warning
      uint8_t len = call SubPayload.linkPayload(msg, &(sHopMsg.bytes));

      *buf = sHopMsg.msg->data;
      return len - SHOP_HEADER_LEN;
   }

   // normally we're layered on top of the active message layer
   default command uint8_t SubPayload.linkPayload(TOS_MsgPtr msg, uint8_t** buf) {
      *buf = msg->data;
      return DATA_LENGTH;
   }

   command result_t SendMsg.send[uint8_t id](uint16_t addr, uint8_t length, 
                                             TOS_MsgPtr msg) {
      SHop_MsgPtr sHopMsg = (SHop_MsgPtr) msg->data;

      length += SHOP_HEADER_LEN;

#if BROADCAST_ONLY_SINGLE_HOP_SEQ
      if (addr == TOS_BCAST_ADDR) {
         sHopMsg->seq = seq;
      } else {
         sHopMsg->seq = 0;
      }
#else
      sHopMsg->seq = seq;
#endif
      sHopMsg->src = (wsnAddr) TOS_LOCAL_ADDRESS;

#if ! DISABLE_LEDS
      call Leds.greenToggle();
#endif


      return call RadioSend.send[id](addr, length, msg);

   }

   default event result_t radioIdle() {
      return SUCCESS;
   }

   event result_t RadioSend.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
      result_t ret;

      sentMessages++;   // count even if fail
      if (msg->addr == TOS_BCAST_ADDR) {
         sentBroadcastMessages++;   // count even if fail
      }
      else {
         sentUnicastMessages++;   // count even if fail
      }

      if (success == SUCCESS) {
         // increment sequence number on successful send
#if BROADCAST_ONLY_SINGLE_HOP_SEQ
         if (msg->addr == TOS_BCAST_ADDR)
#endif
            seq++;
      }

      ret = signal SendMsg.sendDone[id](msg, success);
      signal radioIdle();

      return ret;
   }

   default event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
      return FAIL;
   }

   default event TOS_MsgPtr ReceiveBadMsg.receive(TOS_MsgPtr msg) {
      return msg;
   }

   event TOS_MsgPtr RadioReceive.receive[uint8_t id](TOS_MsgPtr msg) {
      TOS_MsgPtr ret;

#if ! DISABLE_LEDS
      call Leds.redToggle();
#endif

      if (msg->crc == 0) {   // assume a bad packet from MicaHighSpeedRadio
         dbg(DBG_USR1, "Received bad message!\n");
         ret = signal ReceiveBadMsg.receive(msg);
      } else {
         SHop_MsgPtr sHopMsg = (SHop_MsgPtr) msg->data;
#if BROADCAST_ONLY_SINGLE_HOP_SEQ
         if (msg->addr == TOS_BCAST_ADDR)
#endif
            signal SequenceNumber.updateSeqNum(sHopMsg->src, sHopMsg->seq);

         ret = signal PromiscuousReceiveMsg.receive[id](msg);

         if ((msg->addr == TOS_LOCAL_ADDRESS) ||
                 (msg->addr == TOS_BCAST_ADDR)) {
             // has to be account regardless of promiscuous
             // exclude the DSDV_PacketForwarder.PromiscuousIntercept.intercept
             receivedMessages++;
             if(msg->addr == TOS_BCAST_ADDR) {
                 receivedBroadcastMessages++;
             }
             else if (msg->addr == TOS_LOCAL_ADDRESS) {
                 receivedUnicastMessages++;
             }
             if (ret == NULL)
                 ret = signal ReceiveMsg.receive[id](msg);
         } else {
             if (ret == NULL)
                 ret = msg;  // throw away the message
         }
      }
      signal radioIdle();
      return ret;
   }

   default event TOS_MsgPtr PromiscuousReceiveMsg.receive[uint8_t id]
                                                          (TOS_MsgPtr msg) {
      return NULL;
   }

   default event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr msg) {
      return msg;
   }

   default event void SequenceNumber.updateSeqNum(wsnAddr addr, uint8_t seqNum) {
   }

   command wsnAddr SingleHopMsg.getSrcAddress(TOS_MsgPtr msg) {
      SHop_MsgPtr sHopMsg = (SHop_MsgPtr) msg->data;
      return sHopMsg->src;
   }

   command wsnAddr SingleHopMsg.getDestAddress(TOS_MsgPtr msg) {
      return (wsnAddr) msg->addr;
   }

   command wsnAddr SingleHopMsg.getSeqNum(TOS_MsgPtr msg) {
      SHop_MsgPtr sHopMsg = (SHop_MsgPtr) msg->data;
      return sHopMsg->seq;
   }

   command uint8_t SingleHopMsg.getPayloadLen(TOS_MsgPtr msg) {
      return msg->length - SHOP_HEADER_LEN;
   }

   command void packetLost() {
      // Increment local sequence number if an upper layer fails to forward 
      // a packet.  This accounts for a local packet loss in our downstream 
      // link.
      seq++;
   }

   command uint16_t NetStat.sentMessages() {
      return sentMessages;
   }
   
   command uint16_t NetStat.sentUnicastMessages() {
      return sentUnicastMessages;
   }
   
   command uint16_t NetStat.sentBroadcastMessages() {
      return sentBroadcastMessages;
   }

   command uint16_t NetStat.receivedMessages() {
      return receivedMessages;
   }
   
   command uint16_t NetStat.receivedUnicastMessages() {
      return receivedUnicastMessages;
   }
   
   command uint16_t NetStat.receivedBroadcastMessages() {
      return receivedBroadcastMessages;
   }
}
