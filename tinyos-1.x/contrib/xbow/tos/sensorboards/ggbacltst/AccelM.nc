// $Id: AccelM.nc,v 1.1 2004/11/22 14:33:34 husq Exp $
module AccelM {
  provides {
    interface StdControl;
    interface mADC;
  }
}
implementation {
  command result_t StdControl.init() {
    TOSH_MAKE_ACCEL_LOW_CLK_OUTPUT();
    TOSH_MAKE_ACCEL_LOW_CS_OUTPUT();
    TOSH_MAKE_ACCEL_HIGH_CLK_OUTPUT();
    TOSH_MAKE_ACCEL_HIGH_CS_OUTPUT();

    TOSH_MAKE_ACCEL_LOW_VERTICAL_INPUT();
    TOSH_MAKE_ACCEL_LOW_HORIZONTAL_INPUT();
    TOSH_MAKE_ACCEL_HIGH_HORIZONTAL_INPUT();
    TOSH_MAKE_ACCEL_HIGH_VERTICAL_INPUT();
    return SUCCESS;
  }
  command result_t StdControl.start() {
    TOSH_SET_ACCEL_LOW_CS_PIN();
    TOSH_SET_ACCEL_HIGH_CS_PIN();
    TOSH_CLR_ACCEL_LOW_CLK_PIN();
    TOSH_CLR_ACCEL_HIGH_CLK_PIN();
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    TOSH_SET_ACCEL_LOW_CS_PIN();
    TOSH_SET_ACCEL_HIGH_CS_PIN();
    TOSH_CLR_ACCEL_LOW_CLK_PIN();
    TOSH_CLR_ACCEL_HIGH_CLK_PIN();
    return SUCCESS;
  }
  
  async command result_t mADC.getData(uint16_t *data_buffer) {
    int i;
    uint8_t raw_data[22];
    atomic {
      TOSH_CLR_ACCEL_LOW_CS_PIN();
      TOSH_CLR_ACCEL_HIGH_CS_PIN();
      for (i = 0; i < 22; i++) {
        raw_data[i] = inp(PINE);
        TOSH_SET_ACCEL_LOW_CLK_PIN();
        TOSH_SET_ACCEL_HIGH_CLK_PIN();
        asm volatile ("nop" ::); asm volatile ("nop" ::);
        asm volatile ("nop" ::); asm volatile ("nop" ::);
        asm volatile ("nop" ::); asm volatile ("nop" ::);
        asm volatile ("nop" ::); asm volatile ("nop" ::);
        asm volatile ("nop" ::); asm volatile ("nop" ::);
        TOSH_CLR_ACCEL_LOW_CLK_PIN();
        TOSH_CLR_ACCEL_HIGH_CLK_PIN();
      }
      TOSH_SET_ACCEL_LOW_CS_PIN();
      TOSH_SET_ACCEL_HIGH_CS_PIN();
    }

    data_buffer[0] = 0;
    data_buffer[1] = 0;
    data_buffer[2] = 0;
    data_buffer[3] = 0;
    for (i = 6; i < 22; i++) {
      data_buffer[0] <<= 1;
      data_buffer[1] <<= 1;
      data_buffer[2] <<= 1;
      data_buffer[3] <<= 1;
      
      data_buffer[0] |= (raw_data[i] & 0x80) ? 1 : 0;
      data_buffer[1] |= (raw_data[i] & 0x40) ? 1 : 0;
      data_buffer[2] |= (raw_data[i] & 0x10) ? 1 : 0;
      data_buffer[3] |= (raw_data[i] & 0x20) ? 1 : 0;
    }
    data_buffer[2] = 0xffff - data_buffer[2];
    return SUCCESS;
  }
}

