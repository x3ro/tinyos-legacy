/*
 *
 * Authors:  Mike Grimmer
 * Revision:		$Rev$
 *
 */

includes sensorboard;
module PIRM 
{
  provides interface StdControl;
  provides interface PIR;
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
    call ADCControl.bindPort(TOS_ADC_PIR_PORT, TOSH_ACTUAL_PIR_PORT);
    TOSH_SET_PIR_CTL_PIN();
	TOSH_SET_INT2_PIN();
    call ADCControl.init();
    call PotControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() 
  {
    TOSH_CLR_PIR_CTL_PIN();
    return SUCCESS;
  }

  command result_t StdControl.stop() 
  {
    TOSH_SET_PIR_CTL_PIN();
    return SUCCESS;
  }

  command result_t PIR.On()
  {
    TOSH_CLR_PIR_CTL_PIN();
	TOSH_uwait(100);
    return SUCCESS;
  }
  
  command result_t PIR.Off()
  {
    TOSH_SET_PIR_CTL_PIN();
    return SUCCESS;
  }

  command result_t PIR.detectAdjust(uint8_t val)
  {
    TOSH_SET_I2C_MUX_PIN();
    return call I2CPot.writePot(TOS_PIR_POT_ADDR, 0, val);
  }

  command result_t PIR.QuadAdjust(uint8_t val)
  {
    TOSH_SET_I2C_MUX_PIN();
    return call I2CPot.writePot(TOS_PIR_POT_ADDR, 1, val);
  }

  event result_t I2CPot.readPotDone(char data, bool result)
  {
    TOSH_SET_I2C_MUX_PIN();
    return result;
  }

  event result_t I2CPot.writePotDone(bool result)
  {
    return result;
  }


}

