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
 */
/*
 *
 * Authors:		Joe Polastre
 *
 * $Id: MelexisLowerM.nc,v 1.1.1.1 2007/11/05 19:10:40 jpolastre Exp $
 */

includes sensorboard;
module MelexisLowerM {
  provides {
    interface ADC as Thermopile;
    interface ADC as Temp;
    interface SplitControl;
    interface Calibration;
    interface ThermopileEEPROM;
  }
  uses {
    interface StdControl as FlashControl;
    interface ThermopileSelectPin;
  }
}
implementation {

  enum { START=0, STOP, IDLE=7, RESET=8, CALIBRATE=9, TEMP=10, THERMOPILE=11, 
	 DATA_READY=12, SELECT, CLOSED, WP, TEST, WR_EEPROM, RD_EEPROM, ER_EEPROM };

  char calibration_word;
  char state;
  char sensor;

  uint8_t wr_addr;
  uint16_t wr_value;
  
  uint16_t calibration[2];
  uint16_t reading;

  void task initDone() {
    signal SplitControl.initDone();
  }

  void task startDone() {
    signal SplitControl.startDone();
  }

  void task stopDone() {
    signal SplitControl.stopDone();
  }

  void pulse_clock() {
    TOSH_uwait(10);
    THERMOPILE_SET_CLOCK();
    TOSH_uwait(10);
    THERMOPILE_CLEAR_CLOCK();
  }

  char din_value() {
    return THERMOPILE_READ_IN_PIN();
  }

  char read_bit() {
    char i;
    THERMOPILE_CLEAR_OUT_PIN();
    TOSH_uwait(10);
    THERMOPILE_SET_CLOCK();
    TOSH_uwait(10);
    i = din_value();
    THERMOPILE_CLEAR_CLOCK();
    return i;
  }

  void write_bit(bool bit) {
    if (bit)
      THERMOPILE_SET_OUT_PIN();
    else
      THERMOPILE_CLEAR_OUT_PIN();
    pulse_clock();
  }

  void write_word(char word) {
    int i = 0;
    for (i = 0; i < 8; i++) {
      char bit = (word >> (7-i)) & 0x01;
      write_bit(bit);
    }
  }

  uint16_t adc_read() {
    uint16_t result = 0;
    uint16_t tresult = 0;
    char i;
    
    TOSH_uwait(3);
    for (i = 0; i < 16; i++) {
      tresult = (uint16_t)read_bit();
      tresult = tresult << (15-i);
      result += tresult;
    }
    return result;      
  }

  uint16_t spi_word(char num) {
    write_word(MICAWB_THERM_RD_REG);
    if (num == 1)
      write_word(MICAWB_THERM_ADDR_CONFIG0);
    else if (num == 2)
      write_word(MICAWB_THERM_ADDR_CONFIG1);
    
    TOSH_uwait(3);
    
    return adc_read();
  }

  uint16_t read_EEPROM(char addr) {
    write_word(MICAWB_THERM_RD_EE);
    write_word(addr);
    TOSH_uwait(3);
    return adc_read();
  }

  void sense() {
    write_word(MICAWB_THERM_RD_REG);
    if (sensor == THERMOPILE) {
      write_word(MICAWB_THERM_IROUT);
    }
    else if (sensor == TEMP) {
      write_word(MICAWB_THERM_TOUT);
    }

    reading = adc_read();
  }

  void setWPmode() {
    write_word(MICAWB_THERM_WR_REG);
    write_word(MICAWB_THERM_WP_REG);
    write_word((wr_value >> 8) & 0x0FF);
    write_word(wr_value & 0x0FF);
  }

  void setTESTmode() {
    write_word(MICAWB_THERM_WR_REG);
    write_word(MICAWB_THERM_TEST_REG);
    write_word((wr_value >> 8) & 0x0FF);
    write_word(wr_value & 0x0FF);
  }

  void writeEEPROMfunc() {
    write_word(MICAWB_THERM_WR_EE);
    write_word(wr_addr);
    write_word((wr_value >> 8) & 0x0FF);
    write_word(wr_value & 0x0FF);
  }

  void eraseEEPROMfunc() {
    write_word(MICAWB_THERM_ER_EE);
    write_word(wr_addr);
    write_word(0);
    write_word(0);
  }

  task void SPITask() {
    char i;
    uint16_t l_reading;

    if (state == RESET) {
      call ThermopileSelectPin.set(TRUE);
      return;
    }

    else if (state == SELECT) {
      switch(sensor) {
      case CALIBRATE:
        // if calibration is on, grab the calibration data
	calibration[(int)calibration_word-1] = spi_word(calibration_word);
        break;

      case WP:
        setWPmode();
        break;

      case WR_EEPROM:
        writeEEPROMfunc();
        break;

      case TEST:
        setTESTmode();
        break;

      case RD_EEPROM:
        reading = read_EEPROM(wr_addr);
        break;

      case ER_EEPROM:
        eraseEEPROMfunc();
        break;

      case THERMOPILE:
      case TEMP:
	// grab the sensor reading and store it locally
	sense();
        break;

      default:
        break;
      }
      call ThermopileSelectPin.set(FALSE);
    }

    else if (state == CLOSED) {
      switch(sensor) {
      case CALIBRATE:
	if (calibration_word < 2) {
	  calibration_word++;
	  state = RESET;
	  post SPITask();
	  return;
	}
	else {
	  state = IDLE;
	  for (i = 0; i < 2; i++) {
	    signal Calibration.dataReady(i+1, calibration[(int)i]);
	  }
	}
        break;

      case WP:
        state = IDLE;
        signal ThermopileEEPROM.setWPDone();
        break;

      case TEST:
        state = IDLE;
        signal ThermopileEEPROM.setTestDone();
        break;

      case WR_EEPROM:
        state = IDLE;
        signal ThermopileEEPROM.writeEEPROMDone();
        break;

      case ER_EEPROM:
        state = IDLE;
        signal ThermopileEEPROM.eraseEEPROMDone();
        break;

      case RD_EEPROM:
        l_reading = reading;
        state = IDLE;
        signal ThermopileEEPROM.readEEPROMDone(l_reading);
        break;

      case THERMOPILE:
      case TEMP:
	l_reading = reading;

	// we're done, so we can be idle
	state = IDLE;
	
	// give the application the sensor data
	if (sensor == TEMP) {
	  signal Temp.dataReady(l_reading);
	}
	else if (sensor == THERMOPILE) {
	  signal Thermopile.dataReady(l_reading);
	}
        break;

      default:
        break;
      }

    }
  }

  command result_t SplitControl.init() {
    state = STOP;
    post initDone();
    return SUCCESS;
  }

  command result_t SplitControl.start() {
    // disable the external flash
    state = START;
    call ThermopileSelectPin.set(FALSE);
    THERMOPILE_MAKE_CLOCK_OUTPUT();
    THERMOPILE_MAKE_IN_INPUT();
    THERMOPILE_MAKE_OUT_OUTPUT();
    return SUCCESS;
  }

  command result_t SplitControl.stop() {
    state = STOP;
    THERMOPILE_MAKE_CLOCK_INPUT();
    THERMOPILE_MAKE_OUT_INPUT();
    call ThermopileSelectPin.set(FALSE);
    return SUCCESS;
  }

  // tells this module whether to report back the calibration data
  command result_t Calibration.getData() {
    if (state == IDLE) {
      calibration_word = 1;
      state = RESET;
      sensor = CALIBRATE;
      post SPITask();
      return SUCCESS;
    }
    return FAIL;
  }

  event result_t ThermopileSelectPin.setDone() {
    if (state == RESET) {
      state = SELECT;
      post SPITask();
      return SUCCESS;
    }
    else if (state == SELECT) {
      state = CLOSED;
      post SPITask();
      return SUCCESS;
    }
    else if (state == START) {
      state = IDLE;
      post startDone();
      return SUCCESS;
    }

    else if (state == STOP) {
      post stopDone();
      return SUCCESS;
    }

    return SUCCESS;
  }

  // no such thing
  async command result_t Thermopile.getContinuousData() {
    return FAIL;
  }

  // no such thing
  async command result_t Temp.getContinuousData() {
    return FAIL;
  }

  async command result_t Thermopile.getData() {
    if (state == IDLE) {
      state = RESET;
      sensor = THERMOPILE;
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

  default async event result_t Thermopile.dataReady(uint16_t data)
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

  command result_t ThermopileEEPROM.setWP(bool enable) {
    if (state == IDLE) {
      state = RESET;
      sensor = WP;
      if (enable == TRUE)
        wr_value = MELEXIS_WP_EN;
      else
        wr_value = 0;
      post SPITask();
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t ThermopileEEPROM.setTest(bool enable) {
    if (state == IDLE) {
      state = RESET;
      sensor = TEST;
      if (enable == TRUE)
        wr_value = MELEXIS_TEST_EN;
      else
        wr_value = 0;
      post SPITask();
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t ThermopileEEPROM.writeEEPROM(uint8_t addr, uint16_t value) {
    if (state == IDLE) {
      state = RESET;
      sensor = WR_EEPROM;
      wr_addr = addr;
      wr_value = value;
      post SPITask();
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t ThermopileEEPROM.readEEPROM(uint8_t addr) {
    if (state == IDLE) {
      state = RESET;
      sensor = RD_EEPROM;
      wr_addr = addr;
      post SPITask();
      return SUCCESS;
    }
    return FAIL;
  }  

  command result_t ThermopileEEPROM.eraseEEPROM(uint8_t addr) {
    if (state == IDLE) {
      state = RESET;
      sensor = ER_EEPROM;
      wr_addr = addr;
      post SPITask();
      return SUCCESS;
    }
    return FAIL;
  }

  default event result_t ThermopileEEPROM.setWPDone() {
    return SUCCESS;
  }

  default event result_t ThermopileEEPROM.setTestDone() {
    return SUCCESS;
  }

  default event result_t ThermopileEEPROM.writeEEPROMDone() {
    return SUCCESS;
  }

  default event result_t ThermopileEEPROM.readEEPROMDone(uint16_t value) {
    return SUCCESS;
  }

  default event result_t ThermopileEEPROM.eraseEEPROMDone() {
    return SUCCESS;
  }

}

