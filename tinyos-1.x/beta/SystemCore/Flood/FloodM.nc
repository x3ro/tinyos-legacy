includes AM;
includes Flood;

module FloodM {
  provides {
    interface StdControl;
    interface Receive[uint8_t id];
  }
  uses {
    interface StdControl as SubControl;
    interface ReceiveMsg;
    interface SendMsg;
    interface Timer as SendTimer;
    interface Random;
    interface Leds;
  }
}

implementation {

  struct TOS_Msg buf;
  TOS_MsgPtr bufPtr = &buf;
  bool bufBusy = FALSE;

  int8_t seqno = 1;

  enum {
    SEND_DELAY = 32,
  };

  command result_t StdControl.init() {
    return call SubControl.init();
  }

  command result_t StdControl.start() {
    return call SubControl.start();
  }

  command result_t StdControl.stop() {
    return call SubControl.stop();
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr pMsg) {
    FloodMsg *floodMsg = (FloodMsg *)pMsg->data;
    TOS_MsgPtr oldBufPtr = bufPtr;
    
    if (bufBusy)
      return pMsg;

    if (floodMsg->metadata.seqno == 0) {
      seqno++;
      if (seqno == 0)
	seqno++;
      floodMsg->metadata.seqno = seqno;

    } else if (floodMsg->metadata.seqno - seqno > 0) {
      seqno = floodMsg->metadata.seqno;

    } else {
      return pMsg;
    }

    if (call SendTimer.start(TIMER_ONE_SHOT, SEND_DELAY)) {
      bufPtr = pMsg;
      bufBusy = TRUE;
    }
    
    return oldBufPtr;
  }

  event result_t SendTimer.fired() {
    FloodMsg *floodMsg = (FloodMsg *)bufPtr->data;

    if (call SendMsg.send(TOS_BCAST_ADDR, bufPtr->length, bufPtr)) {
      /* wait for sendDone */
    } else {
      bufBusy = FALSE;
    }

    bufPtr = signal Receive.receive[floodMsg->metadata.id]
      (bufPtr, 
       floodMsg->data,
       bufPtr->length - offsetof(FloodMsg,data));
    
    return SUCCESS;
  }
  
  event result_t SendMsg.sendDone(TOS_MsgPtr pMsg, 
				  result_t success) {
    if (pMsg == bufPtr)
      bufBusy = FALSE;
    return SUCCESS;
  }

  default event TOS_MsgPtr Receive.receive[uint8_t id](TOS_MsgPtr msg, 
						       void* payload, 
						       uint16_t payloadLen) {
    return msg;
  }
}
