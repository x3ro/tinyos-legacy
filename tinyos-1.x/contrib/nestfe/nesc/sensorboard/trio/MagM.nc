//$Id: MagM.nc,v 1.2 2005/07/06 17:25:04 cssharp Exp $
/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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

/**
 * Implementation file for the Trio magnetometer <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

includes sensorboard;

module MagM
{
  provides {
    interface StdControl;
    interface Mag;
  }
  uses {
    interface ADCControl;
    interface StdControl as AD5242Control;
    interface AD5242;
    interface StdControl as IOSwitch1Control;
    interface IOSwitch as IOSwitch1;
    interface StdControl as IOSwitch2Control;
    interface IOSwitch as IOSwitch2;
  }
}

implementation
{
  enum {
    STATE_IDLE = 0,

    STATE_START_IOSWITCH1,
    STATE_START_IOSWITCH2,
    STATE_START_AD5242,
    STATE_START_AD5242_O1,
    STATE_START_AD5242_O2,

    STATE_STOP_IOSWITCH1,
    STATE_STOP_IOSWITCH2,
    STATE_STOP_AD5242,
    STATE_STOP_AD5242_O1,
    STATE_STOP_AD5242_O2,

    STATE_ADJUST_GAINX1,
    STATE_ADJUST_GAINX2,
    STATE_ADJUST_GAINY1,
    STATE_ADJUST_GAINY2,

    STATE_READ_GAINX1,
    STATE_READ_GAINX2,
    STATE_READ_GAINY1,
    STATE_READ_GAINY2,
  };

  enum {
    IOSWITCH1_INIT = 0x3e,
  };

  uint8_t state = STATE_IDLE;
  uint8_t m_gainX = 128;
  uint8_t m_gainY = 128;

  task void mag_readGainX_task();
  task void mag_readGainY_task();

  command result_t StdControl.init() {
    call IOSwitch1Control.init();
    call IOSwitch2Control.init();
    call AD5242Control.init();

    call ADCControl.init();
    call ADCControl.bindPort (TOS_ADC_MAG0_PORT, TOSH_ACTUAL_ADC_MAG0_PORT);
    call ADCControl.bindPort (TOS_ADC_MAG1_PORT, TOSH_ACTUAL_ADC_MAG1_PORT);

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IOSwitch1Control.start();
    call IOSwitch2Control.start();
    call AD5242Control.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call IOSwitch1Control.stop();
    call IOSwitch2Control.stop();
    call AD5242Control.stop();
    return SUCCESS;
  }

  command result_t Mag.MagOn() {
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_IDLE) {
      atomic state = STATE_START_IOSWITCH1;
      // turn on PW_MAG pin -- active low
      call IOSwitch1.setPort0Pin(IOSWITCH1_PW_MAG, FALSE);
      return SUCCESS;
    }
    else {
      return FAIL;  
    }
  }

  command result_t Mag.MagOff() {
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_IDLE) {
      atomic state = STATE_STOP_IOSWITCH1;
      // turn off PW_MAG pin -- active low
      call IOSwitch1.setPort0Pin(IOSWITCH1_PW_MAG, TRUE);
      return SUCCESS; 
    }
    else {
      return FAIL;
    }
  }

  command result_t Mag.adjustGainX(uint8_t val) {
    uint8_t _state;
    atomic {
      _state = state;
      m_gainX = val;
    }
    if (_state == STATE_IDLE) {
      atomic state = STATE_ADJUST_GAINX1;
      call IOSwitch2.setPort0Pin(IOSWITCH2_I2C_SW, TRUE);
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t Mag.adjustGainY(uint8_t val) {
    uint8_t _state;
    atomic {
      _state = state;
      m_gainY = val;
    }
    if (_state == STATE_IDLE) {
      atomic state = STATE_ADJUST_GAINY1;
      call IOSwitch2.setPort0Pin(IOSWITCH2_I2C_SW, TRUE);
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t Mag.readGainX() {
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_IDLE) {
      atomic state = STATE_READ_GAINX1;
      call IOSwitch2.setPort0Pin(IOSWITCH2_I2C_SW, TRUE);
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t Mag.readGainY() {
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_IDLE) {
      atomic state = STATE_READ_GAINY1;
      call IOSwitch2.setPort0Pin(IOSWITCH2_I2C_SW, TRUE);
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  event void AD5242.setPot1Done(uint8_t addr, result_t result) {
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_ADJUST_GAINX2) {
      atomic state = STATE_IDLE;
    }
    signal Mag.adjustGainXDone(result);
  }

  event void AD5242.setPot2Done(uint8_t addr, result_t result) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_ADJUST_GAINY2) {
      atomic state = STATE_IDLE;
    }
    signal Mag.adjustGainYDone(result);
  }

  command result_t Mag.SetReset() {
    call IOSwitch1.setPort0Pin(IOSWITCH1_MAG_SR, TRUE);
    TOSH_uwait(1);
    call IOSwitch1.setPort0Pin(IOSWITCH1_MAG_SR, FALSE);
    return SUCCESS;
  }

  event void IOSwitch1.setPortDone(result_t result) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_START_IOSWITCH1) {
      atomic state = STATE_START_IOSWITCH2;
      // select I2C_bus 1
      call IOSwitch2.setPort0Pin(IOSWITCH2_I2C_SW, TRUE);
    }
    else if (_state == STATE_STOP_IOSWITCH1) {
      atomic state = STATE_STOP_IOSWITCH2;
      // select I2C_bus 1
      call IOSwitch2.setPort0Pin(IOSWITCH2_I2C_SW, TRUE);
    }
  }

  event void IOSwitch2.setPortDone(result_t result) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_START_IOSWITCH2) {
      atomic state = STATE_START_AD5242;
      // turn on potentiometer
      call AD5242.start(AD5242_ADDR_MAG_ADJUST);
    }
    else if (_state == STATE_STOP_IOSWITCH2) {
      atomic state = STATE_STOP_AD5242;
      // turn on potentiometer
      call AD5242.stop(AD5242_ADDR_MAG_ADJUST);
    }
    else if (_state == STATE_ADJUST_GAINX1) {
      atomic state = STATE_ADJUST_GAINX2;
      call AD5242.setPot1(AD5242_ADDR_MAG_ADJUST, m_gainX);
    }
    else if (_state == STATE_ADJUST_GAINY1) {
      atomic state = STATE_ADJUST_GAINY2;
      call AD5242.setPot2(AD5242_ADDR_MAG_ADJUST, m_gainY);
    }
    else if (_state == STATE_READ_GAINX1) {
      atomic state = STATE_READ_GAINX2;
      call AD5242.getPot1(AD5242_ADDR_MAG_ADJUST);
    }
    else if (_state == STATE_READ_GAINY1) {
      atomic state = STATE_READ_GAINY2;
      call AD5242.getPot2(AD5242_ADDR_MAG_ADJUST);
    }
  }

  event void AD5242.startDone(uint8_t addr, result_t result) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_START_AD5242) {
      atomic state = STATE_START_AD5242_O1;
      // turn on the output latch of the potentiometer channel 1
      call AD5242.setOutput1(AD5242_ADDR_MAG_ADJUST, TRUE);
    }
  }

  event void AD5242.stopDone(uint8_t addr, result_t result) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_STOP_AD5242) {
      atomic state = STATE_STOP_AD5242_O1;
      // turn off the output latch of the potentiometer channel 1
      call AD5242.setOutput1(AD5242_ADDR_MAG_ADJUST, FALSE);
    }
  }

  event void AD5242.setOutput1Done(uint8_t addr, result_t result) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_START_AD5242_O1) {
      atomic state = STATE_START_AD5242_O2;
      // turn on the output latch of the potentiometer channel 2
      call AD5242.setOutput2(AD5242_ADDR_MAG_ADJUST, TRUE);
    }
    else if (_state == STATE_STOP_AD5242_O1) {
      atomic state = STATE_STOP_AD5242_O2;
      // turn off the output latch of the potentiometer channel 2
      call AD5242.setOutput2(AD5242_ADDR_MAG_ADJUST, FALSE);
    }
  }

  event void AD5242.setOutput2Done(uint8_t addr, result_t result) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_START_AD5242_O2) {
      atomic state = STATE_IDLE;
    }
    else if (_state == STATE_STOP_AD5242_O2) {
      atomic state = STATE_IDLE;
    }
  }

  event void AD5242.getPot1Done(uint8_t addr, uint8_t value,
                                result_t result) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_READ_GAINX2) {
      atomic state = STATE_IDLE;
      atomic m_gainX = value;
      signal Mag.readGainXDone(value);
    }
  }

  event void AD5242.getPot2Done(uint8_t addr, uint8_t value,
                                result_t result) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_READ_GAINY2) {
      atomic state = STATE_IDLE;
      atomic m_gainY = value;
      signal Mag.readGainYDone(value);
    }
  }

  event void IOSwitch1.getPortDone(uint16_t bits, result_t result) { }
  event void IOSwitch2.getPortDone(uint16_t bits, result_t result) { }

}

