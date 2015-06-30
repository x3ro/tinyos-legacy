includes TimeSync;

module ReceiverSyncM {
  provides interface StdControl;
  
  uses {
    interface StdControl as RadioControl;
    interface BareSendMsg as RadioSend ;
    interface ReceiveMsg as RadioReceive;
    interface Leds;
    interface Time as SimpleTime;
    interface TimeSet;
    interface Timer;
  }
    
}
implementation {
  
  TOS_Msg data;
  TOS_MsgPtr p_data;
  tos_time_t time;

  void ReceivedMsg();
  result_t TimeSyncAck();
  
  command result_t StdControl.init() {
    data.length = 0;
    p_data = &data;
    
    return rcombine(call Leds.init(), call RadioControl.init());
  }
  command result_t StdControl.start() {
    return call RadioControl.start();
  }
  command result_t StdControl.stop() {
    return call RadioControl.stop();
  }
  event result_t Timer.fired() {
    return TimeSyncAck();
  }
  
  result_t TimeSyncAck() {
    struct TimeSyncMsg *syncMsg;
    
    p_data->addr = TOS_BCAST_ADDR;
    p_data->type = SYNC_ACK;
    p_data->group = TOS_AM_GROUP;
    p_data->length = sizeof(struct TimeSyncMsg);
    syncMsg->value = 1;

    atomic {
      syncMsg->timeHigh = call SimpleTime.getHigh32();
      syncMsg->timeLow = call SimpleTime.getLow32();    
    }
    
    if(call RadioSend.send(p_data)) 
      call Leds.greenToggle();
    else 
      call Leds.yellowToggle();
    return SUCCESS;
    
    
  }
  
  void ReceivedMsg() {
    struct TimeSyncMsg *syncMsg;
    
    syncMsg = (struct TimeSyncMsg *)p_data->data;
    
    time.high32 = syncMsg->timeHigh;
    time.low32 = syncMsg->timeLow;
    call TimeSet.set(time);
    
    call Leds.redToggle();
    call Timer.start(TIMER_ONE_SHOT, 500);
    
    return;
  }
  event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr msg) {
    p_data = msg;
    ReceivedMsg();
    return msg;
  }
  event result_t RadioSend.sendDone(TOS_MsgPtr msg, result_t success) {
    p_data->length = 0;
    msg->length = 0;
    time.high32 = 0;
    time.low32 = 0;
    
    return SUCCESS;
  }
}