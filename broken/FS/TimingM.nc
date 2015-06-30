module TimingM {
  provides {
    interface StdControl;
    event result_t matchboxReady();
  }
  uses {
    interface Clock;
    interface BareSendMsg;
    interface ReceiveMsg;
    interface FileRead;
    interface FileWrite;
  }
}
implementation {
  uint32_t time;
  TOS_Msg msg;

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
    msg.data[sizeof time] = status;
    msg.length = 5;
    msg.addr = TOS_UART_ADDR;
    call BareSendMsg.send(&msg);
  }

  event result_t Clock.fire() {
    time++;
    return SUCCESS;
  }

  event result_t matchboxReady() {
    sendTime(0);
    return SUCCESS;
  }

  struct orders {
    uint8_t cmd;
    uint32_t size;
  } o;

  uint8_t buffer[256];

  void readAgain() {
    call FileRead.read(buffer, o.size);
  }

  event result_t FileRead.readDone(void *buffer, filesize_t nRead,
				   fileresult_t result) {
    if (result != FS_OK || nRead < o.size)
      {
	call FileRead.close();
	sendTime(result);
      }
    else
      readAgain();
    return SUCCESS;
  }

  event result_t FileRead.opened(fileresult_t result) {
    if (o.size > sizeof buffer)
      o.size = sizeof buffer;
    readAgain();
    return SUCCESS;
  }

  task void bm() {
    time = 0;
    switch (o.cmd)
      {
      case 0: call FileWrite.open("foo", FS_FTRUNCATE | FS_FCREATE); break;
      case 1: call FileRead.open("foo"); break;
      }
  }

  void writeAgain(fileresult_t result) {
    if (result == FS_OK)
      if (o.size == 0)
	call FileWrite.close();
      else
	{
	  filesize_t size = o.size > sizeof buffer ? sizeof buffer : o.size;
	  o.size -= size;
	  call FileWrite.append(buffer, size);
	}
    else
      sendTime(result);
  }

  event result_t FileWrite.opened(filesize_t fileSize, fileresult_t result) {
    writeAgain(result);
    return SUCCESS;
  }

  event result_t FileWrite.closed(fileresult_t result) {
    sendTime(result);
    return SUCCESS;
  }

  event result_t FileWrite.appended(void *buffer, filesize_t nWritten,
				    fileresult_t result) {
    writeAgain(result);
    return SUCCESS;
  }

  event result_t FileWrite.synced(fileresult_t result) {
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msg) {
    o = *(struct orders *)msg->data;
    post bm();
    return msg;
  }

  event result_t FileWrite.reserved(filesize_t reservedSize, fileresult_t result) {
    return SUCCESS;
  }
  event result_t FileRead.remaining(filesize_t n, fileresult_t result) {
    return SUCCESS;
  }
}
