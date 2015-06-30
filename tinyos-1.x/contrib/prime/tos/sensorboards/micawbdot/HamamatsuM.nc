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
 * $Id: HamamatsuM.nc,v 1.1.1.2 2004/03/06 03:00:49 mturon Exp $
 */

includes sensorboard;
module HamamatsuM {
  provides {
    interface ADC[uint8_t id];
    interface SplitControl;
  }
  uses {
    interface ADC as Hamamatsu1;
    interface ADC as Hamamatsu2;
    interface ADCControl;
  }
}
implementation {

  char state;

  enum { IDLE = 0, SAMPLE, POWEROFF };

  task void initDone() {
    signal SplitControl.initDone();
  }

  task void startDone() {
    signal SplitControl.startDone();
  }

  task void stopDone() {
    signal SplitControl.stopDone();
  }

  command result_t SplitControl.init() {
    state = POWEROFF;
    call ADCControl.init();
    post initDone();
    return SUCCESS;
  }

  command result_t SplitControl.start() {
    state = IDLE;
    post startDone();
    return SUCCESS;
  }

  command result_t SplitControl.stop() {
    state = POWEROFF;
    post stopDone();
    return SUCCESS;
  }

  // no such thing
  command result_t ADC.getContinuousData[uint8_t id]() {
    return FAIL;
  }

  command result_t ADC.getData[uint8_t id]() {
    if (state == IDLE)
    {
      state = SAMPLE;
      if (id == 1)
	return call Hamamatsu1.getData();
      else if (id == 2)
        return call Hamamatsu2.getData();
    }
    state = IDLE;
    return FAIL;
  }

  default event result_t ADC.dataReady[uint8_t id](uint16_t data)
  {
    return SUCCESS;
  }

  event result_t Hamamatsu1.dataReady(uint16_t data){ 
    if (state == SAMPLE) {
	state = IDLE;
	signal ADC.dataReady[1](data);
    }
    return SUCCESS;
  }

  event result_t Hamamatsu2.dataReady(uint16_t data){ 
    if (state == SAMPLE) {
	state = IDLE;
	signal ADC.dataReady[2](data);
    }
    return SUCCESS;
  }

}

