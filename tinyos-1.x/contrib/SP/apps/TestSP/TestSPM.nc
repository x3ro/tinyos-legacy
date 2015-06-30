includes TestSPMsg;
includes SPSimDbg;

module TestSPM {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer;
    interface SPSend;
    interface SPSendQueue;
    interface SPReceive;
    interface SplitControl as RadioControl;
  }
}
implementation {
  
  uint8_t cnt;
  uint8_t state;
  uint8_t lastLQI;
  sp_message_t sp_msg;
  sp_message_t sp_msg_u;

  TOS_Msg tos_msg;
  TOS_Msg tos_msg_u;

#ifdef DEBUG
  DebugMode dbgApp = {TRUE, DBG_USR3, DbgNormal, "App"};
  DebugMode dbgReceive = {TRUE, DBG_USR3, DbgNormal, "App"};
#endif

  enum {
    IDLE = 0,
    SENDING,
  };
  
  command result_t StdControl.init() {
    cnt = 0;
    state = IDLE;
    sp_msg.sp_handle = TOS_BCAST_HANDLE;
    sp_msg.service = AM_TESTSPMSG;
    sp_msg.src = TRUE;
    sp_msg.length = 2;
    tos_msg.length = sizeof(test_sp_message_t);
    return call RadioControl.init();
  }

  event result_t RadioControl.initDone() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return call RadioControl.start();
  }

  event result_t RadioControl.startDone() {
    return call Timer.start(TIMER_REPEAT, 1024);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call Timer.stop();
    return SUCCESS;
  }

  event result_t RadioControl.stopDone() {
    //return call Timer.start(TIMER_REPEAT, 1024);
    return SUCCESS;
  }

  event result_t Timer.fired() {
    uint8_t _state;
    atomic _state = state;
    if (state == IDLE) {
      // send a message using SP
      if (!sp_msg.busy) {
        state = SENDING;
	tos_msg.data[2] = cnt;
	tos_msg.data[3] = lastLQI;
	sp_msg.sp_handle = TOS_BCAST_HANDLE;
	sp_msg.quantity = 1;
	//sp_msg.urgent = TRUE;
	sp_msg.urgent = FALSE;
	sp_msg.msg = &tos_msg;
	if (call SPSend.send(&sp_msg)) {
	  //printd(dbgApp, "Timer.fired(): state is idle, msg not busy, sending, sent, cnt = %d", cnt);
	  //cnt++;
	} else {
	  //printd(dbgApp, "Timer.fireD(): state is idle, msg not busy, sending, couldn't send");
	}
      }
    } else {
      atomic {
        if (!sp_msg.busy && sp_msg.quantity < 255) {
	  //printd(dbgApp, "Timer.fired(): state is not idle, msg not busy, incrementing (fp_msg.quantity = %d)", sp_msg.quantity + 1);
	  atomic {sp_msg.quantity++;}
	  //printd(dbgApp, "New quantity value: %d", sp_msg.quantity);
	  //call SPSend.changed(&sp_msg);
	} else {
	  //printd(dbgApp, "Timer.fired(): state is not idle, msg busy");
	}
      }
    }
    return SUCCESS;
  }
  
  event result_t SPSend.sendDone(sp_message_t* _msg, result_t success) {
    
    if (_msg == &sp_msg) {
      //printd(dbgApp, "SPSend.sendDone(): message was mine with count %d", _msg->msg->data[2]);
      state = IDLE;
      cnt++;
    } else {
      //printd(dbgApp, "SPSend.sendDone(): message was not mine!");
    }
    
    return SUCCESS;
  }

  event TOS_MsgPtr SPSendQueue.nextQueueElement(sp_message_t* msg) {
    //printd(dbgApp, "SPSendQueue.nextQueueueElement(): cnt = %d", ++cnt);
    atomic tos_msg.data[2] = cnt;
    //printd(dbgApp, "count: %d, Msg: %d", cnt, tos_msg.data[2]);
    atomic tos_msg.data[3] = lastLQI;
    //printd(dbgApp, "Received quantity:%d, My Quantity: %d", msg->quantity, sp_msg.quantity);
    return &tos_msg;
  }

  event TOS_MsgPtr SPReceive.receive(TOS_MsgPtr msg, void* payload, uint16_t payloadLen, uint8_t sp_handle, uint8_t dest_handle) {
    //printd(dbgReceive, "ReceiveMsg.receive(cnt = %hhu)", msg->data[2]);
    //printd(dbgReceive, "Source was %d %d", msg->data[0], msg->data[1]);
    lastLQI = msg->lqi;
    return msg;
  }

}
