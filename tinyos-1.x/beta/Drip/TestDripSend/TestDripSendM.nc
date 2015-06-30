module TestDripSendM {
  provides interface StdControl;

  uses {
    interface Leds;

    interface Timer;

    interface Send;
    interface SendMsg;
    interface Receive;

    interface GroupManager;
  }
}

implementation {
  
  TOS_Msg msgBuf;
  uint16_t data;

  command result_t StdControl.init() { 
    call Leds.init();
    return SUCCESS; 
  }
  
  command result_t StdControl.start() { 
    if (TOS_LOCAL_ADDRESS == 1)
      call GroupManager.joinForward(0xFEFE);

    if (TOS_LOCAL_ADDRESS == 3) 
      call GroupManager.joinForward(0xFEFE);

    if (TOS_LOCAL_ADDRESS == 6) 
      call GroupManager.joinForward(0xFEFE);
    
    if (TOS_LOCAL_ADDRESS == 18)
      call GroupManager.joinGroup(0xFEFE);
    
    if (TOS_LOCAL_ADDRESS == 1) {
      call Timer.start(TIMER_REPEAT, 2048);
    }
    return SUCCESS; 
  }

  command result_t StdControl.stop() { return SUCCESS; }

  event result_t Timer.fired() {
    uint16_t length;
    TestDripMsg* tdMsg = (TestDripMsg*) call Send.getBuffer(&msgBuf, &length);

    data++;

    tdMsg->data = data;

    dbg(DBG_USR1, "sending data %d\n", tdMsg->data);

    call SendMsg.send(0xFEFE, sizeof(TestDripMsg), &msgBuf);

    return SUCCESS;
  }

  event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg, 
				   void* payload, 
				   uint16_t payloadLen) {
    
    TestDripMsg *tdMsg = (TestDripMsg*)payload;
    data = tdMsg->data;
    call Leds.redToggle();
    dbg(DBG_USR1, "got data %d\n", data);
    return msg;
  }

  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }
}
