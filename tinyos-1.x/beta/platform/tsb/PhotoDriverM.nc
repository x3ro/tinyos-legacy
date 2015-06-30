// $Id: PhotoDriverM.nc,v 1.3 2005/08/04 21:59:19 jpolastre Exp $
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

includes Photo;

module PhotoDriverM
{
  provides {
    interface SplitControl;
    interface Potentiometer;
  }
  uses {
    interface AD524X;
    interface ADCControl;
    interface StdControl as ADCStdControl;
    interface StdControl as AD524XControl;
    interface Leds;
  }
}

implementation
{

  enum {
    OFF = 0,
    IDLE,
    START,
    START_O,
    STOP,
    STOP_O,
    GAIN
  };

  uint8_t state;
  uint8_t gain;

  task void initDone() {
    signal SplitControl.initDone();
  }

  command result_t SplitControl.init() {
    atomic {
      // state is off
      state = OFF;
      // default pot state is in the middle
      gain = 0xFF >> 1;
    }
    call ADCStdControl.init();
    call AD524XControl.init();
    return post initDone();
  }

  command result_t SplitControl.start() {
    uint8_t _state = OFF;
    atomic {
      if (state == OFF) {
	state = START;
	_state = state;
      }
    }
    if (_state == START) {
      call ADCStdControl.start();
      call ADCControl.init();
      if (!call ADCControl.bindPort(TOS_ADC_PHOTO_PORT, 
				    TOSH_ACTUAL_ADC_PHOTO_PORT)) {
	state = OFF;
	return FAIL;
      }
      TOSH_SEL_ADC3_MODFUNC();
      call AD524XControl.start();
      return call AD524X.start(PHOTO_ADDR, PHOTO_TYPE);
    }
    return FAIL;
  }

  event void AD524X.startDone(uint8_t _addr, result_t _result, ad524x_type_t type) {
    uint8_t _state = OFF;
    atomic {
      if (state == START) {
	state = START_O;
	_state = state;
      }
    }
    if (_state == START_O) {
      if (!(call AD524X.setOutput(PHOTO_ON_ADDR, PHOTO_ON_OUTPUT, TRUE, PHOTO_ON_TYPE))) {
	atomic state = IDLE;
	signal SplitControl.startDone();
      }
    }
  }

  command result_t SplitControl.stop() {
    uint8_t _state = OFF;
    atomic {
      if (state == IDLE) {
	state = STOP;
	_state = state;
      }
    }
    if (_state == STOP) {
      return call AD524X.stop(PHOTO_ADDR, PHOTO_TYPE);
    }
    return FAIL;
  }

  event void AD524X.stopDone(uint8_t addr, result_t result, ad524x_type_t type) {
    uint8_t _state = OFF;
    atomic {
      if (state == STOP) {
	state = STOP_O;
	_state = state;
      }
    }
    if (_state == STOP_O) {
      if (!(call AD524X.setOutput(PHOTO_ON_ADDR, PHOTO_ON_OUTPUT, FALSE, PHOTO_ON_TYPE))) {
	atomic state = IDLE;
	signal SplitControl.stopDone();
      }
    }
  }

  event void AD524X.setOutputDone(uint8_t _addr, bool _output, result_t _result, ad524x_type_t _type) { 
    uint8_t _state = OFF;
    atomic {
      if ((state == START_O) || (state == STOP_O)) {
	_state = state;
	state = IDLE;
      }
    }

    if (_state == START_O) 
      signal SplitControl.startDone();
    else if (_state == STOP_O) {
      // turn off the potentiometer
      call AD524XControl.stop();
      signal SplitControl.stopDone();
    }
  }

  event void AD524X.setPotDone(uint8_t _addr, bool _rdac, result_t _result, ad524x_type_t _type) { 
    uint8_t _state = OFF;
    atomic {
      if (state == GAIN) {
	_state = state;
	state = IDLE;
      }
    }

    if (_state == GAIN) {
      signal Potentiometer.setDone(gain, _result);
    }
  }

  event void AD524X.getPotDone(uint8_t addr, bool rdac, uint8_t value, result_t result, ad524x_type_t type) { }

  command result_t Potentiometer.set(uint8_t _gain) {
    uint8_t _state = OFF;
    atomic {
      if (state == IDLE) {
	state = GAIN;
	_state = state;
      }
    }
    if (_state == GAIN) {
      atomic gain = _gain;
      return call AD524X.setPot(PHOTO_GAIN_ADDR, PHOTO_GAIN_RDAC, gain, PHOTO_GAIN_TYPE);
    }
    return FAIL;
  }

  command uint8_t Potentiometer.get() {
    return gain;
  }

  default event void Potentiometer.setDone(uint8_t _gain, uint8_t _result) { }

}
