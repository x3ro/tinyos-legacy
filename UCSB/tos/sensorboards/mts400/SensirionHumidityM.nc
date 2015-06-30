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
 * $Id: SensirionHumidityM.nc,v 1.1.1.1 2006/05/04 23:08:24 ucsbsensornet Exp $
 */

includes sensorboard;
module SensirionHumidityM {
  provides {
    interface ADC as Humidity;
    interface ADC as Temperature;
    interface SplitControl;
    interface ADCError as HumidityError;
    interface ADCError as TemperatureError;
  }
  uses {
    interface ADC as HumSensor;
    interface ADC as TempSensor;
    interface ADCError as HumError;
    interface ADCError as TempError;
    interface StdControl as SensorControl;

    interface Timer;
    interface StdControl as SwitchControl;
    interface Switch as Switch1;
    interface Switch as SwitchI2W;
	interface Leds;
  }
}
implementation {

#include "SODebug.h"  
#define DBG_USR2  0  

  enum {IDLE, BUSY, BUSY_0, BUSY_1, GET_SAMPLE_0, GET_SAMPLE_1,
        OPENSCK, OPENDATA, CLOSESCK, CLOSEDATA,  POWEROFF,
	MAIN_SWITCH_ON, MAIN_SWITCH_OFF, WAIT_SWITCH_ON, WAIT_SWITCH_OFF, TIMER};

  char state;
  char id;
  char tempvalue;
  uint16_t result;
  bool power;

  task void initDone() {
    signal SplitControl.initDone();
  }

  command result_t SplitControl.init() {
    atomic {
    	state = POWEROFF;
    	power = FALSE;
    }
    call SensorControl.init();
    call SwitchControl.init();
    post initDone();
    return SUCCESS;
  }

  command result_t SplitControl.start() {
    // turn the sensor on
    atomic state = MAIN_SWITCH_ON;
    call SensorControl.start();
    call SwitchControl.start();
    if (call Switch1.set(MICAWB_HUMIDITY_POWER,1) != SUCCESS) {
      atomic state = WAIT_SWITCH_ON;
    }
    return SUCCESS;
  }

  command result_t SplitControl.stop() {
    atomic {
    	power = FALSE;
    	state = MAIN_SWITCH_OFF;
    }
    // turn the sensor off
    if (call Switch1.set(MICAWB_HUMIDITY_POWER,0) != SUCCESS) {
      atomic state = WAIT_SWITCH_OFF;
    }
    return call SensorControl.stop();
  }

  event result_t Switch1.getDone(char value) {
    return SUCCESS;
  }

  event result_t Switch1.setDone(bool local_result) {
  	char l_state;
  	atomic l_state = state;

    if (l_state == MAIN_SWITCH_ON) {
      atomic state = IDLE;
      signal SplitControl.startDone();
    }
    else if (l_state == MAIN_SWITCH_OFF) {
      atomic state = POWEROFF;
      signal SplitControl.stopDone();
    }
    else if (l_state == WAIT_SWITCH_ON) {
        if (call Switch1.set(MICAWB_HUMIDITY_POWER,1) == SUCCESS) {
	    atomic state = MAIN_SWITCH_ON;
      }
    }
    else if (l_state == WAIT_SWITCH_OFF) {
      if (call Switch1.set(MICAWB_HUMIDITY_POWER,0) == SUCCESS) {
	atomic state = MAIN_SWITCH_OFF;
      }
    }
    return SUCCESS;
  }

  event result_t Switch1.setAllDone(bool local_result) {
    return SUCCESS;
  }

  event result_t SwitchI2W.getDone(char value) {
    return SUCCESS;
  }

  event result_t SwitchI2W.setDone(bool local_result) {
  	char l_state;
  	atomic l_state = state;
    
//	    SODbg(DBG_USR2, "SensirionHumidityM.SwitchI2W: state: %i \n", state);
	if (l_state == OPENSCK) {                                //SCK line enabled
        atomic state = OPENDATA;
        return call SwitchI2W.set(MICAWB_HUMIDITY_DATA,1);
    } else if (l_state == OPENDATA) {                       //Data line enabled
        atomic state = TIMER;
        SODbg(DBG_USR2, "SensirionHumidityM.SwitchI2W: Timer Started \n");      

        return call Timer.start(TIMER_ONE_SHOT, 100);
    } else if (l_state == CLOSESCK) {
        atomic state = CLOSEDATA;
        return call SwitchI2W.set(MICAWB_HUMIDITY_DATA,0);
    } else if (l_state == CLOSEDATA) {
        uint16_t l_result;
        char l_id;
        atomic {
        	l_result = result;
        	atomic state = IDLE;
        	l_id = id;
        }
	    if (l_id == MICAWB_HUMIDITY){
	       signal Humidity.dataReady(l_result);         //everything complete, humidity data ready
	    }
	    else if (l_id == MICAWB_HUMIDITY_TEMP)
	       signal Temperature.dataReady(l_result);     //everything complete, temp data ready
        }
        return SUCCESS;
  }

  event result_t Timer.fired() {
  	uint8_t l_id;
  	
       atomic {
       	state = BUSY;
       	l_id = id;
       }
      if (l_id == MICAWB_HUMIDITY)
      {
	      SODbg(DBG_USR2, "SensirionHumidityM.Timer.fired: get humidity data \n"); 
		 return call HumSensor.getData();

      }
      else if (l_id == MICAWB_HUMIDITY_TEMP)
      {
	      return call TempSensor.getData();
      }
      atomic state = IDLE;
      return SUCCESS;
  }


event result_t SwitchI2W.setAllDone(bool local_result) {
    return SUCCESS;
  }

  // no such thing
async command result_t Humidity.getContinuousData() {
    return FAIL;
  }

  // no such thing
async  command result_t Temperature.getContinuousData() {
    return FAIL;
  }

async  command result_t Humidity.getData() {
	char l_state;
	atomic l_state = state;
	if (l_state == IDLE)
    {
      atomic {
      	id = MICAWB_HUMIDITY;
      	state = OPENSCK;
      }
      return call SwitchI2W.set(MICAWB_HUMIDITY_SCLK,1);
    } 
	atomic state = IDLE;
    return FAIL;
  }

async  command result_t Temperature.getData() {
	char l_state;
	atomic l_state = state;
    if (l_state == IDLE)
    {
      atomic {
      	id = MICAWB_HUMIDITY_TEMP;
      	state = OPENSCK;
      }
      return call SwitchI2W.set(MICAWB_HUMIDITY_SCLK,1);
    }
    atomic state = IDLE;
    return FAIL;
  }

// 12/11/2003
//  async event result_t Humidity.dataReady(uint16_t data)
//  {
//    return SUCCESS;
//  }

  default async event result_t Temperature.dataReady(uint16_t data)
  {
    return SUCCESS;
  }

 async event result_t TempSensor.dataReady(uint16_t data) {
 	char l_state;
 	
    atomic {
    	result = data;
    	l_state = state;
    }
    if (l_state == BUSY) {
      atomic state = CLOSESCK;
      return call SwitchI2W.set(MICAWB_HUMIDITY_SCLK,0);
    }
    return SUCCESS;
  }

/******************************************************************************
 * HumSensor.dataReady
 *  -Data ready from humidity sensor
 *  -Start to turn-off SCK,SDA serial lines
 ******************************************************************************/
 async event result_t HumSensor.dataReady(uint16_t data) {
 	char l_state;
 	
//    SODbg(DBG_USR2, "SensirionHumidityM.HumSensor.dataReady: data ready \n");
	atomic {
		result = data;
		l_state = state;
	}
    if (l_state == BUSY) {
      atomic state = CLOSESCK;
      return call SwitchI2W.set(MICAWB_HUMIDITY_SCLK,0);
    }
    return SUCCESS;
  }

  command result_t HumidityError.enable() {
    return call HumError.enable();
  }

  command result_t HumidityError.disable() {
    return call HumError.disable();
  }

  command result_t TemperatureError.enable() {
    return call TempError.enable();
  }

  command result_t TemperatureError.disable() {
    return call TempError.disable();
  }

 event result_t HumError.error(uint8_t token) {
    atomic state = IDLE;
    call SensorControl.stop();
    return signal HumidityError.error(token);
  }

 event result_t TempError.error(uint8_t token) {
    atomic state = IDLE;
    call SensorControl.stop();
    return signal TemperatureError.error(token);
  }

  default  event result_t HumidityError.error(uint8_t token) { return SUCCESS; }

  default event result_t TemperatureError.error(uint8_t token) { return SUCCESS;
 }

}

