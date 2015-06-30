/**
 * Private platform initialization code for the msp430.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
module PlatformP {
  provides interface Init as HPLInit;
  uses command result_t hplInit();
  uses interface Init as ArbiterInits;
}
implementation {
  command result_t HPLInit.init() {
    call hplInit();
    call ArbiterInits.init();
    return SUCCESS;
  }

  default command result_t ArbiterInits.init() {
    return SUCCESS;
  }
}

