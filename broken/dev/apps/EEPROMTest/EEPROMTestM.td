module EEPROMTestM
{
  provides interface StdControl;

  uses {
    interface StdControl as EEPROMControl;
    interface EEPROMRead;
    interface EEPROMWrite;

    interface Leds;

    interface StdControl as CommControl;
    interface ReceiveMsg as ReceiveTestMsg;
    interface SendMsg as SendResultMsg;
  }
}
implementation
{
  TOS_Msg buffer; 
  TOS_MsgPtr msg;
  bool bufferInuse;


  command result_t StdControl.init() {
    call EEPROMControl.init();
    call CommControl.init();

    msg = &buffer;
    bufferInuse = 0;
    dbg(DBG_BOOT, "EETEST initialized\n");
    call Leds.redOn();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t SendResultMsg.sendDone(TOS_MsgPtr data, result_t success) {
    call Leds.yellowToggle();
    if(msg == data)
      {
	dbg(DBG_USR2, "EETEST send buffer free\n");
	bufferInuse = FALSE;
      }
    return SUCCESS;
  }

  void sendAnswer(uint8_t code) {
    TOS_MsgPtr lmsg = msg;

    call Leds.redToggle();
    lmsg->data[0] = code;
    if (!call SendResultMsg.send(TOS_BCAST_ADDR, TOS_EEPROM_LINE_SIZE + 3, lmsg))
      bufferInuse = FALSE;
  }

  event result_t EEPROMRead.readDone(uint8_t *buf, result_t success) {
    sendAnswer(success ? 0x90 : 0x84);
    return SUCCESS;
  }

  event result_t EEPROMWrite.writeDone(uint8_t *buf) {
    if (call EEPROMWrite.endWrite() == FAIL)
      sendAnswer(0x86);
    return SUCCESS;
  }

  event result_t EEPROMWrite.endWriteDone(result_t success) {
    sendAnswer(success ? 0x91 : 0x85);
    return SUCCESS;
  }

  task void processPacket() {
    TOS_MsgPtr lmsg = msg;
    uint8_t error = 0x7f;

    switch (lmsg->data[0])
      {
      case 0: /* Read a line */
	if (call EEPROMRead.read(((unsigned char)lmsg->data[1] << 8) + (unsigned char)lmsg->data[2], ((uint8_t*)lmsg->data + 3)))
	  return;
	error = 0x80;
	break;
      case 2: /* Write a line */
	if (call EEPROMWrite.startWrite() &&
	    call EEPROMWrite.write(((unsigned char)lmsg->data[1] << 8) + (unsigned char)lmsg->data[2], ((uint8_t*)lmsg->data + 3)))
	  return;
	error = 0x82;
	break;
      }
    sendAnswer(error);
  }

  event TOS_MsgPtr ReceiveTestMsg.receive(TOS_MsgPtr data) {
    TOS_MsgPtr tmp = data;

    call Leds.greenToggle();
    dbg(DBG_USR2, "EETEST received packet\n");
    if (!bufferInuse)
      {
	bufferInuse = TRUE;
	tmp = msg;
	msg = data;
	dbg(DBG_USR2, "EETEST forwarding packet\n");
	post processPacket();
      }
    return tmp;
  }
}
