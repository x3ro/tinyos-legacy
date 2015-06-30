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
 * Authors:	Lakshman Krishnamurthy, Steve Conner, Jasmeet Chhabra, Mark Yarvis, York Liu, Nandu Kushalnagar
 *
 */

/*
 * DSDV.c -
 * This is capable of handling only 127 hops
 * Supports sending data to only 1 DSDV destination
 * 0xff is assumed to be broadcast altert
 *
 * #ifdef SINK_NODE is used to minimize size when function is not required. 
 * It might make sense to move sink node functions for DSDV into a separate 
 * module.
 *
 * The set interval function is totally mad.
 * 
 */

//  # of times to check for preexisting RUPDATE at start up time
#define DSDV_SEQTRY   3                                

#ifndef DSDV_PARENT_TIMEOUT
#define DSDV_PARENT_TIMEOUT 3
#endif

#ifndef DSDV_RUPDATE_PIGGYBACK_LEN
#define DSDV_RUPDATE_PIGGYBACK_LEN 0
#endif

// adjust the magnitude of rupdate randomization
#if RUPDATE_RANDOMIZE    
   // sets the ratio between the rupdate timeout and the randomization timeout
   // (which use the same timer)
   #ifndef DSDV_RAND_TIMER_GRANULARITY
   #define DSDV_RAND_TIMER_GRANULARITY 1
   #endif

   #ifndef DSDV_RUPDATE_RAND_MAX_DELAY
   #define DSDV_RUPDATE_RAND_MAX_DELAY 5
   #endif
#else
   #define DSDV_RAND_TIMER_GRANULARITY 1
#endif

#ifndef DSDV_RUPINT_DEFAULT
#define DSDV_RUPINT_DEFAULT 30
#endif

module DSDV_Core {
   provides {
      interface StdControl as Control;
      interface Settings;
      event void triggerRouteAdvertisement();
      event void triggerRouteForward(bool on);
   }
   uses {
      interface Random;
      interface RouteUpdate as Metric;
      interface SendMsg as SendRupdate;
      interface Payload as RupdatePayload;
      interface ReceiveMsg as ReceiveRupdate;
      interface SendMsg as SendRupdateReq;
      interface ReceiveMsg as ReceiveRupdateReq;
      interface Timer;
      interface SingleHopMsg; // to decode single hop headers
      interface StdControl as MetricControl;
      interface StdControl as ForwardingControl;
      interface StdControl as RadioControl;
      interface Piggyback as RupdatePiggyback;
      interface Leds;
   }
}

