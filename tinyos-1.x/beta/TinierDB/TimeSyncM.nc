includes AM;
includes TimeStamp;

module TimeSyncM {
  provides {
    interface TimeSync;
    interface StdControl;

    interface SourceAddress;
  }

  uses {
    interface Leds;

    interface EpochScheduler as TimeSyncEpoch;
    //    interface EpochScheduler as SyncCatcherEpoch;

    interface Timer as TransmitTimer;

    interface SendMsg;
    interface ReceiveMsg;
    
    interface Time;
    interface TimeSet;
    interface TimeSetListener;

    interface TinyTimeInterval;

    interface TimeSyncAuthority as TimeSyncAuth;

    interface PowerArbiter;

    interface PiggyBack as TimeSyncPiggy;

    interface Random;

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
    interface RadioCoordinator as RadioSendCoordinator;
    interface RadioCoordinator as RadioReceiveCoordinator;
#endif
  }
} 
implementation {

  void curTimeStamp(TimeStamp t) {
    // Timestamp the message
    tos_time_t now = call Time.get();
    
    tos2timeStamp(now, t);
  }


  // This is the structure of the packet
  typedef struct {
    uint16_t srcAddr;
    TimeStamp timeStamp;

    // XXX: Does the node consider itself synchronized?
    // XXX: Maybe:  asymmetric loss
  } TimeSyncMsg;

  // In 1/1024th of a second, n bytes, 19.2 Kbps
  // Rounded to the next ms, some leeway for task jitter
  // 1 byte / 2.4 binticks

  // XXX:  Wei's how to make it plaform-independent
  // XXX:  Offset will stay constant every time you get a sync packet
  //       so you should nagate the difference
#define TIMESYNCMSG_TRANS_TIME (sizeof(TimeSyncMsg) * 24 / 10)

  TOS_Msg tsMsg;

  // Has this node been synchronized yet?
  // XXX:  Change to a better, abstracted component
  // taht takes into account last time of synchronization
  bool mSynchronized;

  // Is this node awake for synchronization
  // during the properly synchronized interval?
  // If not, this node may be awake, but waiting for
  // a desynchronize node
  bool mAwakeSynch = FALSE;

  // Is this node waiting to emit the time synchronization
  // packet this cycle?
  bool mSetTimer = FALSE;

  // Am I currently sending?
  bool mSending = FALSE;

  // Last known difference in desynchronization, in ms
  int64_t deSynch = NOT_TIME_SYNCHED;

  // Small increment of time which passed since
  // starting to send and until sending the packet
  norace uint16_t sendTS;

  void powerOn() {
    // call Leds.yellowOn();

    //    call PowerArbiter.useResource(PWR_RADIO);
  }

  void powerOff() {
    // call Leds.yellowOff();
    //    call PowerArbiter.releaseResource(PWR_RADIO);
  }

  command result_t StdControl.init() {

    mSynchronized = call TimeSyncAuth.isAuthoritative(TOS_LOCAL_ADDRESS);

    call Leds.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {   

    call TimeSyncEpoch.addSchedule(kTIME_SYNC_MSG_INTERVAL,
				   kTIME_SYNC_WAKING_TIME);
    call TimeSyncEpoch.start();
    
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event void TimeSetListener.timeAdjusted(int64_t msTicks) {

  }

  event void TimeSyncEpoch.epochOver() {
    uint16_t r = call Random.rand();

    dbg(DBG_USR1, "TS: EPOCH OVER\n");

    mAwakeSynch = FALSE;

    // If we are not synchronized, sleep with this probability
    if (mSynchronized) {
      if (r < kSLEEP_WHEN_SYNC)
	return;
    } else {
      if (r < kSLEEP_WHEN_NOTSYNC)
	return;
    }

    // Go to sleep
    if (mSetTimer) 
      call TransmitTimer.stop();

    powerOff();
  }

  // Randomize the time of emission
  // of the timesync heartbeat
  event void TimeSyncEpoch.beginEpoch() {

    dbg(DBG_USR1, "TS: BEGUN EPOCH\n");

    if (!mAwakeSynch) {
      mAwakeSynch = TRUE;

      powerOn();

      // XXX
      if (call TransmitTimer.start(TIMER_ONE_SHOT,
				   ((uint32_t)call Random.rand()) * 10 / 0xFFFF + 5) == FAIL) {
	mAwakeSynch = FALSE;
	mSetTimer = FALSE;
      } else {
	mSetTimer = TRUE;
      }
    }

  }


  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msg) {    
    TimeSyncMsg *tsm = (TimeSyncMsg *)msg->data;
    TimeStamp remoteTS, localTS;
    bool auth = FALSE;

    dbg(DBG_USR1, "TS: RECEIVED MESSAGE\n");

    if (tsm->srcAddr == TOS_LOCAL_ADDRESS) {

      dbg(DBG_USR1, "TS: PROMISCUOUS FEEDBACK\n");

      // Promiscuous
      return msg;
    }

    auth = call TimeSyncAuth.isAuthoritative(tsm->srcAddr);

    if (!auth && mSynchronized && !mAwakeSynch) {

      dbg(DBG_USR1, "TS: INTERCEPTED DESYNC NODE, RESPONDING\n");

      // Emit the message
      signal TransmitTimer.fired();
    } else {

      memcpy(remoteTS, tsm->timeStamp, sizeof(TimeStamp));

      timeStampAdd16(remoteTS, TIMESYNCMSG_TRANS_TIME);

      curTimeStamp(localTS);
      
      dbg(DBG_USR1, "src = %lu\n", tsm->srcAddr);
      dbg(DBG_USR1, "ts = %lu.%lu\n", 
	  remoteTS[0],
	  *(uint32_t *)(&remoteTS[1]) );
      
      // Should we set our own timer according to this message
      if (auth) {
	deSynch = 
	  timeStampDiff(remoteTS, localTS);
	
	call Leds.redOn();
	
	mSynchronized = TRUE;
	
	dbg(DBG_USR1, 
	    "TS: AUTHORITATIVE\n"
	    );
	
	dbg(DBG_USR1, 
	    "TS: Local timeSTAMP is %lu.%lu\n",
	    localTS[0],
	    *(uint32_t *)(&localTS[1]));
	
	// IMPORTANT: the below *must* adjust the time
	// of the occurence of the cycle.
	// I.e. affects the ServiceScheduler
	// through the TimeSetListener interface

	// XXX:  This may cause short-scale 
	// local inconsistencies on time-series data
	// May have to send an adjustment message to chase
	// data that has already been sent out
	call TimeSet.set(timeStamp2tos(remoteTS));
	
	mSynchronized = TRUE;
      } else {
	dbg(DBG_USR1, "TS: NOT AUTHORITATIVE\n");
      }

      // Pass this message on to the component
      // which may be piggybacking to this message
      call TimeSyncPiggy.piggyReceive(msg, 
				      msg->data + 
				      sizeof(TimeSyncMsg),
				      msg->length - sizeof(TimeSyncMsg)
				      );
    }
      
    return msg;
  }
  

  // Send the TimeSync message
  event result_t TransmitTimer.fired() {

    mSetTimer = FALSE;

    if (!mSending) {
      TimeSyncMsg *tsm = (TimeSyncMsg *)tsMsg.data;
      uint8_t len;
      
      tsm->srcAddr = TOS_LOCAL_ADDRESS;

      curTimeStamp(tsm->timeStamp);
            
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
      // Record the time interval until the packet is actually sent
      call TinyTimeInterval.startNow(&sendTS);
#endif
      
      len = sizeof(TimeSyncMsg);
      call TimeSyncPiggy.piggySend(&tsMsg,
				   tsMsg.data + sizeof(TimeSyncMsg),
				   &len,
				   TOSH_DATA_LENGTH - sizeof(TimeSyncMsg));

      dbg(DBG_USR1, "The length of the message is now %d bytes (%d)\n", 
	  len, sizeof(TimeSyncMsg));

      if (call SendMsg.send(TOS_BCAST_ADDR,
			    len,
			    &tsMsg) == SUCCESS) {

	dbg(DBG_USR1, "TS: SENT MESSAGE\n");

	mSending = TRUE;
      } else {
	// Postpone the timer a little
	call TransmitTimer.start(TIMER_ONE_SHOT,
				 20);
	mSending = FALSE;
	mSetTimer = TRUE;
      }
      
    }
    
    return SUCCESS;
  }
  
  event result_t SendMsg.sendDone(TOS_MsgPtr msg,
				  result_t status) {
    mSending = FALSE;

    dbg(DBG_USR1, "TS: SENT MESSAGE DONE\n");

    return SUCCESS;
  }
  

  /**
   * Retrieves the confidence in time synchronization
   *
   * @return Returns the confidence value, in milliseconds.
   * The meaning of it is that the current node is,
   * with high probability, within that many milliseconds
   * of the synchronizing node.  
   * If the return value == NOT_TIME_SYNCHED, the node is not
   * synchronized
   *
   **/
  command uint32_t TimeSync.getConfidence() {
    if (mSynchronized) {
      if (deSynch > 0)
	return (uint32_t)deSynch;
      else
	return (uint32_t)(-(int32_t)deSynch);
    } else {
      return NOT_TIME_SYNCHED;
    }
  }
  

  //low level routines to write timestamps into messages
  // before they go over the radio, on platforms that support
  // low-level timestamping
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
  //this event indicates that the start symbol has been detected
  async event void RadioReceiveCoordinator.startSymbol(uint8_t bitsPerBlock, 
						       uint8_t offset, 
						       TOS_MsgPtr msgBuff) {
  }

  //this event indicates that another byte of the current packet has been rxd
  async event void RadioReceiveCoordinator.byte(TOS_MsgPtr msg, 
						uint8_t byteCount) {
  }

  async event void RadioReceiveCoordinator.blockTimer() {
  }

  async event void RadioSendCoordinator.blockTimer() {  
  }

  //this event indicates that the start symbol has been sent -- 
  // we do our timestamping here
  async event void RadioSendCoordinator.startSymbol(uint8_t bitsPerBlock, 
						    uint8_t offset, 
						    TOS_MsgPtr msgBuff) {
    if (msgBuff->type == TIME_SYNC_AM) {
      TimeSyncMsg *msg = (TimeSyncMsg *)tsMsg.data;
      
      timeStampAdd16(msg->timeStamp,
		     call TinyTimeInterval.passedSince(&sendTS));
    }
  }


  //this event indicates that another byte of the current packet has been sent
  async event void RadioSendCoordinator.byte(TOS_MsgPtr msg, 
					     uint8_t byteCount) {

  }
#endif

  // Default events -------------------------------------
    /**
   * @param msg Message pointer
   * @param buf Pointer to the buffer corresponding to the
   * next layer's code
   * @param lenRemaining Remaining length of the packet data,
   * starting at the location pointed at by buf
   * @return Returns <code>FALSE</code> if the piggyback
   * layers think that this message should be suppressed.
   **/
  default command bool TimeSyncPiggy.piggySuppress(TOS_MsgPtr msg,
						   uint8_t *buf,
						   uint8_t lenRemaining) {
    return FALSE;
  }

  /**
   * @param msg Message pointer
   * @param buf Pointer to the buffer corresponding to the
   * next layer's code
   * @param len Length of the packet so far
   * @param lenRemaining Remaining capacity of the packet,
   * starting at the location pointed at by buf
   **/
  default command result_t TimeSyncPiggy.piggySend(TOS_MsgPtr msg,
						   uint8_t *buf,
						   uint8_t *len,
						   uint8_t lenRemaining) {
    return SUCCESS;
  }

  /**
   * @param msg Message pointer
   * @param buf Pointer to the buffer corresponding to the
   * next layer's code
   * @param lenRemaining Remaining length of the packet,
   * starting at the location pointed at by buf
   **/
  default command result_t TimeSyncPiggy.piggyReceive(TOS_MsgPtr msg,
						      uint8_t *buf,
						      uint8_t lenRemaining) {
    return SUCCESS;
  }


  command uint16_t SourceAddress.getAddress(TOS_MsgPtr msg) {
    if (msg->type == TIME_SYNC_AM) {
      TimeSyncMsg *tsm = (TimeSyncMsg *)msg->data;
      
      return tsm->srcAddr;
    } else
      return TOS_BCAST_ADDR;
  }

}
