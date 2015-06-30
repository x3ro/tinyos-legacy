/*
 *
 * Systemic Realtime Design, LLC.
 * http://www.sysrtime.com
 *
 * Authors:  Qingwei Ma
 *
 * Date last modified:  9/30/04
 *
 */



module SGDriverM {
  provides interface StdControl;
  uses {
    interface ADCControl;
  }
}
implementation {

  command result_t StdControl.init() {
    call ADCControl.init();
    cbi(DDRF, 2);
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }
}

