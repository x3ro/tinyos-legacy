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
  uint16_t LPF_interval;


  command result_t StdControl.init() 
  {
    call ADCControl.bindPort(TOS_ADC_MIC_PORT, TOSH_ACTUAL_MIC_PORT);
    TOSH_MAKE_MIC_CTL_OUTPUT();
    TOSH_SET_MIC_CTL_PIN();
    call ADCControl.init();
    call PotControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() 
  {
    TOSH_CLR_MIC_CTL_PIN();
    return SUCCESS;
  }

  command result_t StdControl.stop() 
  {
    TOSH_SET_MIC_CTL_PIN();
    return SUCCESS;
  }

  command result_t Mic.MicOn()
  {
    TOSH_CLR_MIC_CTL_PIN();
	TOSH_uwait(100);
    return SUCCESS;
  }
  
  command result_t Mic.MicOff()
  {
    TOSH_SET_MIC_CTL_PIN();
    return SUCCESS;
  }
  command result_t Mic.LPFsetFreq(uint8_t freq)
  {
    TOSH_CLR_I2C_MUX_PIN();

    call I2CPot.writePot(TOS_LPF_POT_ADDR, 0, freq);
    call I2CPot.writePot(TOS_LPF_POT_ADDR, 1, freq);

    return SUCCESS;
  }
  
  command result_t Mic.HPFsetFreq(uint8_t freq)
  {
    TOSH_CLR_I2C_MUX_PIN();

    call I2CPot.writePot(TOS_HPF_POT_ADDR, 0, freq/2);
    call I2CPot.writePot(TOS_HPF_POT_ADDR, 1, freq);

    return SUCCESS;
  }

  command result_t Mic.detectAdjust(uint8_t val)
  {
    TOSH_CLR_I2C_MUX_PIN();
    return call I2CPot.writePot(TOS_MIC_POT_ADDR, 1, val);
  }

  command result_t Mic.gainAdjust(uint8_t val)
  {
    TOSH_CLR_I2C_MUX_PIN();
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

