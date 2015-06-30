//$Id: MicM.nc,v 1.2 2005/07/06 17:25:04 cssharp Exp $
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
 * Implementation file for the Trio microphone <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

includes sensorboard;

module MicM
{
  provides {
    interface StdControl;
    interface Mic;
  }
  uses {
    interface ADCControl;
    interface StdControl as AD5242Control;
    interface AD5242;
    interface StdControl as IOSwitch1Control;
    interface IOSwitch as IOSwitch1;
    interface IOSwitchInterrupt as IOSwitch1Interrupt;
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
    STATE_START_AD5242_GD,
    STATE_START_AD5242_GD_O1,
    STATE_START_AD5242_GD_O2,
    STATE_START_AD5242_LPF,
    STATE_START_AD5242_LPF_O1,
    STATE_START_AD5242_LPF_O2,
    STATE_START_AD5242_HPF,
    STATE_START_AD5242_HPF_O1,
    STATE_START_AD5242_HPF_O2,

    STATE_STOP_IOSWITCH1,
    STATE_STOP_IOSWITCH2,
    STATE_STOP_AD5242_GD,
    STATE_STOP_AD5242_GD_O1,
    STATE_STOP_AD5242_GD_O2,
    STATE_STOP_AD5242_LPF,
    STATE_STOP_AD5242_LPF_O1,
    STATE_STOP_AD5242_LPF_O2,
    STATE_STOP_AD5242_HPF,
    STATE_STOP_AD5242_HPF_O1,
    STATE_STOP_AD5242_HPF_O2,

    STATE_ADJUST_DETECT1,
    STATE_ADJUST_DETECT2,
    STATE_ADJUST_GAIN1,
    STATE_ADJUST_GAIN2,
    STATE_ADJUST_LPF0_1,
    STATE_ADJUST_LPF0_2,
    STATE_ADJUST_LPF1_1,
    STATE_ADJUST_LPF1_2,
    STATE_ADJUST_HPF0_1,
    STATE_ADJUST_HPF0_2,
    STATE_ADJUST_HPF1_1,
    STATE_ADJUST_HPF1_2,

    STATE_READ_DETECT1,
    STATE_READ_DETECT2,
    STATE_READ_GAIN1,
    STATE_READ_GAIN2,
    STATE_READ_LPF0_1,
    STATE_READ_LPF0_2,
    STATE_READ_LPF1_1,
    STATE_READ_LPF1_2,
    STATE_READ_HPF0_1,
    STATE_READ_HPF0_2,
    STATE_READ_HPF1_1,
    STATE_READ_HPF1_2,

  };

  uint8_t state = STATE_IDLE;
  uint8_t m_detect = 128;
  uint8_t m_quad = 128;
  uint8_t m_lpf0 = 128;
  uint8_t m_lpf1 = 128;
  uint8_t m_hpf0 = 128;
  uint8_t m_hpf1 = 128;

  command result_t StdControl.init() {
    call IOSwitch1Control.init();
    call IOSwitch2Control.init();
    call AD5242Control.init();
    call ADCControl.init();
    call ADCControl.bindPort(TOS_ADC_ACOUSTIC_PORT,
                             TOSH_ACTUAL_ADC_ACOUSTIC_PORT);
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

  command result_t Mic.MicOn() {
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_IDLE) {
      atomic state = STATE_START_IOSWITCH1;
      // turn on PW_MAG pin -- active low
      call IOSwitch1.setPort0Pin(IOSWITCH1_PW_ACOUSTIC, FALSE);
      return SUCCESS;
    }
    else {
      return FAIL;  
    }
  }

