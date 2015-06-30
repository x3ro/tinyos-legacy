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
 * $Id: IntersemaLowerM.nc,v 1.2 2004/07/16 21:54:39 ammbot Exp $
 */

includes sensorboard;
includes hardware; 
module IntersemaLowerM {
  provides {
    interface ADC as Pressure;
    interface ADC as Temp;
    interface ADCError as PressError;
    interface ADCError as TempError;
    interface StdControl;
    interface Calibration;
  }
  uses {
//    interface StdControl as FlashControl;
    interface Timer;
    interface StdControl as TimerControl;
  }
}
implementation {

  enum { IDLE=7, RESET=8, CALIBRATE=9, TEMP=10, PRESSURE=11, DATA_READY=12 };
  
  char state;
  char sensor;
  
  uint16_t calibration[4];
  uint16_t reading;

  uint8_t timeout;
  uint8_t errornum;

  bool presserror, temperror;

  void task signalPressError() {
    signal PressError.error(errornum);
  }

  void task signalTempError() {
    signal TempError.error(errornum);
  }

  void pulse_clock() {
    TOSH_wait_250ns(); TOSH_wait_250ns();
    PRESSURE_SET_CLOCK();
    TOSH_wait_250ns(); TOSH_wait_250ns();
    PRESSURE_CLEAR_CLOCK();
  }

  char din_value() {
    return PRESSURE_READ_IN_PIN();
  }

  char read_bit() {
    char i;
    PRESSURE_CLEAR_OUT_PIN();
    PRESSURE_SET_CLOCK();
    TOSH_wait_250ns(); TOSH_wait_250ns();
    i = PRESSURE_READ_IN_PIN();
    PRESSURE_CLEAR_CLOCK();
    return i;
  }

  void write_bit(bool bit) {
    if (bit)
      PRESSURE_SET_OUT_PIN();
    else
      PRESSURE_CLEAR_OUT_PIN();
    pulse_clock();
  }

  // resets the intersema device
  void spi_reset() {
    int i = 0;
    for (i = 0; i < 21; i++) {
      if (i < 16) {
	if ((i % 2) == 0) {
	  write_bit(TRUE);
	}
	else {
	  write_bit(FALSE);
	}
      }
      else {
	write_bit(FALSE);
      }
    } 
  }

  uint16_t adc_read() {
    uint16_t result = 0;
    uint16_t tresult = 0;
    char i;
    
    TOSH_wait_250ns();
    for (i = 0; i < 16; i++) {
      tresult = (uint16_t)read_bit();
      tresult = tresult << (15-i);
      result += tresult;
    }
    return result;      
  }

  uint16_t spi_word(char num) {
    int i;
    TOSH_wait_250ns(); TOSH_wait_250ns();
    
    // write first byte
    for (i = 0; i < 3; i++) {
      write_bit(TRUE);
    }
    write_bit(FALSE);
    write_bit(TRUE);
    if (num == 1) {
      write_bit(FALSE);
      write_bit(TRUE);
      write_bit(FALSE);
      write_bit(TRUE);
    }
    else if (num == 2) {
      write_bit(FALSE);
      write_bit(TRUE);
      write_bit(TRUE);
      write_bit(FALSE);
    }
    else if (num == 3) {
      write_bit(TRUE);
      write_bit(FALSE);
      write_bit(FALSE);
      write_bit(TRUE);
    }
    else if (num == 4) {
      write_bit(TRUE);
      write_bit(FALSE);
      write_bit(TRUE);
      write_bit(FALSE);
    }
    for (i = 0; i < 4; i++) 
      write_bit(FALSE);
    
    TOSH_wait_250ns();
    
    return adc_read();
  }

  void task gotInterrupt() {
    uint16_t l_reading;
    bool l_sensor;
    
	reading = adc_read();
    l_reading = reading;

    // we're done, so we can be idle
    atomic state = IDLE;
    
    atomic l_sensor = sensor;
    
    // give the application the sensor data
    if (l_sensor == TEMP) {
      signal Temp.dataReady(l_reading);
    }
    else if (l_sensor == PRESSURE) {
      signal Pressure.dataReady(l_reading);
    }
  }

  void sense() {
    int i;
    bool l_sensor;
    
    TOSH_wait_250ns(); TOSH_wait_250ns();
    
    // write first byte
    for (i = 0; i < 3; i++) {
      write_bit(TRUE);
    }
    atomic l_sensor = sensor;
    if (l_sensor == PRESSURE) {
      write_bit(TRUE);
      write_bit(FALSE);
      write_bit(TRUE);
      write_bit(FALSE);
    }
    else if (l_sensor == TEMP) {
      write_bit(TRUE);
      write_bit(FALSE);
      write_bit(FALSE);
      write_bit(TRUE);
    }
    for (i = 0; i < 5; i++) {
      write_bit(FALSE);
    }

    timeout = 0;
    call Timer.start(TIMER_ONE_SHOT, 36);
  }

  event result_t Timer.fired() {
  	char l_sensor;
  	bool l_presserror,l_temperror;
  	
  	atomic {
  		l_sensor = sensor;
  		l_presserror = presserror;
  		l_temperror = temperror;
  	}
    if (PRESSURE_READ_IN_PIN() == 1) {
      timeout++;
      if (timeout > PRESSURE_TIMEOUT_TRIES) {
        if ((l_sensor == PRESSURE) && (l_presserror == TRUE)) {
          atomic errornum = 1;
          call Timer.stop();
          atomic state = IDLE;
          post signalPressError();
          return SUCCESS; 
        }
        else if ((l_sensor == TEMP) && (l_temperror == TRUE)) {
          atomic errornum = 1;
          call Timer.stop();
          atomic state = IDLE;
          post signalTempError();
          return SUCCESS; 
        }
      }
      call Timer.start(TIMER_ONE_SHOT, 20);
    }
    else {
      call Timer.stop();
      post gotInterrupt();
    }
    return SUCCESS;
  }

  task void SPITask() {
    char i, l_state, l_sensor;
    
    atomic {
    	l_state = state;
    	l_sensor = sensor;
    }

    if (l_state == RESET) {

      // if calibration is on, grab the calibration data
      if (l_sensor == CALIBRATE) {

	for (i = 0; i < 4; i++) {
	  // reset the device
	  spi_reset();
	  calibration[(int)i] = spi_word(i+1);
	}

	// we're done, so we can be idle
	atomic state = IDLE;

	// send the calibration data up to the application
	for (i = 0; i < 4; i++)
	  signal Calibration.dataReady(i+1, calibration[(int)i]);
	return;
      }
      else {
	// reset the device
	spi_reset();

	// grab the sensor reading and store it locally
	sense();
      }
    }
  }

  command result_t StdControl.init() {
    atomic {
    	state = IDLE;
    	presserror = temperror = FALSE;
    }
    call TimerControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    PRESSURE_MAKE_CLOCK_OUTPUT();
    PRESSURE_MAKE_IN_INPUT();
    PRESSURE_SET_IN_PIN();
    PRESSURE_MAKE_OUT_OUTPUT();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  // tells this module whether to report back the calibration data
  command result_t Calibration.getData() {
  	char l_state;
    
    atomic l_state = state;
  	
    if (l_state == IDLE) {
    	atomic {
    		state = RESET;
    		sensor = CALIBRATE;
    	}
    post SPITask();
    return SUCCESS;
    }
    return FAIL;
  }

  // no such thing
  async command result_t Pressure.getContinuousData() {
    return FAIL;
  }

  // no such thing
  async command result_t Temp.getContinuousData() {
    return FAIL;
  }

 async command result_t Pressure.getData() {
 	char l_state;
 	
 	atomic l_state = state;
    if (l_state == IDLE) {
      atomic {
      	state = RESET;
      	sensor = PRESSURE;
      }
      post SPITask();
      return SUCCESS;
    }
    return FAIL;
  }

 async command result_t Temp.getData() {
 	char l_state;
 	
 	atomic l_state = state;
    if (l_state == IDLE) {
      atomic {
      	state = RESET;
      	sensor = TEMP;
      }
      post SPITask();
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t PressError.enable() {
  	bool l_presserror;
  	atomic l_presserror = presserror;
  	
    if (l_presserror == FALSE) {
      atomic presserror = TRUE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t PressError.disable() {
  	bool l_presserror;
  	atomic l_presserror = presserror;
  	
    if (l_presserror == TRUE) {
      atomic presserror = FALSE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t TempError.enable() {
  	bool l_temperror;
  	atomic l_temperror = temperror;
  	
    if (l_temperror == FALSE) {
      atomic temperror = TRUE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t TempError.disable() {
  	bool l_temperror;
  	atomic l_temperror = temperror;
  	
    if (l_temperror == TRUE) {
      atomic temperror = FALSE;
      return SUCCESS;
    }
    return FAIL;
  }

  default event result_t PressError.error(uint8_t token) { return SUCCESS; }

  default event result_t TempError.error(uint8_t token) { return SUCCESS; }

  default async event result_t Pressure.dataReady(uint16_t data)
  {
    return SUCCESS;
  }

  default async event result_t Temp.dataReady(uint16_t data)
  {
    return SUCCESS;
  }

  // in case people don't want to use the calibration data
  default event result_t Calibration.dataReady(char word, uint16_t value)
  {
    return SUCCESS;
  }

}

