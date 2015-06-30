includes Drain;

module TestDrainM {
  provides interface StdControl;
  
  uses {
    interface Leds;

    interface Send;
    interface SendMsg;

    interface Timer;
    interface Random;

    interface Drain;
  }
}

implementation {
  
  TOS_Msg msgBuf;
  bool msgBufBusy;
  uint16_t counter;
  uint16_t sendPeriod;

  command result_t StdControl.init() { 
    sendPeriod = TESTDRAIN_SEND_PERIOD;
    counter = 0;
    msgBufBusy = FALSE;
    return SUCCESS; 
  }
  
  command result_t StdControl.start() { 
    call Timer.start(TIMER_ONE_SHOT, 
		     (call Random.rand() % sendPeriod) + 1);
    return SUCCESS; 
  }
  
  command result_t StdControl.stop() { 
    call Timer.stop();
    return SUCCESS; 
  }

  event result_t Timer.fired() {
    uint16_t length;
    TestDrainMsg* testMHMsg = 
      (TestDrainMsg*) call Send.getBuffer(&msgBuf, &length);
    
    call Leds.redOn();

    if (TOS_LOCAL_ADDRESS == 1) {
      call Drain.buildTree();
      call Timer.start(TIMER_ONE_SHOT, 10000);
      return SUCCESS;
    }

    call Timer.start(TIMER_ONE_SHOT, sendPeriod);

    if (msgBufBusy) {
      return SUCCESS;
    } else {
      msgBufBusy = TRUE;
    }

    testMHMsg->data = counter;

    if (call SendMsg.send(TOS_DEFAULT_ADDR, sizeof(TestDrainMsg), &msgBuf)
	== FAIL) {
      call Leds.yellowToggle();
      msgBufBusy = FALSE;
    }
    
    return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {

    dbg(DBG_USR1, "sendDone(msg=0x%x,success=%d)\n",
	msg, success);

    if (msg == &msgBuf) {
      msgBufBusy = FALSE;
      if (success)
	call Leds.redOff();
      else
	call Leds.greenToggle();
    }

    counter++;

    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }
}