implementation {
    bool forwardRupdateTrigger;

    bool amRunning;

    // Local allocated message buffers
    TOS_Msg msg_buf;
    TOS_MsgPtr rupdate_msg;
    bool rupdate_pending;
    bool rupdate_needed;

    uint16_t time_counter;
    uint16_t rupdate_interval;
#if RUPDATE_RANDOMIZE    
    uint16_t rand_rupdate_interval;
    uint8_t rand_enabled;
#endif    

    // how many RUPDATE requests should we send when starting up?
    uint8_t dsdv_seqtry;			
  
    // 8 bit sequence number for transmitted route announcements
    uint8_t dsdv_adv_seqnum;	

    //TODO: should be extended to multiple destinations...
    wsnAddr dsdv_dest;                            // The default destination
    uint8_t dsdv_destseq;                         // The last DSDV seq #

    enum {
       STARTUP_MODE,
       FIRST_SEQ_MODE,
       NORMAL_MODE
    } operating_mode;

    // Some statictics

    // Variable to keep track of last DSDV sent
    bool dsdv_rupdatesent;				

   command result_t Settings.updateSetting(uint8_t *buf, uint8_t *len) {
      if (*len < 2) {
         return FAIL;
      }

      rupdate_interval = buf[0] * DSDV_RAND_TIMER_GRANULARITY;
#if RUPDATE_RANDOMIZE
      rand_enabled = (buf[1] != 0);
#endif

      call Metric.setUpdateInterval(buf[0]);

      *len = 2;

      return SUCCESS;
   }

   command result_t Settings.fillSetting(uint8_t *buf, uint8_t *len) {
      if (*len < 2) {
         return FAIL;
      }

      buf[0] = rupdate_interval / DSDV_RAND_TIMER_GRANULARITY;
#if RUPDATE_RANDOMIZE
      if (rand_enabled == TRUE) {
         buf[1] = 1;
      } else {
         buf[1] = 0;
      }
#else
      buf[1] = 0;
#endif

      *len = 2;

      return SUCCESS;
   }

//
//  Purpose: Initilaize the DSDV module
//  Returns: Always 1 on success

   command result_t Control.init() {
      dbg(DBG_BOOT, "DSDV_Core initializing\n");
      forwardRupdateTrigger = TRUE;

      amRunning = FALSE;

      rupdate_msg = &msg_buf;

      rupdate_pending = FALSE;

      dsdv_dest = INVALID_NODE_ID;          
      dsdv_adv_seqnum = 0;

      dsdv_seqtry = 0;
#if SINK_NODE
      dsdv_seqtry = DSDV_SEQTRY;
#endif
#ifndef PLATFORM_EMSTAR
#if PLATFORM_PC
      if (TOS_LOCAL_ADDRESS == 0)
         dsdv_seqtry = DSDV_SEQTRY;
#endif
#endif
      dsdv_rupdatesent = FALSE;

      time_counter = 0;

      // sink node starts in normal mode, others start in startup mode
      operating_mode = STARTUP_MODE;
#if SINK_NODE || defined (PLATFORM_PC)
#ifdef PLATFORM_PC
      if (TOS_LOCAL_ADDRESS==0)
#endif
         operating_mode = NORMAL_MODE;
#endif

      rupdate_needed = FALSE;
#if RUPDATE_RANDOMIZE    
      rand_rupdate_interval = DSDV_RUPINT_DEFAULT * DSDV_RAND_TIMER_GRANULARITY;
      rand_enabled = TRUE;
#endif
      rupdate_interval =  DSDV_RUPINT_DEFAULT * DSDV_RAND_TIMER_GRANULARITY;

      call RadioControl.init();
      call Random.init();
      call MetricControl.init();
      call ForwardingControl.init();
      return SUCCESS;
   }

//
// Purpose: Start the DSDV module
// Returns: Always 1
   command result_t Control.start() {
      if (! amRunning) {
         call RadioControl.start();
         call Metric.setUpdateInterval(rupdate_interval  
                                           * DSDV_RAND_TIMER_GRANULARITY);
         call MetricControl.start();
         call ForwardingControl.start();

         amRunning = TRUE;
	 return call Timer.start(TIMER_REPEAT, CLOCK_SCALE / DSDV_RAND_TIMER_GRANULARITY);
     } else {
        return SUCCESS;
     }
   }

   command result_t Control.stop() {
      amRunning = FALSE;
      call MetricControl.stop();
      call ForwardingControl.stop();
      call RadioControl.stop();
      return call Timer.stop();
   }

   event result_t SendRupdateReq.sendDone(TOS_MsgPtr sentBuffer, 
                                          bool success) {
      return signal SendRupdate.sendDone(sentBuffer, success);
   }

   event result_t SendRupdate.sendDone(TOS_MsgPtr sentBuffer, bool success) {
      dbg(DBG_ROUTE, ("DSDVCore SendRupdate.sendDone\n"));
    
      if ((rupdate_pending == TRUE) && (sentBuffer == rupdate_msg)) {
         rupdate_pending = FALSE;
         if (success == TRUE) {
#if SINK_NODE || defined (PLATFORM_PC)
#ifdef PLATFORM_PC
            if (TOS_LOCAL_ADDRESS==0)
#endif
               dsdv_adv_seqnum++;
#endif
         } else {
            rupdate_needed = TRUE;
         }
         return SUCCESS;
      }
      return FAIL;
   }

   uint8_t getRupdatePayload(TOS_MsgPtr msg, DSDV_Rupdate_MsgPtr* ptr) {
      DSDV_Rupdate_MsgPtr_u msg_u; // get around type-punned poitner problem

      uint8_t metricLen = call RupdatePayload.linkPayload(msg, &(msg_u.bytes));
      *ptr = msg_u.msg;

      return metricLen;
   }

#if SINK_NODE || defined (PLATFORM_PC)
   //
   // Purpose: This command sends out a DSDV adverstiement into the network 
   // as a flood message
   //
   task void DSDV_SendAdv() {
      DSDV_Rupdate_MsgPtr msg;
      uint8_t metricLen = getRupdatePayload(rupdate_msg, &msg) 
                                                  - DSDV_RUPDATE_HEADER_LEN
                                                  - DSDV_RUPDATE_PIGGYBACK_LEN;

      dbg(DBG_ROUTE, ("DSDV_Core DSDV_SendAdv\n"));
      if(rupdate_pending == TRUE) {
         dbg(DBG_ROUTE, ("rupdate send pending\n"));
         return;
      }

      if (dsdv_seqtry > 0) {
         dbg(DBG_ROUTE, "DSDV_Core sending route update request\n");
         // We have just started up send out an RUPDATE request to see what 
         // the last sequence number was
         if (call SendRupdateReq.send(TOS_BCAST_ADDR, 0, rupdate_msg) 
                                                           == SUCCESS) {
	    dsdv_seqtry--;
	    rupdate_pending = TRUE;
	    rupdate_needed = FALSE;
         }
         return;
      }
    
      msg->dest = (wsnAddr) TOS_LOCAL_ADDRESS;
      msg->seq = dsdv_adv_seqnum;

      metricLen = call Metric.encodeMetric((uint8_t *) msg->metric, metricLen);

      // piggyback immediately follows the metric
      call RupdatePiggyback.fillPiggyback((wsnAddr) TOS_BCAST_ADDR, 
                                          &(msg->metric[metricLen]), 
                                          DSDV_RUPDATE_PIGGYBACK_LEN);

      if (call SendRupdate.send(TOS_BCAST_ADDR,
                                DSDV_RUPDATE_HEADER_LEN +
                                    DSDV_RUPDATE_PIGGYBACK_LEN + metricLen,
                                rupdate_msg)) {
         rupdate_pending = TRUE;
         rupdate_needed = FALSE;
      }
      return;
   }
#endif

   default command uint8_t RupdatePiggyback.fillPiggyback(wsnAddr addr, 
                                             uint8_t *buf, uint8_t len) {
      return len;
   }

   default command uint8_t RupdatePiggyback.receivePiggyback(wsnAddr addr, 
                                             uint8_t *buf, uint8_t len) {
      return len;
   }

   //
   // Purpose: Recreate a RUPDATE message and forward 
   //
   task void forwardRupdate() {
      DSDV_Rupdate_MsgPtr msg;
      uint8_t metricLen = getRupdatePayload(rupdate_msg, &msg) 
                                                  - DSDV_RUPDATE_PIGGYBACK_LEN
                                                  - DSDV_RUPDATE_HEADER_LEN;

      if (!forwardRupdateTrigger) {
          return;
      }
      if (operating_mode != NORMAL_MODE) {
         rupdate_needed = FALSE;
         return;
      }

      if ((dsdv_dest == INVALID_NODE_ID) || (rupdate_pending == TRUE)) {
         return;
      }

      dbg(DBG_ROUTE, ("DSDV_Core: forwarding an RUPDATE\n"));

      msg->dest = dsdv_dest;
      msg->seq = dsdv_destseq;

      metricLen = call Metric.encodeMetric((uint8_t *) msg->metric, metricLen);

      // piggyback immediately follows the metric
      call RupdatePiggyback.fillPiggyback((wsnAddr) TOS_BCAST_ADDR, 
                                          &(msg->metric[metricLen]), 
                                          DSDV_RUPDATE_PIGGYBACK_LEN);

      if (call SendRupdate.send(TOS_BCAST_ADDR, 
                                metricLen + 
                                      DSDV_RUPDATE_HEADER_LEN + 
                                      DSDV_RUPDATE_PIGGYBACK_LEN,
                                rupdate_msg)) {
#if ! RUPDATE_RANDOMIZE
         time_counter = 0;
#endif
         rupdate_pending = TRUE;
         dsdv_rupdatesent = TRUE;
         rupdate_needed = FALSE;
      } 
   }

   //
   // Purpose: return true of a > b
   //
   bool cycle_greater(uint8_t a, uint8_t b)
   {
      if((a > b) && ((a-b) < 64))  {
         return TRUE;
      }
      if((b > a) && ((b-a) > 64)) {
         return TRUE;
      }
      return FALSE; 
   }


   //
   // Purpose: Handle a DSDV route update message
   //
   event TOS_MsgPtr ReceiveRupdate.receive(TOS_MsgPtr received_msg) {
      DSDV_Rupdate_MsgPtr msg;
      wsnAddr src;
      bool newRound = FALSE;
      uint8_t len;

      getRupdatePayload(received_msg, &msg);
      // get the true payload len
      len = call SingleHopMsg.getPayloadLen(received_msg);

      src = call SingleHopMsg.getSrcAddress(received_msg);

      dbg(DBG_ROUTE, ("DSDV_Core ReceiveRupdate.receive\n"));

      // for metrics that need to see every update (perhaps to grab
      // piggyback data)
      call Metric.receivedMetric(src, (uint8_t *) msg->metric,
                                 len - DSDV_RUPDATE_HEADER_LEN - 
                                       DSDV_RUPDATE_PIGGYBACK_LEN);

#if SINK_NODE
      if(dsdv_seqtry > 0) {
         // This picks the first RUPDATE we get; we ignore the fact that the 
         // previous gateway could have had another address
         // If this is an issue. Add a check here for the DSDV destination 
         // address (similar to the one on the next if block)
         dsdv_adv_seqnum = msg->seq + 1;
         dsdv_seqtry = 0;
         return received_msg;
      }
#endif    

#if SINK_NODE || defined (PLATFORM_PC)
      // drop if we are the final destination
      // commented out to save space in a node that
      // is not a sink node
      // Need to enable this code in the full PC mode
      if(msg->dest == (wsnAddr) TOS_LOCAL_ADDRESS) {
         dbg(DBG_ROUTE, ("We are the destination\n"));
         return received_msg;
      }
#endif    

      if (operating_mode == STARTUP_MODE) {
         // we just got our first route update
         dsdv_destseq = msg->seq;
         operating_mode = FIRST_SEQ_MODE;
         return received_msg;
      } else if (operating_mode == FIRST_SEQ_MODE) {
         // we got anoter route update, but we're waiting for a 2nd seq #
         if (cycle_greater(msg->seq, dsdv_destseq)) {
            // got a second seq #
            operating_mode = NORMAL_MODE;
         } else {
            // still waiting for second seq #
            return received_msg;
         }
      }

      dbg(DBG_ROUTE, "DSDV INFO:\t SingleHop.src = %x\n", src);
      dbg(DBG_ROUTE, "\tRupdate.dest = %x  dsdv_dest = %x\n",
                      msg->dest, dsdv_dest);
      dbg(DBG_ROUTE, "\tRupdate.seq = %x dsdv_destseq = %x\n",
                      msg->seq, dsdv_destseq);

      // if we have a new destination or a new sequence number ...
      if (msg->dest != dsdv_dest) {
         newRound = TRUE;
         dsdv_dest = msg->dest;
         call Metric.newDest(dsdv_dest);
         call Metric.evaluateMetric(src, (uint8_t *) msg->metric, TRUE, TRUE);
      } else if (cycle_greater(msg->seq, dsdv_destseq) && 
                 (call Metric.evaluateMetric(src, (uint8_t *) msg->metric, TRUE,
                      (msg->seq - dsdv_destseq > DSDV_PARENT_TIMEOUT)) )
                ) {
         newRound = TRUE;
      }


      // if the above cases were true or if the same seq # but a better route
      if (newRound || 
          ((msg->seq == dsdv_destseq) && 
           call Metric.evaluateMetric(src, (uint8_t *) msg->metric, FALSE, FALSE)
         )) {
         dsdv_destseq = msg->seq;
         dbg(DBG_ROUTE, 
             "DSDV_Core: A new parent has been established in round %d\n", 
             dsdv_destseq);

         call RupdatePiggyback.receivePiggyback(src, 
                          &(msg->metric[len - DSDV_RUPDATE_HEADER_LEN 
                                            - DSDV_RUPDATE_PIGGYBACK_LEN]), 
                          DSDV_RUPDATE_PIGGYBACK_LEN);

#if RUPDATE_RANDOMIZE
         if(rand_enabled) {
            if(rand_rupdate_interval == 0) {
               rand_rupdate_interval = ((call Random.rand() & 0xff)  % DSDV_RUPDATE_RAND_MAX_DELAY) + 1;
	       time_counter=0;
            }
         } else {
            rupdate_needed = TRUE;
            post forwardRupdate();
         }
#else
         rupdate_needed = TRUE;
         post forwardRupdate();
#endif

      }

      return received_msg;
   }

   //
   // Handle a DSDV route update message
   //
   event TOS_MsgPtr ReceiveRupdateReq.receive(TOS_MsgPtr msg) {
      dbg(DBG_ROUTE, ("DSDV_Core ReceiveRupdateReq.receive\n"));
      rupdate_needed = TRUE;      
      post forwardRupdate();
      return msg;
   }

   //
   // Purpose: Timer driven function that controls how often we send out
   // advertisements
   //
   event result_t Timer.fired() {
//      dbg(DBG_ROUTE, ("DSDV_Core Timer.fired\n"));

#if SINK_NODE
      if (time_counter < (rupdate_interval-1)) {
#else
#if RUPDATE_RANDOMIZE
//         dbg(DBG_ROUTE, "RUPDATE_RANDOMIZE:timer %d %d %d\n",
//                         rand_enabled,time_counter,rand_rupdate_interval);
      if (((rand_rupdate_interval > 0) &&
           (time_counter < rand_rupdate_interval)) ||
          ((rand_rupdate_interval == 0) &&
           (time_counter < (5+rupdate_interval)))) {
#else
      if (time_counter < (5+rupdate_interval-1)) {
#endif
#endif
         time_counter++;
      } else {
         rupdate_needed = TRUE;
         time_counter = 0;
#if RUPDATE_RANDOMIZE
         rand_rupdate_interval = 0;
#endif

      }

#if FAST_START_DSDV
      if (dsdv_seqtry > 0) {
         if (time_counter >= DSDV_RAND_TIMER_GRANULARITY) {
            rupdate_needed = TRUE;
            time_counter=0;
#if RUPDATE_RANDOMIZE
            rand_rupdate_interval = 0;
#endif
         }
      }
#endif

      if (rupdate_needed == TRUE) {
#if SINK_NODE	
         post DSDV_SendAdv();
#else
#ifdef PLATFORM_PC
	 if (TOS_LOCAL_ADDRESS == 0) {
            post DSDV_SendAdv();
	 }
         else
#endif
	 if(dsdv_rupdatesent == FALSE) {
            post forwardRupdate();
	 }
         dsdv_rupdatesent = FALSE;
#endif
      }
      return SUCCESS;
   }

   event void triggerRouteAdvertisement() {
      rupdate_needed = TRUE;
      post forwardRupdate();
   }

   event void triggerRouteForward(bool on) {
      forwardRupdateTrigger = on;
   }
}
