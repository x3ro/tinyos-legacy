module Demo {
  provides interface StdControl;
}
implementation {
  task void nop() {
  }

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    post nop();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }
}
