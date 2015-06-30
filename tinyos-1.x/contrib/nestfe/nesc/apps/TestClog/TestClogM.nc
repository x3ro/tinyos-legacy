module TestClogM {
  provides {
    interface StdControl;
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
    interface Receive as DrainReceive;

    interface StdControl as ClogControl;
  }
}

implementation {
  
  TOS_Msg msgBuf;
  bool msgBufBusy;
  uint16_t counter;
  uint16_t sendPeriod = 4096;
  uint16_t treeBuildPeriod = 32768U;
  uint8_t treeInstance = 0xBB;
  
  uint16_t destination = DRAIN_GROUP_MULTICAST;

  enum {
    TEST_LANDMARK_ADDR = 1,
    TEST_MOBILE_ADDR = 2,
    TEST_BASE_ADDR = 3,
  };

  command result_t StdControl.init() { 
    call Leds.init();
    call ClogControl.init();
    return SUCCESS; 
  }
  
  command result_t StdControl.start() { 

    if (TOS_LOCAL_ADDRESS == TEST_LANDMARK_ADDR) {
      call Timer.start(TIMER_ONE_SHOT, 1000);
    } else if (TOS_LOCAL_ADDRESS == TEST_MOBILE_ADDR) {
      call Timer.start(TIMER_ONE_SHOT, sendPeriod * 2);
    } else if (TOS_LOCAL_ADDRESS == TEST_BASE_ADDR) {
      call Timer.start(TIMER_ONE_SHOT, 
		       (call Random.rand() % 2000) + 2000);
    } else {
      call Timer.start(TIMER_ONE_SHOT, 
		       (call Random.rand() % sendPeriod) + 1);
    }
    return SUCCESS; 
  }

  command result_t StdControl.stop() { return SUCCESS; }

  event result_t Timer.fired() {
    uint16_t length;

    TestClogMsg* testMHMsg = 
      (TestClogMsg*) call Send.getBuffer(&msgBuf, &length);

    // Become the Clog
    if (TOS_LOCAL_ADDRESS == TEST_LANDMARK_ADDR) {
      call ClogControl.start();
      return SUCCESS;
    }

    // Join the Drain group in order to receive messages from the Clog
    if (TOS_LOCAL_ADDRESS == TEST_MOBILE_ADDR) {
      call DrainGroup.joinGroup(DRAIN_GROUP_MULTICAST);
      call Timer.start(TIMER_ONE_SHOT, sendPeriod);
      return SUCCESS;
    }

    // Become the Root
    if (TOS_LOCAL_ADDRESS == TEST_BASE_ADDR) { 
      call Drain.buildTreeInstance(treeInstance, FALSE);
      call Timer.start(TIMER_ONE_SHOT, treeBuildPeriod);
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

    // Alternate destinations between the multicast group and the
    // regular drain tree.

    if (destination == DRAIN_GROUP_MULTICAST) {
      destination = TEST_BASE_ADDR;
    } else if (destination == TEST_BASE_ADDR) {
      destination = DRAIN_GROUP_MULTICAST;
    }

    call Leds.redOn();
    
    if (call SendMsg.send(destination, sizeof(TestClogMsg), &msgBuf)
	== FAIL) {
      call Leds.yellowToggle();
      msgBufBusy = FALSE;
    } else {
      dbg(DBG_USR1, "TestClogM: sent data %d\n", testMHMsg->data);
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

    call Leds.greenToggle();
    return msg;
  }

  event TOS_MsgPtr DrainReceive.receive(TOS_MsgPtr msg, 
					void* payload, 
					uint16_t payloadLen) {
#ifdef PLATFORM_PC
    DrainMsg *drainMsg = (DrainMsg*) msg->data;
    TestClogMsg *tcMsg = (TestClogMsg*)payload;
#endif

    if (TOS_LOCAL_ADDRESS == TEST_LANDMARK_ADDR) {
      return msg;
    }

#ifdef PLATFORM_PC
    dbg(DBG_USR1, "TestClogM: got data %d from node %d over Drain\n", tcMsg->data, drainMsg->source);
#endif

    call Leds.yellowToggle();
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
}
