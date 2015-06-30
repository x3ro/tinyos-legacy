includes Drain;
module StrawM
{
  provides {
    interface StdControl;
    interface Straw[uint8_t id];
  }
  uses {
    interface Timer as DripSendTimer;
    interface Timer as ShootingTimer;
    interface SendMsg as SendUART;

    interface Receive as ReceiveGrp;
    interface Drip;
    interface DrainGroup;
    interface Receive as ReceiveCmd;

    interface RouteControl;
    interface Send as DummyReply;
    interface SendMsg as SendReply;
  }
}
implementation
{
  enum {
    NO_OF_BFFR = 5,
    RADIUS_OF_INTERFERENCE = 5,
  };
  uint16_t UART_ONLY_DELAY = (TOSH_DATA_LENGTH * 7 + 157) / 36;
  uint16_t UART_DELAY = (TOSH_DATA_LENGTH * 7 + 85) / 36;
  uint16_t RADIO_DELAY = (TOSH_DATA_LENGTH * 7 + 234) / 65;
 
  //  Buffer space for drip. But it will not be processed later.  //
  uint8_t dripBffr[sizeof(StrawGrpMsg)];
  uint8_t dripLength;
  uint16_t timeout;

  uint8_t cmdBffr[STRAWCMDMSG_LENGTH];
  uint8_t cmdLength;
  StrawCmdMsg *cmd;

  TOS_Msg replyBffr[NO_OF_BFFR];
  uint16_t replyLen[NO_OF_BFFR];
  StrawReplyMsg *reply[NO_OF_BFFR];
  uint8_t bffrState[NO_OF_BFFR];
  uint8_t replyIndex;

  uint8_t portId;
  uint32_t start;
  uint32_t size;
  bool toUART;

  uint8_t state;
  uint8_t subState;

  uint32_t dataIndex;
  uint8_t seqNoIndex;
  uint8_t readingSize;

  uint16_t checksum;
  uint8_t depth;



  command result_t StdControl.init() {
    call Drip.init();
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

  
  command result_t Straw.readDone[uint8_t id](result_t success) {
    //  all  //
    uint8_t i;
    if (success) {
      bffrState[replyIndex] = STRAW_BFFR_READDONE;
      if (state == STRAW_TRANSFER_DATA) {
        dataIndex += readingSize;
	
        for (i = 0; i < readingSize; i++)
          checksum += reply[replyIndex]->arg.dr.data[i];

      } else if (state == STRAW_RANDOM_READ) {
        ++seqNoIndex;
      }
    } else {
      bffrState[replyIndex] = STRAW_BFFR_EMPTY;
    }
    return SUCCESS;
  }



  void adjPktIntrv() {
    if (subState == STRAW_SUB_PROC && !toUART) {
      int8_t tempDepth = call RouteControl.getDepth();
      if (tempDepth > RADIUS_OF_INTERFERENCE)
        tempDepth = RADIUS_OF_INTERFERENCE;
      
      if (tempDepth != depth) {
        call ShootingTimer.stop();
        depth = tempDepth;
        call ShootingTimer.start(TIMER_REPEAT, depth < RADIUS_OF_INTERFERENCE
	  ? UART_DELAY + depth * RADIO_DELAY
	  : RADIUS_OF_INTERFERENCE * RADIO_DELAY);
      }
    }
  }
 
  //  tdNext and rrNext assume at least 1 packet  //
  task void tdNext() {
    
    if (dataIndex == start + size) {
      subState = STRAW_SUB_FNSHD;
      call ShootingTimer.stop();
      if (bffrState[(replyIndex + NO_OF_BFFR - 1) % NO_OF_BFFR]
        != STRAW_BFFR_SENDING) {
        state = STRAW_IDLE_STATE;
        subState = STRAW_SUB_IDLE;
      }
      
    } else if ((bffrState[replyIndex] == STRAW_BFFR_EMPTY)
      || (bffrState[replyIndex] == STRAW_BFFR_READDONE)) {
      readingSize = dataIndex + MAX_DATA_REPLY_DATA_SIZE > start + size
        ? start + size - dataIndex : MAX_DATA_REPLY_DATA_SIZE;
	
      if (signal Straw.read[portId](dataIndex, readingSize,
        reply[replyIndex]->arg.dr.data)) {
        reply[replyIndex]->arg.dr.seqNo = (dataIndex - start)
          / MAX_DATA_REPLY_DATA_SIZE + STRAW_TYPE_SHIFT;
        bffrState[replyIndex] = STRAW_BFFR_READING;
      } else {
        bffrState[replyIndex] = STRAW_BFFR_EMPTY;
      }
    }

    adjPktIntrv();
  }

  task void rrNext() {
    uint32_t readingStart;

    if ((seqNoIndex == MAX_RANDOM_READ_SEQNO_SIZE)
      || (cmd->arg.rr.seqNo[seqNoIndex] == STRAW_RANDOM_READ)) {
      subState = STRAW_SUB_FNSHD;
      call ShootingTimer.stop();
      if (bffrState[(replyIndex + NO_OF_BFFR - 1) % NO_OF_BFFR]
        != STRAW_BFFR_SENDING) {
        state = STRAW_IDLE_STATE;
        subState = STRAW_SUB_IDLE;
      }

    } else if ((bffrState[replyIndex] == STRAW_BFFR_EMPTY)
      || (bffrState[replyIndex] == STRAW_BFFR_READDONE)) {
      readingStart =  start +
        (uint32_t)(cmd->arg.rr.seqNo[seqNoIndex] - STRAW_TYPE_SHIFT)
        * MAX_DATA_REPLY_DATA_SIZE;
      readingSize = readingStart + MAX_DATA_REPLY_DATA_SIZE > start + size
        ? start + size - readingStart : MAX_DATA_REPLY_DATA_SIZE;
      
      if (signal Straw.read[portId](readingStart, readingSize,
        reply[replyIndex]->arg.dr.data)) {
        reply[replyIndex]->arg.dr.seqNo = cmd->arg.rr.seqNo[seqNoIndex];
        bffrState[replyIndex] = STRAW_BFFR_READING;
      } else {
        bffrState[replyIndex] = STRAW_BFFR_EMPTY;
      }
    }

    adjPktIntrv();
  }



  event result_t DripSendTimer.fired() {
    call DrainGroup.joinGroup(GRP_STRAWCMDMSG, timeout);
    return SUCCESS;
  }
  
  result_t timerStart() {
    subState = STRAW_SUB_PROC;
    depth = call RouteControl.getDepth();
    if (depth > RADIUS_OF_INTERFERENCE) depth = RADIUS_OF_INTERFERENCE;
    return call ShootingTimer.start(TIMER_REPEAT, toUART
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
    case STRAW_ERR_CHK:
      subState = STRAW_SUB_FNSHD;
      break;
    default:
      break;
    }
  }
  event result_t ShootingTimer.fired() {
    post timerTask();
    return SUCCESS;
  }



  task void grpIntpr() {
    StrawGrpMsg *grpMsg = (StrawGrpMsg *)dripBffr;
    switch(grpMsg->type) {
    case STRAW_GRP_JOIN:
      call DripSendTimer.stop();
      timeout = grpMsg->timeout;
      call DrainGroup.joinGroup(GRP_STRAWCMDMSG, timeout);
      call DripSendTimer.start(TIMER_REPEAT, grpMsg->repeat);
      break;
    case STRAW_GRP_LEAVE:
      call DripSendTimer.stop();
      break;
    default:
      break;
    }
  }
  event TOS_MsgPtr ReceiveGrp.receive(TOS_MsgPtr msg, void *payload,
    uint16_t payloadLen) {
    StrawGrpMsg *grpMsg;
    dripLength = payloadLen;
    memcpy(dripBffr, (uint8_t *)payload, dripLength);
    grpMsg = (StrawGrpMsg *)dripBffr;

    if (grpMsg->dest != TOS_LOCAL_ADDRESS) return msg;
    if (state != STRAW_IDLE_STATE) return msg;

    post grpIntpr();

    return msg;
  }
  
  event result_t Drip.rebroadcastRequest(TOS_MsgPtr msg, void *payload) {
    memcpy(payload, dripBffr, dripLength);
    return call Drip.rebroadcast(msg, payload, dripLength);
  }
  
  task void cmdIntpr() {
    subState = STRAW_SUB_FIRST;
    call ShootingTimer.start(TIMER_ONE_SHOT,
      RADIUS_OF_INTERFERENCE * RADIO_DELAY);
    switch (state) {
    case STRAW_NETWORK_INFO:
      toUART = cmd->arg.ni.toUART;
      if ((bffrState[replyIndex] == STRAW_BFFR_EMPTY)
        || (bffrState[replyIndex] == STRAW_BFFR_READDONE)) {
        reply[replyIndex]->arg.nir.type = STRAW_NETWORK_INFO_REPLY;
        reply[replyIndex]->arg.nir.uartOnlyDelay = UART_ONLY_DELAY;
        reply[replyIndex]->arg.nir.uartDelay = UART_DELAY;
        reply[replyIndex]->arg.nir.radioDelay = RADIO_DELAY;

        reply[replyIndex]->arg.nir.parent = call RouteControl.getParent();
        reply[replyIndex]->arg.nir.depth = call RouteControl.getDepth();
        reply[replyIndex]->arg.nir.occupancy = call RouteControl.getOccupancy();
        reply[replyIndex]->arg.nir.quality = call RouteControl.getQuality();
        bffrState[replyIndex] = STRAW_BFFR_READDONE;
      }
      break;
    case STRAW_TRANSFER_DATA:
      portId = cmd->arg.td.portId;
      start = cmd->arg.td.start;
      size = cmd->arg.td.size;

      UART_ONLY_DELAY = cmd->arg.td.uartOnlyDelay;
      UART_DELAY = cmd->arg.td.uartDelay;
      RADIO_DELAY = cmd->arg.td.radioDelay;
      toUART = cmd->arg.td.toUART;
      dataIndex = start;
      checksum = 0;
      post tdNext();
      break;
    case STRAW_RANDOM_READ:
      seqNoIndex = 0;
      post rrNext();
      break;
    case STRAW_ERR_CHK:
      toUART = cmd->arg.ec.toUART;
      if ((bffrState[replyIndex] == STRAW_BFFR_EMPTY)
        || (bffrState[replyIndex] == STRAW_BFFR_READDONE)) {
        reply[replyIndex]->arg.ecr.type = STRAW_ERR_CHK_REPLY;
        reply[replyIndex]->arg.ecr.checksum = checksum;
        bffrState[replyIndex] = STRAW_BFFR_READDONE;
      }
      break;
    default:
      break;
    }
  }
  event TOS_MsgPtr ReceiveCmd.receive(TOS_MsgPtr msg, void *payload,
    uint16_t payloadLen) {

    StrawCmdMsg *cmdMsg = (StrawCmdMsg *)payload;

    if (cmdMsg->dest != TOS_LOCAL_ADDRESS) return msg;
    if (state != STRAW_IDLE_STATE) return msg;

    cmdLength = payloadLen;
    memcpy(cmdBffr, payload, cmdLength);
    cmd = (StrawCmdMsg *)cmdBffr;

    state = cmd->arg.cd.type < STRAW_TYPE_SHIFT
      ? (uint8_t)cmd->arg.cd.type : STRAW_RANDOM_READ;
    post cmdIntpr();

    return msg;
  }



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



  default event result_t Straw.read[uint8_t id](uint32_t aStart, uint32_t aSize,
    uint8_t* aBffr) {
    return FAIL;
  }
}

