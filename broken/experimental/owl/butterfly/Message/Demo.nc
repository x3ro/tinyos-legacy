module Demo {
  provides interface StdControl;
  uses interface LCD;
}
implementation {

  task void message() {
    call LCD.display("TinyOS");
  }

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    post message();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }
}
