/**
 * Compass - Copyright (c) 2003 ISIS
 *
 * Author: Peter Volgyesi, based on UCB work (Cory Sharp)
 **/
 


module SmartMagM {
  provides {
    interface StdControl;
    interface SmartMag;
  }
  uses {
    interface StdControl as MagControl;
    interface MagSetting;
    interface ADC as MagX;
    interface ADC as MagY;
  }
}
implementation {

  /** 
   * state variables
   */
  MagValue values;
  uint8_t  new_biasX;
  uint8_t  new_biasY;
  bool	busy;
  uint16_t sm_bias_center;
  uint16_t sm_bias_scale;
  
  uint8_t calc_new_bias(uint8_t oldbias, uint16_t sample)
  {
    if( sample < sm_bias_center ) {
      uint16_t delta = (sm_bias_center - sample) / sm_bias_scale;
      return (oldbias < delta) ? 0 : (oldbias - (uint8_t)delta);
    }
    else {
      uint16_t delta = (sample - sm_bias_center) / sm_bias_scale;
      return ((255 - oldbias) < delta) ? 255 : (oldbias + (uint8_t)delta);
    }
  }

  task void process_new_mag_reading()
  {
    new_biasX = calc_new_bias(values.biasX, values.X);
    new_biasY = calc_new_bias(values.biasY, values.Y);

    call MagSetting.gainAdjustX(new_biasX);
    
    // assumed that m_mag is reset to new values upon reentry
    values.X += sm_bias_scale * values.biasX;
    values.Y += sm_bias_scale * values.biasY;

    signal SmartMag.readDone(&values);
  }

  /**
   * Initialize the component.
   **/
  command result_t StdControl.init() {
    call MagControl.init();
    
    sm_bias_center = SM_BIAS_CENTER;
    sm_bias_scale = SM_BIAS_SCALE;
    busy = FALSE;
    new_biasX = new_biasY = 0;
    
    // Is it safe to do this ?
    call MagSetting.gainAdjustX(new_biasX); // gainAdjustX will be called automatically
    
    return SUCCESS;
  }


  /**
   * Start things up.
   **/
  command result_t StdControl.start() {
    return call MagControl.start();
  }

  /**
   * Halt execution of the application.
   **/
  command result_t StdControl.stop() {
    return call MagControl.stop();
  }
  
  /**
   * Get new data.
   **/
  command result_t SmartMag.read()
  {

    if( busy ) {
     return FAIL;
     }     

    busy = TRUE;    values.biasX = new_biasX;
    values.biasY = new_biasY;
    return call MagX.getData();

  }
  
  /**
   * Calibrate.
   **/
  command result_t SmartMag.calibrate(uint16_t bias_center, uint16_t bias_scale)
  {
    sm_bias_center = bias_center;
    sm_bias_scale = bias_scale;
    return SUCCESS;
  }
  
  /**
   * Signalled when data is ready from the MAG.
   */
  event result_t MagX.dataReady(uint16_t data) {
    values.X = data;
    call MagY.getData();
    return SUCCESS;
  }
  
  event result_t MagY.dataReady(uint16_t data) {
    values.Y = data;
    post process_new_mag_reading();
    return SUCCESS;
  }
  
  
  /** 
   * Pot adjustment on the Y axis of the magnetometer is finished.
   */
  event result_t MagSetting.gainAdjustXDone(bool result)
  {
  	call MagSetting.gainAdjustY(new_biasY);
  	return SUCCESS;
  }

  /**
   * Pot adjustment on the Y axis of the magnetometer is finished.
   */
  event result_t MagSetting.gainAdjustYDone(bool result)
  {
  	busy = FALSE;
  	return SUCCESS;
  }  
}
