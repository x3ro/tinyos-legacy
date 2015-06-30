
module TestLoggerM
{
  provides interface StdControl;

  uses {
    interface LoggerInit;
    interface LoggerRead;
    interface LoggerWrite;

    interface Leds;

    interface StdControl as CommControl;
    interface ReceiveMsg as ReceiveTestMsg;
    interface SendMsg as SendResultMsg;

  }
}
implementation
{
  enum {
    LOG_VOLUME_ID = 0xDF,
  };

  enum {
    LOGGER_LINE_SIZE = 16,
  };

  TOS_Msg buffer; 
  TOS_MsgPtr msg;
  bool bufferInuse;

  task void processPacket();

  /** 
   * Application initialization code. Initializes subcomponents: the eeprom
   * driver and the communication stack. 
   *
   * @return always SUCCESS
   */

  command result_t StdControl.init() {
    call CommControl.init();
    call Leds.init();
    
    msg = &buffer;
    bufferInuse = 0;

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call CommControl.start();
    call LoggerInit.init(LOG_VOLUME_ID, FALSE);
    return SUCCESS;
  }

  command result_t StdControl.stop() { 
    return SUCCESS;
  }

  event void LoggerInit.initDone(result_t result) {
    if (result == SUCCESS) call Leds.redOn();
  }

  /** 
   * When a message has been sent, the app marks the message buffer as
   * available for further use. The buffer will be used in processing further
   * directives from the network. 
   * 
   * @return Always SUCCESS.
   */

  event result_t SendResultMsg.sendDone(TOS_MsgPtr data, result_t success) {
    call Leds.yellowToggle();
    if(msg == data)
      {
	dbg(DBG_USR2, "EETEST send buffer free\n");
	bufferInuse = FALSE;
      }

    return SUCCESS;
  }

  /** 
   * Helper function used to produce the final response of the app to the
   * command fron the network.  The first byte of the message is the success
   * code; the remainder is the response specic data. The return codes are as
   * follows: 
   *<ul>
   *<li> 0x80 -- READ command was not accepted by the driver
   *<li> 0x82 -- WRITE command was not accepted by the driver
   *<li> 0x84 -- READ command failed 
   *<li> 0x85 -- WRITE command failed to write data into the temporary buffer
   *<li> 0x86 -- WRITE command failed to flush the temporary buffer into
   *nonvolatile storage. 
   *<li> 0x90 -- READ command succeeded 
   *<li> 0x91 -- WRITE command succeeded 
   *</ul>
   */ 

  void sendAnswer(uint8_t code) {
    TOS_MsgPtr lmsg = msg;

    call Leds.redToggle();
    lmsg->data[0] = code;
    if (!call SendResultMsg.send(TOS_UART_ADDR, LOGGER_LINE_SIZE + 3, lmsg))
      bufferInuse = FALSE;
  }

  /** 
   * This event is called when the eeprom read command succeeds; it sends a
   * message indicating the success or failure of the operation. If read
   * succeeded the data read will be located in the response buffer, starting
   * at the 3rd byte. 
   *
   * @return Always SUCCESS
   */ 

  event result_t LoggerRead.readDone(uint8_t *buf, result_t success) {
    sendAnswer(success ? 0x90 : 0x84);
    return SUCCESS;
  }

  /**
   * This event is invoked when EEPROM finishes transfering data into its
   * temporary buffer. In this app the temporary buffer is immediately flushed
   * to nonvolatile storage. If a transfer to the temporary buffer failed,
   * this handler will send a response code over the radio. 
   *
   * @return Always SUCCESS. 
   */ 

  event result_t LoggerWrite.writeDone(result_t success) {
    sendAnswer(success ? 0x91 : 0x86);
    return SUCCESS;
  }

  /** 
   * Decode the message buffer: pull out operation (0 for read, 2 for write),
   * code, decode the address, and execute the operation. 
   */ 

  task void processPacket() {
    TOS_MsgPtr lmsg = msg;
    uint8_t error = 0x7f;

    switch (lmsg->data[0])
      {
      case 0: /* Read a line */
	if (call LoggerRead.read(((unsigned char)lmsg->data[1] << 8) + (unsigned char)lmsg->data[2], 
                                 ((uint8_t*)lmsg->data + 3)))
	  return;
	error = 0x80;
	break;
      case 2: /* Write a line */
	if (call LoggerWrite.write(((unsigned char)lmsg->data[1] << 8) + (unsigned char)lmsg->data[2], 
                                   ((uint8_t*)lmsg->data + 3)))
	  return;
	error = 0x82;
	break;
      }
    sendAnswer(error);
  }


  /** 
   * When the command message has been received, this handler check if the
   * previous operation was completed, and if so it will dispatch the incoming
   * message to processPacket task. 
   *
   */

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
