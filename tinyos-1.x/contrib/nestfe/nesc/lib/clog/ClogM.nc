module ClogM {  
  provides interface StdControl;

  uses interface Drain;
  uses interface Receive as DrainReceive;

  uses interface Send as DripSend;
  uses interface SendMsg as DripSendMsg;

  uses interface Timer;
  uses interface Random;
  uses interface Leds;
}
implementation {

  TOS_Msg msgBuf;
  
  uint8_t treeInstance;
  uint16_t treeBuildPeriod = 32768U;
  bool isClog;

  uint16_t packetsForwarded;

  command result_t StdControl.init() { return SUCCESS; }

  command result_t StdControl.start() {
    isClog = TRUE;
    treeInstance = call Random.rand() % 0xFF;
    call Timer.start(TIMER_ONE_SHOT, 5);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    isClog = FALSE;
    call Timer.stop();
    return SUCCESS;
  }

  event result_t Timer.fired() {
    call Drain.buildTreeInstance(treeInstance, TRUE);
    call Timer.start(TIMER_ONE_SHOT, treeBuildPeriod);
    return SUCCESS;
  }

  event TOS_MsgPtr DrainReceive.receive(TOS_MsgPtr msg, 
					void* payload, 
					uint16_t payloadLen) {

    uint16_t length;
    DrainMsg* drainMsg = (DrainMsg*) msg->data;
    uint8_t* drainData = call DripSend.getBuffer(&msgBuf, &length); 

    // special case for bridging. getBuffer normally returns a ptr to
    // the inside of the AddressMsg, and we're modifying the outside.

    AddressMsg* addressMsg = (AddressMsg*) (drainData - sizeof(AddressMsg));

    if (isClog == FALSE) {
      return msg;
    }

    dbg(DBG_USR1, "Received Drain message: dest=%d, src=%d\n",
	drainMsg->dest, drainMsg->source);
    
    addressMsg->dest = drainMsg->dest;
    addressMsg->source = drainMsg->source;

    dbg(DBG_USR1, "Addrmsg = %x\n", addressMsg);

    memcpy(addressMsg->data, payload, payloadLen);

    call Leds.yellowToggle();

    call DripSend.send(&msgBuf, offsetof(AddressMsg, data) + payloadLen);

    packetsForwarded++;

    return msg;
  }

  event result_t DripSend.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }

  event result_t DripSendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }
}
