includes Drain;
module StrawM
{
  provides {
    interface StdControl;
    interface Straw;
  }
  uses {
    interface Receive as ReceiveCmd;
    ////interface Drip;
    interface Send as DummyReply;
    interface SendMsg as SendReply;
    interface SendMsg as SendUART;
    interface RouteControl;
    interface Timer;
  }
}
implementation
{
  enum {
    NO_OF_BFFR = 5,
    RADIUS_OF_INTERFERENCE = 3,
  };
  uint16_t UART_ONLY_DELAY = (TOSH_DATA_LENGTH * 7 + 157) / 36;
  uint16_t UART_DELAY = (TOSH_DATA_LENGTH * 7 + 85) / 36;
  uint16_t RADIO_DELAY = (TOSH_DATA_LENGTH * 7 + 234) / 85;
 
  //  Buffer space for drip. But it will not be processed later.  //
  uint8_t dripBffr[STRAWCMDMSG_LENGTH];
  uint8_t dripLength;

  uint8_t cmdBffr[STRAWCMDMSG_LENGTH];
  uint8_t cmdLength;
  StrawCmdMsg *cmd;

  TOS_Msg replyBffr[NO_OF_BFFR];
  uint16_t replyLen[NO_OF_BFFR];
  StrawReplyMsg *reply[NO_OF_BFFR];
  uint8_t bffrState[NO_OF_BFFR];
  uint8_t replyIndex;

  uint32_t start;
  uint32_t size;
  bool toUART;

  uint8_t state;
  uint8_t subState;

  uint32_t dataIndex;
  uint8_t seqNoIndex;
  uint8_t depth;



  void adjPktIntrv() {
    if (subState == STRAW_SUB_PROC && !toUART) {
      int8_t tempDepth = call RouteControl.getDepth();
      if (tempDepth > RADIUS_OF_INTERFERENCE)
        tempDepth = RADIUS_OF_INTERFERENCE;
      
      if (tempDepth != depth) {
        call Timer.stop();
        depth = tempDepth;
        call Timer.start(TIMER_REPEAT, depth < RADIUS_OF_INTERFERENCE
	  ? UART_DELAY + depth * RADIO_DELAY
	  : RADIUS_OF_INTERFERENCE * RADIO_DELAY);
      }
    }
  }
 
  //  tdNext and rrNext assume at least 1 packet  //
  task void tdNext() {
    uint8_t readingSize;
    
    if (dataIndex == start + size) {
      subState = STRAW_SUB_FNSHD;
      call Timer.stop();
      
    } else if ((bffrState[replyIndex] == STRAW_BFFR_EMPTY)
      || (bffrState[replyIndex] == STRAW_BFFR_READDONE)) {
      readingSize = dataIndex + MAX_DATA_REPLY_DATA_SIZE > start + size
        ? start + size - dataIndex : MAX_DATA_REPLY_DATA_SIZE;
	
      if (signal Straw.read(dataIndex, readingSize,
        reply[replyIndex]->arg.dr.data)) {
        reply[replyIndex]->arg.dr.seqNo = (dataIndex - start)
          / MAX_DATA_REPLY_DATA_SIZE + STRAW_TYPE_SHIFT;
        dataIndex += readingSize;
        bffrState[replyIndex] = STRAW_BFFR_READING;
      } else {
        bffrState[replyIndex] = STRAW_BFFR_EMPTY;
      }
    }

    adjPktIntrv();
  }

  task void rrNext() {
    uint32_t readingStart;
    uint8_t readingSize;
    
    if ((seqNoIndex == MAX_RANDOM_READ_SEQNO_SIZE)
      || (cmd->arg.rr.seqNo[seqNoIndex] == STRAW_RANDOM_READ)) {
      subState = STRAW_SUB_FNSHD;
      call Timer.stop();
      
    } else if ((bffrState[replyIndex] == STRAW_BFFR_EMPTY)
      || (bffrState[replyIndex] == STRAW_BFFR_READDONE)) {
      readingStart =  start +
        (uint32_t)(cmd->arg.rr.seqNo[seqNoIndex] - STRAW_TYPE_SHIFT)
        * MAX_DATA_REPLY_DATA_SIZE;
      readingSize = readingStart + MAX_DATA_REPLY_DATA_SIZE > start + size
        ? start + size - readingStart : MAX_DATA_REPLY_DATA_SIZE;
      
      if (signal Straw.read(readingStart, readingSize,
        reply[replyIndex]->arg.dr.data)) {
        reply[replyIndex]->arg.dr.seqNo = cmd->arg.rr.seqNo[seqNoIndex];
        ++seqNoIndex;
        bffrState[replyIndex] = STRAW_BFFR_READING;
      } else {
        bffrState[replyIndex] = STRAW_BFFR_EMPTY;
      }
    }
    adjPktIntrv();
  }

  command result_t Straw.readDone(result_t success) {
    //  all  //
    bffrState[replyIndex] = success ? STRAW_BFFR_READDONE : STRAW_BFFR_EMPTY;
    return SUCCESS;
  }

  task void cmdIntpr() {
    subState = STRAW_SUB_FIRST;
    call Timer.start(TIMER_ONE_SHOT, RADIUS_OF_INTERFERENCE * RADIO_DELAY);
    switch (state) {
    case STRAW_NETWORK_INFO:
      UART_ONLY_DELAY = cmd->arg.ni.uartOnlyDelay;
      UART_DELAY = cmd->arg.ni.uartDelay;
      RADIO_DELAY = cmd->arg.ni.radioDelay;
      toUART = cmd->arg.ni.toUART;
      if ((bffrState[replyIndex] == STRAW_BFFR_EMPTY)
        || (bffrState[replyIndex] == STRAW_BFFR_READDONE)) {
        reply[replyIndex]->arg.nir.type = STRAW_NETWORK_INFO_REPLY;
        reply[replyIndex]->arg.nir.parent = call RouteControl.getParent();
        reply[replyIndex]->arg.nir.depth = call RouteControl.getDepth();
        reply[replyIndex]->arg.nir.occupancy = call RouteControl.getOccupancy();
        reply[replyIndex]->arg.nir.quality = call RouteControl.getQuality();
        bffrState[replyIndex] = STRAW_BFFR_READDONE;
      }
      break;
    case STRAW_TRANSFER_DATA:
      start = cmd->arg.td.start;
      size = cmd->arg.td.size;
      toUART = cmd->arg.td.toUART;
      dataIndex = start;
      post tdNext();
      break;
    case STRAW_RANDOM_READ:
      seqNoIndex = 0;
      post rrNext();
      break;
    default:
      break;
    }
  }
  event TOS_MsgPtr ReceiveCmd.receive(TOS_MsgPtr msg, void *payload,
    uint16_t payloadLen) {

    StrawCmdMsg *dripCmd;
    dripLength = payloadLen;
    memcpy(dripBffr, (uint8_t *)payload, dripLength);
    dripCmd = (StrawCmdMsg *)dripBffr;

    if (dripCmd->dest != TOS_LOCAL_ADDRESS) return msg;
    if (state != STRAW_IDLE_STATE) return msg;

    cmdLength = dripLength;
    memcpy(cmdBffr, dripBffr, cmdLength);
    cmd = (StrawCmdMsg *)cmdBffr;

    state = cmd->arg.cd.type < STRAW_TYPE_SHIFT
      ? (uint8_t)cmd->arg.cd.type : STRAW_RANDOM_READ;
    post cmdIntpr();

    return msg;
  }

  ////event result_t Drip.rebroadcastRequest(TOS_MsgPtr msg, void *payload) {
  ////  memcpy(payload, dripBffr, dripLength);
  ////  return call Drip.rebroadcast(msg, payload, dripLength);
  ////}

  result_t sendDoneCmn(TOS_MsgPtr msg) {
    //  all  //
    uint8_t i;
    for (i = 0; i < NO_OF_BFFR; i++)
      if (msg == &(replyBffr[i])) {
        bffrState[i] = STRAW_BFFR_EMPTY;
        break;
      }
    if (subState == STRAW_SUB_FNSHD) {
      state = STRAW_IDLE_STATE;
      subState = STRAW_SUB_IDLE;
    }
    return SUCCESS;
  }
  event result_t DummyReply.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }
  event result_t SendReply.sendDone(TOS_MsgPtr msg, result_t success) {
    return sendDoneCmn(msg);
  }
  event result_t SendUART.sendDone(TOS_MsgPtr msg, result_t success) {
    return sendDoneCmn(msg);
  }

  result_t timerStart() {
    subState = STRAW_SUB_PROC;
    depth = call RouteControl.getDepth();
    if (depth > RADIUS_OF_INTERFERENCE) depth = RADIUS_OF_INTERFERENCE;
    return call Timer.start(TIMER_REPEAT, toUART
      ? UART_ONLY_DELAY
      : (depth < RADIUS_OF_INTERFERENCE ? UART_DELAY + depth * RADIO_DELAY
        : RADIUS_OF_INTERFERENCE * RADIO_DELAY));
  }
  task void timerTask() {
    if (bffrState[replyIndex] == STRAW_BFFR_READDONE) {
      if (toUART) {
        bffrState[replyIndex] = call SendUART.send(TOS_UART_ADDR,
	  TOSH_DATA_LENGTH, &replyBffr[replyIndex])
	  ? STRAW_BFFR_SENDING : STRAW_BFFR_EMPTY;
      } else {
        bffrState[replyIndex] = call SendReply.send(TOS_DEFAULT_ADDR,
	  sizeof(StrawReplyMsg), &replyBffr[replyIndex])
	  ? STRAW_BFFR_SENDING : STRAW_BFFR_EMPTY;
      }
    }
    replyIndex = (replyIndex + 1) % NO_OF_BFFR;

    switch (state) {
    case STRAW_NETWORK_INFO:
      subState = STRAW_SUB_FNSHD;
      break;
    case STRAW_TRANSFER_DATA:
      if (subState == STRAW_SUB_FIRST) {
        subState = STRAW_SUB_PROC;
	timerStart();
      }
      post tdNext();
      break;
    case STRAW_RANDOM_READ:
      if (subState == STRAW_SUB_FIRST) {
        subState = STRAW_SUB_PROC;
	timerStart();
      }
      post rrNext();
      break;
    default:
      break;
    }
  }
  event result_t Timer.fired() {
    post timerTask();
    return SUCCESS;
  }



  command result_t StdControl.init() {
    return SUCCESS;
  }
  command result_t StdControl.start() {
    uint8_t i;
    state = STRAW_IDLE_STATE;
    subState = STRAW_SUB_IDLE;
    for (i = 0; i < NO_OF_BFFR; i++) {
      reply[i] = (StrawReplyMsg *) call DummyReply.getBuffer(&replyBffr[i],
        &replyLen[i]);
      bffrState[i] = STRAW_BFFR_EMPTY;
    }
    replyIndex = 0;
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    state = STRAW_IDLE_STATE;
    subState = STRAW_SUB_IDLE;
    return SUCCESS;
  }
}

