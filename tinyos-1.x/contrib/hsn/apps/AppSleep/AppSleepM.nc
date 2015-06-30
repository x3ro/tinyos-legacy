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

// todo:
// - deivide variables into consts, and those that are applciation-defined
// 0) Allow negative vals for time-to-sleep: this means that node should
// have gone to sleep a while ago, and that it should sleep for x seconds
// less than it normally would have during that stint.
// 1) Need message queueing - especially since we delay sending packets!
//   so need quing on receive side too? Definitely need it in sendSYNCH
//   and sendHelpMsg, where if (send_pending), then we queue the message!
// 3) broadcast queries, but set a next-hop. THAT way everyone hears a
// query, and generaly knows whats up - esp if you want to know if
// your next-hop got the query - you know if they bdcast the query or not
// BUT - node canNOT goto sleep if it hears a bdcast query and its not 
// the next-hop, cuz it may be the next-next-hop
// 4) Robustness for first ts-msg!

// 1) Queries to handle: streaming, change sample-frequency (CH handles this)
// 2) Reboot/crashproofing: if doesn't hear init ts_pkt, then send help_pkt
//     on start-up, when gets pkt then forward it on. if node crashed,
//     and is not 1h from CH, then it will jsut have to stay awake and
//     listen to traffic to infer what is going on. if it hears traffic,
//     i could send help_pkt
//     

includes AppSleepMsg;

module AppSleepM 
{
  uses {
    interface StdControl as RadioControl;
    interface SendMsg as Send;
    interface ReceiveMsg as Recv;
    interface Leds;
    interface Timer as WakeUpTimer;
    interface Timer as ExpectTimeSynch;
    interface Timer as StayAwakeTimer;
    interface Timer as TimeSynch;
    interface Timer as CalculateSD;
    interface Timer as SendPkt;
    interface SysTime; // Needs a millisecond-granularity clock!
    interface TimeStamping;
#ifdef USE_LPL
    interface LowPowerListening;
#endif
#ifdef MEASURE_STATS
    interface Timer as SendStats;
    interface ReportPacketEvent;
    interface RetreiveStatistics;
#endif
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
    CLUSTER_HEAD_ID = 1,
    NUM_HOPS = 7, 
    SAMPLE_RETURN_DAYS = 7, // 7-days: Time bet sample-return
    BASE_TIME_STAY_AWAKE_MSEC = NUM_HOPS * 50, 
  };

  float TIME_TX_1_BYTE_MSEC = .417;
  // fixme - 20 is estimated MAC overhead on top of TOS_Msg struct
  uint16_t ESTIMATED_PKT_OVERHEAD = 7 + 20; 

  //*** Protocol related vars

  // Time to wait for a time-synch message
  uint16_t WAIT_FOR_TS_MSG_MSEC = 300;
  // This must be 1-HOUR because time_since_last_ts_hour depends on it
  // to fire 1/hour!
  uint32_t CALCULATE_SEND_DELAY_PD_MSEC = 3660000; 
  float CLK_DRIFT_PER_HOUR_MSEC = 36; 

  // Initial delay before sending first time-synch message on start-up
  // NOTE: DO NOTE set this variable any-where else, code depends on 
  // the fact that its non-zero ONLY at the beginning!
  uint16_t init_ts_delay_msec = 5000; 
  uint8_t TOTAL_NUM_HELP_MSGS = 3;

