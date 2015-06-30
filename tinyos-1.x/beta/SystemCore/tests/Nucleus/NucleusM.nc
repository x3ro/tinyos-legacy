module NucleusM {
  provides {
    interface StdControl;
  }
  uses {    
    interface StdControl as DelugeControl;
    interface StdControl as DelugeSSControl;
    interface StdControl as GIWControl;
    interface StdControl as SNMSControl;
  }
}
implementation {

  command result_t StdControl.init() {
    call DelugeControl.init();
    call SNMSControl.init();
    return SUCCESS;
  }
  command result_t StdControl.start() {
    call DelugeSSControl.start();
    if (call GIWControl.start() == FAIL) {
      // The golden image has already been written.
      call SNMSControl.start();
    }
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }
}
