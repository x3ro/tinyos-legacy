

/*
 *
 * Authors:		Joe Polastre
 *
 */

includes sensorboard;

module IntersemaPressureM {
  provides {
    interface ADC as Temperature;
    interface ADC as Pressure;
    interface SplitControl;
    interface Calibration;
  }
  uses {
    interface StdControl as SwitchControl;
    interface StdControl as LowerControl;
    interface Calibration as LowerCalibrate;
    interface Switch;
    interface Switch as IOSwitch;
    interface ADC as LowerPressure;
    interface ADC as LowerTemp;
    interface Timer;
    interface StdControl as TimerControl;
  }
}

implementation {

  #include "SODebug.h"  
  #define DBG_USR2 0  //disables printf msgs

  enum { IDLE,
         WARM_UP,
         WAIT_SWITCH_ON,
         WAIT_SWITCH_OFF,
         BUSY, 
	 MAIN_SWITCH_ON,
         MAIN_SWITCH_OFF,
         SWITCH_IO1,
         SWITCH_IO2,
         SWITCH_IO3, 
	 POWERON,
         POWEROFF,
         IOON = 1,
         IOOFF = 0 };

  // FIXME: Remove the norace and fix the rest of the atomic r/w warnings.
  norace char state;
  char sensor;
  char iostate;
  char c_word;

  uint16_t temp,pressure;
  uint16_t c_value;


  task void initDone() {
	signal SplitControl.initDone();
  }

  task void stopDone() {
 	signal SplitControl.stopDone();
  }

  task void startDone(){
    signal SplitControl.startDone();
  }


#if 1
  /** The #define'd MICAWB_PRESSURE_* are in sensorboard.h.
   * iostate is IOON = 1, IOOF = 0.  Somehow, this is
   * screwing up the GPS unit from reading.
   */
  task void IOBus() {

    if (state == BUSY) {

      state = SWITCH_IO1;
      atomic {
      call IOSwitch.set(MICAWB_PRESSURE_SCLK, iostate);
    }
    }
    else if (state == SWITCH_IO1) {
	  SODbg(DBG_USR2, "IntersemaPressure.IoBus.SCLK switch set \n"); 
      state = SWITCH_IO2;
      atomic {
      call IOSwitch.set(MICAWB_PRESSURE_DIN, iostate);
    }
    }
    else if (state == SWITCH_IO2) {
	  SODbg(DBG_USR2, "IntersemaPressure.IoBus.Din switch set \n"); 
      state = SWITCH_IO3;
      atomic {
      call IOSwitch.set(MICAWB_PRESSURE_DOUT, iostate);
      }
    } else if (state == SWITCH_IO3) {

      SODbg(DBG_USR2, "IntersemaPressure.IOBus.all switches set \n"); 
      state = IDLE;
      atomic {
        if (iostate == IOOFF){
	   call LowerControl.stop();
    	   post stopDone();
        } else {
       	   post startDone();
        }
      }
    }
    
//    else if (iostate == IOOFF) {
//	      call LowerControl.stop();
//	      state = IDLE;
//	  post stopDone();
//      state = POWEROFF;



    //}

  }
#endif

command result_t SplitControl.init() {
    state = IDLE;
    atomic {
      iostate = IOOFF;
    }
    call LowerControl.init();
    call SwitchControl.init();
    call TimerControl.init();
    post initDone();
    return SUCCESS;
  }

  command result_t SplitControl.start() {
    SODbg(DBG_USR2, "IntersemaPressureM.SplitControl.start: turning on power \n"); 
    state = MAIN_SWITCH_ON;
    call SwitchControl.start();
    if (call Switch.set(MICAWB_PRESSURE_POWER,1) != SUCCESS) {
      state = WAIT_SWITCH_ON;
    }
    return SUCCESS;
  }

  command result_t SplitControl.stop() {

    SODbg(DBG_USR2, "IntersemaPressureM.SplitControl.stop: turning off power \n"); 
    state = MAIN_SWITCH_OFF;
    call SwitchControl.start();
    if (call Switch.set(MICAWB_PRESSURE_POWER,0) != SUCCESS) {
      SODbg(DBG_USR2, "IntersemaPressureM.SplitControl.stop: failed to get bus \n"); 
      state = WAIT_SWITCH_OFF;
    }
    return SUCCESS;
  }


 
  event result_t Switch.getDone(char value) {
    return SUCCESS;
  }

  event result_t Switch.setDone(bool l_result) {
    
    if (state == WAIT_SWITCH_ON) {
	SODbg(DBG_USR2, "IntersemaPressureM.Switch.setDone(): WAIT_SWITCH_ON\n"); 
      if (call Switch.set(MICAWB_PRESSURE_POWER,1) == SUCCESS) {
	     state = MAIN_SWITCH_ON;
      }
    }
    else if (state == WAIT_SWITCH_OFF) {
	SODbg(DBG_USR2, "IntersemaPressureM.Switch.setDone(): WAIT_SWITCH_OFF\n"); 
      if (call Switch.set(MICAWB_PRESSURE_POWER,0) == SUCCESS) {
	     state = MAIN_SWITCH_OFF;
      }
    }
    else if (state == MAIN_SWITCH_ON) {

	SODbg(DBG_USR2, "IntersemaPressureM.Switch.setDone(): MAIN_SWITCH_ON\n"); 
        atomic {
          iostate = IOON;
        }
	state = BUSY;
        post IOBus();          //turn on other switches
	return SUCCESS;
    }
    else if (state == MAIN_SWITCH_OFF) {
	SODbg(DBG_USR2, "IntersemaPressureM.Switch.setDone(): MAIN_SWITCH_OFF\n"); 
        state = BUSY;
        atomic {
          iostate = IOOFF;
        }
	post IOBus();	  
	//post stopDone();
        //state = POWEROFF;
    }
    return SUCCESS;
  }

  event result_t Switch.setAllDone(bool l_result) {
    return SUCCESS;
  }

  event result_t IOSwitch.getDone(char value) {
    return SUCCESS;
  }


//turn on/off all the I/O switches
  event result_t IOSwitch.setDone(bool l_result) {

    SODbg(DBG_USR2, "IntersemaPressure.IOSwitch.setDone() \n"); 

    if ((state == SWITCH_IO1) || (state == SWITCH_IO2) || (state == SWITCH_IO3)) {
      post IOBus();
    }
    return SUCCESS;
  }

  event result_t IOSwitch.setAllDone(bool l_result) {
    return SUCCESS;
  }


 event result_t Timer.fired() {
   if (state == WARM_UP) {
      SODbg(DBG_USR2, "IntersemaPressure.Timer.fired \n"); 
      state = BUSY;
      post IOBus();
   }
   return SUCCESS;
  }


 task void startLowerTemp() {
   call LowerControl.start();
   call LowerTemp.getData();
 }

/******************************************************************************
 * Get temperature or pressure data from sensor
 *****************************************************************************/
async  command result_t Temperature.getData() {
    if (state == IDLE)
    {
      state = BUSY;

      //call LowerControl.start();
      //call LowerTemp.getData();
      post startLowerTemp();
      return SUCCESS;
    }
    return FAIL;
  }

  async event result_t LowerTemp.dataReady(uint16_t data) {
    
    atomic {
      state = IDLE;
    }
    signal Temperature.dataReady(data);
    return SUCCESS;
  }


  task void startLowerPressure() {

     call LowerControl.start();
     call LowerPressure.getData();
  }

 async command result_t Pressure.getData() {

    if (state == IDLE) {

      state = BUSY;
      atomic {
        sensor = MICAWB_PRESSURE;
        iostate = IOON;
      }
      //call LowerControl.start();
      //call LowerPressure.getData();
      post startLowerPressure();
      return SUCCESS;
    }
    return FAIL;
  }

 async event result_t LowerPressure.dataReady(uint16_t data) {
    state = IDLE;
    signal Pressure.dataReady(data);
    return SUCCESS;
  }

  // no such thing
 async command result_t Temperature.getContinuousData() {
    return FAIL;
  }

  // no such thing
 async command result_t Pressure.getContinuousData() {
    return FAIL;
  }

 default async event result_t Temperature.dataReady(uint16_t data)
  {
    return SUCCESS;
  }

 default async event result_t Pressure.dataReady(uint16_t data)
  {
    return SUCCESS;
  }

/******************************************************************************
 * Read calibration words (4) from sensor
 *****************************************************************************/
   command result_t Calibration.getData() {

     if (state == IDLE) {

	 SODbg(DBG_USR2, "IntersemaPressure.Calibration.getData \n"); 
         state = BUSY;
         call LowerControl.start();
         call LowerCalibrate.getData();
         return SUCCESS;
       }
       return FAIL;  
   }

 // on the last byte of calibration data, shut down the I/O interface
// async event result_t LowerCalibrate.dataReady(char word, uint16_t value) {
  event result_t LowerCalibrate.dataReady(char word, uint16_t value) {

    if (word == 4) {
      call LowerControl.stop();
      atomic {
        state = IDLE;
      }
      signal Calibration.dataReady(word, value);
    }
    else {
	  call LowerControl.stop();
      signal Calibration.dataReady(word, value);
    }
    return SUCCESS;
  }

// default async event result_t Calibration.dataReady(char word, uint16_t value) {
 default event result_t Calibration.dataReady(char word, uint16_t value) {

    return SUCCESS;
  }

}

