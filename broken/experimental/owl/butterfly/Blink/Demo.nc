module Demo {
  provides interface StdControl;
  uses interface LCD;
  uses interface Timer;
}
implementation {

  task void message() {
    call LCD.display("TinyOS");
  }

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

  bool on;

  event result_t Timer.fired() {
    if (on = !on)
      call LCD.display("TinyOS");
    else
      call LCD.display("");
  }
}
