includes IFS;
module ETimingM {
  provides {
    interface StdControl;
  }
  uses {
    interface Clock;
    interface BareSendMsg;
    interface ReceiveMsg;

    interface PageEEPROM;
  }
}
implementation {
  uint32_t time;
  TOS_Msg msg;

  enum { PAGE_SIZE = 512 };

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Clock.setRate(TOS_I100PS, TOS_S100PS);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t BareSendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }

  void sendTime(uint8_t status) {
    memcpy(msg.data, &time, sizeof time);
    time = 0;
    msg.data[sizeof time] = status;
    msg.length = 5;
    msg.addr = TOS_UART_ADDR;
    call BareSendMsg.send(&msg);
  }

  event result_t Clock.fire() {
    time++;
    return SUCCESS;
  }

  struct orders {
    uint8_t cmd;
    uint32_t size;
  } o;

  uint8_t buffer[PAGE_SIZE];

  eeprompage_t page;
  uint32_t count;

#if 0
  bool realErasePhase;

  void continueWrite() {
    call PageEEPROM.erase(page, TOS_EEPROM_PREVIOUSLY_ERASED);
  }

  void falseErase() {
    eeprompageoffset_t n;

    if (count == 0)
      {
	sendTime(1);
	return;
      }

    if (count > PAGE_SIZE)
      n = PAGE_SIZE;
    else
      n = count;

    count -= n;
    call PageEEPROM.write(page, 0, buffer, n);
  }

  event result_t PageEEPROM.writeDone(result_t result) {
    if (result == FAIL)
      sendTime(0);
    else 
#if 1
      call PageEEPROM.flush(page++);
#else
    {
      page++;
      continueWrite();
    }
#endif
    return SUCCESS;
  }

  event result_t PageEEPROM.flushDone(result_t result) {
    if (result == FAIL)
      sendTime(0);
    else 
      continueWrite();
    return SUCCESS;
  }

  void startWrite() {
    realErasePhase = FALSE;
    page = IFS_NUM_PAGES;
    count = o.size;
    continueWrite();
  }

  void realErase() {
    eeprompageoffset_t n;

    if (count == 0)
      {
	sendTime(2);
	startWrite();
	return;
      }

    if (count > PAGE_SIZE)
      n = PAGE_SIZE;
    else
      n = count;

    count -= n;
    call PageEEPROM.erase(page++, TOS_EEPROM_ERASE);
  }

  event result_t PageEEPROM.eraseDone(result_t result) {
    if (result == FAIL)
      {
	sendTime(0);
	return SUCCESS;
      }

    if (realErasePhase)
      realErase();
    else
      falseErase();
    return SUCCESS;
  }

  void directWrite() {
    realErasePhase = TRUE;
    page = IFS_NUM_PAGES;
    count = o.size;
    realErase();
  }
#else
  void continueWrite() {
    call PageEEPROM.erase(page, TOS_EEPROM_DONT_ERASE);
  }

  event result_t PageEEPROM.eraseDone(result_t result) {
    eeprompageoffset_t n;

    if (result == FAIL)
      {
	sendTime(0);
	return SUCCESS;
      }

    if (count == 0)
      {
	sendTime(1);
	return SUCCESS;
      }

    if (count > PAGE_SIZE)
      n = PAGE_SIZE;
    else
      n = count;

    count -= n;
    call PageEEPROM.write(page, 0, buffer, n);
    return SUCCESS;
  }

  event result_t PageEEPROM.writeDone(result_t result) {
    if (result == FAIL)
      sendTime(0);
    else 
#if 1
      call PageEEPROM.flush(page++);
#else
    {
      page++;
      continueWrite();
    }
#endif
    return SUCCESS;
  }

  event result_t PageEEPROM.flushDone(result_t result) {
    if (result == FAIL)
      sendTime(0);
    else 
      continueWrite();
    return SUCCESS;
  }

  void directWrite() {
    page = IFS_NUM_PAGES;
    count = o.size;
    continueWrite();
  }
#endif

  void continueRead() {
    eeprompageoffset_t n;

    if (count == 0)
      {
	sendTime(1);
	directWrite();
      }

    if (count > PAGE_SIZE)
      n = PAGE_SIZE;
    else
      n = count;

    count -= n;
    call PageEEPROM.read(page, 0, buffer, n);
    page++;
  }

  event result_t PageEEPROM.readDone(result_t result) {
    if (result == FAIL)
      sendTime(0);
    else
      continueRead();
    return SUCCESS;
  }

  void directRead() {
    page = IFS_NUM_PAGES;
    count = o.size;
    continueRead();
  }

  task void bm() {
    time = 0;
    directRead();
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msg) {
    o = *(struct orders *)msg->data;
    post bm();
    return msg;
  }

  event result_t PageEEPROM.syncDone(result_t result) {
    return SUCCESS;
  }
  event result_t PageEEPROM.computeCrcDone(result_t result, uint16_t crc) {
    return SUCCESS;
  }
}
