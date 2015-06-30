#define AODV_RETRY_INTERVAL  (1 * CLOCK_SCALE)

#define AODV_PERSISTANCE 1

#define MAX_RETRYS 10



#if PLATFORM_PC
//#define AODV_TEST_RERR 1
#endif


module AODV_PacketForwarder {
   provides {
      interface StdControl as Control;
      interface Send[uint8_t app];
      interface SendMHopMsg[uint8_t app];
      interface Receive[uint8_t app];
      interface Intercept[uint8_t app]; // for plugin
      interface Intercept as PromiscuousIntercept[uint8_t app]; 
      interface AODVMsg;
      interface MultiHopMsg;
      event result_t singleHopRadioIdle();
      //      interface Settings; // not interfaced yet
   }
   uses {
      interface StdControl as SingleHopControl;
      interface SendMsg as SingleHopSend;
      interface ReceiveMsg as SingleHopReceive;
      interface Payload as SingleHopPayload;
      interface RoutingControl; // to check for forwarding enable
      interface Timer;
      interface RouteLookup;
      interface RouteError;
      interface SingleHopMsg;
      interface ReactiveRouter;
      //      interface ReactiveRouter;
      event result_t radioIdle();
      command void packetLost();
   }
}

implementation {

   TOS_Msg msg_buf;
   TOS_MsgPtr forward_msg;
   wsnAddr forward_next_hop;  // next hop where forward_msg should be sent


   bool forward_pending;
#if AODV_TEST_RERR
   uint8_t sendCount;
#endif
   
#if AODV_PERSISTANCE
   uint8_t forward_tries_left;
#endif
   
   // 8-bit sequence number for transmitted packets
   uint8_t aodv_seqnum;

   command result_t Control.init() {
      forward_msg = &msg_buf;
      forward_pending = FALSE;
#if AODV_PERSISTANCE
      forward_tries_left = 0;
#endif
#if AODV_TEST_RERR
      sendCount = 0;
#endif
      aodv_seqnum = 0;

#if AODV_PASSIVE_ACK
      passive_ack_pending = FALSE;
      passive_ack_enable  = TRUE;
#endif

      call SingleHopControl.init();
      return SUCCESS;
   }

   command result_t Control.start() {
      call SingleHopControl.start();
      return call Timer.start(TIMER_REPEAT, AODV_RETRY_INTERVAL);
   }

   command result_t Control.stop() {
      call Timer.stop();
      return call SingleHopControl.stop();
   }

   inline AODV_MsgPtr getAODVPtr(TOS_MsgPtr msg) {
      AODV_MsgPtr aodv_ptr;

      call SingleHopPayload.linkPayload(msg, (uint8_t **) &aodv_ptr);
      return aodv_ptr;
   }

   command void * Send.getBuffer[uint8_t app](TOS_MsgPtr msg, uint16_t *len) {
      AODV_MsgPtr aodv_ptr;
      uint8_t singleHopPayloadLen = 
                call SingleHopPayload.linkPayload(msg, (uint8_t **) &aodv_ptr);
      *len = (uint16_t)(singleHopPayloadLen - AODV_HEADER_LEN);
      return aodv_ptr->data;
   }

   command wsnAddr MultiHopMsg.getSource(TOS_MsgPtr msg) {
      return getAODVPtr(msg)->mhop.src;
   }

   command wsnAddr MultiHopMsg.getDest(TOS_MsgPtr msg) {
      return getAODVPtr(msg)->mhop.dest;
   }

   command uint8_t MultiHopMsg.getApp(TOS_MsgPtr msg) {
      return getAODVPtr(msg)->mhop.app;
   }

   command uint8_t MultiHopMsg.getLength(TOS_MsgPtr msg) {
      return getAODVPtr(msg)->mhop.length;
   }

   command uint8_t AODVMsg.getSequenceNum(TOS_MsgPtr msg) {
      return getAODVPtr(msg)->seq;
   }

   command uint8_t AODVMsg.getTTL(TOS_MsgPtr msg) {
      return getAODVPtr(msg)->ttl;
   }

   command uint8_t AODVMsg.getNext(TOS_MsgPtr msg) {
      return call SingleHopMsg.getDestAddress(msg);
   }

   //
   // Purpose: A task to send out the AODV message
   // this cannot run as a command
   //
   // There is no need here to reset VAR(PASSIVE_ACK_PENIDNG)

   task void forwardAODVMsg() {
      TOS_MsgPtr msg = forward_msg;
      AODV_MsgPtr aodv_msg = getAODVPtr(msg);

#if AODV_PERSISTANCE
      if (forward_tries_left == 0) {
         dbg(DBG_ROUTE, ("FORWARD_AODV_MSG_TASK: exiting because not currently trying\n"));
         forward_pending = FALSE;
         return;
      }
#endif

      if (aodv_msg->ttl > 0) {
         if (call SingleHopSend.send(forward_next_hop, 
                                     aodv_msg->mhop.length + AODV_HEADER_LEN, 
                                     msg) != SUCCESS) {
#if AODV_PERSISTANCE
	     forward_tries_left--;
	     if (forward_tries_left == 0) {
		 call RouteError.SendRouteErr(aodv_msg->mhop.dest);
		 
	     }
#endif
            //disable persistance:
            forward_pending = FALSE;
         }
      } else {   // TTL
#if AODV_PERSISTANCE
	  forward_tries_left = 0;
#endif
	  forward_pending = FALSE;
      }
   }

   // THis is a function that simply saves a little code space
   result_t forward_helper() {
      if (post forwardAODVMsg()) {
         dbg(DBG_ROUTE, ("posted task: HANDLE_FLOOD_MSG_TASK\n"));
         forward_pending = TRUE;
#if AODV_PERSISTANCE
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
   //  Procedure: aodv_handle_received_msg
   //
   //  Purpose: This procedure handles the processing of an incoming AODV
   //      message received from a neighbor.
   //
   //  Returns: pointer to a free message, either msg or some other unused
   //      message pointer
   //
   //  Parameters:
   //      msg -- the message to process
   //
   //--------------------------------------------------------------------------
   TOS_MsgPtr aodv_handle_received_msg(TOS_MsgPtr msg, wsnAddr nextHop){
      TOS_MsgPtr retmsg = msg;
      AODV_MsgPtr aodv_msg = getAODVPtr(msg);
#if 0
      //Only perform AODV if I am a relay
      if (call RoutingControl.isForwardingEnabled() != TRUE) {
         dbg(DBG_ROUTE, 
             "Dropping AODV packet because forwarding is disabled\n");
         return msg;
      }
#endif
      //TODO:
      //  for now, drop all incomming forward packets if currently trying 
      //  to forward a packet because avoids race condition of replacing 
      //  forward_msg
      //  This should probably change to replace forward message with most 
      //  recent one received
      if (forward_pending) {
         dbg(DBG_ROUTE, 
             "Dropping AODV packet because already have forward pending\n");
         return msg;
      }

      dbg(DBG_ROUTE, ("Trying to rebroadcast AODV packet \n"));

      if (forward_helper() == SUCCESS) {
	  retmsg = forward_msg;
	  forward_msg = msg;
	  forward_next_hop = nextHop;
#if AODV_PERSISTANCE
	  if (forward_tries_left == 0) {
	    call RouteError.SendRouteErr(aodv_msg->mhop.dest);
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
   // Purpose: Handle a AODV message that needs to be routed
   // Args: msg: message that needs to be sent out
   // Return:  a mesage pointer that may be reused.
   //
   event TOS_MsgPtr SingleHopReceive.receive(TOS_MsgPtr msg) {
      TOS_MsgPtr retmsg=msg;
      AODV_MsgPtr aodv_msg = getAODVPtr(msg);

      dbg(DBG_ROUTE, "AODV_PacketForwarder got packet src: %d\n", aodv_msg->mhop.src);

      if (call SingleHopMsg.getDestAddress(msg) == 
                                 (wsnAddr) TOS_LOCAL_ADDRESS) {
         dbg(DBG_ROUTE, "AODV_PacketForwarder calling plugin\n");
         if (signal Intercept.intercept[aodv_msg->mhop.app]
                             (msg, aodv_msg->data, (uint16_t)aodv_msg->mhop.length) == SUCCESS) {
            // Hand packet to plugin before continuing
            // A higher-level plugin can return an error, indicating that the 
            // message should not be forwarded.
            // Note: the plugin may modify the payload of the message, but 
            // must not hold on to the msg after returning.

            if(aodv_msg->mhop.dest == (wsnAddr) TOS_LOCAL_ADDRESS) {
               // This node is the destination, so stop forwarding and 
               // process the packet

               dbg(DBG_ROUTE, "AODV_PacketForwarder delivering locally\n");

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

               retmsg = signal Receive.receive[aodv_msg->mhop.app](msg, aodv_msg->data, (uint16_t)aodv_msg->mhop.length);
            } else {
               wsnAddr nextHop = call RouteLookup.getNextHop(msg, aodv_msg->mhop.dest);
               dbg(DBG_ROUTE, "AODV_PacketForwarder forwarding through %x\n", 
                   nextHop);
               if (nextHop != INVALID_NODE_ID) {
                  // Have a valid nexthop to the destination, so forward the 
                  // packet to the nexthop
                  retmsg = aodv_handle_received_msg(msg, nextHop);
               } else {
               }
            }
         }
      } else {
         // signal whatever packet receives but not dest to myself, put here to 
         // replace the ReceiveSnooper module which is used for 
         // TinyDBShim.snoopedDataMsg
         signal PromiscuousIntercept.intercept[aodv_msg->mhop.app]
                             (msg, aodv_msg->data, (uint16_t)aodv_msg->mhop.length);
      }

      return retmsg;
   }

   event result_t Timer.fired() {
     dbg(DBG_TEMP, ("AODV_PacketForwarder: Timer.fired()\n"));
#if AODV_PERSISTANCE
       if (forward_tries_left > 0) {
	   if (forward_pending == FALSE) {
	       dbg(DBG_ROUTE, ("AODV_SUB_TIMER_EVENT: reposting FORWARD_AODV_MSG_TASK\n"));
            if (post forwardAODVMsg()) {
		forward_pending = TRUE;
            }
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
      signal radioIdle();
      return SUCCESS;
   }

   result_t sendHelper(wsnAddr dest, TOS_MsgPtr msg, uint16_t len, uint8_t app) {
       AODV_MsgPtr aodv_msg = getAODVPtr(msg);
       wsnAddr nexthop = call RouteLookup.getNextHop(msg, dest);
       if(dest == TOS_LOCAL_ADDRESS){
	 return SUCCESS;
       }
       if(call ReactiveRouter.getNextHop(dest) == INVALID_NODE_ID){
	  dbg(DBG_USR3, "AODV_PacketForwarder generateRoute \n");
	  call ReactiveRouter.generateRoute(AODV_ROOT_NODE);
	  return FAIL;
	}



       dbg(DBG_ROUTE, "Packet initiated to node %x through node %x\n", 
	   dest, nexthop);
       
       if (nexthop == INVALID_NODE_ID) {
	   return FAIL;
       }
       
       aodv_msg->mhop.src = (wsnAddr) TOS_LOCAL_ADDRESS;
       aodv_msg->mhop.length = (uint8_t)len;
       aodv_msg->mhop.dest = (wsnAddr) dest;
       aodv_msg->mhop.app = app;
       aodv_msg->seq = aodv_seqnum;
       
       //Initialize TTL to a large value.  
       aodv_msg->ttl=25;
       
      return call SingleHopSend.send(nexthop, (uint8_t)len+AODV_HEADER_LEN, msg); 
   }
   //  Purpose: This command prepares a message for transmission using the
   //      AODV protocol and sends it.
   command result_t Send.send[uint8_t app](TOS_MsgPtr msg, uint16_t len) {

       
       wsnAddr dest = call RouteLookup.getRoot();
       return sendHelper(dest, msg, len, app); 
   }

   command result_t SendMHopMsg.sendTTL[uint8_t app](uint16_t dest, uint8_t len, TOS_MsgPtr msg, uint8_t ttl){
       return sendHelper(dest, msg, len, app); // ttl ignored for now
   }



   default event result_t Send.sendDone[uint8_t app](TOS_MsgPtr sentBuffer, result_t success) {
      dbg(DBG_ROUTE, "AODV_PacketForwarder: default send done\n");
      return FAIL;
   }

   event result_t SingleHopSend.sendDone(TOS_MsgPtr sentBuffer, result_t success) {
       AODV_MsgPtr aodv_msg;
      if ((forward_pending == TRUE) && (sentBuffer == forward_msg)) {
	  aodv_msg = getAODVPtr(sentBuffer);
         dbg(DBG_ROUTE, 
                "AODV_PacketForwarder: got send done (%s) for forwarded packet  \n", (success == SUCCESS ? "SUCCESS" : "FAIL"));

#if AODV_TEST_RERR
	 if(TOS_LOCAL_ADDRESS == 1)
         dbg(DBG_ROUTE, "AODV_PacketForwarder: senddone: sendCount = %d \n", sendCount);
#endif

#if AODV_PERSISTANCE

         if ((success == TRUE) && sentBuffer->ack
#if AODV_TEST_RERR
	     && sendCount <20
#endif
	     ) {
#if AODV_TEST_RERR
	     if(TOS_LOCAL_ADDRESS == 1){
		 dbg(DBG_ROUTE, "Packet forwarder sendcount = %d \n", sendCount);
		 sendCount++;
	     }
#endif
	     forward_tries_left = 0;
	 } else {
	     forward_tries_left--;
#if AODV_TEST_RERR
	     if(sendCount >=20){
		 sendCount = 0;
		 forward_tries_left = 0;
	     }
#endif
	     // temporary for testing rerr


	     if (forward_tries_left == 0) {
		 dbg(DBG_ROUTE, "Packet forwarder Calling SendRerr\n");
		 call RouteError.SendRouteErr(aodv_msg->mhop.dest);
	     }
	 }
#endif
	 forward_pending = FALSE;
      } else {
#if PLATFORM_PC
	  dbg(DBG_ROUTE, 
	      "AODV_PacketForwarder: passing sendDone to app (%d)\n", 
	      getAODVPtr(sentBuffer)->mhop.app);
#endif
	  if (signal Send.sendDone[getAODVPtr(sentBuffer)->mhop.app]
                                      (sentBuffer, success) == SUCCESS) {
            if (success == TRUE)
               aodv_seqnum++;
         } else {
            return FAIL;
         }
      }
      return SUCCESS;
   }

}
