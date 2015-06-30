includes TimeSync;

module BaseSyncM {
  provides interface StdControl;
  
  uses {
    interface StdControl as RadioControl;
    interface BareSendMsg as RadioSend;
    interface ReceiveMsg as RadioReceive;
    interface Timer;
    //interface SysTime;
    interface Time as SimpleTime;
    interface Leds;
  }
}

implementation {
  bool pending;
  TOS_Msg data;
  TOS_MsgPtr p_data;
  tos_time_t time;
  
  result_t TimeSyncRfm();
  result_t TimeSyncAck();
  
  command result_t StdControl.init() {
    data.length = 0;
    p_data = &data;
    pending = FALSE;
    
    return rcombine(call Leds.init(), call RadioControl.init());
  }
  command result_t StdControl.start() {
    return rcombine(call RadioControl.start(), call Timer.start(TIMER_REPEAT, 5000));
  }
  command result_t StdControl.stop() {
  	return call RadioControl.stop();
  }
  	
  event result_t Timer.fired() {
    //call Leds.redToggle();
    return TimeSyncRfm();
  }
  result_t TimeSyncRfm() {
  	struct TimeSyncMsg *syncMsg;
  	atomic {
  	  time.high32 = call SimpleTime.getLow32();
  	  time.low32 = call SimpleTime.getHigh32();
  	}
  	
  	p_data->addr = TOS_BCAST_ADDR;
  	p_data->type = TIME_SYNC;
  	p_data->group = TOS_AM_GROUP;
  	p_data->length = sizeof(struct TimeSyncMsg);
  	syncMsg = (struct TimeSyncMsg *)p_data->data;
  	syncMsg->value = 1;
  	syncMsg->timeHigh = time.high32;
  	syncMsg->timeLow = time.low32;
  	
  	if(call RadioSend.send(p_data)) 
  	  call Leds.greenToggle();
  	else 
  	  call Leds.redToggle();
  	return SUCCESS;
  }
  result_t TimeSyncAck() {
    struct TimeSyncMsg *syncMsg;
    tos_time_t ackTime;
    
    syncMsg = (struct TimeSyncMsg *)p_data->data;
    ackTime.high32 = syncMsg->timeHigh;
    ackTime.low32 = syncMsg->timeLow;
    
    atomic {
      time.high32 = call SimpleTime.getHigh32();
      time.low32 = call SimpleTime.getLow32();
    }
    return SUCCESS;
    
  }
  event result_t RadioSend.sendDone(TOS_MsgPtr Msg, result_t success) {
    p_data->length = 0;
    Msg->length = 0;
    time.high32 = 0;
    time.low32 = 0;
    return SUCCESS;
  }
  event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr msg) {
    p_data = msg;
    call Leds.yellowToggle();
    return msg;
  }
}
    