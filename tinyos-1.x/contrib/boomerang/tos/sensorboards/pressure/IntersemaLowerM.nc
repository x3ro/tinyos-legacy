/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 *
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 *
 */
/*
 *
 * Authors:		Joe Polastre
 * Modifications for the Telos platform: Robert Szewczyk
 *
 * $Id: IntersemaLowerM.nc,v 1.1.1.1 2007/11/05 19:11:36 jpolastre Exp $
 */

//includes hardware; 
includes sensorboard;
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
    interface MSP430Interrupt as PressureInterrupt;
  }
}
implementation {
    MSP430REG_NORACE(P2DIR);MSP430REG_NORACE(P2SEL);
  enum { IDLE=7, RESET=8, CALIBRATE=9, TEMP=10, PRESSURE=11, DATA_READY=12 };
  
  norace char state;
  norace char sensor;
  
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
    char i;
    
    TOSH_wait_250ns();
    for (i = 0; i < 16; i++) {
 	result <<=1; 
 	if (read_bit()) { 
 	    result++; 
 	} 
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

    reading = adc_read();
    l_reading = reading;

    // we're done, so we can be idle
    state = IDLE;
    
    // give the application the sensor data
    if (sensor == TEMP) {
      signal Temp.dataReady(l_reading);
    }
    else if (sensor == PRESSURE) {
      signal Pressure.dataReady(l_reading);
    }
  }

  void sense() {
    int i;
    TOSH_wait_250ns(); TOSH_wait_250ns();
    
    // write first byte
    for (i = 0; i < 3; i++) {
      write_bit(TRUE);
    }
    if (sensor == PRESSURE) {
      write_bit(TRUE);
      write_bit(FALSE);
      write_bit(TRUE);
      write_bit(FALSE);
    }
    else if (sensor == TEMP) {
      write_bit(TRUE);
      write_bit(FALSE);
      write_bit(FALSE);
      write_bit(TRUE);
    }
    for (i = 0; i < 5; i++) {
      write_bit(FALSE);
    }

    timeout = 0;
    call Timer.start(TIMER_ONE_SHOT, 50);
    call PressureInterrupt.edge(FALSE);//trigger on the falling edge
    call PressureInterrupt.clear(); // any pending interrupts
    call PressureInterrupt.enable(); //enable interrupt flag
    
// kill busy waiting for now
//    while (PRESSURE_READ_IN_PIN() == 1) { TOSH_wait_250ns(); TOSH_wait_250ns(); }
    // falling edge of int0 triggers data ready
    //cbi(EICRA, ISC01);
    //cbi(EICRA, ISC00);
    // enable INT0
    //sbi(EIMSK, INT0);
  }

  event result_t Timer.fired() {
    if (PRESSURE_READ_IN_PIN() == 1) {
	timeout++;
      if (timeout > PRESSURE_TIMEOUT_TRIES) {
        if ((sensor == PRESSURE) && (presserror == TRUE)) {
          errornum = 1;
          call Timer.stop();
          state = IDLE;
          post signalPressError();
          return SUCCESS; 
        }
        else if ((sensor == TEMP) && (temperror == TRUE)) {
          errornum = 1;
          call Timer.stop();
          state = IDLE;
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

  //  TOSH_SIGNAL(PRESSURE_INTERRUPT) {
  async event void PressureInterrupt.fired() {
      call PressureInterrupt.clear();
      call PressureInterrupt.disable();
      call Timer.stop();
      post gotInterrupt();
  }

  task void SPITask() {
    char i;

    if (state == RESET) {

      // if calibration is on, grab the calibration data
      if (sensor == CALIBRATE) {

	for (i = 0; i < 4; i++) {
	  // reset the device
	  spi_reset();
	  calibration[(int)i] = spi_word(i+1);
	}

	// we're done, so we can be idle
	state = IDLE;

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
    state = IDLE;
    presserror = temperror = FALSE;
    call TimerControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    PRESSURE_MAKE_CLOCK_OUTPUT();
    PRESSURE_MAKE_IN_INPUT();
    PRESSURE_SET_IN_PIN();
    PRESSURE_MAKE_OUT_OUTPUT();
    TOSH_MAKE_ADC3_INPUT();
    TOSH_MAKE_ADC2_INPUT();
    P2DIR |= 1;
    P2SEL |= 1;
    P2DIR &= 0xfd;P2SEL &= 0xfd;
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  // tells this module whether to report back the calibration data
  command result_t Calibration.getData() {
    if (state == IDLE) {
      state = RESET;
      sensor = CALIBRATE;
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
    if (state == IDLE) {
      state = RESET;
      sensor = PRESSURE;
      post SPITask();
      return SUCCESS;
    }
    return FAIL;
  }

  async command result_t Temp.getData() {
    if (state == IDLE) {
      state = RESET;
      sensor = TEMP;
      post SPITask();
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t PressError.enable() {
    if (presserror == FALSE) {
      atomic presserror = TRUE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t PressError.disable() {
    if (presserror == TRUE) {
      atomic presserror = FALSE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t TempError.enable() {
    if (temperror == FALSE) {
      atomic temperror = TRUE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t TempError.disable() {
    if (temperror == TRUE) {
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

