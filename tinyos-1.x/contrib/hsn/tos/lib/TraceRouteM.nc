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
 * Authors:     Mark Yarvis, York Liu, Nandu Kushalnagar
 *
 */

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
#define TR_SEND_RATE 5
#endif

module TraceRouteM {
   provides {
      interface StdControl as Control;
      interface Settings;
      interface Settings as OnOffSettings;
      interface Intercept;
      interface TraceRouteHeader;
   }
   uses {
      interface Timer;
#if !TR_MODULE
      interface StdControl as MHopControl;
#endif
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
   bool tracerouteSwitch;

   typedef struct {
      uint8_t len;
      uint8_t trace[1];  // actual length is unknown
   } TraceRoute_Msg;

   typedef TraceRoute_Msg *TraceRoute_MsgPtr;

   command result_t Control.init() {
      msg = &msg_buf;
      send_pending = FALSE;
      delivery_msg = &delivery_buf;
      delivery_pending = FALSE;
      xmitRate = TR_SEND_RATE;
      timeCounter = TOS_LOCAL_ADDRESS % TR_SEND_RATE;
#if VIB_SENSOR || FAKE_SENSOR
      tracerouteSwitch = FALSE;
#else
      tracerouteSwitch = TRUE;
#endif

#if SINK_NODE
      call UARTControl.init();
#endif

#if TR_MODULE
      return SUCCESS;
#else
      return call MHopControl.init();
#endif
   }

   command result_t Control.start() {
#if !TR_MODULE
      call MHopControl.start();
#endif
      call Timer.start(TIMER_REPEAT, CLOCK_SCALE+9);
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
#if TR_MODULE
      return SUCCESS;
#else
      return call MHopControl.stop();
#endif
   }

   default command result_t Piggyback.receivePiggyback(wsnAddr addr, 
                                            uint8_t *buf, uint8_t len) {
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

#if TR_PLUGIN_LEN!=0
      {
         uint8_t i;
         void *data;

         data = &(tr->trace[payload_len - TR_PIGGYBACK_LEN - TR_PLUGIN_LEN 
                                    - offsetof(TraceRoute_Msg, trace)]);

         /* Reset the Plugin Value */
         for (i=0; i<TR_PLUGIN_LEN; i++) {
            *(uint8_t *)(data+i) = 0;
         }

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

      dbg(DBG_USR1, "Traceroute: sending message\n");
      if (call Send.send(msg, (uint16_t)payload_len) != SUCCESS) {
         dbg(DBG_USR1, "Traceroute: Send failed for new packet\n");
         send_pending = FALSE;
      }
   }

   event PacketResult_t MultiHopIntercept.intercept(TOS_MsgPtr forward_msg, 
                                 void *payload, uint16_t len) {
      TraceRoute_MsgPtr tr = (TraceRoute_MsgPtr)payload;
      int maxTraceLen = (uint8_t)len - offsetof(TraceRoute_Msg, trace) 
                                            - TR_PIGGYBACK_LEN - TR_PLUGIN_LEN;
      void *data;

#if TR_LEAF_DETECTION
      timeCounter = 0;
#endif

      dbg(DBG_USR1, "Forwarding traceroute message from %d (prevhop = %d)\n", 
                    call MultiHopMsg.getSource(forward_msg), 
                    call SingleHopMsg.getSrcAddress(forward_msg));

      if (tr->len < maxTraceLen) {
         // WARNING: casting an address to a byte!
         tr->trace[tr->len++] = (uint8_t) TOS_LOCAL_ADDRESS;
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

      /* In DSDV it intercepts every packet even though its the final
         destination. Sink appends plugin bits here so don't duplicate
	 singal Intercept again in Receive.receive */

      data = &(tr->trace[(uint8_t)len - TR_PIGGYBACK_LEN - TR_PLUGIN_LEN 
                                    - offsetof(TraceRoute_Msg, trace)]);
      return signal Intercept.intercept(forward_msg, data, 
                                        (uint16_t)TR_PLUGIN_LEN);
   }

#ifndef PLATFORM_EMSTAR
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
#endif
   task void deliverMessage() {
#if 0
#if PLATFORM_PC

      if (TOS_LOCAL_ADDRESS==0) {
         uint8_t totalNodes;
         NodePtr nodeptr;
         uint8_t i;

         call TraceRouteHeader.getNodeIds(delivery_msg,
                                &totalNodes, &nodeptr);
         dbg(DBG_USR1,"TotalNode %d\n", totalNodes);
         for(i=0; i<totalNodes; i++) {
            dbg(DBG_USR1,"NodeIds %x\n", nodeptr[i]);
         }
      }
#endif
#endif

      // deliver locally
#ifndef PLATFORM_EMSTAR
#if PLATFORM_PC
      if (TOS_LOCAL_ADDRESS==0)
#endif
#endif
      if (call UARTSend.send(delivery_msg) != SUCCESS) {
         dbg(DBG_USR1, "Delivery on UART failed: \n");
         delivery_pending = FALSE;
#if DEBUG_UART
         call Leds.yellowToggle();
#endif
      }
#ifndef PLATFORM_EMSTAR
#if PLATFORM_PC
      print_traceroute(delivery_msg);
      if (TOS_LOCAL_ADDRESS!=0)
         delivery_pending = FALSE;
#endif
#endif
   }

   event result_t UARTSend.sendDone(TOS_MsgPtr sentMsg, result_t success) {
      if (sentMsg == delivery_msg) {
#if DEBUG_UART
         if (!success) call Leds.yellowToggle();
#endif
         delivery_pending = FALSE;
         return SUCCESS;
      }
      return FAIL;
   }

   event result_t Timer.fired() {
      if(!tracerouteSwitch) {
          dbg(DBG_USR1, "Traceroute turned off\n");
          return SUCCESS;
      }
#ifndef PLATFORM_EMSTAR /* must be changed if emstar is sink !!! */
#if SINK_NODE || defined(PLATFORM_PC)
      if (TOS_LOCAL_ADDRESS == 0)
	return SUCCESS;
#endif
#endif
      timeCounter++;
      /*
       * 255 is a magic transmit interval that stops the ndoe from 
       * originating traceroute packets.
       */
      if ((timeCounter < xmitRate) || (xmitRate == 255)) {
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

      /* No need to signal Intercept.intercept since in MultiHopIntercept
         we already did so */
#ifndef PLATFORM_EMSTAR /* must be changed if emstar is sink !!! */
#if PLATFORM_PC || SINK_NODE
      if (delivery_pending == FALSE) {
         ret = delivery_msg;
         delivery_msg = received_msg;
         if (post deliverMessage()) {
            delivery_pending = TRUE;
         }
      } else {
         dbg(DBG_USR1, "Traceroute: Discarding delivery due to pending delivery!\n");
#if DEBUG_UART
         call Leds.yellowToggle();
#endif
      }
#endif
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

   command result_t OnOffSettings.updateSetting(uint8_t *buf, uint8_t *len) {
      tracerouteSwitch = (bool)*buf;
      return SUCCESS;
   }

   command result_t OnOffSettings.fillSetting(uint8_t *buf, uint8_t *len) {
      *buf = tracerouteSwitch;
      *len = 1;
      return SUCCESS;
   }

   command result_t Settings.updateSetting(uint8_t *buf, uint8_t *len) {
      xmitRate = *buf;
      /* To avoid the sync problem after xmitRate from big num. to small */
      timeCounter = timeCounter % xmitRate;
      *len = 1;
      return SUCCESS;
   }

   command result_t Settings.fillSetting(uint8_t *buf, uint8_t *len) {
      *buf = xmitRate;
      *len = 1;
      return SUCCESS;
   }

   command result_t TraceRouteHeader.getNodeIds(TOS_MsgPtr tr_msg,
                                uint8_t *totalnodes, NodePtr *nodes) {
      uint16_t len;
      uint8_t i=0;
      TraceRoute_MsgPtr tr  = (TraceRoute_MsgPtr) call Send.getBuffer(
                                                              tr_msg, &len);

      // WARNING: casting an address to a byte! Need to change NodePtr def
      *totalnodes = tr->len;
      *nodes = (NodePtr) &(tr->trace[0]);
      return SUCCESS;
   }    

}
