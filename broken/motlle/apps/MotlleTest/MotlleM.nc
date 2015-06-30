includes Motlle;
module MotlleM {
  provides interface StdControl;
  uses {
    interface StdControl as SubControl;
    interface ReceiveMsg as ReceiveCode;
    interface Timer;
    interface Leds;
    interface Debug;
  }
  provides event void dbgAvailable();
}
implementation {
  enum { s_ready, s_data, s_data_size, s_globals,
	 s_running, s_waiting, s_crashed } state;
  enum { 
    w_time = 1,
    w_dbg = 2
  };
  uint8_t waitMask;
  uint16_t sleeptime;
  uvalue nglobals, nload_globals;
  enum {
    DBG_SYS = 1,
    DBG_RUN = 2
  };
  uint8_t dbgOptions;

  void sysDbg8(uint8_t x) {
    if (dbgOptions & DBG_SYS)
      call Debug.dbg8(x);
  }

  void sysDbg16(uint16_t x) {
    if (dbgOptions & DBG_SYS)
      call Debug.dbg8(x);
  }

  task void motlleRun() {
    while (state == s_running)
      motlle_run1();
  }

  void waitFor(uint8_t ev) {
    waitMask |= ev;
    if (state == s_running)
      state = s_waiting;
  }

  void eventOccurred(uint8_t ev) {
    waitMask &= ~ev;
    if (state == s_waiting && waitMask == 0)
      {
	state = s_running;
	post motlleRun();
      }
  }	

  void fullReset() {
    state = s_ready;
    waitMask = 0;
    sleeptime = 0;
    motlle_init();
    call Leds.set(0);
    sysDbg8(dbg_reset);
  }

  command result_t StdControl.init() {
    call Leds.init();
    call Debug.init();
    dbgOptions = DBG_SYS;
    return call SubControl.init();
  }

  command result_t StdControl.start() {
    fullReset();
    return call Timer.start(TIMER_REPEAT, 1000);
  }

  command result_t StdControl.stop() {
    return call Timer.stop();
  }

  void crash(uint8_t cause) {
    sysDbg8(0xef);
    sysDbg8(cause);
    state = s_crashed;
    motlle_init();
  }

  enum { req_load, req_reset, req_debug };

  struct motlle_cmd
  {
    uint8_t request;
    uint8_t pad;
    union {
      struct {
	uvalue nglobals;
	uint8_t data[1];
      } req_load;
      uint8_t req_debug;
    } u;
  };

  static void handle_data_packet(uint8_t *data, uint8_t offset) {
    if (state == s_globals)
      {
	while (nload_globals > 0 && offset < DATA_LENGTH)
	  {
	    mvalue gv = *((mvalue *)(data + offset));

	    offset += sizeof(uvalue);
	    motlle_global_set(nglobals - nload_globals, gv);
	    nload_globals--;
	  }
	if (nload_globals == 0)
	  state = s_data_size;
      }

    if (state == s_data_size)
      {
	uvalue size;

	if (offset == DATA_LENGTH)
	  return;

	size = *((uvalue *)(data + offset));
#if 1
	{
	  sysDbg8(0xee);
	  sysDbg16(size);
	}
#endif
	offset += sizeof(uvalue);
	if (!motlle_data_init(size))
	  {
	    crash(1);
	    return;
	  }

	state = s_data;
      }

    if (state == s_data)
      {
	mvalue code;

	if ((code = motlle_data(data + offset, DATA_LENGTH - offset)))
	  {
	    state = s_running;
	    motlle_exec(code);
	    post motlleRun();
	  }
      }
  }

  static void handle_packet(struct motlle_cmd *packet) {
    switch (packet->request)
      {
      case req_load:
	state = s_globals;
	nload_globals = packet->u.req_load.nglobals;
	nglobals = motlle_globals_reserve(nload_globals);
	if (nload_globals && !nglobals)
	  crash(2);
	else
	  handle_data_packet((uint8_t *)packet,
			     offsetof(struct motlle_cmd, u.req_load.data));
	break;
      case req_reset:
	fullReset();
	return;
      case req_debug:
	dbgOptions = packet->u.req_debug;
	return;
      }
  }

  event TOS_MsgPtr ReceiveCode.receive(TOS_MsgPtr msg) {
    /* unlikely to appear in a message */
    if (strcmp(msg->data, "please reset now! thanks.") == 0)
      fullReset();
    else if (state == s_crashed)
      {
	sysDbg8(0xef);
	sysDbg8(3);
      }
    else if (state == s_data || state == s_data_size || state == s_globals)
      handle_data_packet(msg->data, 0);
    else
      handle_packet((struct motlle_cmd *)msg->data);

    return msg;
  }

  event result_t Timer.fired() {
    if (sleeptime > 0)
      {
	if (--sleeptime == 0)
	  eventOccurred(w_time);
      }
    return SUCCESS;
  }

  void motlle_req_leds(uint8_t cmd) __attribute__((C, spontaneous)) {
    switch (cmd) {
    case led_y_toggle:
      call Leds.yellowToggle();
      break;
    case led_y_on:
      call Leds.yellowOn();
      break;
    case led_y_off:
      call Leds.yellowOff();
      break;
    case led_r_toggle:
      call Leds.redToggle();
      break;
    case led_r_on:
      call Leds.redOn();
      break;
    case led_r_off:
      call Leds.redOff();
      break;
    case led_g_toggle:
      call Leds.greenToggle();
      break;
    case led_g_on:
      call Leds.greenOn();
      break;
    case led_g_off:
      call Leds.greenOff();
      break;
    }
  }

  void motlle_req_exit(uint8_t exitcode) __attribute__((C, spontaneous)) {
    sysDbg8(dbg_exit);
    sysDbg8(exitcode);
    state = s_ready;
  }

  void motlle_req_sleep(int16_t time) __attribute__((C, spontaneous)) {
    if (time)
      {
	waitFor(w_time);
	sleeptime = time;
      }
  }

  uint8_t motlle_req_send_msg(uint8_t *data, uint8_t len) __attribute__((C, spontaneous)) {
    return 0;
  }

  void motlle_req_msg_data(uint8_t *data) __attribute__((C, spontaneous)) {
  }

  void motlle_req_receive(mvalue newreceiver) __attribute__((C, spontaneous)) {
  }

  void motlle_req_dbg(uint8_t x) __attribute__((C, spontaneous)) {
    if (dbgOptions & DBG_RUN)
      if (!call Debug.dbg8(x))
	waitFor(w_dbg);
  }

  event void dbgAvailable() {
    if (waitMask & w_dbg)
      eventOccurred(w_dbg);
  }
}
