includes Motlle;
module MotlleSleep {
  uses {
    interface MotlleControl;
    interface Timer;
  }
}
implementation {
  uint16_t sleeptime;

  event result_t MotlleControl.init() {
    sleeptime = 0;
    return call Timer.start(TIMER_REPEAT, 1000);
  }

  void motlle_req_sleep(int16_t time) __attribute__((C, spontaneous)) {
    if (time)
      {
	call MotlleControl.waitForEvent(W_TIME);
	sleeptime = time;
      }
  }

  event result_t Timer.fired() {
    if (sleeptime > 0)
      {
	if (--sleeptime == 0)
	  call MotlleControl.eventOccurred(W_TIME);
      }
    return SUCCESS;
  }
}
