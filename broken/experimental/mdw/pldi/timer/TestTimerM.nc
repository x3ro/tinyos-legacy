includes Timer;

module TestTimerM {
  provides interface StdControl;
  uses interface Timer;
} implementation {

  command result_t StdControl.init() {
    dbg(DBG_USR1, "TimerTestM: StdControl.init()\n");
    return SUCCESS;
  }

  command result_t StdControl.start() {
    dbg(DBG_USR1, "TimerTestM: StdControl.start()\n");
    return call Timer.start(TIMER_REPEAT, 1000);
  }

  command result_t StdControl.stop() {
    dbg(DBG_USR1, "TimerTestM: StdControl.stop()\n");
    return call Timer.stop();
  }

  event result_t Timer.fired() {
    dbg(DBG_USR1, "TimerTestM: Timer.fired()\n");
    return SUCCESS;
  }
}
