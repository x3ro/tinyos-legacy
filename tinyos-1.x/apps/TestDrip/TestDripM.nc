module TestDripM {
  provides interface StdControl;

  uses {
    interface Leds;

    interface Timer;

    interface Receive as ReceiveDrip;
    interface Drip;
  }
}

implementation {
  
  uint16_t data;

  command result_t StdControl.init() { 
    call Leds.init();
    call Drip.init();
    return SUCCESS; 
  }
  
  command result_t StdControl.start() { 
    if (TOS_LOCAL_ADDRESS == 1) {
      call Timer.start(TIMER_REPEAT, 2048);
    }
    return SUCCESS; 
  }

  command result_t StdControl.stop() { return SUCCESS; }

  event result_t Timer.fired() {
    call Drip.change();
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveDrip.receive(TOS_MsgPtr msg, 
				       void* payload, 
				       uint16_t payloadLen) {
    
    TestDripMsg *tdMsg = (TestDripMsg*)payload;
    data = tdMsg->data;
    call Leds.redToggle();
    return msg;
  }

  event result_t Drip.rebroadcastRequest(TOS_MsgPtr msg, 
					 void *payload) {

    TestDripMsg *tdMsg = (TestDripMsg*)payload;
    tdMsg->data = data;

    call Leds.greenToggle();
    call Drip.rebroadcast(msg, payload, sizeof(TestDripMsg));
    return SUCCESS;
  }
}
