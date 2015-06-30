includes Field;
module Field
{
  provides interface StdControl;

  uses {
    interface ReceiveMsg as WakeupMsg;
    interface ReceiveMsg as FieldMsg;
    interface SendMsg as FieldReplyMsg;
    interface Timer;
    //interface Debug;
    interface Leds;
  }
}
implementation
{
  bool awake, busy, sleepPending;
  uint16_t lastCmdId;
  TOS_Msg reply;

  enum {
    FIELD_TIMEOUT = 10000
  };

  void sendReply(uint16_t to, uint16_t cmdId, uint8_t result);

  command result_t StdControl.init() {
    awake = busy = FALSE;
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  void sleep() {
    call Leds.redOff();
    awake = FALSE;
  }

  void wakeup() {
    if (!awake)
      {
	awake = TRUE;
	call Leds.redOn();
      }
  }

  void startTimeout() {
    call Timer.stop();
    // Cancel any pending sleep request
    sleepPending = FALSE;
    call Timer.start(TIMER_ONE_SHOT, FIELD_TIMEOUT);
  }

  task void gotoSleep() {
    if (sleepPending)
      sleep();
  }

  event result_t Timer.fired() {
    sleepPending = TRUE;
    if (!post gotoSleep())
      call Timer.start(TIMER_ONE_SHOT, FIELD_TIMEOUT >> 3);
  }

  event TOS_MsgPtr WakeupMsg.receive(TOS_MsgPtr msg) {
    if (!busy)
      {
	struct WakeupMsg *m = (struct WakeupMsg *)msg->data;

	busy = TRUE;
	startTimeout();
	wakeup();
	sendReply(m->sender, WAKEUP_CMDID, 42);
      }
    return msg;
  }

  bool duplicate(struct FieldMsg *m) {
    if (m->cmdId == lastCmdId)
      return TRUE;
    lastCmdId = m->cmdId;
    return FALSE;
  }

  event TOS_MsgPtr FieldMsg.receive(TOS_MsgPtr msg) {
    struct FieldMsg *m = (struct FieldMsg *)msg->data;

    if (awake && !busy && !duplicate(m))
      {
	uint8_t result = 0;

	busy = TRUE;
	startTimeout();

	switch (m->cmd)
	  {
	  case 0:
	    call Leds.greenToggle();
	    break;
	  case 1:
	    call Leds.yellowToggle();
	    break;
	  case 2:
	    result = call Leds.get();
	    break;
	  default:
	    result = 0xff;
	  }
	sendReply(m->sender, m->cmdId, result);
      }
    return msg;
  }

  void sendReply(uint16_t to, uint16_t cmdId, uint8_t result) {
    struct FieldReplyMsg *m = (struct FieldReplyMsg *)reply.data;

    m->sender = TOS_LOCAL_ADDRESS;
    m->cmdId = cmdId;
    m->response = result;

    if (!call FieldReplyMsg.send(to, sizeof(struct FieldReplyMsg), &reply))
      busy = FALSE;
  }

  event result_t FieldReplyMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    busy = FALSE;
    return SUCCESS;
  }
}
