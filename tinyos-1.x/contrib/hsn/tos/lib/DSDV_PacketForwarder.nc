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
 * Authors:	Mark Yarvis, York Liu, Nandu Kushalnagar
 *
 */

#define DSDV_RETRY_INTERVAL (1 * CLOCK_SCALE)

/* Duplicate Removal check cache right after rcv SingleHop msg and confirm its
   sh to himeself. Add into cache before signal Rcv to local delivery
   and after Forward:SingleHopSend success */
/* PERSISTANCE - keep forwarding untill forward:singlehop.sendDone success
   PASSIVE_ACK - keep forwarding if not receiving passive ack */

#if DUPLICATE_REMOVAL
#if DSDV_PERSISTANCE||DSDV_PASSIVE_ACK||(USE_SEND_QUEUE&&QUEUE_USE_PACKET_ACK)
#define DSDV_CACHE_SIZE 10
#else
#undef DUPLICATE_REMOVAL
#endif
#endif

#define DSDV_PERSISTANCE 1
#define MAX_RETRYS 10

#ifndef PASSIVE_ACK_MAX_RETRIES
#define PASSIVE_ACK_MAX_RETRIES 1
#endif

module DSDV_PacketForwarder {
   provides {
      interface StdControl as Control;
      interface Send[uint8_t app];
      interface Receive[uint8_t app];
      interface Intercept[uint8_t app];
      interface Intercept as PromiscuousIntercept[uint8_t app];
      interface DSDVMsg;
      interface MultiHopMsg;
      event result_t singleHopRadioIdle();
      interface Settings;
      interface PacketAck;
   }
   uses {
      interface StdControl as SingleHopControl;
      interface SendMsg as SingleHopSend;
      interface ReceiveMsg as SingleHopReceive;
      interface Payload as SingleHopPayload;
      interface RoutingControl;
      interface Timer;
      interface RouteLookup;
      interface SingleHopMsg;
      interface Leds;
      event result_t radioIdle();
      command void packetLost();
   }
}