  // Have one of these structs for each state
  state_info min_power = {
    time_synch_period_hours: 2, // 4 hours
    wakeup_period_msec: (uint32_t) 10 * 60 * 1000, // 20 minutes
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

  // Time to stay awake each time, in msec, start at BASE_TIME_STAY_AWAKE,
  // but its recalculated each time we change state
  // Its based on the maximum drift that could occur between time-
  //  synchronization. 
  uint16_t stay_awake_time_msec = BASE_TIME_STAY_AWAKE_MSEC;

  // Global variable indicating approximate time to sleep when 
  // a time-synch packet has been received.  We don't have to worry
  // about overflow - because this is all in relative time.
  bool rcvd_ts_msg = FALSE;
  uint32_t time_rcvd_ts_msg_msec = 0;
  uint32_t time_until_SYNCH_sec = 0;
  uint16_t time_to_sleep_msec = 0;
  bool radio_on = FALSE;
  uint32_t wakeup_time = 0;

  uint8_t num_help_msgs = 0;
  uint16_t total_num_help_msgs = 0;
  //*** Misc vars
  // indicates initial send delay: includes send_delay_msec, and max_clk_drift
  uint16_t init_send_delay_msec = 1; 
  uint16_t time_since_last_ts_hour = 0; 

#ifdef MEASURE_STATS
  bool send_stats_msg = FALSE;
#endif

  uint32_t sample_return_seconds; // period between returning data-samples
  bool send_pending;
  bool ts_pending;
  // fixme - for CH, i think this variable is synonymous w/ts_pending
  bool send_ts = FALSE;
  bool sending_help = FALSE;
  struct TOS_Msg data;

#ifdef DEBUGGING
  uint32_t proc_delay_msec, rcv_delay;
  uint16_t num_ts_msgs_expected;
  uint16_t num_ts_msgs_rcvd;
  uint16_t num_msgs_rx = 0;
  uint16_t num_msgs_tx = 0;
  bool sent_debug_pkt = FALSE;
#endif

  uint16_t num_ts_msgs_sent_this_pd = 0;

  //*** Task declarations;
  task void sendSYNCH();
  task void calculate_misc_vars();
  task void change_state();

  command result_t StdControl.init() {
    send_pending = FALSE;

    sample_return_seconds = SAMPLE_RETURN_DAYS * 24 * 60;
    sample_return_seconds *= 60;

    min_power.time_in_state_seconds = sample_return_seconds - query_ready1.time_in_state_seconds - data_ready.time_in_state_seconds; 
   
    current_state = min_power;
    dbg(DBG_USR1, "wakeup_pd: %d\n", current_state.wakeup_period_msec);

    call Leds.init();
    return call RadioControl.init();
  }

  command result_t StdControl.start() 
  {
#ifdef USE_LPL
    uint8_t set_power, power = 0;
#endif
    post change_state();
#ifdef MEASURE_STATS
    call RetreiveStatistics.ResetStatistics();
    send_stats_msg = TRUE;
    call ReportPacketEvent.PacketEvent(MOTE_ON, 0);
#endif

    // Initially the timer should be set off after an initial delay to
    // send a time-synch message. Only do this if you are the CH, otherwise
    // just stay on until you hear from the cluster-head
    if (TOS_LOCAL_ADDRESS == CLUSTER_HEAD_ID) {
      call WakeUpTimer.start(TIMER_ONE_SHOT, init_ts_delay_msec);
    }
    else {
      wakeup_time = call SysTime.getTime32();
    }
    
    if (!radio_on) {
      radio_on = call RadioControl.start();
      call Leds.yellowOn();
    }
#ifdef USE_LPL
    call LowPowerListening.SetListeningMode(power);
    set_power = call LowPowerListening.GetListeningMode();
    if (power != set_power) {
      call Leds.yellowToggle();
    }
    call LowPowerListening.SetTransmitMode(power);
    set_power = call LowPowerListening.GetTransmitMode();
    if (power != set_power) {
      call Leds.redOn();
    }
#endif
    return (radio_on);
  }

  command result_t StdControl.stop() 
  {
    call WakeUpTimer.stop();
    call StayAwakeTimer.stop();
    radio_on = FALSE;
    call Leds.yellowOff();
    return call RadioControl.stop();
#ifdef MEASURE_STATS
    call ReportPacketEvent.PacketEvent(MOTE_OFF, 0);
#endif
  }

  task void calculate_misc_vars()
  {
    // Calculating clk-drift since last time-synch message
    uint16_t calculated_drift_msec = (time_since_last_ts_hour + 1) * CLK_DRIFT_PER_HOUR_MSEC;
    stay_awake_time_msec = BASE_TIME_STAY_AWAKE_MSEC + 4 * calculated_drift_msec;
    if (stay_awake_time_msec > current_state.wakeup_period_msec) {
      stay_awake_time_msec = current_state.wakeup_period_msec * .95;
    }

    // Calculate the delay introduced through:
    // 1) Clock-drift between time-synch periods. 
    // 2) Processing delay
    // Use this delay when sending packets. 
    init_send_delay_msec = (uint16_t) (2 * calculated_drift_msec);
  }

  task void change_state()
  {
    post calculate_misc_vars();
    ts_pending = TRUE;
    if (TOS_LOCAL_ADDRESS == CLUSTER_HEAD_ID) {
      send_ts = TRUE; // Set because we want to forward the ts-pkt
    }
  }
  
  task void sendHelpMsg()
  {
    uint16_t wait_for_ts;
    AS_Msg *fm = (AS_Msg *)data.data;
#ifdef DEBUGGING
    AS_SYNCH *tsMsg = (AS_SYNCH *)fm->pkt;
    tsMsg->ts_valid = rcvd_ts_msg;
    tsMsg->time_to_sleep_msec = num_msgs_rx;
#endif

    if ((!send_pending) && (radio_on)) {
      fm->type = APPSLEEP_REQ_SYNCH;
      fm->id = TOS_LOCAL_ADDRESS;
#ifdef DEBUGGING
      if (call Send.send(TOS_BCAST_ADDR, sizeof(AS_Msg) + 8, &data)) {
#else
      if (call Send.send(TOS_BCAST_ADDR, sizeof(AS_Msg), &data)) {
#endif

#ifdef MEASURE_STATS
        call ReportPacketEvent.PacketEvent(CONTROL_POWERSAVE_PACKETS_SEND, 0);
#endif
        send_pending = TRUE;
        call Leds.redToggle();
      }
    }

    // Decay delay between sending next help message - fixme make this a better val
    wait_for_ts = (100) * (2 * num_help_msgs);
    call ExpectTimeSynch.start(TIMER_ONE_SHOT, wait_for_ts);
  }

#ifdef MEASURE_STATS
  task void sendStatsMsg()
  {
    AS_Msg *fm = (AS_Msg *)data.data;
    Statistics_t *stats = (Statistics_t *)fm->pkt;

    call Leds.redToggle();
    if ((!send_pending) && (radio_on)) {
      fm->type = APPSLEEP_STATS;
      fm->id = TOS_LOCAL_ADDRESS;
      call RetreiveStatistics.Retreive(stats);
      if (call Send.send(TOS_LOCAL_ADDRESS + 1, 
	sizeof(AS_Msg) + sizeof(Statistics_t), &data)) {
        call ReportPacketEvent.PacketEvent(MISC_PACKET_TX, 0);
	send_stats_msg = FALSE;
	send_pending = TRUE;
      }
    }
  }
#endif

  task void sendSYNCH()
  {
    AS_Msg *fm = (AS_Msg *)data.data;
    AS_SYNCH *tsMsg = (AS_SYNCH *)fm->pkt;
    uint16_t address;
    uint32_t ts_msec, tmp_time;
    uint32_t time_msg_sent_msec;

    if ((!send_pending) && (radio_on)) {
      fm->id = TOS_LOCAL_ADDRESS;
      fm->type = APPSLEEP_SYNCH;
      tsMsg->ts_valid = FALSE;

      // This is valid time-synch pkt IF we are the CH and we know there
      // is time-sycn pending, OR if we are a non-CH and we have already 
      // received a time-synch packet in this period.
      if (((send_ts) && (TOS_LOCAL_ADDRESS == CLUSTER_HEAD_ID)) ||
           (rcvd_ts_msg)) {
        tsMsg->ts_valid = TRUE;
      }

      time_msg_sent_msec = call SysTime.getTime32();
      time_msg_sent_msec /= 1000;

#ifdef DEBUGGING
      tsMsg->num_msgs_rx = num_msgs_rx;
      tsMsg->num_msgs_tx = num_msgs_tx;
      tsMsg->stay_awake_time_msec = stay_awake_time_msec;
      //tsMsg->num_ts_msgs_expected = num_ts_msgs_expected;
      //tsMsg->num_ts_msgs_rcvd = num_ts_msgs_rcvd;
      tsMsg->num_ts_msgs_expected = proc_delay_msec;
      tsMsg->num_ts_msgs_sent = (uint16_t) rcv_delay;
      tsMsg->ts_pending = ts_pending;
      tsMsg->total_num_help_msgs_sent = total_num_help_msgs; 
      tsMsg->time_to_sleep_msec = time_msg_sent_msec - wakeup_time;
#endif

      tsMsg->time_until_SYNCH_sec = 0; 
      if (tsMsg->ts_valid) {
        tmp_time = call SysTime.getTime32();

        // We add the time-step for the offset right when we start the
        // stay-awake timers for added accuracy.
	tsMsg->time_offset_usec = (uint32_t) (tmp_time * (-1));

        if (TOS_LOCAL_ADDRESS == CLUSTER_HEAD_ID) {
          time_until_SYNCH_sec = (uint32_t) current_state.time_synch_period_hours * 60 * 60; 

          if (!rcvd_ts_msg) {
	    time_rcvd_ts_msg_msec = time_msg_sent_msec;
	    time_to_sleep_msec = current_state.time_awake_during_ts_msec;
	    rcvd_ts_msg = TRUE;
	  }
          time_until_SYNCH_sec += (time_to_sleep_msec / 1000);
        }

	if (rcvd_ts_msg) {  
	  tsMsg->time_to_sleep_msec = time_to_sleep_msec 
		- (time_msg_sent_msec - time_rcvd_ts_msg_msec);
          tsMsg->time_until_SYNCH_sec = time_until_SYNCH_sec - 
		- ((time_msg_sent_msec - time_rcvd_ts_msg_msec)/1000);
          //fixme check for overflow!
        }

        if ((TOS_LOCAL_ADDRESS == CLUSTER_HEAD_ID) && (num_ts_msgs_sent_this_pd == 0)) {
	  //*** Handle Next Time-synch
	  ts_msec = (uint32_t)(tsMsg->time_until_SYNCH_sec * 1000);
	  call TimeSynch.stop();
	  call TimeSynch.start(TIMER_ONE_SHOT, ts_msec);
	  call CalculateSD.stop();
	  call CalculateSD.start(TIMER_REPEAT, CALCULATE_SEND_DELAY_PD_MSEC);
	  time_since_last_ts_hour = 0; 
  
	  //*** Handle Stay-Awake:
	  // fixme check for time_to_sleep < 0 if convert to int16_t
	  call StayAwakeTimer.stop();
	  call StayAwakeTimer.start(TIMER_ONE_SHOT,tsMsg->time_to_sleep_msec);

	  //*** Handle Next-WakeUp:
	  ts_msec = (uint32_t) (current_state.wakeup_period_msec 
	      + tsMsg->time_to_sleep_msec);
	  call WakeUpTimer.stop();
	  call WakeUpTimer.start(TIMER_ONE_SHOT, ts_msec);
	}
      }

#ifdef DEBUGGING
      else {
        tmp_time = call SysTime.getTime32();
	tsMsg->time_offset_usec = (uint32_t) (tmp_time * (-1));
      }

      tsMsg->send_delay = init_send_delay_msec;
#endif

      address = TOS_BCAST_ADDR;
#ifdef DEBUGGING
      address = TOS_LOCAL_ADDRESS + 1;
#endif

      // If this is a help message then broadcast it. Once we stop debugging
      // we will always broadcast these msgs anyways and can take out this
      // clause
      if (sending_help) {
        address = TOS_BCAST_ADDR;
      }

      // Either send a message if we are sending-help and we have  valid ts,
      // or if this is a regular msg
#ifdef DEBUGGING
      if ((tsMsg->ts_valid) || (!sent_debug_pkt)) {
        if (!sending_help) {
          num_msgs_tx++;
        }
#else
      if (tsMsg->ts_valid) {
#endif

        // fixme - what happens if this fails?
        if (call Send.send(address, sizeof(AS_Msg) + sizeof(AS_SYNCH), 
		&data)) {
          if (tsMsg->ts_valid) {
            call TimeStamping.addStamp(sizeof(AS_Msg));
            num_ts_msgs_sent_this_pd++;
#ifdef MEASURE_STATS
            call ReportPacketEvent.PacketEvent(CONTROL_POWERSAVE_PACKETS_SEND, 0);
#endif
          }
          else {
#ifdef DEBUGGING
            call TimeStamping.addStamp(sizeof(AS_Msg));
#endif
#ifdef MEASURE_STATS
            call ReportPacketEvent.PacketEvent(MISC_PACKET_TX, 0);
#endif
          }
          send_pending = TRUE;
          call Leds.redToggle();
        }
      }
#ifdef DEBUGGING
      sent_debug_pkt = TRUE;
#endif
    }
  }

  event TOS_MsgPtr Recv.receive(TOS_MsgPtr m) 
  {
    AS_Msg* fm = (AS_Msg *) m->data;
    AS_SYNCH *tsMsg = (AS_SYNCH *)fm->pkt;
#ifndef DEBUGGING
    uint32_t proc_delay_msec, rcv_delay;
#endif
    uint32_t ts_msec;
    uint32_t time_mac_rcvd_msg;

    call Leds.greenToggle();
    if (m->length < sizeof(AS_Msg)) {
      dbg(DBG_USR1, "ERROR: msglen: %d <= %d\n", m->length, 
	sizeof(AS_Msg)); 
      return m;
    }

    if (fm->type == APPSLEEP_REQ_SYNCH) {
#ifdef MEASURE_STATS
      call ReportPacketEvent.PacketEvent(CONTROL_POWERSAVE_PACKETS_RECV, 0);
#endif
      // No Delay needed; we know node is awake cuz we got a help msg 
      // fixme - a node should send a pkt regardless w/correct info 
      if (rcvd_ts_msg) {
        post sendSYNCH();
        sending_help = TRUE;
      }
    }

    else if (fm->type == APPSLEEP_SYNCH) {
#ifdef MEASURE_STATS
      call ReportPacketEvent.PacketEvent(CONTROL_POWERSAVE_PACKETS_RECV, 0);
#endif
#ifdef DEBUGGING
      num_msgs_rx++;
#endif
      if (TOS_LOCAL_ADDRESS != CLUSTER_HEAD_ID) {

	// We only want to process one time-synch packet at the most,
	// each wake-up period! If the absolute time-to-sleep has been set
	// then we know we processed a ts-packet this wakeup-cycle
	if ((tsMsg->ts_valid) && (!rcvd_ts_msg)) {
          call ExpectTimeSynch.stop();
          atomic {
            rcvd_ts_msg = TRUE;
            time_mac_rcvd_msg = call TimeStamping.getStamp(); 
            time_mac_rcvd_msg /= 1000;
          }

	  send_ts = TRUE; // Set because we want to forward the ts-pkt
          ts_pending = FALSE;
          num_help_msgs = 0; // Reset help messages cuz we got a ts pkt!

          // Figure out processing/mac/transmissino delay and subtract
          // this from the time-to-sleep.
          time_rcvd_ts_msg_msec = call SysTime.getTime32();
          time_rcvd_ts_msg_msec /= 1000;
          rcv_delay = time_rcvd_ts_msg_msec - time_mac_rcvd_msg;
          proc_delay_msec = (tsMsg->time_offset_usec/1000) + rcv_delay;
          time_to_sleep_msec = tsMsg->time_to_sleep_msec - proc_delay_msec;
          time_until_SYNCH_sec = (uint32_t) 
		(tsMsg->time_until_SYNCH_sec - (proc_delay_msec / 1000));

          //*** Handle Stay-Awake:
	  // fixme check for time_to_sleep < 0 if convert to int16_t
	  call StayAwakeTimer.stop();
	  call StayAwakeTimer.start(TIMER_ONE_SHOT, time_to_sleep_msec);

	  //*** Handle Next-WakeUp:
	  ts_msec = (uint32_t) (current_state.wakeup_period_msec 
	      + time_to_sleep_msec);
	  call WakeUpTimer.stop();
	  call WakeUpTimer.start(TIMER_ONE_SHOT, ts_msec);

	  //*** Handle Next Time-synch
	  // Dont need to worry about delay at receive/sending layers because
	  // this value is on the order of seconds
	  ts_msec = (uint32_t)(tsMsg->time_until_SYNCH_sec * 1000) - 200;
	  call TimeSynch.stop();
	  call TimeSynch.start(TIMER_ONE_SHOT, ts_msec);

	  call CalculateSD.stop();
	  call CalculateSD.start(TIMER_REPEAT, CALCULATE_SEND_DELAY_PD_MSEC);
	  time_since_last_ts_hour = 0; 
          post sendSYNCH();
#ifdef DEBUGGING
          num_ts_msgs_rcvd++;
#endif
	}

#ifdef DEBUGGING
	else if ((!tsMsg->ts_valid) && (!sent_debug_pkt)) {
#else
	else if (!tsMsg->ts_valid) {
#endif
          post sendSYNCH();
	}
      }
    }
#ifdef MEASURE_STATS
    else if (fm->type == APPSLEEP_STATS) {
      post sendStatsMsg();
      call ReportPacketEvent.PacketEvent(MISC_PACKET_RX, 0);
    }
#endif
    call Leds.greenToggle();
    return m;
  }

  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success)
  {
    AS_Msg* fm = (AS_Msg *)msg->data;
    AS_SYNCH *tsMsg = (AS_SYNCH *)fm->pkt;

    if ((send_pending) && (msg == &data)) {
        call Leds.redToggle();

        // Only want to do this at most once in a wakeup period!
        if ((send_ts) && (tsMsg->ts_valid)) {
          post calculate_misc_vars();
          atomic {
            send_ts = FALSE; 
            ts_pending = FALSE;
          }
        }
        send_pending = FALSE;
        sending_help = FALSE;
      }

    return SUCCESS;
  }

  event result_t ExpectTimeSynch.fired()
  {
    // See if we have received a time-synch packet
    if ((ts_pending) && (!rcvd_ts_msg)) {
      if (num_help_msgs <= TOTAL_NUM_HELP_MSGS) {
        post sendHelpMsg(); 
        num_help_msgs++;
        total_num_help_msgs++;
      }

      // O/w Just stop all timers and wait for a time-synch message.
      else {
        if (!radio_on) {
          radio_on = call RadioControl.start();
          call Leds.yellowOn();
        }
      }
    }
    return SUCCESS;
  }

  // Timer to wake-up the radio
  event result_t WakeUpTimer.fired()
  {
    uint16_t wait_for_ts;

    wakeup_time = call SysTime.getTime32();
    wakeup_time /= 1000;
#ifdef DEBUGGING
    sent_debug_pkt = FALSE;
#endif
    rcvd_ts_msg = FALSE;
    num_ts_msgs_sent_this_pd = 0;

    if ((ts_pending) && (TOS_LOCAL_ADDRESS != CLUSTER_HEAD_ID)) {
      wait_for_ts = stay_awake_time_msec - 80;

      // Check overflow
      if (wait_for_ts > stay_awake_time_msec) {
        wait_for_ts = (stay_awake_time_msec * 2) / 3;
      }
      call ExpectTimeSynch.start(TIMER_ONE_SHOT, wait_for_ts);
    }

    if (!radio_on) {
      radio_on = call RadioControl.start();
      call Leds.yellowOn();
    }

    call StayAwakeTimer.start(TIMER_ONE_SHOT, stay_awake_time_msec);
    call WakeUpTimer.start(TIMER_ONE_SHOT, (current_state.wakeup_period_msec));
   
    if (init_send_delay_msec > stay_awake_time_msec) {
      init_send_delay_msec = stay_awake_time_msec/4;
      dbg(DBG_USR1, "now init-send-delay: %d\n", init_send_delay_msec);
    }

    if (TOS_LOCAL_ADDRESS == CLUSTER_HEAD_ID) {
      if (ts_pending) {
        call ExpectTimeSynch.stop();
	call SendPkt.start(TIMER_ONE_SHOT, init_send_delay_msec);
	dbg(DBG_USR1, "call send-pkt in: %d msec\n", init_send_delay_msec);
      }
#ifdef MEASURE_STATS
      else if (send_stats_msg) {
	call SendStats.start(TIMER_ONE_SHOT, init_send_delay_msec);
      }
#endif
    
#ifdef DEBUGGING
      else {
        call SendPkt.start(TIMER_ONE_SHOT, init_send_delay_msec);
      }
#endif
    }
    return SUCCESS;
  }

#ifdef MEASURE_STATS
  event result_t SendStats.fired()
  {
    post sendStatsMsg();
    return SUCCESS;
  }
#endif
  
  event result_t SendPkt.fired()
  {
    post sendSYNCH();
    return SUCCESS;
  }
  
  // Timer to put the radio back to sleep
  event result_t StayAwakeTimer.fired()
  {
    if ((!send_pending) && (!ts_pending)) {
      call RadioControl.stop();
      radio_on = FALSE;
      call Leds.yellowOff();
    }
    else {
      call StayAwakeTimer.start(TIMER_ONE_SHOT, stay_awake_time_msec);
    }
    return SUCCESS;
  }

  event result_t TimeSynch.fired()
  {
    ts_pending = TRUE;

    if (!radio_on) {
      radio_on = call RadioControl.start();
      call Leds.yellowOn();
    }

    if (TOS_LOCAL_ADDRESS == CLUSTER_HEAD_ID) {
      send_ts = TRUE; // Set because we want to forward the ts-pkt
    }
#ifdef DEBUGGING
    num_ts_msgs_expected++;
#endif
#ifdef MEASURE_STATS
    send_stats_msg = TRUE;
#endif
    return SUCCESS;
  }

  event result_t CalculateSD.fired()
  {
    time_since_last_ts_hour++; 
    post calculate_misc_vars();
    return SUCCESS;
  }
}
