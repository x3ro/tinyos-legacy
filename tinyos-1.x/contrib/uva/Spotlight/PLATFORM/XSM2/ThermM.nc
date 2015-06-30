/*
 *
 * Authors:  Mike Grimmer
 * Revision:		$Rev$
 *
 */
includes sensorboard;
module ThermM 
{
  provides interface StdControl;
  provides interface Therm;
  uses 
  {
    interface ADCControl;
  }
}
implementation 
{
  command result_t StdControl.init() 
  {
    call ADCControl.bindPort(TOS_ADC_PHOTO_PORT, TOSH_ACTUAL_PHOTO_PORT);
    call ADCControl.init();
    TOSH_MAKE_PHOTO_CTL_INPUT();
	TOSH_CLR_PHOTO_CTL_PIN();
    TOSH_MAKE_THERM_PWR_INPUT();
	TOSH_CLR_THERM_PWR_PIN();
    return SUCCESS;
  }

  command result_t StdControl.start() 
  {
    TOSH_MAKE_THERM_PWR_INPUT();
    TOSH_CLR_THERM_PWR_PIN();

    return SUCCESS;
  }

  command result_t StdControl.stop() 
  {
    TOSH_MAKE_THERM_PWR_INPUT();
    TOSH_CLR_THERM_PWR_PIN();
    return SUCCESS;
  }

  command result_t Therm.On() 
  {
    TOSH_MAKE_PHOTO_CTL_INPUT();
	TOSH_CLR_PHOTO_CTL_PIN();
    TOSH_MAKE_THERM_PWR_OUTPUT();
    TOSH_SET_THERM_PWR_PIN();
    return SUCCESS;
  }

  command result_t Therm.Off() 
  {
    TOSH_MAKE_PHOTO_CTL_INPUT();
	TOSH_CLR_PHOTO_CTL_PIN();
    TOSH_MAKE_THERM_PWR_INPUT();
    TOSH_CLR_THERM_PWR_PIN();
    return SUCCESS;
  }

}

