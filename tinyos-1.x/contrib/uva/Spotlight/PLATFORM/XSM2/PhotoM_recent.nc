/*
 *
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 */

/*  OS component abstraction of the analog photo sensor and */
/*  associated A/D support.  It provides an asynchronous interface */
/*  to the photo sensor. */

/*  PHOTO_INIT command initializes the device */
/*  PHOTO_GET_DATA command initiates acquiring a sensor reading. */
/*  It returns immediately.   */
/*  PHOTO_DATA_READY is signaled, providing data, when it becomes */
/*  available. */
/*  Access to the sensor is performed in the background by a separate */
/* TOS task. */

includes sensorboard;
module PhotoM 
{
  provides interface StdControl as PhotoStdControl;
  provides interface ADC as ExternalPhotoADC;
  uses 
  {
    interface ADCControl;
    interface ADC as InternalPhotoADC;
  }
}

implementation 
{
  enum
  {
    IDLE = 1,
    BUSY = 2,
    CONTINUOUS = 3
  };
  int state;

  command result_t PhotoStdControl.init() 
  {
    call ADCControl.bindPort(TOS_ADC_PHOTO_PORT, TOSH_ACTUAL_PHOTO_PORT);
    atomic 
	{
      state = IDLE;
    }
    dbg(DBG_BOOT, "PHOTO initialized.\n");    
    return call ADCControl.init();
  }

  command result_t PhotoStdControl.start() 
  {
    atomic 
	{
      TOSH_SET_PHOTO_CTL_PIN();
      TOSH_MAKE_PHOTO_CTL_OUTPUT();
    }
    return SUCCESS;
  }

  command result_t PhotoStdControl.stop() 
  {
    atomic 
	{
      TOSH_CLR_PHOTO_CTL_PIN();
      TOSH_MAKE_PHOTO_CTL_INPUT();
    }
    return SUCCESS;
  }

  async command result_t ExternalPhotoADC.getData()
  {
    uint8_t oldState;
    atomic 
	{
      oldState = state;
      if (state == IDLE) 
	  {
	    state = BUSY;
      }
    }
    if (oldState == IDLE)
	{
      TOSH_SET_PHOTO_CTL_PIN();
      TOSH_MAKE_PHOTO_CTL_OUTPUT();
      return call InternalPhotoADC.getData();
    }
    return FAIL;
  }

  async command result_t ExternalPhotoADC.getContinuousData()
  {
    uint8_t oldState;
    atomic 
	{
      oldState = state;
      if (state == IDLE) 
	  {
        state = CONTINUOUS;
      }
    }
    if (oldState == IDLE)
	{
      TOSH_SET_PHOTO_CTL_PIN();
      TOSH_MAKE_PHOTO_CTL_OUTPUT();
      return call InternalPhotoADC.getContinuousData();     
    }
    return FAIL;
  }

  default async event result_t ExternalPhotoADC.dataReady(uint16_t data) 
  {
    return SUCCESS;
  }

  async event result_t InternalPhotoADC.dataReady(uint16_t data)
  {
    uint8_t oldState;
    atomic 
	{
      oldState = state;
      if (state == BUSY) 
	  {
	    state = IDLE;
      }
    }
    if (oldState == BUSY)
	{
      return signal ExternalPhotoADC.dataReady(data);
    }
	else if (oldState == CONTINUOUS)
	{
      int ret;
      ret = signal ExternalPhotoADC.dataReady(data);
      if (ret == FAIL)
	  {
	    atomic 
		{
	      state = IDLE;
	    }
      }
      return ret;
    }
    return FAIL;
  }

}
