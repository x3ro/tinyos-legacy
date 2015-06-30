module TimerClient {
  provides interface StdControl;
  uses interface Timer;
} implementation {

  command result_t StdControl.init() {
    return SUCCESS;
  }
  command result_t StdControl.start() {
    call Timer.start(TIMER_REPEAT, 1000);
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t Timer.fired() {
    dbg(DBG_USR1, "MDW: TimerClient: Timer.fire()\n");
    return SUCCESS;
  }


}
