
module GenericCommDbgM {
  provides {
    interface SendMsg[uint8_t id];
    interface ReceiveMsg[uint8_t id];
    event result_t sendDurationMsg(uint8_t status, uint16_t value);
  }
  uses {
    interface SendMsg as Dump[uint8_t id];
    interface SendMsg as RadioSend[uint8_t id];
    interface ReceiveMsg as RadioReceive[uint8_t id];
  }
}

implementation {
  
#define UART_BUFFER_LENGTH 10
#define ONLY_EVENT_MSG     TRUE
  
  TOS_Msg msgBuffer[UART_BUFFER_LENGTH], durationMsg;
  uint8_t bufStartIndex;
  uint8_t bufNextIndex;
  
  uint8_t isDumping, isSendingDuration;
  TOS_MsgPtr lastDumpMsg;
  

  enum {
    SEND_BUFFER_LOCATION = 0,
    RECEIVE_BUFFER_LOCATION = 1
  };
  
  uint8_t bufLength() {
    return (bufNextIndex + UART_BUFFER_LENGTH - bufStartIndex) % UART_BUFFER_LENGTH;
  }

  void addMsg(TOS_MsgPtr msg, uint8_t action) {
    if (bufLength() >= UART_BUFFER_LENGTH - 1) 
      return;
    memcpy(&msgBuffer[bufNextIndex], msg, sizeof(TOS_Msg));
    msgBuffer[bufNextIndex].group = action;
    if (action == 2)
      msgBuffer[bufNextIndex].type += 10;
    bufNextIndex = (bufNextIndex + 1) % UART_BUFFER_LENGTH;

  }
  TOS_MsgPtr peekMsg() {
    TOS_MsgPtr returnMsg;
    if (bufLength() == 0)
      return 0;
    returnMsg = &msgBuffer[bufStartIndex];
    return returnMsg;
  }
  void removeMsg() {
    if (bufLength() != 0)
      bufStartIndex = (bufStartIndex + 1) % UART_BUFFER_LENGTH;
  }

  task void dumpMsg() {

    TOS_MsgPtr uartMsg = peekMsg();

    // we will redump when we get send done
    if (isDumping == 1) return;
    // if there is not message
    if (uartMsg == 0) return;
    isDumping = call Dump.send[uartMsg->type](TOS_UART_ADDR, uartMsg->length, uartMsg);
    if (isDumping == FAIL) {

    } else {
      lastDumpMsg = uartMsg;
    }
  }


  command result_t SendMsg.send[uint8_t id](uint16_t address, uint8_t length, TOS_MsgPtr msg) {
    result_t result;
    msg->group = TOS_AM_GROUP;
    result = call RadioSend.send[id](address, length, msg);

    if ((!ONLY_EVENT_MSG)
	&& result == SUCCESS 
	&& msg->addr != TOS_UART_ADDR) {
      msg->addr = address;
      msg->length = length;
      msg->type = id;
      addMsg(msg, 1);
    }

    return result;
  }
  event result_t RadioSend.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
    uint8_t result;
    if (msg == lastDumpMsg) {
      isDumping = 0;
      removeMsg();
    } else {
      result = signal SendMsg.sendDone[id](msg, success);
    }

    post dumpMsg();
    return result;
  }

  event result_t Dump.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }

  event TOS_MsgPtr RadioReceive.receive[uint8_t id](TOS_MsgPtr msg) {
    if (msg->addr != TOS_UART_ADDR
	&& !ONLY_EVENT_MSG) {
      addMsg(msg, 2);
      post dumpMsg();
    }
    return signal ReceiveMsg.receive[id](msg);
  }

  default event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr msg) {
    return msg;
  }
  default event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }
  //////////////////////////////////////////////////////////////////////
  uint8_t internalStatus;
  event result_t sendDurationMsg(uint8_t status, uint16_t value) {
    DelugeDurationMsg *ddm;
    //if (status == internalStatus) return SUCCESS;
    internalStatus = status;
    ddm = (DelugeDurationMsg *)durationMsg.data;
    ddm->sourceAddr = TOS_LOCAL_ADDRESS;
    ddm->status = status;
    ddm->value = value;
    durationMsg.type = AM_DELUGEDURATIONMSG;
    durationMsg.length = sizeof(DelugeDurationMsg);
    addMsg(&durationMsg, 1);
    post dumpMsg();
    return SUCCESS;
  }
}
