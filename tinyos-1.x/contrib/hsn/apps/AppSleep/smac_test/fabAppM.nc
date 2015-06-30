/*                                                                      tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */
/*
 * Authors:     Nithya Ramanathan
 *
 */

// This is a test program for SMAC!

includes fabAppMsg;
includes PacketTypes;

module fabAppM 
{
  uses {
    interface Leds;
    interface Timer as WakeUpTimer;
    interface Timer as TimeSynch;
    interface SysTime; // Needs a millisecond-granularity clock!
#ifdef MEASURE_STATS
    interface RetreiveStatistics;
    interface ReportPacketEvent;
#endif

    // SMAC
    interface MACComm;
    interface MACTest;
    interface StdControl as MACControl;
  }

  provides {
    interface StdControl;
  }
}

implementation
{

//***  Global variables/constants

  // Power-states
  enum {
    MIN_POWER = 1,
    QUERY_READY1,
    QUERY_READY2,
    DATA_READY,
  };
    
  // Application-related Constants
  enum {
    CLUSTER_HEAD_ID = 1, // DEBUGGING - just for bmac test!
    SAMPLE_RETURN_DAYS = 7, // 7-days: Time bet sample-return
  };

  float TIME_TX_1_BYTE_MSEC = .417;
  //*** Protocol related vars

  // Time to wait for a time-synch message
  uint16_t WAIT_FOR_TS_MSG_MSEC = 300;
  // This must be 1-HOUR because time_since_last_ts_hour depends on it
  // to fire 1/hour!
  uint32_t CALCULATE_SEND_DELAY_PD_MSEC = (uint32_t) 3660000; 
  float CLK_DRIFT_PER_HOUR_MSEC = 36; 

  // Initial delay before sending first time-synch message on start-up
  // NOTE: DO NOTE set this variable any-where else, code depends on 
  // the fact that its non-zero ONLY at the beginning!
  uint32_t init_ts_delay_msec = (uint32_t) 6000; 
  uint8_t TOTAL_NUM_HELP_MSGS = 3;

  // Have one of these structs for each state
  state_info min_power = {
    time_synch_period_hours: 2, // 4 hours
    wakeup_period_msec: (uint32_t) 30 * 1000, // 20 minutes
    time_awake_during_ts_msec: (uint32_t) 3 * 1000,
    id: MIN_POWER,
  };

  state_info data_ready = {
    time_in_state_seconds: (uint32_t) 2 * 60 * 60, // 2 hours
    time_synch_period_hours: 2, // same as time_in_state because
			// there is no time-synch for this state
    wakeup_period_msec: 30 * 1000, // 30 seconds
    time_awake_during_ts_msec: (uint32_t) 3 * 1000,
    id: DATA_READY,
  };

  state_info query_ready1 = {
    time_in_state_seconds: (uint32_t) 2 * 60 * 60, // 2 hours
    time_synch_period_hours: 2, // same as time_in_state because
			// there is no time-synch for this state
    id: QUERY_READY1,
    wakeup_period_msec: 30 * 1000, // 30 seconds
    time_awake_during_ts_msec: (uint32_t) 3 * 1000,
  };

  // *** State-related variables
  state_info current_state;

  // Global variable indicating approximate time to sleep when 
  // a time-synch packet has been received.  We don't have to worry
  // about overflow - because this is all in relative time.
  uint32_t time_until_time_synch_sec = 0;
  uint16_t time_to_sleep_msec = 0;
  bool radio_on = TRUE;
  uint32_t wakeup_time = 0;

  uint8_t num_help_msgs = 0;
  uint16_t total_num_help_msgs = 0;
  //*** Misc vars
  // indicates initial send delay: includes send_delay_msec, and max_clk_drift
  uint16_t init_send_delay_msec = 1; 
  uint16_t time_since_last_ts_hour = 0; 
  bool send_stats_msg = FALSE;
  bool send_ts = FALSE;

  uint32_t sample_return_seconds; // period between returning data-samples
  bool send_pending = FALSE;
  bool send_msg = FALSE;
  //struct TOS_Msg data;
  AppPkt data;

  //*** Debugging vars
  uint32_t proc_delay_msec, txmission_delay, rcv_delay;
  uint16_t num_ts_msgs_expected;
  uint16_t num_ts_msgs_rcvd;
  uint16_t num_msgs_rx = 0;
  uint16_t num_msgs_tx = 0;
  uint16_t num_ts_msgs_sent_this_pd = 0;

  //*** Task declarations;
  task void sendTSMsg();

  command result_t StdControl.init() {
    send_pending = FALSE;

    sample_return_seconds = SAMPLE_RETURN_DAYS * 24 * 60;
    sample_return_seconds *= 60;

    min_power.time_in_state_seconds = sample_return_seconds - query_ready1.time_in_state_seconds - data_ready.time_in_state_seconds; 
   
    current_state = min_power;
    dbg(DBG_USR1, "fab wakeup_pd: %d\n", current_state.wakeup_period_msec);

    call Leds.init();
    return call MACControl.init();
  }

  command result_t StdControl.start() 
  {
    uint32_t ts_msec;
#ifdef MEASURE_STATS
    call RetreiveStatistics.ResetStatistics();
    send_stats_msg = TRUE;
    call ReportPacketEvent.PacketEvent(MOTE_ON, 0);
#endif

    // Initially the timer should be set off after an initial delay to
    // send a time-synch message. Only do this if you are the CH, otherwise
    // just stay on until you hear from the cluster-head
    if (TOS_LOCAL_ADDRESS == CLUSTER_HEAD_ID) {
      call Leds.redOn();
      ts_msec = (uint32_t) current_state.time_synch_period_hours * 3600 * 1000 - 5000;

      call WakeUpTimer.start(TIMER_ONE_SHOT, init_ts_delay_msec);
#ifdef MEASURE_STATS
      call TimeSynch.stop();
      call TimeSynch.start(TIMER_REPEAT, ts_msec );
#endif
    }
    return call MACControl.start();
  }

  command result_t StdControl.stop() 
  {
    call WakeUpTimer.stop();
    call MACControl.stop();
#ifdef MEASURE_STATS
    call ReportPacketEvent.PacketEvent(MOTE_OFF, 0);
#endif
    return SUCCESS;
  }

  task void sendStatsMsg()
  {
    fabAppMsg *fm = (fabAppMsg *)data.data;
    Statistics_t *stats = (Statistics_t *)fm->pkt;

    if (!send_pending) {
      fm->type = FABAPP_STATS_MSG;
      fm->id = TOS_LOCAL_ADDRESS;
#ifdef MEASURE_STATS
      call RetreiveStatistics.Retreive(stats);
#endif
      if (call MACComm.unicastMsg(&data, sizeof(data), TOS_LOCAL_ADDRESS + 1
	,1) == SUCCESS) {
#ifdef MEASURE_STATS
        call ReportPacketEvent.PacketEvent(MISC_PACKET_TX, 0);
	send_stats_msg = FALSE;
#endif
	send_pending = TRUE;
	call Leds.redToggle();
      }
    }
  }

  task void sendTSMsg()
  {
    fabAppMsg *fm = (fabAppMsg *)data.data;
    fabAppTSMsg *tsMsg = (fabAppTSMsg *)fm->pkt;
    uint16_t address;
    uint32_t time_msg_sent_msec;

    if ((!send_pending) && (radio_on)) {
      fm->id = TOS_LOCAL_ADDRESS;
      fm->type = FABAPP_TS_MSG;
      tsMsg->current_state = current_state.id;
      tsMsg->ts_valid = FALSE;

      // Debugging 
      tsMsg->num_msgs_rx = num_msgs_rx;
      tsMsg->num_msgs_tx = num_msgs_tx;
      //tsMsg->num_ts_msgs_expected = num_ts_msgs_expected;
      //tsMsg->num_ts_msgs_rcvd = num_ts_msgs_rcvd;
      tsMsg->num_ts_msgs_rcvd = txmission_delay;
      tsMsg->num_ts_msgs_expected = proc_delay_msec;
      tsMsg->num_ts_msgs_sent = (uint16_t) rcv_delay;

      tsMsg->time_until_time_synch_sec = 0; 
      tsMsg->total_num_help_msgs_sent = total_num_help_msgs; 

      // Debugging
      time_msg_sent_msec = call SysTime.getTime32();
      time_msg_sent_msec /= 1000;
      tsMsg->time_to_sleep_msec = time_msg_sent_msec - wakeup_time;
      fm->time = time_msg_sent_msec;

      tsMsg->send_delay = init_send_delay_msec;

      // Debuggnig - fixme - normally this would be a broadcast for
      // time-synch messages - HOWEVER to test, i will make this unicast 4 now
      address = TOS_LOCAL_ADDRESS + 1;

      num_msgs_tx++;
//        if (call Send.send(address, sizeof(fabAppMsg) + sizeof(fabAppTSMsg), 
//		&data)) {
     if (call MACComm.unicastMsg(&data, sizeof(data), address,1) == SUCCESS) {
#ifdef MEASURE_STATS
            call ReportPacketEvent.PacketEvent(MISC_PACKET_TX, 0);
#endif
          send_pending = TRUE;
          call Leds.redToggle();
        }
      }
    }

//  event TOS_MsgPtr Recv.receive(TOS_MsgPtr m) 
//  {
   event void* MACComm.rxMsgDone(void* msg)
   {
      AppPkt* pkt = (AppPkt*)msg;
      fabAppMsg* fm = (fabAppMsg *) pkt->data;
      call Leds.greenToggle();
    num_msgs_rx++;
    if (fm->type == FABAPP_TS_MSG) {
#ifdef MEASURE_STATS
      call ReportPacketEvent.PacketEvent(CONTROL_POWERSAVE_PACKETS_RECV, 0);
#endif
      num_msgs_rx++;
      if (TOS_LOCAL_ADDRESS != CLUSTER_HEAD_ID) {
	// Debugging
        post sendTSMsg();
      }
    }
#ifdef MEASURE_STATS
    else if (fm->type == FABAPP_STATS_MSG) {
      post sendStatsMsg();
      call ReportPacketEvent.PacketEvent(MISC_PACKET_RX, 0);
    }
#endif

      call Leds.greenToggle();
      return msg;
   }


//  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success)
   event result_t MACComm.unicastDone(void* msg, uint8_t txFragCount)
  {
    if (send_pending) {
        call Leds.redToggle();
	send_pending = FALSE;
    }
    return SUCCESS;
  }

  // Timer to wake-up the radio
  event result_t WakeUpTimer.fired()
  {
    num_ts_msgs_sent_this_pd = 0;

    // Debugging send_stats_msg = TRUE;
    call Leds.redToggle();
    call WakeUpTimer.start(TIMER_ONE_SHOT, (current_state.wakeup_period_msec));
    send_msg = TRUE;
   
    return SUCCESS;
  }

  event result_t TimeSynch.fired()
  {
    send_ts = TRUE;
    send_stats_msg = TRUE;
    return SUCCESS;
  }

   event void MACTest.clockFire()
   {
     if ((send_pending == 0) && (send_msg)) {
       if (TOS_LOCAL_ADDRESS == CLUSTER_HEAD_ID) {
         if (send_ts) {
           // Do Nothing
           send_ts = FALSE;
         }

         else if (send_stats_msg) {
           post sendStatsMsg();
         }
    
         else {
           post sendTSMsg();
         }
       }
       send_msg = FALSE;
     }
   }
                                                                                
   event void MACTest.MACSleep()
   {
      call Leds.yellowOff();  // turn off yellow led when sleep
   }
                                                                                
                                                                                
   event void MACTest.MACWakeup()
   {
      call Leds.yellowOn();  // turn on yellow led when wake-up
   }
 
   event result_t MACComm.broadcastDone(void* msg)
   {
     return SUCCESS;
   }

  event result_t MACComm.txFragDone(void* frag)
   {
      return SUCCESS;
   }
                                                                                
}
