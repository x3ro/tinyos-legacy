/*
 *
 * Authors:    Mike Grimmer
 * Date last modified:  3/15/04
 *
 */

includes sensorboard;
module PhotoM 
{
  provides interface StdControl;
  provides interface Photo;
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
	TOSH_MAKE_PHOTO_CTL_INPUT();
	TOSH_CLR_PHOTO_CTL_PIN();
	TOSH_MAKE_THERM_PWR_INPUT();
	TOSH_CLR_THERM_PWR_PIN();

    return call ADCControl.init();
  }

  command result_t StdControl.start() 
  {
    atomic 
	{
      TOSH_MAKE_THERM_PWR_INPUT();
      TOSH_CLR_THERM_PWR_PIN();
      TOSH_MAKE_PHOTO_CTL_INPUT();
      TOSH_CLR_PHOTO_CTL_PIN();
    }
    return SUCCESS;
  }

  command result_t StdControl.stop() 
  {
    atomic 
	{
      TOSH_CLR_PHOTO_CTL_PIN();
      TOSH_MAKE_PHOTO_CTL_INPUT();
    }
    return SUCCESS;
  }

  command result_t Photo.On()
  {
    atomic 
	{
      TOSH_MAKE_THERM_PWR_INPUT();
      TOSH_CLR_THERM_PWR_PIN();
      TOSH_MAKE_PHOTO_CTL_OUTPUT();
      TOSH_SET_PHOTO_CTL_PIN();
    }
    return SUCCESS;
  }

  command result_t Photo.Off()
  {
    atomic 
	{
      TOSH_MAKE_THERM_PWR_INPUT();
      TOSH_CLR_THERM_PWR_PIN();
      TOSH_MAKE_PHOTO_CTL_INPUT();
      TOSH_CLR_PHOTO_CTL_PIN();
    }
    return SUCCESS;
  }

}
