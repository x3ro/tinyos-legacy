/* Author: Matt Welsh
 */

abstract module AMHandler(uint8_t handler_id) {
  provides {
    interface StdControl as Control;
    interface CommControl;
    interface SendMsg;
    interface ReceiveMsg;

    // How many packets were received in the past second
    command uint16_t activity();

  }

  uses {
    // signaled after every send completion for components which wish to
    // retry failed sends
    event result_t sendDone();
   
    interface static StdControl as UARTControl;
    interface static BareSendMsg as UARTSend;
    interface static ReceiveMsg as UARTReceive;

    interface static StdControl as RadioControl;
    interface static BareSendMsg as RadioSend;
    interface static ReceiveMsg as RadioReceive;
    interface Leds;
    interface Timer as ActivityTimer;
  }
}
implementation
{
  bool state;
  static TOS_MsgPtr buffer;
  uint16_t lastCount;
  uint16_t counter;
  bool promiscuous_mode;
  bool crc_check;
  static bool initialized;

  // Table mapping handler ID to handler instance
  // This could be done in other ways!
  enum {
     MAX_HANDLERS = 256,
  };
  static int handlerTable[MAX_HANDLERS];
  
  // Initialization of this component
  command bool Control.init() {
    int i;
    result_t ok1, ok2;

    if (initialized) return SUCCESS;

    ok1 = call UARTControl.init();
    ok2 = call RadioControl.init();

    for (i = 0; i < _NUMINSTANCES; i++) {
      instance(i).state = FALSE;
      instance(i).lastCount = 0;
      instance(i).counter = 0;
      instance(i).promiscuous_mode = FALSE;
      instance(i).crc_check = FALSE;
    }

    for (i = 0; i < MAX_HANDLERS; i++) {
      handlerTable[i] = -1;
    }

    handlerTable[handler_id] = _INSTANCENUM;
    
    dbg(DBG_BOOT, "AM Module initialized\n");

    initialized = TRUE;
    return rcombine(ok1, ok2);
  }

  // Command to be used for power managment
  command bool Control.start() {
    result_t ok1 = call UARTControl.start();
    result_t ok2 = call RadioControl.start();
    result_t ok3 = call ActivityTimer.start(TIMER_REPEAT, 1000);
    return rcombine3(ok1, ok2, ok3);
  }
  
  command bool Control.stop() {
    result_t ok1 = call UARTControl.stop();
    result_t ok2 = call RadioControl.stop();
    result_t ok3 = call ActivityTimer.stop();
    return rcombine3(ok1, ok2, ok3);
  }

  command result_t CommControl.setCRCCheck(bool value) {
    crc_check = value;
    return SUCCESS;
  }

  command bool CommControl.getCRCCheck() {
    return crc_check;
  }

  command result_t CommControl.setPromiscuous(bool value) {
    promiscuous_mode = value;
    return SUCCESS;
  }

  command bool CommControl.getPromiscuous() {
    return promiscuous_mode;
  }

  command uint16_t activity() {
    return lastCount;
  }
  
  void dbgPacket(TOS_MsgPtr data) {
    uint8_t i;

    for(i = 0; i < sizeof(TOS_Msg); i++)
      {
	dbg_clear(DBG_AM, "%02hhx ", ((uint8_t *)data)[i]);
      }
    dbg(DBG_AM, "\n");
  }

  static int getInstance(TOS_MsgPtr msg) {
    return handlerTable[msg->type];
  }

  // Handle the event of the completion of a message transmission
  result_t reportSendDone(TOS_MsgPtr msg, result_t success) {
    int inst;
    inst = getInstance(msg);
    if (inst > 0) {
      instance(inst).state = FALSE;
      signal instance(inst).SendMsg.sendDone(msg, success);
    }
    signal sendDone();

    return SUCCESS;
  }

  default event result_t sendDone() {
    return SUCCESS;
  }

  event result_t ActivityTimer.fired() {
    lastCount = counter;
    counter = 0;
    return SUCCESS;
  }
  
  // This task schedules the transmission of the Active Message
  task void sendTask() {
    result_t ok;

    if (buffer->addr == TOS_UART_ADDR)
      ok = call UARTSend.send(buffer);
    else
      ok = call RadioSend.send(buffer);

    if (ok == FAIL) // failed, signal completion immediately
      reportSendDone(buffer, FAIL);
  }

  // Command to accept transmission of an Active Message
  command result_t SendMsg.send(uint16_t addr, uint8_t length, TOS_MsgPtr data) {
    if (!state) {
      if (length > DATA_LENGTH) {
	dbg(DBG_AM, "AM: Send length too long: %i. Fail.\n", (int)length);
	return FAIL;
      }
      state = TRUE;
      post sendTask();
      buffer = data;
      data->length = length;
      data->addr = addr;
      data->type = handler_id;
      buffer->group = TOS_AM_GROUP;
      dbg(DBG_AM, "Sending message: %hx, %hhx\n\t", addr, handler_id);
      dbgPacket(data);
      return SUCCESS;
    }
    
    return FAIL;
  }

  event result_t UARTSend.sendDone(TOS_MsgPtr msg, result_t success) {
    return reportSendDone(msg, success);
  }
  event result_t RadioSend.sendDone(TOS_MsgPtr msg, result_t success) {
    return reportSendDone(msg, success);
  }

  // Handle the event of the reception of an incoming message
  TOS_MsgPtr received(TOS_MsgPtr packet)  __attribute__ ((C, spontaneous)) {
    int inst;
    dbg(DBG_AM, "AM_address = %hx, %hhx\n", packet->addr, packet->type);

    inst = getInstance(packet);

    if (inst > 0 &&
	packet->group == TOS_AM_GROUP &&
	(instance(inst).promiscuous_mode == TRUE || 
 	 packet->addr == TOS_BCAST_ADDR ||
	 packet->addr == TOS_LOCAL_ADDRESS) &&
	(instance(inst).crc_check == FALSE || packet->crc == 1)) 
    {
        uint8_t type = packet->type;
   	TOS_MsgPtr tmp;

	if (inst > 0) {
	  instance(inst).counter++;

	  // Debugging output
	  dbg(DBG_AM, "Received message:\n\t");
	  dbgPacket(packet);
	  dbg(DBG_AM, "AM_type = %d\n", type);

	  // dispatch message
	  tmp = signal instance(inst).ReceiveMsg.receive(packet);
	  if (tmp) 
	    packet = tmp;
	}
      }
    return packet;
  }

  event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr packet) {
    return received(packet);
  }
  event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr packet) {
    return received(packet);
  }
}

