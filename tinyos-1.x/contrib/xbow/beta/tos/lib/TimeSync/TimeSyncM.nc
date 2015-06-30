

includes TosTime;
includes Timer;
includes AbsoluteTimer;

module TimeSyncM {
  provides {
    interface StdControl;
    interface Time;
    interface TimeSet;
  }
  uses {
    interface Timer as UpdateTimer;
    interface Timer;
    interface TimeUtil;
    interface StdControl as TimerControl;
    interface StdControl as CommControl;
    interface Leds;
    interface SendMsg;
    interface ReceiveMsg;
    interface RadioCoordinator;
  }
}
implementation
{

typedef struct TimeSyncMsg {
    uint16_t source_addr;
    uint8_t phase;
    int8_t corr;
    uint8_t authority; // time sync depth
    uint32_t timeH;
    uint32_t timeL;
}TimeSyncMsg;



  enum {
    TRANS_TIME = 16,
    INTERVAL = 5 * 1024,
    SMOOTH_FACTOR = 3,
#ifdef TEN_X
    NUM_CYCLES_PER_CALC = 13  // send an update every NUM_CYCLES*INTERVAL secods.
#else
    NUM_CYCLES_PER_CALC = 128  // send an update every NUM_CYCLES*INTERVAL secods.
#endif
  };

  tos_time_t time;
  uint8_t interval_count;
  uint32_t skiew;
  int32_t skiew_so_far;
  uint8_t authority;
  int8_t last_shift;
  TOS_Msg msg;

  command result_t StdControl.init() {
    // initialize logical time
    atomic {
      time.high32=0; 
      time.low32 =0;
    }
    skiew = 128;
    skiew <<= (4 + SMOOTH_FACTOR);
    call TimerControl.init();
    authority = 10;
    if(TOS_LOCAL_ADDRESS == 0) authority = 2;
    interval_count  = NUM_CYCLES_PER_CALC - 3;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call TimerControl.start();
    call UpdateTimer.start(TIMER_REPEAT, INTERVAL);
    call Timer.start(TIMER_REPEAT, INTERVAL);
    return SUCCESS ;
  }

  command result_t StdControl.stop() {
    call Timer.stop();
    call TimerControl.stop();
    return SUCCESS;
  }

  async command uint16_t Time.getUs() {
    return 0;
  }

  async command tos_time_t Time.get() {
    tos_time_t t;
    uint32_t left;

    atomic t = time;
    left = call Timer.ticksLeft();
    t = call TimeUtil.addUint32(t, INTERVAL - left);
    return t;
  }

  async command uint32_t Time.getHigh32()  {
    uint32_t rval;
    atomic {
      rval = time.high32;
    }
    return rval;
  }

  async command uint32_t Time.getLow32() {
    tos_time_t t;
    uint16_t rval;
    //t = call Time.get();
    atomic {
      rval = time.low32;
      rval += INTERVAL - call Timer.ticksLeft();
    }
    return rval;
  }

 uint8_t fill_pending;

 task void FillTime(){
	if(fill_pending == 1){
		TimeSyncMsg* tMsg = (TimeSyncMsg*)msg.data;
    		tos_time_t t;
		t = call Time.get();
		tMsg->source_addr = TOS_LOCAL_ADDRESS;
		tMsg->timeH = t.high32;
		tMsg->timeL = t.low32;
		tMsg->timeH = skiew;
		tMsg->authority = authority;
		if(authority < 120) authority ++;
        	if(TOS_LOCAL_ADDRESS == 0) authority = 2;
	}
	fill_pending = 0;
 }

 task void SendTask(){
	TimeSyncMsg* tMsg = (TimeSyncMsg*)msg.data;
	tMsg->authority = 255;
	tMsg->phase = last_shift;
	fill_pending = 1;
	msg.strength = 0;
	call SendMsg.send(TOS_BCAST_ADDR, 0x1C, &msg);
	return;
  }
  int16_t skiew_corr;

  event result_t UpdateTimer.fired() {
    TimeSyncMsg* tMsg = (TimeSyncMsg*)msg.data;
    int32_t corr;
    interval_count ++;
    if(interval_count >= NUM_CYCLES_PER_CALC){
	interval_count = 0;
	skiew_so_far += 128;
	if(skiew_so_far > 0){
		skiew -= skiew >> SMOOTH_FACTOR;
		skiew += skiew_so_far << 4;	
		skiew_so_far = 0;
	}
#ifndef G_BASE
	post SendTask();
#endif
    }

    corr = skiew;
    corr = corr >> SMOOTH_FACTOR;
    tMsg->corr = skiew >> 4;
    corr -= (128 << 4);
    skiew_corr += corr;
    if(skiew_corr > (NUM_CYCLES_PER_CALC << 4)){
	skiew_corr = 0;
    	atomic {
      		time = call TimeUtil.addint32(time, -1);
		skiew_so_far ++;
    	}
    }else if(skiew_corr < -(NUM_CYCLES_PER_CALC << 4)){
	skiew_corr = 0;
	atomic{
    		time = call TimeUtil.addint32(time, 1);
		skiew_so_far --;
	}
    }
    return SUCCESS;
  }
    
  event result_t Timer.fired() {
    atomic time = call TimeUtil.addUint32(time, INTERVAL);
    return SUCCESS;
  }

  /**
   *  Set the 64 bits logical time to a specified value 
   *  @param t Time in the unit of binary milliseconds
   *           type is tos_time_t
   *  @return none
   */
  command void TimeSet.set(tos_time_t t) {
	//to set the current time we must take into account the current 
	//timer value
    atomic {
      time.high32 = t.high32;
      time.low32 = t.low32;
      call Timer.start(TIMER_REPEAT, INTERVAL);
    }

  }


  /**
   *  Adjust logical time by n  binary milliseconds.
   *
   *  @param us unsigned 16 bit interger 
   *            positive number advances the logical time 
   *            negtive argument regress the time 
   *            This operation will not take effect immidiately
   *            The adjustment is done duing next clock.fire event
   *            handling.
   *  @return none
   */
  command void TimeSet.adjust(int16_t n) {
    call TimeSet.adjustNow(n);
  }

  /**
   *  Adjust logical time by x milliseconds.
   *
   *  @param x  32 bit interger
   *            positive number advances the logical time
   *            negtive argument regress the time
   *  @return none
   */
  command void TimeSet.adjustNow(int32_t x) {
    call TimeSet.set(call TimeUtil.addint32(time, x));
  }



  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr pMsg) {
	int16_t delta;
	TimeSyncMsg* tMsg = (TimeSyncMsg*)pMsg->data;
    	tos_time_t t = call Time.get();
    	tos_time_t val;
    	tos_time_t new_time;
	//do no listen to messages with a higher authority number.
	if(authority < (tMsg->authority + 2)) return pMsg;
	else if(authority == (tMsg->authority + 2)){
		//if the authority numbers are equal, then only listen to
		//the nodes with a lower source address.
		if(TOS_LOCAL_ADDRESS < tMsg->source_addr)
			return pMsg;
	}
	authority = tMsg->authority + 2;
	val.high32 = tMsg->timeH;
	val.high32 = 0;
	val.low32 = tMsg->timeL;


	//set your time to the current time.
#ifndef G_BASE
	new_time =  call TimeUtil.addint32(val, TRANS_TIME);
	call TimeSet.set(new_time);
#endif

	//determine the time offset between new time and current time
	delta = (call TimeUtil.subtract(t, val)).low32;
	delta -= TRANS_TIME;
	last_shift = delta;
	if(delta > -50 && delta < 50) skiew_so_far += delta;
	if(skiew_corr < 0) skiew_corr = -(NUM_CYCLES_PER_CALC << 2);
	else skiew_corr = (NUM_CYCLES_PER_CALC << 2);
	return pMsg;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
	return SUCCESS;
  }

  async event void RadioCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff){
	if(msgBuff == &msg) post FillTime();
	return;
  }
  async event void RadioCoordinator.byte(TOS_MsgPtr Tmsg, uint8_t val) { 
	return;
  }
  async event void RadioCoordinator.blockTimer(){
	return;
  }

}
