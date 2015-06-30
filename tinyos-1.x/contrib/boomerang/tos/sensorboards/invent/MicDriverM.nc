// $Id: MicDriverM.nc,v 1.1.1.1 2007/11/05 19:11:36 jpolastre Exp $
/*
 * "Copyright (c) 2000-2005 The Regents of the University  of California.
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
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#include "Mic.h"

/**
 * Implementation of the microphone driver for Tmote Invent,
 * including noise gating, variable compression, and configuration of 
 * the microphone energy detection circuit (to generate an interrupt).
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module MicDriverM
{
  provides {
    interface SplitControl;
    interface Microphone;
    interface SensorInterrupt as MicInterrupt;
    interface Potentiometer as Vrc; //compression point
    interface Potentiometer as Vrg; //gain
    interface Potentiometer as MicInterruptDrain;
    interface Potentiometer as MicInterruptThreshold;
  }
  uses {
    interface AD524X;
    interface ADCControl;
    interface StdControl as ADCStdControl;
    interface StdControl as PotControl;
    interface StdControl as AD524XControl;
    interface MSP430Interrupt as MicInt;
    interface MSP430ADC12Single as MSP430ADC;
    interface MSP430DMAControl as DMAControl;
    interface MSP430DMA as DMA;
    interface Leds;
  }
}

implementation
{

  enum {
    OFF = 0,
    IDLE,
    START1,
    START2,
    START_O, // mic circuit power on
    STOP1,
    STOP2,
    STOP_O,
    DRAIN,
    THRESH,
    VRG,
    VRC,
    INITPOTS_1,
    INITPOTS_2,
    INITPOTS_3,
    DMA_INUSE,
    DMA_INUSE_WAIT,
  };

  bool repeat;
  uint8_t state;
  uint8_t drain, thresh;
  uint8_t vrg, vrc;
  void* buf;
  uint16_t length;

  task void initDone() {
    signal SplitControl.initDone();
  }

  command result_t SplitControl.init() {
    atomic {
      // state is off
      state = OFF;

      // These are defaults for the compression ratio (between 2:1 and 5:1) and
      // noise gate (-48 dmb) described in the SSM2167 application note.

      // These are set assigned to local values here in init so that other
      // components can override them.  SplitControl.start chains through to
      // eventually call initPots() which pushes these values out over i2c.

      vrc = 10; // 17 kohms, 2:1 compression ratio
      vrg = 14; // 530 ohms, -44 dBV noise gate
    }
    call ADCStdControl.init();
    call AD524XControl.init();
    return post initDone();
  }

  command result_t SplitControl.start() {
    uint8_t _state = OFF;
    atomic {
      if (state == OFF) {
	state = START1;
	_state = state;
      }
    }
    if (_state == START1) {
      call ADCStdControl.start();
      call ADCControl.init();
      if (!call ADCControl.bindPort(TOS_ADC_MIC_PORT, 
				    TOSH_ACTUAL_ADC_MIC_PORT)) {
	atomic state = OFF;
	return FAIL;
      }
      TOSH_MAKE_ADC2_INPUT();
      TOSH_SEL_ADC2_MODFUNC();
      call AD524XControl.start();
      return call AD524X.start(MIC_ADDR1, MIC_TYPE1);
    }
    return FAIL;
  }

  void initPotsHelper() {
    uint8_t _state;
    int _success = -1; //neither success nor fail
    atomic _state = state;

    switch( _state ) {
      case INITPOTS_1:
        _success = call AD524X.setPot(MIC_VRG_ADDR, MIC_VRG_RDAC, vrg, MIC_VRG_TYPE);
        break;
      case INITPOTS_2:
        _success = call AD524X.setPot(MIC_VRC_ADDR, MIC_VRC_RDAC, vrc, MIC_VRC_TYPE);
        break;
      case INITPOTS_3:
        _success = 0;
        //done, default fail means go idle
        break;
    }

    if( _success == SUCCESS ) {
      atomic state = _state+1;
    }
    else if( _success == FAIL ) {
      atomic state = IDLE;
      signal SplitControl.startDone();
    }
  }

  void initPots() {
    result_t _result = FAIL;
    atomic {
      if( state != IDLE ) {
        state = INITPOTS_1;
        _result = SUCCESS;
      }
    }
    if( _result == SUCCESS ) {
      initPotsHelper();
    }
    else {
      signal SplitControl.startDone();
    }
  }

  event void AD524X.startDone(uint8_t _addr, result_t _result, ad524x_type_t _type) {
    uint8_t _state = OFF;
    atomic {
      if (state == START1) {
	state = START2;
      }
      else if (state == START2) {
	state = START_O;
      }
      _state = state;
    }
    if (_state == START2) {
      if (!(call AD524X.start(MIC_ADDR2, MIC_TYPE2))) {
	atomic state = IDLE;
	signal SplitControl.startDone();
      }
    }
    // turn on the microphone circuit
    else if (_state == START_O) {
      if (!(call AD524X.setOutput(MIC_ON_ADDR, MIC_ON_OUTPUT, TRUE, MIC_ON_TYPE))) {
	atomic state = IDLE;
        initPots();
      }
    }
  }

  command result_t SplitControl.stop() {
    uint8_t _state = OFF;
    atomic {
      if (state == IDLE) {
	state = STOP1;
	_state = state;
      }
    }
    if (_state == STOP1) {
      return call AD524X.stop(MIC_ADDR1, MIC_TYPE1);
    }
    return FAIL;
  }

  event void AD524X.stopDone(uint8_t _addr, result_t _result, ad524x_type_t _type) {
    uint8_t _state = OFF;
    atomic {
      if (state == STOP1) {
	state = STOP1;
	_state = state;
      }
      else if (state == STOP2) {
	state = STOP_O;
	_state = state;
      }
    }

    if (_state == STOP2) {
      if (!(call AD524X.stop(MIC_ADDR2, MIC_TYPE2))) {
	atomic state = IDLE;
	signal SplitControl.startDone();
      }
    }
    if (_state == STOP_O) {
      if (!(call AD524X.setOutput(MIC_ON_ADDR, MIC_ON_OUTPUT, FALSE, MIC_ON_TYPE))) { 
	atomic state = IDLE;
	signal SplitControl.stopDone();
      }
    }
  }

  event void AD524X.setOutputDone(uint8_t _addr, bool _output, result_t _result, ad524x_type_t _type) { 
    uint8_t _state = OFF;
    atomic {
      if (state == START_O) {
	_state = state;
	state = IDLE;
      }
      else if (state == STOP_O) {
	_state = state;
	state = IDLE;
      }
    }

    if (_state == START_O) 
      signal SplitControl.startDone();
    else if (_state == STOP_O) {
      call AD524XControl.stop();
      signal SplitControl.stopDone();
    }
  }

  event void AD524X.setPotDone(uint8_t _addr, bool _rdac, result_t _result, ad524x_type_t _type) { 
    uint8_t _state = OFF;

    atomic {
      _state = state;
      if ((state == VRC) || (state == VRG) || (state == THRESH) || (state == DRAIN)) {
        state = IDLE;
      }
    }

    switch( _state ) {
      case VRC: signal Vrc.setDone(vrc, _result); break;
      case VRG: signal Vrg.setDone(vrg, _result); break;
      case DRAIN: signal MicInterruptDrain.setDone(drain, _result); break;
      case THRESH: signal MicInterruptThreshold.setDone(thresh, _result); break;
      default: initPotsHelper();
    }
  }

  event void AD524X.getPotDone(uint8_t _addr, bool _rdac, uint8_t _val, result_t _result, ad524x_type_t _type) { }

  command result_t Vrg.set(uint8_t _value) {
    uint8_t _state = OFF;
    atomic {
      if (state == IDLE) {
        state = VRG;
        _state = state;
      }
    }
    if (_state == VRG) {
      atomic vrg = _value;
      return call AD524X.setPot(MIC_VRG_ADDR, MIC_VRG_RDAC, vrg, MIC_VRG_TYPE);
    }
    return FAIL;
  }

  command uint8_t Vrg.get() {
    return vrg;
  }

  default event void Vrg.setDone(uint8_t value, result_t result) { }

  command result_t Vrc.set(uint8_t _value) {
    uint8_t _state = OFF;
    atomic {
      if (state == IDLE) {
        state = VRC;
        _state = state;
      }
    }
    if (_state == VRC) {
      atomic vrc = _value;
      return call AD524X.setPot(MIC_VRC_ADDR, MIC_VRC_RDAC, vrc, MIC_VRC_TYPE);
    }
    return FAIL;
  }

  command uint8_t Vrc.get() {
    return vrc;
  }

  default event void Vrc.setDone(uint8_t value, result_t result) { }

  command result_t MicInterruptDrain.set(uint8_t _drain) {
    uint8_t _state = OFF;
    atomic {
      if (state == IDLE) {
        state = DRAIN;
        _state = state;
      }
    }
    if (_state == DRAIN) {
      atomic drain = _drain;
      return call AD524X.setPot(MIC_INT_DRAIN_ADDR, MIC_INT_DRAIN_RDAC, thresh, MIC_INT_DRAIN_TYPE);
    }
    return FAIL;
  }

  default event void MicInterruptDrain.setDone(uint8_t _gain, result_t _result) { }

  command uint8_t MicInterruptDrain.get() {
    return drain;
  }

  command result_t MicInterruptThreshold.set(uint8_t _thresh) {
    uint8_t _state = OFF;
    atomic {
      if (state == IDLE) {
        state = THRESH;
        _state = state;
      }
    }
    if (_state == THRESH) {
      atomic thresh = _thresh;
      return call AD524X.setPot(MIC_INT_THRESH_ADDR, MIC_INT_THRESH_RDAC, thresh, MIC_INT_THRESH_TYPE);
    }
    return FAIL;
  }

  default event void MicInterruptThreshold.setDone(uint8_t _gain, result_t _result) { }

  command uint8_t MicInterruptThreshold.get() {
    return thresh;
  }

  async command result_t MicInterrupt.enable() {
    atomic {
      TOSH_MAKE_MIC_INT_INPUT();
      call MicInt.disable();
      call MicInt.clear();
      call MicInt.edge(FALSE);
      call MicInt.enable();
    }
    return SUCCESS;
  }

  async command result_t MicInterrupt.disable() {
    atomic {
      call MicInt.disable();
      call MicInt.clear();
      TOSH_MAKE_MIC_INT_OUTPUT();
    }
    return SUCCESS;
  }

  default async event void MicInterrupt.fired() { }

  async event void MicInt.fired() {
    signal MicInterrupt.fired();
    call MicInt.clear();
  }

  task void dmaDone() {
    void* _buf;
    uint16_t _length;

    atomic {
      state = IDLE;
      _buf = buf;
      _length = length;
    }

    signal Microphone.done(_buf, _length);
  }

  async event void DMA.transferDone(result_t s){
    bool _done = TRUE;
    if (repeat == TRUE) {
	call MSP430ADC.pauseSampling();
	atomic {
	    state = DMA_INUSE_WAIT;
	}
	if (signal Microphone.repeat(buf, length) == SUCCESS) {
	    _done = FALSE;
	}
    }

    if (_done) {
      call MSP430ADC.stopSampling();
      call DMA.stopTransfer();
      post dmaDone();
    }
  }

  async command result_t Microphone.repeatStart(void* _addr, uint16_t _length) {
    result_t result = FAIL;
    atomic {
      if ((state == DMA_INUSE_WAIT) && (_addr != NULL)) {
	buf = _addr;
	length = _length;
	state = DMA_INUSE;
	call DMA.repeatTransfer((void *)ADC12MEM0_,
				buf,
				length);
	call MSP430ADC.resumeSampling();
	result = SUCCESS;
      }
    }
    return result;
  }

  command result_t Microphone.start(void* _addr, uint16_t _length, uint16_t _freq, bool _repeat) {
    uint8_t _state = OFF;
    atomic {
      if (state == IDLE) {
        state = DMA_INUSE;
        _state = state;
	buf = _addr;
	length = _length;
	repeat = _repeat;
      }
    }
    if (_state == DMA_INUSE) {
      call DMAControl.init();
      call DMAControl.setFlags(FALSE,FALSE,FALSE);
      
      call MSP430ADC.bind(ADC12_SETTINGS(MIC_INPUT_CHANNEL,
					 REFERENCE_VREFplus_AVss,
					 SAMPLE_HOLD_4_CYCLES, 
					 SHT_SOURCE_ADC12OSC,
					 SHT_CLOCK_DIV_2,
					 SAMPCON_SOURCE_SMCLK,
					 SAMPCON_CLOCK_DIV_1,
					 MIC_REFVOLT));
      
      call DMA.setupTransfer(DMA_SINGLE_TRANSFER, 
			     DMA_TRIGGER_ADC12IFGx, 
			     DMA_EDGE_SENSITIVE, 
			     (void *)ADC12MEM0_,
			     _addr,
			     _length,
			     DMA_WORD, DMA_WORD,
			     DMA_ADDRESS_UNCHANGED,
			     DMA_ADDRESS_INCREMENTED);
      
      call DMA.startTransfer();

      if (call MSP430ADC.startSampling(_freq) == SUCCESS) {
	return SUCCESS;
      }
      // can't start the transfer, kill the DMA.
      else {
	call DMA.stopTransfer();
	atomic state = IDLE;
      }
    }
    return FAIL;
  }

  async command result_t Microphone.stop() {
    result_t result = FAIL;
    atomic {
      if (state == DMA_INUSE) {
	call MSP430ADC.stopSampling();
	call DMA.stopTransfer();
	result = post dmaDone();
      }
    }
    return result;
  }

  async event result_t MSP430ADC.dataReady(uint16_t data) { return SUCCESS; }

  default async event void Microphone.done(void* _addr, uint16_t _length) { }
  default async event result_t Microphone.repeat(void* _addr, uint16_t _length) { return FAIL; }

}
