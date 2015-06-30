// $Id: TempM.nc,v 1.1 2004/11/22 14:33:34 husq Exp $
module TempM {
  provides {
    interface StdControl;
    interface ADC;
  }
}
implementation {
  command result_t StdControl.init() {
    TOSH_MAKE_TEMP_CS_OUTPUT();
    TOSH_MAKE_TEMP_SCK_OUTPUT();
    TOSH_MAKE_TEMP_SIO_INPUT();
    return SUCCESS;
  }
  command result_t StdControl.start() {
    TOSH_SET_TEMP_CS_PIN();
    TOSH_CLR_TEMP_SCK_PIN();
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    TOSH_SET_TEMP_CS_PIN();
    TOSH_CLR_TEMP_SCK_PIN();
    return SUCCESS;
  }
  
  async command result_t ADC.getData() {
    int i;
    uint16_t data_buffer = 0;
    atomic {
      TOSH_CLR_TEMP_CS_PIN();
      for (i = 0; i < 13; i++) {
        data_buffer <<= 1;
        TOSH_SET_TEMP_SCK_PIN();
        data_buffer |= TOSH_READ_TEMP_SIO_PIN() ? 1 : 0;
        TOSH_CLR_TEMP_SCK_PIN();
        asm volatile ("nop" ::); asm volatile ("nop" ::);
        asm volatile ("nop" ::);
      }
      TOSH_SET_TEMP_CS_PIN();
    }
    data_buffer <<= 3;
    signal ADC.dataReady(data_buffer);
    return SUCCESS;
  }
  async command result_t ADC.getContinuousData() {
    return FAIL;
  }
}

