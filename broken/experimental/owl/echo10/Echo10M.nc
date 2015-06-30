module Echo10M {
  provides interface SplitControl;
  uses {
    interface Timer;
    interface Power;
    interface SetParam;
    interface StdControl as SubControl;
  }
}
implementation {
  enum {
    WARMUP = 10
  };

  task void initDone() { signal SplitControl.initDone(); }
  command result_t SplitControl.init() {
    post initDone();
    return call SubControl.init();
  }

  command result_t SplitControl.start() {
    if (!call SubControl.start())
      return FAIL;

    call Power.on();
    call SetParam.setParam(AVERAGE_FOUR);
    return call Timer.start(TIMER_ONE_SHOT, WARMUP);
  }

  event result_t Timer.fired() {
    signal SplitControl.startDone();
    return SUCCESS;
  }

  task void stopDone() { signal SplitControl.stopDone(); }
  command result_t SplitControl.stop() {
    post stopDone();
    call Power.off();
    return call SubControl.stop();
  }
}
