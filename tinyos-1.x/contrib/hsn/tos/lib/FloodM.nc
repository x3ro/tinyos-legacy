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
 * Authors:     Lakshman Krishnamurthy, Steve Conner, Mark Yarvis, York Liu, Jasmeet Chhabra, Nandu Kushalnagar
 *
 */

includes Flood;
includes WSN_Messages;
includes WSN;

module FloodM 
{
   provides {
      interface StdControl as Control;
      interface Send[uint8_t app];
      interface SendMHopMsg[uint8_t app];
      interface Receive[uint8_t app];
      interface Intercept[uint8_t app];
      interface MultiHopMsg;
      interface FloodMsg;
      event result_t singleHopRadioIdle();
   }
   uses {
      interface StdControl as SingleHopControl;
      interface SendMsg as SingleHopSend;
      interface ReceiveMsg as SingleHopReceive;
      interface Payload as SingleHopPayload;
      interface RoutingControl;
      event result_t radioIdle();
      interface Leds;
   }
}


implementation {
   typedef struct {
      wsnAddr addr;
      uint8_t seq;
   } cacheEnt;

   // Variables for controlled flooding packet signature cache
   uint8_t cache_write;
   cacheEnt pkt_sig_cache[FLOOD_CACHE_SIZE];

   // Local allocated message buffers
   TOS_Msg forward_msg_buf;
   TOS_MsgPtr forward_msg;
   bool forward_pending;

   bool waiting_to_forward;

   // 8-bit sequence number for transmitted packets
   uint8_t flood_seqnum;

   command result_t Control.init() {
      uint8_t i;
    
      // Initialize the packet signature cache
      for (i=0; i<FLOOD_CACHE_SIZE; i++) {
         pkt_sig_cache[i].addr = INVALID_NODE_ID;
         pkt_sig_cache[i].seq = 0xff;
      }
      cache_write=0;

      forward_msg = &forward_msg_buf;
      flood_seqnum = FALSE;

      waiting_to_forward = FALSE;
      forward_pending = FALSE;

      return call SingleHopControl.init();
   }

   command result_t Control.start() {
      return call SingleHopControl.start();
   }

   command result_t Control.stop() {
      return call SingleHopControl.stop();
   }

   inline Flood_MsgPtr getFloodPtr(TOS_MsgPtr msg) {
      Flood_MsgPtr_u flood_ptr;

      call SingleHopPayload.linkPayload(msg, &(flood_ptr.bytes));
      return flood_ptr.msg;
   }

   command void * Send.getBuffer[uint8_t app](TOS_MsgPtr msg, uint16_t *len) {
      Flood_MsgPtr_u flood_ptr;
      uint8_t singleHopPayloadLen = 
               call SingleHopPayload.linkPayload(msg, &(flood_ptr.bytes));
      *len =  (uint8_t)(singleHopPayloadLen - FLOOD_HEADER_LEN);
      return flood_ptr.msg->data;
   }

   command wsnAddr MultiHopMsg.getSource(TOS_MsgPtr msg) {
      return getFloodPtr(msg)->mhop.src;
   }

   command wsnAddr MultiHopMsg.getDest(TOS_MsgPtr msg) {
      return getFloodPtr(msg)->mhop.dest;
   }

   command uint8_t MultiHopMsg.getApp(TOS_MsgPtr msg) {
      return getFloodPtr(msg)->mhop.app;
   }

   command uint8_t MultiHopMsg.getLength(TOS_MsgPtr msg) {
      return getFloodPtr(msg)->mhop.length;
   }

   command uint8_t FloodMsg.getSequenceNum(TOS_MsgPtr msg) {
      return getFloodPtr(msg)->seq;
   }

   command uint8_t FloodMsg.getTTL(TOS_MsgPtr msg) {
      return getFloodPtr(msg)->ttl;
   }

   //--------------------------------------------------------------------------
   //  Procedure: add_msg_to_cache
   //
   //  Purpose: Adds a signature to the message signature cache for use in
   //           controlled flooding to avoid retransmitting the same message
   //           more than once.
   //
   //  Returns: 1 on success, 0 otherwise
   //           
   //  Parameters:  
   //      msg -- the message to cache
   //
   //--------------------------------------------------------------------------
   result_t add_msg_to_cache(Flood_MsgPtr msg) {
      cacheEnt *cache = &(pkt_sig_cache[cache_write]);

      if (!msg) {
         dbg(DBG_ROUTE, ("FLOOD: Error in add_msg_to_cache:  bad msg!\n"));
         return FAIL;
      }

#ifdef PLATFORM_PC
      dbg(DBG_ROUTE, "FLOOD: Adding %d %d to cache\n", 
                      msg->mhop.src, msg->seq);
#endif

      cache->addr = msg->mhop.src;
      cache->seq = msg->seq;

      // Note: this method uses 26 less bytes than i = (i+1)%SIZE on AVR8535
      if (cache_write == (FLOOD_CACHE_SIZE - 1))
         cache_write = 0;
      else
         cache_write++;

#ifdef PLATFORM_PC
      {
         int i;
         for (i=0; i<FLOOD_CACHE_SIZE; i++) {
	    dbg(DBG_ROUTE, "\t\t\t\tafter add -- (%d): %d %d\n", 
                            i, pkt_sig_cache[i].addr, pkt_sig_cache[i].seq);
         }
      }
#endif
      return SUCCESS;
   }


   //--------------------------------------------------------------------------
   //  Procedure: find_msg_in_cache
   //
   //  Purpose: Searches the message signature cache for a particular message.
   //           Used in controlled flooding to avoid retransmitting the same 
   //           message more than once.
   //
   //  Returns: 1 if message found in cache, 0 otherwise
   //           
   //  Parameters:  
   //      msg -- the message to search for
   //
   //--------------------------------------------------------------------------
   result_t find_msg_in_cache(Flood_MsgPtr msg) {
      uint8_t i;

      if (!msg) {
         dbg(DBG_ROUTE, ("FLOOD: Error in find_msg_in_cache:  bad msg!\n"));
         return FAIL;
      }

#ifdef PLATFORM_PC
      dbg(DBG_ROUTE, "FLOOD: Searching for %d %d in cache -- \n", 
                      msg->mhop.src, msg->seq);
#endif

      // TODO: Replace this with hash lookup?
      for (i=0; i<FLOOD_CACHE_SIZE; i++) {
#ifdef PLATFORM_PC
         dbg(DBG_ROUTE, "\t\t\t\t(%d): %d %d\n", i, 
                         pkt_sig_cache[i].addr, pkt_sig_cache[i].seq);
#endif
         if (pkt_sig_cache[i].addr == msg->mhop.src  &&
             pkt_sig_cache[i].seq == msg->seq) {
            return SUCCESS;
         }
      }
      return FAIL;
   }

   default event PacketResult_t Intercept.intercept[uint8_t app]
                                  (TOS_MsgPtr m, void *payload, uint16_t len) {
      return SUCCESS;
   }

   default event TOS_MsgPtr Receive.receive[uint8_t app]
                                  (TOS_MsgPtr m, void *payload, uint16_t len) {
      return m;
   }

   default command bool RoutingControl.isForwardingEnabled() {
      return TRUE;
   }

   //--------------------------------------------------------------------------
   //  Procedure: handle_flood_msg
   //
   //  Purpose: This procedure handles the processing of an incoming flooded
   //	message received from a neighbor.  Compares the message against
   //	the packet signature cache and rebroadcasts if TTL > 0.
   //	Returns a free message pointer.
   //
   //  Returns: pointer to a free message, either msg or some other unused
   //	message pointer
   //           
   //  Parameters:  
   //	msg -- the message to process
   //
   //--------------------------------------------------------------------------
   task void handleFloodMsg() {
	      bool forwarded = FALSE;
	      Flood_MsgPtr flood_msg = getFloodPtr(forward_msg);

	      dbg(DBG_ROUTE, ("FLOOD: handleFloodMessage task\n"));

	      if (!forward_pending) {
		 goto flood_task_done;
	      }

	      waiting_to_forward = FALSE;
	    
	      // Execute flood intercept, and only forward if returned success
	      if (signal Intercept.intercept[flood_msg->mhop.app]
                (forward_msg, flood_msg->data, (uint16_t)flood_msg->mhop.length) != SUCCESS) {
	// TODO: implement return to sender
		 dbg(DBG_ROUTE, ("FLOOD: plugin stopped the forwarding\n"));
		 goto flood_task_done;
	      }

	      if (flood_msg->mhop.dest == (wsnAddr) TOS_LOCAL_ADDRESS) {
		 // This node is the destination, so stop forwarding and deliver 
		 // the packet
		    
		 dbg(DBG_ROUTE, ("FLOOD: delivering locally\n"));
		 forward_pending = FALSE;
		 forward_msg = signal Receive.receive[flood_msg->mhop.app](forward_msg, flood_msg->data, (uint16_t)flood_msg->mhop.length);
		 return;
	      }

	      //Only perform flooding if I am a relay
	      if (call RoutingControl.isForwardingEnabled() == FALSE) {
		 goto flood_task_done;
	      }

	      // First, check if we have already seen this packet
	      if (find_msg_in_cache(flood_msg)) {
#ifndef PLATFORM_EMSTAR
	#if PLATFORM_PC
		 dbg(DBG_ROUTE, ("FLOOD: Dropping dupl packet:  \n"));
		 dbg_print_floodmsg(forward_msg);
	#endif
#endif
		 goto flood_task_done;
	      }

	      if  (flood_msg->ttl > 0) {
		 flood_msg->ttl--;
#ifndef PLATFORM_EMSTAR		    
	#if PLATFORM_PC
	      dbg(DBG_ROUTE, "FLOOD: sending flood msg:  \n");
	      dbg_print_floodmsg(forward_msg);
	#endif
#endif
		 if (call SingleHopSend.send(TOS_BCAST_ADDR, 
					     flood_msg->mhop.length + FLOOD_HEADER_LEN, 
					     forward_msg) == SUCCESS) {
		    forwarded = TRUE;
		    dbg(DBG_ROUTE, ("\t\t successful\n"));
         } else {
		    dbg(DBG_ROUTE, ("\t\t failed\n"));
         }

      }

      // if that's the BCAST message deliver to the upper layer after 
      // SingleHopSend.sendDone

   flood_task_done:
      forward_pending = forwarded;
      return;
   }


   task void retryForwardFloodMsg() {
      if (forward_pending == FALSE) {
         waiting_to_forward = FALSE;
         return;
      }
      if (call SingleHopSend.send(TOS_BCAST_ADDR, 
                                  getFloodPtr(forward_msg)->mhop.length 
                                                   + FLOOD_HEADER_LEN, 
                                  forward_msg) == SUCCESS) {
	  waiting_to_forward = FALSE;
      }
   }


   command result_t Send.send[uint8_t app]
                                (TOS_MsgPtr msg, uint16_t length) { //, wsnAddr addr) {
      
      return call SendMHopMsg.sendTTL[app](TOS_BCAST_ADDR, (uint8_t)length, msg, 12);
   }

   //  Purpose: This command prepares a message for transmission using the 
   //	flooding protocol and sends it.
   command result_t SendMHopMsg.sendTTL[uint8_t app](uint16_t addr, 
                                 uint8_t length, TOS_MsgPtr msg, uint8_t ttl) {
#ifndef PLATFORM_EMSTAR
#if PLATFORM_PC
      dbg(DBG_ROUTE, "FLOOD: flood_send:  dest = %02x msg= %x\n", 
                      addr, msg);
      dbg_print_floodmsg(msg);
#endif
#endif

      //      call Leds.yellowToggle();

      if (!msg) {
         dbg(DBG_ROUTE, "FLOOD: Error in flood_msg_send:  invalid msg: %x\n", 
                       msg);
	return FAIL;
      }

      {
         Flood_MsgPtr flood_msg = getFloodPtr(msg);
         flood_msg->mhop.app = app;
         flood_msg->mhop.src = (wsnAddr) TOS_LOCAL_ADDRESS;
         flood_msg->mhop.dest = (wsnAddr) addr;
         flood_msg->mhop.length = length;
         flood_msg->seq = flood_seqnum;
         flood_msg->ttl = ttl;
      }

      length += FLOOD_HEADER_LEN;

      return call SingleHopSend.send(TOS_BCAST_ADDR, length, msg);
   }

   default event result_t Send.sendDone[uint8_t app](TOS_MsgPtr msg, 
                                                     result_t success) {
      return FAIL;
   }

   event result_t SingleHopSend.sendDone(TOS_MsgPtr sentBuffer, 
                                         result_t success) {
      Flood_MsgPtr flood_msg = getFloodPtr(sentBuffer);

      if (success == SUCCESS) {
         add_msg_to_cache(flood_msg);
      }

      if (sentBuffer == forward_msg) {
	 forward_pending = FALSE;
         // only signal the receive if the mhop dest is bcast, previously already signal
         // upper layer if the mhop dest is localhost, then stop forward. won't reach here
         if (flood_msg->mhop.dest == (wsnAddr) TOS_BCAST_ADDR) {
            forward_msg = signal Receive.receive[flood_msg->mhop.app]
                         (sentBuffer, flood_msg->data, (uint16_t)flood_msg->mhop.length);
         }
      } else {
         signal Send.sendDone[flood_msg->mhop.app](sentBuffer, success);
	 if (success == SUCCESS)
	    flood_seqnum++;
      }

      return SUCCESS;
   }

   event TOS_MsgPtr SingleHopReceive.receive(TOS_MsgPtr msg) {
      TOS_MsgPtr retmsg=msg;

//#if PLATFORM_PC
      dbg(DBG_ROUTE, ("FLOOD: Received packet:       \n"));
//      dbg_print_floodmsg(msg);
//#endif

#ifdef MHOP_GATEWAY_HACK
#ifdef PLATFORM_PC
//		if (TOS_LOCAL_ADDRESS == 0) {
		    // Hack by SConner to send packet to uartserver
//		    uart_pktsnd((char *)msg);

		    //Don't return here or else the simulated gateway can't participate
		    // in interacting with neighbors via flood messages
		    //return msg;
//		}
#endif
#endif

      if (forward_pending == TRUE) {
	dbg(DBG_ROUTE, ("FLOOD: Dropping flood packet because already have forward pending:  \n"));
      } else {
         if (post handleFloodMsg()) {
            dbg(DBG_ROUTE, ("FLOOD: posted task: HANDLE_FLOOD_MSG_TASK\n"));

            forward_pending = TRUE;
            retmsg = forward_msg;
            forward_msg = msg;
         }
      }

      if (waiting_to_forward == TRUE) {
         post retryForwardFloodMsg();
      }

      return retmsg;
   }

   default event result_t radioIdle() {
      return SUCCESS;
   }

   event result_t singleHopRadioIdle() {
      if (waiting_to_forward == TRUE) {
	 post retryForwardFloodMsg();
         return SUCCESS;
      } else {
         return signal radioIdle();
      }
   }
}
