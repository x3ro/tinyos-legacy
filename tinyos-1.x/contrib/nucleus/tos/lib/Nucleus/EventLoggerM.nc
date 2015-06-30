//$Id: EventLoggerM.nc,v 1.5 2005/06/14 18:10:10 gtolle Exp $

module EventLoggerM {
  provides {
    interface StdControl;
  }

  uses {
    interface StdControl as SubControl;

    interface EventClient[EventID id];

    interface Send as ResponseSendMH;
    interface SendMsg as ResponseSend;

    interface Random;
    
    interface Leds;
  }
}

implementation {

  typedef struct {
    bool entryBufBusy:1;
  } EventLoggerState;

  TOS_Msg  entryBuf;
  uint8_t  entryLength;

  uint16_t seqno = 0;

  EventLoggerState state;

  result_t newEvent(EventID id, uint8_t length, uint8_t class, void* buf);
  LogEntryMsg* selectResponseBuffer(TOS_MsgPtr pMsgBuf, 
				    uint8_t destination, 
				    uint16_t *bufLen);
  void setHeaders(LogEntryMsg *entry, EventID id, uint8_t class);

  task void logEntry();

  command result_t StdControl.init() {

    call SubControl.init();

    state.entryBufBusy = FALSE;

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call SubControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t EventClient.fired[EventID id](uint8_t length, void *buf) {

    return newEvent(id, length, 0, buf);
  }

  event result_t EventClient.logged[EventID id](uint8_t length, 
						uint8_t class,
						void *buf) {

    return newEvent(id, length, class, buf);
  }

  result_t newEvent(EventID id, uint8_t length, uint8_t class, void* buf) {

    // For now, just send the event to the UART
    // You should be able to set the destination of each named event
    // at runtime

    uint16_t payloadLength;
    LogEntryMsg* entry = selectResponseBuffer(&entryBuf,
					      EVENTLOGGER_DEST_SERIAL,
					      &payloadLength);

    if (state.entryBufBusy)
      return FAIL;
    
    state.entryBufBusy = TRUE;
    
    setHeaders(entry, id, class);

    entryLength = (EVENTLOGGER_HEADER_SIZE + length) < payloadLength ? 
      (EVENTLOGGER_HEADER_SIZE + length) : payloadLength;
    
    memcpy(entry->data, buf, entryLength - EVENTLOGGER_HEADER_SIZE);

    seqno++;

    post logEntry();
    return SUCCESS;
  }

  LogEntryMsg* selectResponseBuffer(TOS_MsgPtr pMsgBuf, 
				    uint8_t destination, 
				    uint16_t *bufLen) {
    switch(destination) {
      
    case EVENTLOGGER_DEST_COLLECTION: 
      return (LogEntryMsg*) 
	call ResponseSendMH.getBuffer(pMsgBuf, bufLen);
      break;

    case EVENTLOGGER_DEST_LOCAL:
    case EVENTLOGGER_DEST_SERIAL:
      *bufLen = TOSH_DATA_LENGTH;
      return (LogEntryMsg*) pMsgBuf->data;
      break;

    case EVENTLOGGER_DEST_STORAGE:
      return NULL;
      
    default:
      return NULL;
    }
  }
  
  void setHeaders(LogEntryMsg *entry, EventID id, uint8_t class) {
    entry->entryKey = id;
    entry->entrySeqno = seqno;
    entry->entryLevel = class;
  }

  task void logEntry() {

    if (!state.entryBufBusy) {
      // This is a bug;
      return;
    }

    if (call ResponseSend.send(TOS_UART_ADDR, 
			       entryLength,
			       &entryBuf) == FAIL) {
      post logEntry();
      return;
    }
  }

  event result_t ResponseSend.sendDone(TOS_MsgPtr pMsg, result_t success) {

    if (pMsg == &entryBuf && state.entryBufBusy) {
      state.entryBufBusy = FALSE;
    }

    return SUCCESS;
  }

  event result_t ResponseSendMH.sendDone(TOS_MsgPtr pMsg, result_t success) {

    if (pMsg == &entryBuf && state.entryBufBusy) {
      state.entryBufBusy = FALSE;
    }

    return SUCCESS;
  }
}


