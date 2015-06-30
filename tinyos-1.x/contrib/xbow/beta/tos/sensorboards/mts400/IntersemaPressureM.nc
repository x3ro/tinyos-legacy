/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:		Joe Polastre
 *
 * $Id: IntersemaPressureM.nc,v 1.1 2004/10/11 22:10:54 mturon Exp $
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
  #define DBG_USR2    0               //disables printf msgs

  enum { IDLE, WARM_UP, WAIT_SWITCH_ON, WAIT_SWITCH_OFF, BUSY, 
	 MAIN_SWITCH_ON, MAIN_SWITCH_OFF, SWITCH_IO1, SWITCH_IO2, SWITCH_IO3, 
	 POWERON, POWEROFF, IOON = 1, IOOFF = 0 };

  char state;
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

  task void IOBus() {
  	char l_state, l_iostate;
  	
  	atomic {
  		l_state = state;
  		l_iostate = iostate;
  	}
    if (l_state == BUSY) {
      atomic state = SWITCH_IO1;
      call IOSwitch.set(MICAWB_PRESSURE_SCLK, l_iostate);
    }
    else if (l_state == SWITCH_IO1) {
//	  SODbg(DBG_USR2, "IntesemaPressure.IoBus.SCLK switch set \n"); 
      atomic state = SWITCH_IO2;
      call IOSwitch.set(MICAWB_PRESSURE_DIN, l_iostate);
    }
    else if (l_state == SWITCH_IO2) {
//	  SODbg(DBG_USR2, "IntesemaPressure.IoBus.Din switch set \n"); 
      atomic state = SWITCH_IO3;
      call IOSwitch.set(MICAWB_PRESSURE_DOUT, l_iostate);
    }
    else if (l_state == SWITCH_IO3) {
//	    SODbg(DBG_USR2, "IntesemaPressure.IOBus.all switches set \n"); 
		atomic state = IDLE;
		if (l_iostate == IOOFF){
	      call LowerControl.stop();
    	  post stopDone();
        }
        else {
       	 post startDone();
	    }
    }
//    else if (iostate == IOOFF) {
//	      call LowerControl.stop();
//	      state = IDLE;
//	  post stopDone();
//      state = POWEROFF;



    //}

  }


command result_t SplitControl.init() {
    atomic {
    	state = IDLE;
    	iostate = IOOFF;
    }
    call LowerControl.init();
    call SwitchControl.init();
	call TimerControl.init();
	post initDone();
	return SUCCESS;
  }

  command result_t SplitControl.start() {
//    SODbg(DBG_USR2, "IntesemaPressure.start: turning on power \n"); 
    atomic state = MAIN_SWITCH_ON;
    call SwitchControl.start();
    if (call Switch.set(MICAWB_PRESSURE_POWER,1) != SUCCESS) {
      atomic state = WAIT_SWITCH_ON;
    }
    return SUCCESS;
  }

  command result_t SplitControl.stop() {
//    SODbg(DBG_USR2, "IntesemaPressure.stop: turning off power \n"); 
    atomic state = MAIN_SWITCH_OFF;
    call SwitchControl.start();
    if (call Switch.set(MICAWB_PRESSURE_POWER,0) != SUCCESS) {
//      SODbg(DBG_USR2, "IntesemaPressure.stop: failed to get bus \n"); 
      atomic state = WAIT_SWITCH_OFF;
    }
    return SUCCESS;
  }


 
  event result_t Switch.getDone(char value) {
    return SUCCESS;
  }

  event result_t Switch.setDone(bool l_result) {
  	char l_state;
  	atomic l_state = state;
    
    if (l_state == WAIT_SWITCH_ON) {
      if (call Switch.set(MICAWB_PRESSURE_POWER,1) == SUCCESS) {
	     atomic state = MAIN_SWITCH_ON;
      }
    }
    else if (l_state == WAIT_SWITCH_OFF) {
      if (call Switch.set(MICAWB_PRESSURE_POWER,0) == SUCCESS) {
	     atomic state = MAIN_SWITCH_OFF;
      }
    }
    else if (l_state == MAIN_SWITCH_ON) {
//	  SODbg(DBG_USR2, "IntesemaPressure.start: power on, timer activated \n"); 
        atomic {
        	iostate = IOON;
        	state = BUSY;
        }
        post IOBus();          //turn on other switches
		return SUCCESS;
    }
    else if (l_state == MAIN_SWITCH_OFF) {
    	atomic {
        	state = BUSY;
        	iostate = IOOFF;
        }
		post IOBus();	  
//	  post stopDone();
//      state = POWEROFF;
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
  	atomic if ((state == SWITCH_IO1) || (state == SWITCH_IO2) || (state == SWITCH_IO3)) {
      post IOBus();
    }
    return SUCCESS;
  }

  event result_t IOSwitch.setAllDone(bool l_result) {
    return SUCCESS;
  }


 event result_t Timer.fired() {
 	char l_state;
 	atomic l_state = state;
   if (l_state == WARM_UP) {
//	    SODbg(DBG_USR2, "IntesemaPressure.Timer.fired \n"); 
		atomic state = BUSY;
        post IOBus();
   }
   return SUCCESS;
  }



/******************************************************************************
 * Get temperature or pressure data from sensor
 *****************************************************************************/
async  command result_t Temperature.getData() {
	char l_state;
 	atomic l_state = state;
    if (l_state == IDLE)
    {
      atomic state = BUSY;
      call LowerControl.start();
      call LowerTemp.getData();
      return SUCCESS;
    }
    return FAIL;
  }

 async event result_t LowerTemp.dataReady(uint16_t data) {
    atomic state = IDLE;
	signal Temperature.dataReady(data);
    return SUCCESS;
  }

 async command result_t Pressure.getData() {
	char l_state;
 	atomic l_state = state;
    if (l_state == IDLE)
    {
      atomic {
      	state = BUSY;
      	sensor = MICAWB_PRESSURE;
      	iostate = IOON;
      }
      call LowerControl.start();
	  call LowerPressure.getData();
      return SUCCESS;
    }
    return FAIL;
  }

  async event result_t LowerPressure.dataReady(uint16_t data) {
    atomic state = IDLE;
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
	char l_state;
 	atomic l_state = state;
	
    if (l_state == IDLE)
//	 SODbg(DBG_USR2, "IntesemaPressure.Calibration.getData \n"); 
    {
      atomic state = BUSY;
      call LowerControl.start();
	  call LowerCalibrate.getData();
      return SUCCESS;
    }
    return FAIL;
  }

 // on the last byte of calibration data, shut down the I/O interface
  event result_t LowerCalibrate.dataReady(char word, uint16_t value) {
    if (word == 4) {
      call LowerControl.stop();
	  atomic state = IDLE;
	  signal Calibration.dataReady(word, value);
    }
    else {
	  call LowerControl.stop();
      signal Calibration.dataReady(word, value);
    }
    return SUCCESS;
  }

  default event result_t Calibration.dataReady(char word, uint16_t value) {
    return SUCCESS;
  }

 
}

