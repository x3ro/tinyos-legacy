// $Id: MicDriverM.nc,v 1.3 2005/08/04 21:59:19 jpolastre Exp $
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

/**
 * @author Joe Polastre <info@moteiv.com>
 * Revision:  $Revision: 1.3 $
 *
 */

includes Mic;

module MicDriverM
{
  provides {
    interface SplitControl;
    interface TSBInterrupt as MicInterrupt;
    interface Potentiometer as Vrc;
    interface Potentiometer as Vrg;
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
  };

  uint8_t state;
  uint8_t drain, thresh;
  uint8_t vrg, vrc;

  task void initDone() {
    signal SplitControl.initDone();
  }

  command result_t SplitControl.init() {
    atomic {
      // state is off
      state = OFF;
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
	state = OFF;
	return FAIL;
      }
      TOSH_MAKE_ADC2_INPUT();
      TOSH_SEL_ADC2_MODFUNC();
      call AD524XControl.start();
      return call AD524X.start(MIC_ADDR1, MIC_TYPE1);
    }
    return FAIL;
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
	signal SplitControl.startDone();
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
      // questionable whether this should be here...
      call ADCStdControl.stop();
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
      if ((state == VRC) || (state == VRG) || (state == THRESH) || (state == DRAIN)) {
        _state = state;
        state = IDLE;
      }
    }

    if (_state == VRC) {
      signal Vrc.setDone(vrc, _result);
    }
    if (_state == VRG) {
      signal Vrg.setDone(vrc, _result);
    }
    if (_state == DRAIN) {
      signal MicInterruptDrain.setDone(drain, _result);
    }
    if (_state == THRESH) {
      signal MicInterruptThreshold.setDone(thresh, _result);
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

}
