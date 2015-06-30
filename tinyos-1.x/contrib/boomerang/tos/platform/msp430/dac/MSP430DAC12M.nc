// $Id: MSP430DAC12M.nc,v 1.1.1.1 2007/11/05 19:11:32 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Private implementation of MSP430 DAC functionality.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module MSP430DAC12M {
  provides {
    interface StdControl;
    interface MSP430DAC as DAC0;
    interface MSP430DAC as DAC1;
  }
  uses {
    interface HPLDAC12 as HPLDAC0;
    interface HPLDAC12 as HPLDAC1;
    interface RefVolt;
  }
}
implementation {

  MSP430REG_NORACE(P6SEL);

  uint8_t state;

  enum {
    IDLE,
    PROC_DAC0,
    PROC_DAC1,
    RV_DAC0,
    RV_DAC1,
  };

  command result_t StdControl.init() {
    atomic {
      state = IDLE;
    }
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  // calibrate the output on DAC0
  task void calibDAC0() {
    call HPLDAC0.startCalibration();
    // wait for the calibration to finish
    while (call HPLDAC0.getCalibration() != 0) ;
    atomic state = IDLE;
    signal DAC0.enableDone(SUCCESS);
  }

  // calibrate the output on DAC1
  task void calibDAC1() {
    call HPLDAC1.startCalibration();
    // wait for the calibration to finish
    while (call HPLDAC1.getCalibration() != 0) ;
    atomic state = IDLE;
    signal DAC1.enableDone(SUCCESS);
  }

  /**************************** DAC 0 ************************/

  // to enable the DAC, the following steps must be taken:
  // 0) switch DAC0 to be MODFUNC
  // 1) turn on the reference voltage to 2.5V
  // 2) calibrate the output amplifier
  // 3) set DAC settings
  // 4) enable output
  async command result_t DAC0.enable() {
    result_t result = SUCCESS;
    
    atomic {
      if (state != IDLE) {
	result = FAIL;
      }
      else {
	state = PROC_DAC0;
      }
    }

    if (result == SUCCESS) {

      // set dac0 on port 6 to mod func
      P6SEL |= (1 << 6);

      // set the 2.5V reference
      result = call RefVolt.get(REFERENCE_2_5V);
      
      if (result == SUCCESS) {
	if (call RefVolt.getState() == REFERENCE_2_5V){
	  return post calibDAC0();
	} else {
	  // wait for the stable event
	  atomic state = RV_DAC0;
	  return SUCCESS;
	}
      }
    }
    return FAIL;
  }

  command result_t DAC0.bind(dac12ref_t reference,
			     dac12res_t resolution,
			     dac12load_t loadselect,
			     dac12fsout_t fsout,
			     dac12amp_t amp,
			     dac12df_t dataformat,
			     dac12group_t group) {
    dac12ctl_t control;

    call HPLDAC0.off();
    control = call HPLDAC0.getControl();

    control.group = group;
    control.format = dataformat;
    control.dacamp = amp;
    control.range = fsout;
    control.load = loadselect;
    control.resolution = resolution;
    control.reference = reference;

    call HPLDAC0.setControl(control);
    return SUCCESS;
  }

  default event void DAC0.enableDone(result_t success) { }

  async command result_t DAC0.enableOutput() {
    call HPLDAC0.on();
    return SUCCESS;
  }
  async command result_t DAC0.disableOutput() {
    call HPLDAC0.off();
    return SUCCESS;
  }

  task void disableDone0() {
    signal DAC0.disableDone(SUCCESS);
  }

  async command result_t DAC0.disable() {
    // release the reference voltage
    call HPLDAC0.off();
    if (call RefVolt.release() == SUCCESS) {
      return post disableDone0();
    }
    return FAIL;
  }
  default event void DAC0.disableDone(result_t success) { }

  async command result_t DAC0.set(uint16_t dacunits) { 
    call HPLDAC0.setData(dacunits);
    return SUCCESS;
  }

  /**************************** DAC 1 ************************/

  // to enable the DAC, the following steps must be taken:
  // 0) switch DAC1 to be MODFUNC
  // 1) turn on the reference voltage to 2.5V
  // 2) calibrate the output amplifier
  // 3) set DAC settings
  // 4) enable output
  async command result_t DAC1.enable() {
    result_t result = SUCCESS;
    
    atomic {
      if (state != IDLE) {
	result = FAIL;
      }
      else {
	state = PROC_DAC1;
      }
    }

    if (result) {

      // set dac1 on port 6 to mod func
      P6SEL |= (1 << 7);

      // set the 2.5V reference
      result = call RefVolt.get(REFERENCE_2_5V);
      
      if (result == SUCCESS) {
	if (call RefVolt.getState() == REFERENCE_2_5V){
	  return post calibDAC1();
	} else {
	  // wait for the stable event
	  atomic state = RV_DAC1;
	  return SUCCESS;
	}
      }
    }
    return FAIL;
  }

  command result_t DAC1.bind(dac12ref_t reference,
			     dac12res_t resolution,
			     dac12load_t loadselect,
			     dac12fsout_t fsout,
			     dac12amp_t amp,
			     dac12df_t dataformat,
			     dac12group_t group) {
    dac12ctl_t control;

    call HPLDAC1.off();
    control = call HPLDAC1.getControl();

    control.group = group;
    control.format = dataformat;
    control.dacamp = amp;
    control.range = fsout;
    control.load = loadselect;
    control.resolution = resolution;
    control.reference = reference;

    call HPLDAC1.setControl(control);
    return SUCCESS;
  }

  default event void DAC1.enableDone(result_t success) { }

  async command result_t DAC1.enableOutput() {
    call HPLDAC1.on();
    return SUCCESS;
  }
  async command result_t DAC1.disableOutput() {
    call HPLDAC1.off();
    return SUCCESS;
  }

  task void disableDone1() {
    signal DAC1.disableDone(SUCCESS);
  }

  async command result_t DAC1.disable() {
    // release the reference voltage
    call HPLDAC1.off();
    if (call RefVolt.release() == SUCCESS) {
      return post disableDone1();
    }
    return FAIL;
  }
  default event void DAC1.disableDone(result_t success) { }

  async command result_t DAC1.set(uint16_t dacunits) { 
    call HPLDAC1.setData(dacunits);
    return SUCCESS;
  }

  event void RefVolt.isStable(RefVolt_t vref) {
    uint8_t _state = IDLE;
    atomic {
      if (state == RV_DAC0) {
	_state = state;
	state = PROC_DAC0;
      }
      else if (state == RV_DAC1) {
	_state = state;
	state = PROC_DAC1;
      }
    }

    switch(_state) {
    case RV_DAC0:
      post calibDAC0();
    case RV_DAC1:
      post calibDAC1();
    }

  }
}
