includes Attrs;

module TestClogM {
  provides {
    interface StdControl;

    interface Attr<uint8_t> as TestClogIsMobile @nucleusAttr("TestClogIsMobile");
    interface AttrSet<uint8_t> as TestClogIsMobileSet @nucleusAttr("TestClogIsMobile");
  }

  uses {
    interface Leds;
    interface Timer;
    interface Random;

    interface Send;
    interface SendMsg;
    interface DrainGroup;
    interface Drain;

    interface Receive;

//    interface StdControl as ClogControl;
  }
}

implementation {
  
  TOS_Msg msgBuf;
  bool msgBufBusy;

  bool isMobile = FALSE;

  uint16_t counter;

  uint16_t sendPeriod = 4096;
  uint16_t joinPeriod = 4096;
  uint16_t treeBuildPeriod = 32768U;

  uint8_t treeInstance = 0xBB;

  uint16_t staticMsgsSent = 0;
  uint16_t mobileMsgsRcvd = 0;

  uint16_t destination = DRAIN_GROUP_MULTICAST;

  command result_t StdControl.init() { 
    call Leds.init();
//    call ClogControl.init();
    return SUCCESS; 
  }
  
  command result_t StdControl.start() { 
/*
    if (TOS_LOCAL_ADDRESS == 1) {
      call ClogControl.start();
      return SUCCESS;
    }
*/

    call Timer.start(TIMER_ONE_SHOT, 
		     (call Random.rand() % sendPeriod) + 1);
    return SUCCESS; 
  }

  command result_t StdControl.stop() { return SUCCESS; }

  event result_t Timer.fired() {
    uint16_t length;

    TestClogMsg* testMHMsg = 
      (TestClogMsg*) call Send.getBuffer(&msgBuf, &length);

    if (isMobile) {
      call DrainGroup.joinGroup(DRAIN_GROUP_MULTICAST, joinPeriod / 1024 * 2);
      call Timer.start(TIMER_ONE_SHOT, joinPeriod);
      return SUCCESS;
    }

    // Every other node: send a message.
    call Timer.start(TIMER_ONE_SHOT, sendPeriod);

    if (msgBufBusy) {
      return SUCCESS;
    } else {
      msgBufBusy = TRUE;
    }

    testMHMsg->data = counter;

    destination = DRAIN_GROUP_MULTICAST;

    call Leds.redOn();
    
    if (call SendMsg.send(destination, sizeof(TestClogMsg), &msgBuf)
	== FAIL) {
      call Leds.yellowToggle();
      msgBufBusy = FALSE;
    } else {
      dbg(DBG_USR1, "TestClogM: sent data %d\n", testMHMsg->data);
      staticMsgsSent++;
    }
    
    return SUCCESS;
  }

  event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg, 
				   void* payload, 
				   uint16_t payloadLen) {

#ifdef PLATFORM_PC
    DripMsg *dripMsg = (DripMsg*) msg->data;
    AddressMsg *addressMsg = (AddressMsg*) dripMsg->data;
    TestClogMsg *tcMsg = (TestClogMsg*)payload;

    dbg(DBG_USR1, "TestClogM: got data %d from node %d over Drip\n", tcMsg->data, addressMsg->source);
#endif

    mobileMsgsRcvd++;

    return msg;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {

    if (msg == &msgBuf) {
      msgBufBusy = FALSE;
      if (success)
	call Leds.redOff();
    }

    counter++;

    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }

  command result_t TestClogIsMobile.get(uint8_t* buf) {
    memcpy(buf, &isMobile, 1);
    signal TestClogIsMobile.getDone(buf);
    return SUCCESS;
  }

  command result_t TestClogIsMobileSet.set(uint8_t* buf) {
    memcpy(&isMobile, buf, 1);
    if (isMobile) {
      call DrainGroup.joinGroup(DRAIN_GROUP_MULTICAST, joinPeriod / 1024 * 2);
      call Timer.start(TIMER_ONE_SHOT, joinPeriod);
    } else {
      call Timer.stop();
      call Timer.start(TIMER_ONE_SHOT, sendPeriod);
    }
    signal TestClogIsMobileSet.setDone(buf);
    return SUCCESS;
  }
}