  command result_t Mic.MicOff() {
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_IDLE) {
      atomic state = STATE_STOP_IOSWITCH1;
      // turn off PW_MAG pin -- active low
      call IOSwitch1.setPort0Pin(IOSWITCH1_PW_ACOUSTIC, TRUE);
      return SUCCESS; 
    }
    else {
      return FAIL;
    }
  }

  command result_t Mic.adjustDetect(uint8_t val) {
    uint8_t _state;
    atomic {
      _state = state;
      m_detect = val;
    }
    if (_state == STATE_IDLE) {
      atomic state = STATE_ADJUST_DETECT1;
      call IOSwitch2.setPort0Pin(IOSWITCH2_I2C_SW, FALSE);
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t Mic.adjustGain(uint8_t val) {
    uint8_t _state;
    atomic {
      _state = state;
      m_quad = val;
    }
    if (_state == STATE_IDLE) {
      atomic state = STATE_ADJUST_GAIN1;
      call IOSwitch2.setPort0Pin(IOSWITCH2_I2C_SW, FALSE);
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t Mic.adjustLpfFreq0(uint8_t val) {
    uint8_t _state;
    atomic {
      _state = state;
      m_lpf0 = val;
    }
    if (_state == STATE_IDLE) {
      atomic state = STATE_ADJUST_LPF0_1;
      call IOSwitch2.setPort0Pin(IOSWITCH2_I2C_SW, FALSE);
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t Mic.adjustLpfFreq1(uint8_t val) {
    uint8_t _state;
    atomic {
      _state = state;
      m_lpf1 = val;
    }
    if (_state == STATE_IDLE) {
      atomic state = STATE_ADJUST_LPF1_1;
      call IOSwitch2.setPort0Pin(IOSWITCH2_I2C_SW, FALSE);
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t Mic.adjustHpfFreq0(uint8_t val) {
    uint8_t _state;
    atomic {
      _state = state;
      m_hpf0 = val;
    }
    if (_state == STATE_IDLE) {
      atomic state = STATE_ADJUST_HPF0_1;
      call IOSwitch2.setPort0Pin(IOSWITCH2_I2C_SW, FALSE);
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t Mic.adjustHpfFreq1(uint8_t val) {
    uint8_t _state;
    atomic {
      _state = state;
      m_hpf1 = val;
    }
    if (_state == STATE_IDLE) {
      atomic state = STATE_ADJUST_HPF1_1;
      call IOSwitch2.setPort0Pin(IOSWITCH2_I2C_SW, FALSE);
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t Mic.readDetect() {
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_IDLE) {
      atomic state = STATE_READ_DETECT1;
      call IOSwitch2.setPort0Pin(IOSWITCH2_I2C_SW, FALSE);
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t Mic.readGain() {
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_IDLE) {
      atomic state = STATE_READ_GAIN1;
      call IOSwitch2.setPort0Pin(IOSWITCH2_I2C_SW, FALSE);
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t Mic.readLpfFreq0() {
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_IDLE) {
      atomic state = STATE_READ_LPF0_1;
      call IOSwitch2.setPort0Pin(IOSWITCH2_I2C_SW, FALSE);
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t Mic.readLpfFreq1() {
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_IDLE) {
      atomic state = STATE_READ_LPF1_1;
      call IOSwitch2.setPort0Pin(IOSWITCH2_I2C_SW, FALSE);
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t Mic.readHpfFreq0() {
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_IDLE) {
      atomic state = STATE_READ_HPF0_1;
      call IOSwitch2.setPort0Pin(IOSWITCH2_I2C_SW, FALSE);
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t Mic.readHpfFreq1() {
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_IDLE) {
      atomic state = STATE_READ_HPF1_1;
      call IOSwitch2.setPort0Pin(IOSWITCH2_I2C_SW, FALSE);
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  event void AD5242.setPot1Done(uint8_t addr, result_t result) {
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_ADJUST_DETECT2) {
      atomic state = STATE_IDLE;
    }
    else if (_state == STATE_ADJUST_LPF0_2) {
      atomic state = STATE_IDLE;
    }
    else if (_state == STATE_ADJUST_HPF0_2) {
      atomic state = STATE_IDLE;
    }
    signal Mic.adjustDetectDone(result);
  }

  event void AD5242.setPot2Done(uint8_t addr, result_t result) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_ADJUST_GAIN2) {
      atomic state = STATE_IDLE;
    }
    else if (_state == STATE_ADJUST_LPF1_2) {
      atomic state = STATE_IDLE;
    }
    else if (_state == STATE_ADJUST_HPF1_2) {
      atomic state = STATE_IDLE;
    }
    signal Mic.adjustGainDone(result);
  }

  event void IOSwitch1.setPortDone(result_t result) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_START_IOSWITCH1) {
      atomic state = STATE_START_IOSWITCH2;
      // select I2C_bus 0
      call IOSwitch2.setPort0Pin(IOSWITCH2_I2C_SW, FALSE);
    }
    else if (_state == STATE_STOP_IOSWITCH1) {
      atomic state = STATE_STOP_IOSWITCH2;
      // select I2C_bus 0
      call IOSwitch2.setPort0Pin(IOSWITCH2_I2C_SW, FALSE);
    }
  }

  event void IOSwitch2.setPortDone(result_t result) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_START_IOSWITCH2) {
      atomic state = STATE_START_AD5242_GD;
      // turn on potentiometer
      call AD5242.start(AD5242_ADDR_MIC_ADJUST);
    }
    else if (_state == STATE_STOP_IOSWITCH2) {
      atomic state = STATE_STOP_AD5242_GD;
      // turn on potentiometer
      call AD5242.stop(AD5242_ADDR_MIC_ADJUST);
    }
    else if (_state == STATE_ADJUST_DETECT1) {
      atomic state = STATE_ADJUST_DETECT2;
      call AD5242.setPot1(AD5242_ADDR_MIC_ADJUST, m_detect);
    }
    else if (_state == STATE_ADJUST_GAIN1) {
      atomic state = STATE_ADJUST_GAIN2;
      call AD5242.setPot2(AD5242_ADDR_MIC_ADJUST, m_quad);
    }
    else if (_state == STATE_ADJUST_LPF0_1) {
      atomic state = STATE_ADJUST_LPF0_2;
      call AD5242.setPot1(AD5242_ADDR_MIC_LPF, m_lpf0);
    }
    else if (_state == STATE_ADJUST_LPF1_1) {
      atomic state = STATE_ADJUST_LPF1_2;
      call AD5242.setPot2(AD5242_ADDR_MIC_LPF, m_lpf1);
    }
    else if (_state == STATE_ADJUST_HPF0_1) {
      atomic state = STATE_ADJUST_HPF0_2;
      call AD5242.setPot1(AD5242_ADDR_MIC_HPF, m_hpf0);
    }
    else if (_state == STATE_ADJUST_HPF1_1) {
      atomic state = STATE_ADJUST_HPF1_2;
      call AD5242.setPot2(AD5242_ADDR_MIC_HPF, m_hpf1);
    }
    else if (_state == STATE_READ_DETECT1) {
      atomic state = STATE_READ_DETECT2;
      call AD5242.getPot1(AD5242_ADDR_MIC_ADJUST);
    }
    else if (_state == STATE_READ_GAIN1) {
      atomic state = STATE_READ_GAIN2;
      call AD5242.getPot2(AD5242_ADDR_MIC_ADJUST);
    }
    else if (_state == STATE_READ_LPF0_1) {
      atomic state = STATE_READ_LPF0_2;
      call AD5242.getPot1(AD5242_ADDR_MIC_LPF);
    }
    else if (_state == STATE_READ_LPF1_1) {
      atomic state = STATE_READ_LPF1_2;
      call AD5242.getPot2(AD5242_ADDR_MIC_LPF);
    }
    else if (_state == STATE_READ_HPF0_1) {
      atomic state = STATE_READ_HPF0_2;
      call AD5242.getPot1(AD5242_ADDR_MIC_HPF);
    }
    else if (_state == STATE_READ_HPF1_1) {
      atomic state = STATE_READ_HPF1_2;
      call AD5242.getPot2(AD5242_ADDR_MIC_HPF);
    }
  }

  event void AD5242.startDone(uint8_t addr, result_t result) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_START_AD5242_GD) {
      atomic state = STATE_START_AD5242_GD_O1;
      // turn on the output latch of the potentiometer channel 1
      call AD5242.setOutput1(AD5242_ADDR_MIC_ADJUST, TRUE);
    }
    else if (_state == STATE_START_AD5242_LPF) {
      atomic state = STATE_START_AD5242_LPF_O1;
      // turn on the output latch of the potentiometer channel 1
      call AD5242.setOutput1(AD5242_ADDR_MIC_LPF, TRUE);
    }
    else if (_state == STATE_START_AD5242_HPF) {
      atomic state = STATE_START_AD5242_HPF_O1;
      // turn on the output latch of the potentiometer channel 1
      call AD5242.setOutput1(AD5242_ADDR_MIC_HPF, TRUE);
    }
  }

  event void AD5242.stopDone(uint8_t addr, result_t result) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_STOP_AD5242_GD) {
      atomic state = STATE_STOP_AD5242_GD_O1;
      // turn off the output latch of the potentiometer channel 1
      call AD5242.setOutput1(AD5242_ADDR_MIC_ADJUST, FALSE);
    }
    else if (_state == STATE_STOP_AD5242_LPF) {
      atomic state = STATE_STOP_AD5242_LPF_O1;
      // turn off the output latch of the potentiometer channel 1
      call AD5242.setOutput1(AD5242_ADDR_MIC_LPF, FALSE);
    }
    else if (_state == STATE_STOP_AD5242_HPF) {
      atomic state = STATE_STOP_AD5242_HPF_O1;
      // turn off the output latch of the potentiometer channel 1
      call AD5242.setOutput1(AD5242_ADDR_MIC_HPF, FALSE);
    }
  }

  event void AD5242.setOutput1Done(uint8_t addr, result_t result) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_START_AD5242_GD_O1) {
      atomic state = STATE_START_AD5242_GD_O2;
      // turn on the output latch of the potentiometer channel 2
      call AD5242.setOutput2(AD5242_ADDR_MIC_ADJUST, TRUE);
    }
    else if (_state == STATE_START_AD5242_LPF_O1) {
      atomic state = STATE_START_AD5242_LPF_O2;
      // turn on the output latch of the potentiometer channel 2
      call AD5242.setOutput2(AD5242_ADDR_MIC_LPF, TRUE);
    }
    else if (_state == STATE_START_AD5242_HPF_O1) {
      atomic state = STATE_START_AD5242_HPF_O2;
      // turn on the output latch of the potentiometer channel 2
      call AD5242.setOutput2(AD5242_ADDR_MIC_HPF, TRUE);
    }
    else if (_state == STATE_STOP_AD5242_GD_O1) {
      atomic state = STATE_STOP_AD5242_GD_O2;
      // turn off the output latch of the potentiometer channel 2
      call AD5242.setOutput2(AD5242_ADDR_MIC_ADJUST, FALSE);
    }
    else if (_state == STATE_STOP_AD5242_LPF_O1) {
      atomic state = STATE_STOP_AD5242_LPF_O2;
      // turn off the output latch of the potentiometer channel 2
      call AD5242.setOutput2(AD5242_ADDR_MIC_LPF, FALSE);
    }
    else if (_state == STATE_STOP_AD5242_HPF_O1) {
      atomic state = STATE_STOP_AD5242_HPF_O2;
      // turn off the output latch of the potentiometer channel 2
      call AD5242.setOutput2(AD5242_ADDR_MIC_HPF, FALSE);
    }
  }

  event void AD5242.setOutput2Done(uint8_t addr, result_t result) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_START_AD5242_GD_O2) {
      atomic state = STATE_START_AD5242_LPF;
      call AD5242.start(AD5242_ADDR_MIC_LPF);
    }
    else if (_state == STATE_START_AD5242_LPF_O2) {
      atomic state = STATE_START_AD5242_HPF;
      call AD5242.start(AD5242_ADDR_MIC_HPF);
    }
    else if (_state == STATE_START_AD5242_HPF_O2) {
      atomic state = STATE_IDLE;
    }
    else if (_state == STATE_STOP_AD5242_GD_O2) {
      atomic state = STATE_STOP_AD5242_LPF;
      call AD5242.stop(AD5242_ADDR_MIC_LPF);
    }
    else if (_state == STATE_STOP_AD5242_LPF_O2) {
      atomic state = STATE_STOP_AD5242_HPF;
      call AD5242.start(AD5242_ADDR_MIC_HPF);
    }
    else if (_state == STATE_STOP_AD5242_HPF_O2) {
      atomic state = STATE_IDLE;
    }
  }

  event void AD5242.getPot1Done(uint8_t addr, uint8_t value,
                                result_t result) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_READ_DETECT2) {
      atomic state = STATE_IDLE;
      atomic m_detect = value;
      signal Mic.readDetectDone(value);
    }
    else if (_state == STATE_READ_LPF0_2) {
      atomic state = STATE_IDLE;
      atomic m_lpf0 = value;
      signal Mic.readLpfFreq0Done(value);
    }
    else if (_state == STATE_READ_HPF0_2) {
      atomic state = STATE_IDLE;
      atomic m_hpf0 = value;
      signal Mic.readHpfFreq0Done(value);
    }
  }

  event void AD5242.getPot2Done(uint8_t addr, uint8_t value,
                                result_t result) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_READ_GAIN2) {
      atomic state = STATE_IDLE;
      atomic m_quad = value;
      signal Mic.readGainDone(value);
    }
    else if (_state == STATE_READ_LPF1_2) {
      atomic state = STATE_IDLE;
      atomic m_lpf1 = value;
      signal Mic.readLpfFreq1Done(value);
    }
    else if (_state == STATE_READ_HPF1_2) {
      atomic state = STATE_IDLE;
      atomic m_hpf1 = value;
      signal Mic.readHpfFreq1Done(value);
    }
  }

  event void IOSwitch1.getPortDone(uint16_t bits, result_t result) {
  }

  async event void IOSwitch1Interrupt.fired(uint8_t mask) { 
    if (mask & IOSWITCH1_INT_ACOUSTIC) {
      signal Mic.firedAcoustic();
    }
  }

  event void IOSwitch2.getPortDone(uint16_t bits, result_t result) { }

  default event void Mic.firedAcoustic() { }

}    

