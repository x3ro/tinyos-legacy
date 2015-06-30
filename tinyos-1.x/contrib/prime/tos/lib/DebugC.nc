module DebugC {
  provides interface Debug;
  uses {
    interface SendMsg;
    interface Timer;

    event void available();
  }
}
implementation {
  /* We buffer up more than one message to deal with bursts */
  enum {
    DBG_LENGTH = 100
  };
  char dbg[DBG_LENGTH];
  uint8_t dbgStart, dbgEnd, outstanding;

  TOS_Msg dbgMsg;
  bool sending;
  uint16_t address;

  command void Debug.init() {
    dbgStart = dbgEnd = outstanding = 0;
    sending = FALSE;
    address = TOS_UART_ADDR;
    call Timer.start(TIMER_REPEAT, 1000);
  }

  command void Debug.setAddr(uint16_t addr) {
    address = addr;
  }

  command void Debug.setTimeout(uint32_t timeout) {
    call Timer.stop();
    if (timeout != 0)
      call Timer.start(TIMER_REPEAT, timeout);
  }

  void sendDbgInfo() {
    uint16_t i, j, newStart;

    if (!outstanding || sending)
      return;

    i = 0;
    newStart = dbgStart;
    while (i < DATA_LENGTH && i < outstanding)
      {
	dbgMsg.data[i++] = dbg[newStart++];
	if (newStart == DBG_LENGTH)
	  newStart = 0;
      }

    j = i;
    while (j < DATA_LENGTH)
      dbgMsg.data[j++] = 0x2a;
    
    if (call SendMsg.send(address, DATA_LENGTH, &dbgMsg))
      {
	sending = TRUE;
	dbgStart = newStart;
	outstanding -= i;
	signal available();
      }
  }

  default event void available() { }

  event result_t SendMsg.sendDone(TOS_MsgPtr data, result_t success) {
    if (data == &dbgMsg)
      sending = FALSE;
    return SUCCESS;
  }

  event result_t Timer.fired() {
    sendDbgInfo();
    return SUCCESS;
  }

  command result_t Debug.dbg8(uint8_t x) {
    if (outstanding >= DATA_LENGTH)
      sendDbgInfo();

    if (outstanding < DBG_LENGTH)
      {
	dbg[dbgEnd++] = x;
	if (dbgEnd == DBG_LENGTH)
	  dbgEnd = 0;
	outstanding++;
      }

    return outstanding < DATA_LENGTH ? SUCCESS : FAIL;
  }

  command result_t Debug.dbg16(uint16_t x) {
    call Debug.dbg8(x >> 8);
    return call Debug.dbg8(x);
  }

  command result_t Debug.dbg32(uint32_t x) {
    call Debug.dbg16(x >> 16);
    return call Debug.dbg16(x);
  }

  command result_t Debug.dbgString(char *s) {
    while (*s)
      call Debug.dbg8(*s++);
    return call Debug.dbg8(0);
  }
}
