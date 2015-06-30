/*
 *
 * Authors:  Mike Grimmer
 * Revision:		$Rev$
 *
 */


includes sensorboard;
module MagM 
{
  provides interface StdControl;
  provides interface MagSetting;
  uses 
  {
    interface ADCControl;
    interface StdControl as PotControl;
    interface I2CPot;
  }
}
implementation 
{
  bool Xaxis;

  command result_t StdControl.init() 
  {
    call ADCControl.bindPort(TOS_ADC_MAG_X_PORT, TOSH_ACTUAL_MAG_X_PORT);
    call ADCControl.bindPort(TOS_ADC_MAG_Y_PORT, TOSH_ACTUAL_MAG_Y_PORT);
    TOSH_SET_MAG_CTL_PIN();
	TOSH_CLR_MAG_SR_PIN();
    call ADCControl.init();
    call PotControl.init();
	Xaxis = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start() 
  {
    TOSH_CLR_MAG_CTL_PIN();
    /////// --lin    TOSH_SET_MAG_CTL_PIN();
	TOSH_CLR_MAG_SR_PIN();
    return SUCCESS;
  }

  command result_t StdControl.stop() 
  {
    TOSH_SET_MAG_CTL_PIN();
    TOSH_uwait(1);
    TOSH_CLR_MAG_SR_PIN();
    return SUCCESS;
  }

  command result_t MagSetting.setReset()
  {
	TOSH_SET_MAG_SR_PIN();
	TOSH_uwait(1);
	TOSH_CLR_MAG_SR_PIN();
    return SUCCESS;
  }

  command result_t MagSetting.gainAdjustX(uint8_t val)
  {
    Xaxis = TRUE;
    TOSH_SET_I2C_MUX_PIN();
    return call I2CPot.writePot(TOS_MAG_POT_ADDR, 0, val);
  }

  command result_t MagSetting.gainAdjustY(uint8_t val)
  {
    Xaxis = FALSE;
    TOSH_SET_I2C_MUX_PIN();
    return call I2CPot.writePot(TOS_MAG_POT_ADDR, 1, val);
  }
/*
  event result_t Mag.gainAdjustXDone(result_t result)
  {
    return result;
  }

  event result_t Mag.gainAdjustYDone(result_t result)
  {
    return result;
  }
*/

  event result_t I2CPot.readPotDone(char data, bool result)
  {
    return result;
  }

  event result_t I2CPot.writePotDone(bool result)
  {
    result_t ok;

	if (result == TRUE)
	  ok = SUCCESS;
	else
	  ok = FAIL;
    if (Xaxis)
	  signal MagSetting.gainAdjustXDone(ok);
    else
	  signal MagSetting.gainAdjustYDone(ok);

    return result;
  }

}

