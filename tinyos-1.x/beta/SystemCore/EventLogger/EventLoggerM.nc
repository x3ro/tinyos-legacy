module EventLoggerM {
  provides {
    interface StdControl;
    interface EventLogger;
  }

  uses {
    interface AllocationReq;
    interface LogData;
    interface ReadData;

    interface Timer;
    interface Send;
    interface Time;
    interface Random;

    interface Receive as CmdReceive;
    interface Drip as CmdDrip;
    interface Naming;
    
    interface Leds;

    interface SharedMsgBuf;

    interface MgmtAttr as MA_LogReadOffset;
    interface MgmtAttr as MA_LogWriteOffset;
  }
}

implementation {

  /* stuff coming into the log */
  TOS_Msg  entryBuf;
  bool     entryBufBusy;
  uint16_t writeOffset;
  uint8_t  pos;

  /* stuff being read out of the log */
  /*  TOS_Msg  readBuf; */
  bool     readBufBusy;
  uint8_t  readState;
  uint16_t readOffset;
  bool     setLog = FALSE;
  uint16_t  toSet;
// setLog prevents readOffset from being reset in the middle of a two-phase
// read operation.

  NamingMsg namingMsgCache;
  EventLoggerCmdMsg cmdMsgCache;

  void switchReadState(uint8_t read_state);

  enum {
    READ_NONE,
    READ_HEADER,
    READ_DATA,
  };

  uint16_t seqno = 0;
  uint8_t  reqResult;

  task void readLogEntry();

  command result_t StdControl.init() {
    entryBufBusy = FALSE;
    writeOffset = 0;
    readOffset = 0;

    call MA_LogReadOffset.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_LogWriteOffset.init(sizeof(uint16_t), MA_TYPE_UINT);
    
    (void)unique("Drip");
    call CmdDrip.init();

    reqResult = call AllocationReq.requestAddr(LOG_START_PAGE * 
					       TOS_BYTEEEPROM_PAGESIZE,
					       MAX_LOG_SIZE);
    
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  void setHeaders(LogEntryMsg *entry) {
    tos_time_t theTime;
    
    theTime = call Time.get();
    
    entry->entryID = seqno++;
    entry->entryTimestamp = theTime.low32;
  }

  command LogEntryMsg* EventLogger.getBuffer() {

    uint16_t maxPayloadLength;
    LogEntryMsg *entry = (LogEntryMsg *)
      call Send.getBuffer(&entryBuf, &maxPayloadLength);

    if (writeOffset >= MAX_LOG_SIZE)
      return NULL;

    if (entryBufBusy)
      return NULL;

    entryBufBusy = TRUE;

    memset(&entryBuf, 0, sizeof(entryBuf));
    pos = 0;
    setHeaders(entry);
    return entry;
  }

  command result_t EventLogger.push(LogEntryMsg *buf, uint8_t *data, 
				    uint8_t len) {
    if (pos + len > MAX_LOGENTRY_SIZE)
      return FAIL;

    memcpy(&buf->data[pos], data, len);
    pos += len;
    return SUCCESS;
  }
  
  command result_t EventLogger.logBuffer(uint16_t key) {
    
    uint16_t maxPayloadLength;
    uint8_t *mhData = 
      call Send.getBuffer(&entryBuf, &maxPayloadLength);
    LogEntryMsg *entry = (LogEntryMsg*) mhData;

    if (!entryBufBusy)
      return FAIL;

    entry->length = pos;
    entry->entryKey = key;

    if (!call LogData.append((uint8_t*)mhData, 
			     offsetof(LogEntryMsg,data) + pos)) {
      entryBufBusy = FALSE;
      return FAIL;
    }
    writeOffset += offsetof(LogEntryMsg,data) + pos;    
    return SUCCESS;
  }

  command result_t EventLogger.sendBuffer(uint16_t key) {

    uint16_t maxPayloadLength;
    uint8_t *mhData = 
      call Send.getBuffer(&entryBuf, &maxPayloadLength);
    LogEntryMsg *entry = (LogEntryMsg*) mhData;

    entry->length = pos;
    entry->entryKey = key;

    if (!call Send.send(&entryBuf, offsetof(LogEntryMsg, data) + pos)) {
      entryBufBusy = FALSE;
      return FAIL;
    }

    return SUCCESS;
  }

  task void eraseTask() {
    call LogData.erase();
  }

  event result_t AllocationReq.requestProcessed(result_t success) {
    // Allocation must succeed
    if (success) {
      post eraseTask();
    }
    return SUCCESS;
  }

  event result_t Timer.fired() {
    if (readState == READ_NONE && 
	readOffset < MAX_LOG_SIZE &&
	readOffset < writeOffset) 
      post readLogEntry();

    call Timer.start(TIMER_ONE_SHOT, cmdMsgCache.playbackSpeed);
    return SUCCESS;
  }

  task void readLogEntry() { 
    uint16_t maxPayloadLength;
    uint8_t *mhData;
    TOS_MsgPtr readBuf = call SharedMsgBuf.getMsgBuf();

    if (!call SharedMsgBuf.lock()) {
      return;
    }
    
    readBufBusy = TRUE;
    mhData = call Send.getBuffer(readBuf, &maxPayloadLength);

    if (call ReadData.read(readOffset, mhData, offsetof(LogEntryMsg, data))) {
      switchReadState(READ_HEADER);
    } else {
      readBufBusy = FALSE;
      call SharedMsgBuf.unlock();
    }
  }

  event result_t ReadData.readDone(uint8_t *buffer, 
				   uint32_t bytes, result_t ok) {

    uint16_t maxPayloadLength;

    TOS_MsgPtr readBuf = call SharedMsgBuf.getMsgBuf();
    LogEntryMsg *logEntry = (LogEntryMsg *) 
      call Send.getBuffer(readBuf, &maxPayloadLength);

    if (!readBufBusy)
      return FAIL;

    switch( readState ) {
      case READ_HEADER:
        if (call ReadData.read(readOffset + offsetof(LogEntryMsg, data),
                               logEntry->data,
                               logEntry->length)) {
          switchReadState(READ_DATA);
        } else {
          switchReadState(READ_NONE);
          readBufBusy = FALSE;
          call SharedMsgBuf.unlock();
        }
      break;

      case READ_DATA:
        if (ok && call Send.send(readBuf, 
                                 offsetof(LogEntryMsg, data) + logEntry->length)) {
          readOffset += (offsetof(LogEntryMsg, data) + logEntry->length);
        } else {
          switchReadState(READ_NONE);
          readBufBusy = FALSE;
          call SharedMsgBuf.unlock();
        }
      break;
    }

    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr pMsg, result_t success) {
    TOS_MsgPtr readBuf = call SharedMsgBuf.getMsgBuf();

    if (pMsg == readBuf && readBufBusy) {
      if (readState == READ_DATA) {
	switchReadState(READ_NONE);
	memset(readBuf, 0, sizeof(readBuf));
      }
      readBufBusy = FALSE;
      call SharedMsgBuf.unlock();
    } else if (pMsg == &entryBuf) {
      entryBufBusy = FALSE;
    }

    return SUCCESS;
  }

  void setLogOffset(uint16_t readOff) {
    if (readState != READ_NONE)
      setLog = TRUE;
    else 
      readOffset = readOff;
  }

  event TOS_MsgPtr CmdReceive.receive(TOS_MsgPtr msg, void* payload, 
				      uint16_t payloadLen) {

    NamingMsg *namingMsg = (NamingMsg *) payload;
    EventLoggerCmdMsg *cmdMsg = 
      (EventLoggerCmdMsg *) call Naming.getBuffer(namingMsg);

    memcpy(&namingMsgCache, namingMsg, sizeof(namingMsgCache));
    memcpy(&cmdMsgCache, cmdMsg, sizeof(cmdMsgCache));

    if (!call Naming.isEndpoint(namingMsg))
      return msg;

    switch (cmdMsg->commandID) {
    case LOGCMD_PLAY:
      call Timer.stop();
      call Timer.start(TIMER_ONE_SHOT, 
		       call Random.rand() % cmdMsg->playbackSpeed);
      break;
    case LOGCMD_STOP:
      call Timer.stop();
      setLogOffset(0);
      break;
    case LOGCMD_PAUSE:
      call Timer.stop();
      break;
    case LOGCMD_REWIND:
      setLogOffset(0);
      break;
    case LOGCMD_CURRENT:
      setLogOffset(writeOffset);
    }

    return msg;
  }

  event result_t CmdDrip.rebroadcastRequest(TOS_MsgPtr msg, void* pData) {

    if (call Naming.isIntermediary(&namingMsgCache)) {
      EventLoggerCmdMsg *cmdMsg;

      NamingMsg *namingMsg = (NamingMsg*) pData;
      memcpy(namingMsg, &namingMsgCache, sizeof(namingMsgCache));

      call Naming.prepareRebroadcast(msg, namingMsg);

      cmdMsg = (EventLoggerCmdMsg *) call Naming.getBuffer(namingMsg);
      memcpy(cmdMsg, &cmdMsgCache, sizeof(cmdMsgCache));

      call CmdDrip.rebroadcast(msg, pData, sizeof(namingMsgCache) + sizeof(cmdMsgCache));
      return SUCCESS;
    }
    
    return FAIL;
  }

  event result_t MA_LogReadOffset.getAttr(uint8_t *attrBuf) {
    memcpy(attrBuf, &readOffset, sizeof(readOffset));
    return SUCCESS;
  }
  event result_t MA_LogWriteOffset.getAttr(uint8_t *attrBuf) {
    memcpy(attrBuf, &writeOffset, sizeof(writeOffset));
    return SUCCESS;
  }

  event result_t LogData.appendDone(uint8_t* data, uint32_t numBytes, 
				    result_t success) {

    entryBufBusy = FALSE;
    return SUCCESS;
  }

  event result_t LogData.eraseDone(result_t ok) {
    return SUCCESS;
  }
  event result_t LogData.syncDone(result_t result) {
    return SUCCESS;
  }

  void switchReadState(uint8_t read_state) {
    switch(read_state) {
    case READ_NONE:
      readState = READ_NONE;
      if (setLog) {
	readOffset = toSet;
	setLog = FALSE;
      }
      break;
    case READ_HEADER:
      readState = READ_HEADER;
      break;
    case READ_DATA:
      readState = READ_DATA;
      break;
    }
  }

}


