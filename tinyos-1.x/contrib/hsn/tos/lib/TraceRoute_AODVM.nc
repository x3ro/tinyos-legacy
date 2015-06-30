/**
 * WARNING: This module packs addresses into 8 bytes.  Be careful when
 * using 16-byte addressing.
 */

#ifndef TRACE_TARGET
#define TRACE_TARGET 0
#endif

#ifndef TR_PIGGYBACK_LEN
#define TR_PIGGYBACK_LEN 0
#endif

#ifndef TR_PLUGIN_LEN
#define TR_PLUGIN_LEN 0
#endif

#ifndef TR_SEND_RATE
#if PLATFORM_PC
#define TR_SEND_RATE 5
#else
#define TR_SEND_RATE 20
#endif
#endif

module TraceRoute_AODVM {
   provides {
      interface StdControl as Control;
      //      interface Settings;
      interface Intercept;
   }
   uses {
      interface Timer;
      interface StdControl as MHopControl;
      interface Send;
      interface Receive;
      interface Intercept as MultiHopIntercept;
      interface StdControl as UARTControl;
      interface BareSendMsg as UARTSend;
      interface Leds;
      interface Piggyback;
      interface MultiHopMsg;
      interface SingleHopMsg;
   }
}

implementation {
   TOS_Msg msg_buf;
   TOS_MsgPtr msg;
   bool send_pending;
   TOS_Msg delivery_buf;
   TOS_MsgPtr delivery_msg;
   bool delivery_pending;
   uint16_t xmitRate;   // in sec
   uint16_t timeCounter;

   typedef struct {
      uint8_t len;
      uint8_t trace[1];  // actual length is unknown
   } __attribute__ ((packed)) TraceRoute_Msg;

   typedef TraceRoute_Msg *TraceRoute_MsgPtr;

   command result_t Control.init() {
      msg = &msg_buf;
      send_pending = FALSE;
      delivery_msg = &delivery_buf;
      delivery_pending = FALSE;
      xmitRate = TR_SEND_RATE;
      timeCounter=0;

#if SINK_NODE
      call UARTControl.init();
#endif

      return call MHopControl.init();
   }

   command result_t Control.start() {
      call MHopControl.start();
      call Timer.start(TIMER_REPEAT, CLOCK_SCALE);
#if SINK_NODE
      call UARTControl.start();
#endif
      return SUCCESS;
   }

   command result_t Control.stop() {
      call Timer.stop();
#if SINK_NODE
      call UARTControl.stop();
#endif
      return call MHopControl.stop();
   }

   default command result_t Piggyback.receivePiggyback(wsnAddr addr, 
                                                              uint8_t *buf, 
	uint8_t len) {
      return SUCCESS;
   }

   default command result_t Piggyback.fillPiggyback(wsnAddr addr, 
                                                          uint8_t *buf,
                                                          uint8_t len) {
      return SUCCESS;
   }

   default event PacketResult_t Intercept.intercept(TOS_MsgPtr m, void *payload,
                                                     uint16_t len) {
      return SUCCESS;
   }

   // to be called by the Intercept - Replaced before calling Intercept.intercept
//   command uint8_t PluginPayloadlinkPayload(TOS_MsgPtr m, uint8_t ** buf) {
//      TraceRoute_MsgPtr tr;
//      uint8_t len = call MultiHopPayload.linkPayload(m, (uint8_t **) &tr);
//      *buf = &(tr->trace[len - TR_PIGGYBACK_LEN - TR_PLUGIN_LEN 
//                                    - offsetof(TraceRoute_Msg, trace)]);
//      return TR_PLUGIN_LEN;
//   }

   task void sendMessage() {
      TraceRoute_MsgPtr tr;
      uint16_t len;
      uint8_t payload_len;

      tr = call Send.getBuffer(msg, &len);
      payload_len = (uint8_t)len;
      tr->len = 0;

#if (TR_PIGGYBACK_LEN==0) && (TR_PLUGIN_LEN==0)
      payload_len = 1;
#endif

#if TR_PLUGIN_LEN!=0
      {
         uint8_t i;
         void *data;

         for (i=0; i<TR_PLUGIN_LEN; i++) {
            tr->trace[payload_len - TR_PIGGYBACK_LEN 
                      - i - offsetof(TraceRoute_Msg, trace)] = 0;
         }

         data = &(tr->trace[payload_len - TR_PIGGYBACK_LEN - TR_PLUGIN_LEN 
                                    - offsetof(TraceRoute_Msg, trace)]);
         // warning: callee probably shouldn't change payload_len!
         if (signal Intercept.intercept(msg, data, (uint16_t)TR_PLUGIN_LEN) != SUCCESS) {
            return;
         }
      }
#endif

#if TR_PIGGYBACK_LEN!=0
      call Piggyback.fillPiggyback((wsnAddr) TOS_LOCAL_ADDRESS, 
                                  &(tr->trace[payload_len - TR_PIGGYBACK_LEN 
                                       - offsetof(TraceRoute_Msg, trace)]), 
                                    TR_PIGGYBACK_LEN);
#endif
#if PLATFORM_PC
      if(TOS_LOCAL_ADDRESS != 0){
#endif
	dbg(DBG_USR1, "Traceroute: sending message\n");
	if (call Send.send(msg, (uint16_t)payload_len) != SUCCESS) {
	  dbg(DBG_USR1, "Traceroute: Send failed for new packet\n");
	  send_pending = FALSE;
	}
#if PLATFORM_PC
      }
#endif
   }

   event PacketResult_t MultiHopIntercept.intercept(TOS_MsgPtr forward_msg, 
                                 void *payload, uint16_t len) {
      TraceRoute_MsgPtr tr = (TraceRoute_MsgPtr)payload;
      int maxTraceLen = (uint8_t)len - offsetof(TraceRoute_Msg, trace) 
                                            - TR_PIGGYBACK_LEN - TR_PLUGIN_LEN;
      void *data;

      dbg(DBG_USR1, "Forwarding traceroute message from %d (prevhop = %d)\n", 
                    call MultiHopMsg.getSource(forward_msg), 
                    call SingleHopMsg.getSrcAddress(forward_msg));
      if (tr->len < maxTraceLen) {
         // WARNING: casting an address to a byte!
         tr->trace[tr->len++] = (uint8_t) TOS_LOCAL_ADDRESS;
#if (TR_PIGGYBACK_LEN==0) && (TR_PLUGIN_LEN==0)
         //(*len)++;
         len++;
#endif
      } else {
         // traceroute is full; do FIFO insertion on list
         uint8_t i;

         for (i=1; i<maxTraceLen; i++) {
            tr->trace[i-1] = tr->trace[i];
         }
         tr->trace[maxTraceLen - 1] = (uint8_t) TOS_LOCAL_ADDRESS;
         (tr->len)++;  // increment length anyway so we know that the
                       // source is further away than maxTraceLen
      }

      dbg(DBG_USR1, "Traceroute length is now %d\n", tr->len);

      data = &(tr->trace[(uint8_t)len - TR_PIGGYBACK_LEN - TR_PLUGIN_LEN 
                                    - offsetof(TraceRoute_Msg, trace)]);
      return signal Intercept.intercept(forward_msg, data, (uint16_t)TR_PLUGIN_LEN);
   }

#if PLATFORM_PC
   void print_traceroute(TOS_MsgPtr m) {
      uint8_t i;
      uint8_t len;
      uint16_t payload_len;
      TraceRoute_MsgPtr tr;
      char buf[160];
      char *b = buf;
      tr = call Send.getBuffer(m, &payload_len);
      len = (uint8_t)payload_len; 
      
      for (i=0; i < tr->len; i++) {
         sprintf(b, " %02d", tr->trace[i]);
         b+=3;
      }
      dbg(DBG_USR1, "Delivering packet from node %d: %s\n", 
                    call MultiHopMsg.getSource(m), buf);
   }
#endif

   task void deliverMessage() {
      // deliver locally
#if PLATFORM_PC
      if (TOS_LOCAL_ADDRESS==0)
#endif
      if (call UARTSend.send(delivery_msg) != SUCCESS) {
         dbg(DBG_USR1, "Delivery on UART failed: \n");
         delivery_pending = FALSE;
      }
#if PLATFORM_PC
      print_traceroute(delivery_msg);
      if (TOS_LOCAL_ADDRESS!=0)
         delivery_pending = FALSE;
#endif
   }

   event result_t UARTSend.sendDone(TOS_MsgPtr sentMsg, result_t success) {
      if (sentMsg == delivery_msg) {
         delivery_pending = FALSE;
         return SUCCESS;
      }
      return FAIL;
   }

   event result_t Timer.fired() {
      timeCounter++;
      if (timeCounter < xmitRate) {
         return SUCCESS;
      }

      if (! send_pending) {
         if (post sendMessage()) {
            send_pending = TRUE;
         }
      }
      return SUCCESS;
   }

   event TOS_MsgPtr Receive.receive(TOS_MsgPtr received_msg, void *payload, uint16_t len) {
      TOS_MsgPtr ret = received_msg;
      TraceRoute_MsgPtr tr = (TraceRoute_MsgPtr)payload;
      void *data;

      data = &(tr->trace[(uint8_t)len - TR_PIGGYBACK_LEN - TR_PLUGIN_LEN 
                                    - offsetof(TraceRoute_Msg, trace)]);
      signal Intercept.intercept(received_msg, data, (uint16_t)TR_PLUGIN_LEN);

#if PLATFORM_PC || SINK_NODE
      if (delivery_pending == FALSE) {
         ret = delivery_msg;
         delivery_msg = received_msg;
         if (post deliverMessage()) {
            delivery_pending = TRUE;
         }
      } else {
         dbg(DBG_USR1, "Traceroute: Discarding delivery due to pending delivery!\n");
      }
#endif
      return ret;
   }

   event result_t Send.sendDone(TOS_MsgPtr sentMsg, result_t success) {
      dbg(DBG_USR1, "Traceroute: sendDone (%s)\n", 
                    (success == SUCCESS ? "SUCCESS": "FAIL"));
      if (sentMsg == msg) {
#if USE_SYNC_ACK
         if ((success == SUCCESS) && sentMsg->ack) {
#else
         if (success == SUCCESS) {
#endif
            timeCounter = 0;
         }
         send_pending = FALSE;
         return SUCCESS;
      }
      return FAIL;
   }
#if 0
   command result_t Settings.updateSetting(uint8_t *buf, uint8_t *len) {
      xmitRate = *buf;
      *len = 1;
      return SUCCESS;
   }

   command result_t Settings.fillSetting(uint8_t *buf, uint8_t *len) {
      *buf = xmitRate;
      *len = 1;
      return SUCCESS;
	}
#endif

   }