implementation {

   /* Duplicate removal for all the re-transmission, PASSIVE_ACK,
      PERSISTANCE or QUEUE+PacketAck */
#if DUPLICATE_REMOVAL
   typedef struct {
      wsnAddr src;
      uint8_t seq;
   } cacheEnt;

   cacheEnt pkt_cache[DSDV_CACHE_SIZE];
   uint8_t index_cache;
#endif

   TOS_Msg msg_buf;
   TOS_MsgPtr forward_msg;
   wsnAddr forward_next_hop;  // next hop where forward_msg should be sent

#if DSDV_PERSISTANCE
   uint8_t forward_tries_left;
#endif

   bool forward_pending;

#if DSDV_PASSIVE_ACK
   uint8_t passive_ack_tries_left;
   bool passive_ack_enable;
#endif

   // 8-bit sequence number for transmitted packets
   uint8_t dsdv_seqnum;

   command result_t Control.init() {
#if DUPLICATE_REMOVAL
      // Initialize the packet re-transmission duplicate removal cache
      uint8_t i;
      for (i=0; i<DSDV_CACHE_SIZE; i++) {
         pkt_cache[i].src = INVALID_NODE_ID;
         pkt_cache[i].seq = 0xff;
      }
      index_cache = 0;
#endif

      forward_msg = &msg_buf;
      forward_pending = FALSE;
#if DSDV_PERSISTANCE
      forward_tries_left = 0;
#endif
      dsdv_seqnum = 0;

#if DSDV_PASSIVE_ACK
      passive_ack_tries_left = 0;
      passive_ack_enable  = TRUE;
#endif

      call SingleHopControl.init();
      return SUCCESS;
   }

   command result_t Control.start() {
      call SingleHopControl.start();
      return call Timer.start(TIMER_REPEAT, DSDV_RETRY_INTERVAL);
   }

   command result_t Control.stop() {
      call Timer.stop();
      return call SingleHopControl.stop();
   }

   command result_t Settings.updateSetting(uint8_t *buf, uint8_t *len) {
#if DSDV_PASSIVE_ACK
      if (*buf != 0) {
         passive_ack_enable = TRUE;
      } else {
         passive_ack_enable = FALSE;
      }
#endif
      *len = 1;

      return SUCCESS;
   }

   command result_t Settings.fillSetting(uint8_t *buf, uint8_t *len) {
#if DSDV_PASSIVE_ACK
      *buf = (passive_ack_enable == TRUE);
#endif

      *len = 1;

      return SUCCESS;
   }

   inline DSDV_MsgPtr getDSDVPtr(TOS_MsgPtr msg) {
      // use union to get rid of type-punned message warning
      DSDV_MsgPtr_u dsdv_ptr; 

      call SingleHopPayload.linkPayload(msg, &(dsdv_ptr.bytes));
      return dsdv_ptr.msg;
   }

#if DUPLICATE_REMOVAL
   /* Check duplicated DSDV packet with same (src,seq) pair */
   bool cache_is_duplicated(TOS_MsgPtr msg) {

      uint8_t i;
      DSDV_MsgPtr dsdv_msg = getDSDVPtr(msg);

      if (msg == NULL)
         return TRUE;
      for (i=0; i<DSDV_CACHE_SIZE; i++) {
         if (pkt_cache[i].src == dsdv_msg->mhop.src &&
             pkt_cache[i].seq == dsdv_msg->seq) {
            return TRUE;
         }
      }
      return FAIL;
   }

   /* Add DSDV packet (src, seq) pair into cache */
   void cache_add(TOS_MsgPtr msg) {
      DSDV_MsgPtr dsdv_msg = getDSDVPtr(msg);
      cacheEnt *cache = &(pkt_cache[index_cache]);

      cache->src = dsdv_msg->mhop.src;
      cache->seq = dsdv_msg->seq;
      if (index_cache == (DSDV_CACHE_SIZE-1))
         index_cache = 0;
      else
         index_cache++;
      return;
   }

#endif

   command void * Send.getBuffer[uint8_t app](TOS_MsgPtr msg, uint16_t *len) {
      DSDV_MsgPtr_u dsdv_ptr;
      uint8_t singleHopPayloadLen = 
                call SingleHopPayload.linkPayload(msg, &(dsdv_ptr.bytes));
      *len = (uint16_t)(singleHopPayloadLen - DSDV_HEADER_LEN);
      return dsdv_ptr.msg->data;
   }

   command wsnAddr MultiHopMsg.getSource(TOS_MsgPtr msg) {
      return getDSDVPtr(msg)->mhop.src;
   }

   command wsnAddr MultiHopMsg.getDest(TOS_MsgPtr msg) {
      return getDSDVPtr(msg)->mhop.dest;
   }

   command uint8_t MultiHopMsg.getApp(TOS_MsgPtr msg) {
      return getDSDVPtr(msg)->mhop.app;
   }

   command uint8_t MultiHopMsg.getLength(TOS_MsgPtr msg) {
      return getDSDVPtr(msg)->mhop.length;
   }

   command uint8_t DSDVMsg.getSequenceNum(TOS_MsgPtr msg) {
      return getDSDVPtr(msg)->seq;
   }

   command uint8_t DSDVMsg.getTTL(TOS_MsgPtr msg) {
      return getDSDVPtr(msg)->ttl;
   }

   command uint8_t DSDVMsg.getNext(TOS_MsgPtr msg) {
      return call SingleHopMsg.getDestAddress(msg);
   }

   //
   // Purpose: A task to send out the DSDV message
   // this cannot run as a command
   //

   task void forwardDSDVMsg() {
      TOS_MsgPtr msg = forward_msg;
      DSDV_MsgPtr dsdv_msg = getDSDVPtr(msg);

#if DSDV_PERSISTANCE
      if (forward_tries_left == 0) {
         dbg(DBG_ROUTE, ("FORWARD_DSDV_MSG_TASK: exiting because not currently trying\n"));
         forward_pending = FALSE;
         return;
      }
#endif

      if (dsdv_msg->ttl > 0) {
         if (call SingleHopSend.send(forward_next_hop, 
                                     dsdv_msg->mhop.length + DSDV_HEADER_LEN, 
                                     msg) != SUCCESS) {
#if DSDV_PERSISTANCE
            forward_tries_left--;
            if (forward_tries_left == 0) {
               call packetLost();
            }
#endif
            //disable persistance:
            forward_pending = FALSE;

            dbg(DBG_USR3, "Packet #%d:%d forwarding through %x FAIL, %d left\n", dsdv_msg->seq, dsdv_msg->mhop.src, forward_next_hop, forward_tries_left);
         } else {
            dbg(DBG_USR3, "Packet #%d:%d forwarding through %x SUCCESS\n", dsdv_msg->seq, dsdv_msg->mhop.src, forward_next_hop);
#if DUPLICATE_REMOVAL
            cache_add(msg);
#endif
         }
      } else {   // TTL
#if DSDV_PERSISTANCE
         forward_tries_left = 0;
#endif
         forward_pending = FALSE;
#if DSDV_PASSIVE_ACK
         passive_ack_tries_left = 0;
#endif
      }
   }

   // THis is a function that simply saves a little code space
   result_t forward_helper() {
      if (post forwardDSDVMsg()) {
         dbg(DBG_ROUTE, ("posted task: HANDLE_FLOOD_MSG_TASK\n"));
         forward_pending = TRUE;
#if DSDV_PERSISTANCE
         forward_tries_left = MAX_RETRYS;
#endif
         return SUCCESS;
      }
      return FAIL;
   }

   default command bool RoutingControl.isForwardingEnabled() {
      return TRUE;
   }

   //--------------------------------------------------------------------------
   //  Procedure: dsdv_handle_received_msg
   //
   //  Purpose: This procedure handles the processing of an incoming DSDV
   //      message received from a neighbor.
   //
   //  Returns: pointer to a free message, either msg or some other unused
   //      message pointer
   //
   //  Parameters:
   //      msg -- the message to process
   //
   //--------------------------------------------------------------------------
   TOS_MsgPtr dsdv_handle_received_msg(TOS_MsgPtr msg, wsnAddr nextHop){
      TOS_MsgPtr retmsg = msg;
      DSDV_MsgPtr dsdv_msg = getDSDVPtr(msg);

      dsdv_msg->ttl--;

      //Only perform DSDV if I am a relay
      if (call RoutingControl.isForwardingEnabled() != TRUE) {
         dbg(DBG_ROUTE,
             "Dropping DSDV packet because forwarding is disabled\n");
         return msg;
      }

      //TODO:
      //  for now, drop all incomming forward packets if currently trying
      //  to forward a packet because avoids race condition of replacing
      //  forward_msg
      //  This should probably change to replace forward message with most
      //  recent one received
      if (forward_pending) {
         dbg(DBG_ROUTE,
             "Dropping DSDV packet because already have forward pending\n");
         call packetLost();
         return msg;
      }

      dbg(DBG_ROUTE, ("Trying to rebroadcast DSDV packet \n"));

      if (forward_helper() == SUCCESS) {
         retmsg = forward_msg;
         forward_msg = msg;
         forward_next_hop = nextHop;

#if DSDV_PERSISTANCE  // FIXME TODO: why > 0? just set to MAX in forward_helper
         if (forward_tries_left > 0) {
            call packetLost();
         }
#endif

#if DSDV_PASSIVE_ACK
         if (passive_ack_enable && (nextHop != dsdv_msg->mhop.dest)) {
            passive_ack_tries_left = PASSIVE_ACK_MAX_RETRIES;
         }
#endif

      }

      return retmsg;
   }

   default event result_t Intercept.intercept[uint8_t app](
                              TOS_MsgPtr m, void *payload, uint16_t len) {
      return SUCCESS;
   }

   default event result_t PromiscuousIntercept.intercept[uint8_t app](
                              TOS_MsgPtr m, void *payload, uint16_t len) {
      return SUCCESS;
   }

   default event TOS_MsgPtr Receive.receive[uint8_t app](
                              TOS_MsgPtr m, void *payload, uint16_t len) {
      return m;
   }

   //
   // Purpose: Handle a DSDV message that needs to be routed
   // Args: msg: message that needs to be sent out
   // Return:  a mesage pointer that may be reused.
   //
   event TOS_MsgPtr SingleHopReceive.receive(TOS_MsgPtr msg) {
      TOS_MsgPtr retmsg=msg;
      DSDV_MsgPtr dsdv_msg = getDSDVPtr(msg);

      dbg(DBG_ROUTE, "DSDV_PacketForwarder got packet\n");

      if (call SingleHopMsg.getDestAddress(msg) == 
                                 (wsnAddr) TOS_LOCAL_ADDRESS) {

         dbg(DBG_ROUTE, "DSDV_PacketForwarder calling plugin - final dest to %x\n", dsdv_msg->mhop.dest);
         dbg(DBG_USR3, "Packet #%d:%d received from %d\n", dsdv_msg->seq, dsdv_msg->mhop.src, call SingleHopMsg.getSrcAddress(msg));

#if DUPLICATE_REMOVAL
         if (cache_is_duplicated(msg)) {
            dbg(DBG_USR3, "Duplicated packet %d:%d\n", dsdv_msg->seq, dsdv_msg->mhop.src);
            return retmsg;
         }
#endif
	 /* NOTE: Keep in mind the final destination (SINK) will receive
	          both intercept and receive calls */
         if (signal Intercept.intercept[dsdv_msg->mhop.app]
                             (msg, dsdv_msg->data, (uint16_t)dsdv_msg->mhop.length) == SUCCESS) {
            // Hand packet to plugin before continuing
            // A higher-level plugin can return an error, indicating that the 
            // message should not be forwarded.
            // Note: the plugin may modify the payload of the message, but 
            // must not hold on to the msg after returning.

            if(dsdv_msg->mhop.dest == (wsnAddr) TOS_LOCAL_ADDRESS) {
               // This node is the destination, so stop forwarding and 
               // process the packet

               dbg(DBG_ROUTE, "DSDV_PacketForwarder delivering locally\n");

#ifdef MHOP_GATEWAY_HACK
#ifdef PLATFORM_PC
               if (TOS_LOCAL_ADDRESS == 0) {
                  // Hack by SConner to send packet to uartserver
                  uart_pktsnd((char *)msg);

                  // Don't return here or else the simulated gateway can't 
                  // participate in interacting with neighbors via flood 
                  // messages
                  //return msg;
               }
#endif
#endif

#if DUPLICATE_REMOVAL
               cache_add(msg);
#endif

               retmsg = signal Receive.receive[dsdv_msg->mhop.app](msg, dsdv_msg->data, (uint16_t)dsdv_msg->mhop.length);
            } else {
               wsnAddr nextHop = call RouteLookup.getNextHop(msg, dsdv_msg->mhop.dest);
               dbg(DBG_ROUTE, "DSDV_PacketForwarder forwarding through %x\n", 
                   nextHop);
               if (nextHop != INVALID_NODE_ID) {
                  // Have a valid nexthop to the destination, so forward the 
                  // packet to the nexthop
                  retmsg = dsdv_handle_received_msg(msg, nextHop);
               } else {
               }
            }
         }
      } else {
         dbg(DBG_USR3, "DSDV_PacketForwarder overhear packet to %d\n", call SingleHopMsg.getDestAddress(msg));
         // signal whatever packet receives but not dest to myself, put here to 
         // replace the ReceiveSnooper module which is used for 
         // TinyDBShim.snoopedDataMsg
         signal PromiscuousIntercept.intercept[dsdv_msg->mhop.app]
                             (msg, dsdv_msg->data, (uint16_t)dsdv_msg->mhop.length);
#if DSDV_PASSIVE_ACK
         {
         DSDV_MsgPtr dsdv_forward_msg = getDSDVPtr(forward_msg);

         if ((dsdv_msg->mhop.src == dsdv_forward_msg->mhop.src) &&
             (dsdv_msg->seq == dsdv_forward_msg->seq) &&
             (call SingleHopMsg.getSrcAddress(msg) == forward_next_hop)) {
            dbg(DBG_ROUTE,("DSDV_PacketForwarder: Got ack\n"));
            passive_ack_tries_left = 0;
         }
         }
#endif
      }

      return retmsg;
   }

   command bool PacketAck.isAck(TOS_MsgPtr origMsg, TOS_MsgPtr possibleAck) {
      DSDV_MsgPtr dsdv_origMsg = getDSDVPtr(origMsg);
      DSDV_MsgPtr dsdv_possibleAck = getDSDVPtr(possibleAck);

      return ((dsdv_origMsg->mhop.src == dsdv_possibleAck->mhop.src) &&
              (dsdv_origMsg->seq == dsdv_possibleAck->seq) &&
              (call SingleHopMsg.getSrcAddress(possibleAck) == 
                    call SingleHopMsg.getDestAddress(origMsg)));
   }

   command bool PacketAck.isAckRequired(TOS_MsgPtr msg) {
      DSDV_MsgPtr dsdv_msg = getDSDVPtr(msg);
      if (call SingleHopMsg.getDestAddress(msg) == dsdv_msg->mhop.dest)
         return FALSE;
      return TRUE;
   }

   event result_t Timer.fired() {
#if DSDV_PERSISTANCE
      if (forward_tries_left > 0) {
         if (forward_pending == FALSE) {
            dbg(DBG_ROUTE, ("DSDV_SUB_TIMER_EVENT: reposting FORWARD_DSDV_MSG_TASK\n"));
            if (post forwardDSDVMsg()) {
               forward_pending = TRUE;
            }
         }
      }
#endif
#if DSDV_PASSIVE_ACK
      // check forward_pending == FALSE to avoid a timer fired re-tansmission
      // right after send but before sendDone happens
      if (passive_ack_tries_left > 0 && forward_pending == FALSE) {
         if (forward_helper()) {
            dbg(DBG_USR3, "Packet #%d:%d passive ack resend through node %x ******\n", getDSDVPtr(forward_msg)->seq, getDSDVPtr(forward_msg)->mhop.src, forward_next_hop);
            // A race condition can occur if the timer gets called
            // before the send message function is scheduled
            // This can cause the TTL to be incremented
            passive_ack_tries_left--;
         }
      }
#endif   
      return SUCCESS;
   }

   // default version of global send done to signal radio may be ready
   default event result_t radioIdle() {
      return FAIL;
   }

   // this used to be the radio idle event
   event result_t singleHopRadioIdle() {
#if DSDV_PERSISTANCE
// Doing this on radio idle tends to cause all nodes to be synchronized.
// For now, only do it on a timer event
//      if (forward_tries_left > 0) {
//         if (forward_pending == FALSE) {
//            dbg(DBG_ROUTE, ("DSDV_SUB_RADIO_IDLE_EVENT: reposting FORWARD_DSDV_MSG_TASK\n"));
//            if (post forwardDSDVMsg()) {
//               forward_pending = TRUE;
//            }
//         }
//      } else
#endif
      signal radioIdle();
      return SUCCESS;
   }

   //  Purpose: This command prepares a message for transmission using the
   //      DSDV protocol and sends it.
   command result_t Send.send[uint8_t app](TOS_MsgPtr msg, uint16_t len) {
      result_t ret;
      DSDV_MsgPtr dsdv_msg = getDSDVPtr(msg);

      wsnAddr dest = call RouteLookup.getRoot();
      wsnAddr nexthop = call RouteLookup.getNextHop(msg, dest);

      dbg(DBG_ROUTE, "Packet initiated to node %x through node %x\n", 
          dest, nexthop);

      


      
      if (nexthop == INVALID_NODE_ID) {
         return FAIL;
      }

      //      call Leds.redToggle();

      dsdv_msg->mhop.src = (wsnAddr) TOS_LOCAL_ADDRESS;
      dsdv_msg->mhop.length = (uint8_t)len;
      dsdv_msg->mhop.dest = (wsnAddr) dest;
      dsdv_msg->mhop.app = app;
      dsdv_msg->seq = dsdv_seqnum;

      //Initialize TTL to a large value.  This is okay in dsdv as long as
      //  a node only forwards if it has a next hop.  This allows us to avoid
      //  having artifical depth limits in our dsdv trees.
      dsdv_msg->ttl=25;

      ret = call SingleHopSend.send(nexthop, (uint8_t)len+DSDV_HEADER_LEN, msg);

      dbg(DBG_USR3, "Packet #%d:%d initiated to node %x through node %x %s\n",
          dsdv_seqnum, dsdv_msg->mhop.src, dest, nexthop, (ret==SUCCESS?"SUCCESS":"FAIL"));
      return ret;
   }

   default event result_t Send.sendDone[uint8_t app](TOS_MsgPtr sentBuffer, result_t success) {
      dbg(DBG_ROUTE, "DSDV_PacketForwarder: default send done\n");
      return FAIL;
   }

   event result_t SingleHopSend.sendDone(TOS_MsgPtr sentBuffer, result_t success) {
      {
      DSDV_MsgPtr dsdv_msg;
      dsdv_msg=getDSDVPtr(sentBuffer);
      dbg(DBG_USR3, "Packet #%d:%d %s to node %x through node %x SendDone %s\n", dsdv_msg->seq, dsdv_msg->mhop.src, (forward_pending==TRUE?"forward":"initiated"),dsdv_msg->mhop.dest, sentBuffer->addr, (success==SUCCESS?"SUCCESS":"FAIL"));
      }
   
   if ((forward_pending == TRUE) && (sentBuffer == forward_msg)) {
         dbg(DBG_ROUTE, 
                "DSDV_PacketForwarder: got send done (%s) for forwarded packet\n", (success == SUCCESS ? "SUCCESS" : "FAIL"));
#if DSDV_PERSISTANCE
#if USE_SYNC_ACK
         if ((success == TRUE) && sentBuffer->ack) {
#else
         if (success == TRUE) {
#endif
            forward_tries_left = 0;
         } else {
            forward_tries_left--;
            if (forward_tries_left == 0) {
               call packetLost();
            }
         }
#endif
         forward_pending = FALSE;
      } else {
#ifndef PLATFORM_EMSTAR
#if PLATFORM_PC
        dbg(DBG_ROUTE, 
                "DSDV_PacketForwarder: passing sendDone to app (%d)\n", 
                getDSDVPtr(sentBuffer)->mhop.app);
#endif
#endif
         if (signal Send.sendDone[getDSDVPtr(sentBuffer)->mhop.app]
                                      (sentBuffer, success) == SUCCESS) {
            if (success == TRUE)
               dsdv_seqnum++;
         } else {
            return FAIL;
         }
      }
      return SUCCESS;
   }

}
