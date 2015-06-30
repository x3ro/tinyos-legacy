/*
 *
 * Authors:  Mike Grimmer
 * Revision:		$Rev$
 *
 */

includes sensorboard;
module MicM 
{
  provides interface StdControl;
  provides interface Mic;
  uses 
  {
    interface ADCControl;
    interface StdControl as PotControl;
    interface I2CPot;
  }
}
implementation 
{
  command result_t StdControl.init() 
  {
    call ADCControl.bindPort(TOS_ADC_MIC_PORT, TOSH_ACTUAL_MIC_PORT);
    TOSH_MAKE_MIC_CTL_OUTPUT();
    TOSH_CLR_MIC_CTL_PIN();
    call ADCControl.init();
    call PotControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() 
  {
    TOSH_SET_MIC_CTL_PIN();
    return SUCCESS;
  }

  command result_t StdControl.stop() 
  {
    TOSH_MAKE_MIC_CTL_OUTPUT();
    TOSH_CLR_MIC_CTL_PIN();
    return SUCCESS;
  }

  command result_t Mic.gainAdjust(uint8_t val)
  {
    return call I2CPot.writePot(TOS_MIC_POT_ADDR, 0, val);
  }

  event result_t I2CPot.readPotDone(char data, bool result)
  {
    return SUCCESS;
  }

  event result_t I2CPot.writePotDone(bool result)
  {
    return SUCCESS;
  }

}

