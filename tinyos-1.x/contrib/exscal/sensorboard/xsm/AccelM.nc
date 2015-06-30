/**
 * @author Alec Woo
 * @author Su Ping
 */

includes sensorboard;
module AccelM 
{
  provides interface StdControl;
  uses 
  {
    interface ADCControl;
  }
}
implementation 
{
  command result_t StdControl.init() 
  {
    call ADCControl.bindPort(TOS_ADC_ACCEL_X_PORT, TOSH_ACTUAL_ACCEL_X_PORT);
    call ADCControl.bindPort(TOS_ADC_ACCEL_Y_PORT, TOSH_ACTUAL_ACCEL_Y_PORT);
    TOSH_MAKE_ACCEL_CTL_OUTPUT();
    TOSH_SET_ACCEL_CTL_PIN();
    dbg(DBG_BOOT, "ACCEL initialized.\n");
    return call ADCControl.init();
  }
  command result_t StdControl.start() 
  {
    TOSH_SET_ACCEL_CTL_PIN();
    return SUCCESS;
  }

  command result_t StdControl.stop() 
  {
      TOSH_CLR_ACCEL_CTL_PIN();
      return SUCCESS;
  }
}

