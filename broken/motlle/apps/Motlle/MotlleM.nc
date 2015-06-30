includes Motlle;
module MotlleM {
  provides {
    interface StdControl;
    interface MotlleControl;
  }
  uses {
    interface StdControl as SubControl;
    interface Debug;
    interface Leds;
  }
}
implementation {
  bool isBusy;
  bool posted;
  uint8_t waitMask;

  void sysDbg8(uint8_t x) {
    call Debug.dbg8(x);
  }

  void sysDbg16(uint16_t x) {
    call Debug.dbg16(x);
  }

  task void motlleRun();

  void postMotlle() {
    if (!posted && isBusy && !waitMask)
      {
	posted = TRUE;
	post motlleRun();
      }
  }

  task void motlleRun() {
    posted = FALSE;
    if (isBusy && !waitMask)
      {
	motlle_run1();
	postMotlle();
      }
  }

  command void MotlleControl.eventOccurred(uint8_t id) {
    waitMask &= ~id;
    postMotlle();
  }

  command void MotlleControl.waitForEvent(uint8_t id) {
    waitMask |= id;
  }

  command bool MotlleControl.busy() {
    return isBusy;
  }

  command result_t MotlleControl.execute(mvalue fn) {
    if (!isBusy) {
      isBusy = TRUE;
      sysDbg8(dbg_start);
      sysDbg16((uvalue)fn);
      motlle_exec(fn);
      postMotlle();
      return SUCCESS;
    }
    return FAIL;
  }

  void motlle_req_exit(uint8_t exitcode) __attribute__((C, spontaneous)) {
    sysDbg8(dbg_exit);
    sysDbg8(exitcode);
    isBusy = FALSE;
  }

  command void MotlleControl.reset() {
    isBusy = FALSE;
    waitMask = 0;
    motlle_init();
    signal MotlleControl.init();
    sysDbg8(dbg_reset);
  }

  command result_t StdControl.init() {
    call SubControl.init();
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call SubControl.start();
    call Debug.init();
    call MotlleControl.reset();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return call SubControl.stop();
  }


  uint8_t motlle_req_send_msg(uint8_t *data, uint8_t len) __attribute__((C, spontaneous)) {
    return 0;
  }

  void motlle_req_msg_data(uint8_t *data) __attribute__((C, spontaneous)) {
  }

  void motlle_req_receive(mvalue newreceiver) __attribute__((C, spontaneous)) {
  }
}
