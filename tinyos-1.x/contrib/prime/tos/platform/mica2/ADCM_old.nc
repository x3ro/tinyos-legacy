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
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 */

/*  OS component abstraction of the analog to digital converter
 * It provides an asynchronous interface.
 */

/*  ADC_INIT command initializes the device */
/*  ADC_GET_DATA command initiates acquiring a sensor reading. */
/*  It returns immediately.   */
/*  ADC_DATA_READY is signaled, providing data, when it becomes */
/*  available. */
/*  Access to the sensor is performed in the background by a separate */
/* TOS task. */

module ADCM 
{
  provides {
    interface ADC[uint8_t port];
    interface ADCControl;
  }
  uses interface HPLADC;
}
implementation
{

  enum {
    IDLE = 0,
    SINGLE_CONVERSION = 1,
    CONTINUOUS_CONVERSION = 2
  };

  uint8_t state;
  uint8_t tosPort;

  /* ADC_INIT: initialize the A/D to access the photo sensor */
  command result_t ADCControl.init() {
    state = IDLE;

    dbg(DBG_BOOT, ("ADC initialized.\n"));

    return call HPLADC.init();
  }

  command result_t ADCControl.setSamplingRate(uint8_t rate) {
    return call HPLADC.setSamplingRate(rate);
  }

  command result_t ADCControl.bindPort(uint8_t port, uint8_t adcPort) {
    return call HPLADC.bindPort(port, adcPort);
  }

  default event result_t ADC.dataReady[uint8_t port](uint16_t data) {
    return FAIL; // ensures ADC is disabled if no handler
  }

  event result_t HPLADC.dataReady(uint16_t data) {
    uint8_t port = tosPort;
    result_t ok;

    switch (state)
      {
      case IDLE:
	return SUCCESS;

      case SINGLE_CONVERSION:
	call HPLADC.sampleStop();
	state = IDLE;
	break;

      case CONTINUOUS_CONVERSION:
	call HPLADC.sampleAgain();
	break;
      }

    dbg(DBG_ADC, "adc_tick: port %d with value %i \n", port, (int)data);
    ok = signal ADC.dataReady[port](data);
    if (ok == FAIL && state == CONTINUOUS_CONVERSION)
      {
	call HPLADC.sampleStop();
	state = IDLE;
      }
    return SUCCESS;
  }

  result_t startGet(uint8_t newState, uint8_t port) {
    if (state == IDLE)
      {
    	state = newState;
	tosPort = port;
	return call HPLADC.samplePort(port);
      }
    return FAIL;
  }

  command result_t ADC.getData[uint8_t port]() {
    return startGet(SINGLE_CONVERSION, port);
  }

  command result_t ADC.getContinuousData[uint8_t port]() {
    return startGet(CONTINUOUS_CONVERSION, port);
  }
}
