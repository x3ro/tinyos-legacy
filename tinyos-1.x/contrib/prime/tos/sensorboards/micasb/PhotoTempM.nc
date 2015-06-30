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

/*  OS component abstraction of the analog photo sensor and */
/*  associated A/D support.  It provides an asynchronous interface */
/*  to the photo sensor. */

/*  PHOTO_INIT command initializes the device */
/*  PHOTO_GET_DATA command initiates acquiring a sensor reading. */
/*  It returns immediately.   */
/*  PHOTO_DATA_READY is signaled, providing data, when it becomes */
/*  available. */
/*  Access to the sensor is performed in the background by a separate */
/* TOS task. */

includes sensorboard;
module PhotoTempM {
  provides interface StdControl as TempStdControl;
  provides interface StdControl as PhotoStdControl;
  provides interface ADC as ExternalPhotoADC;
  provides interface ADC as ExternalTempADC;
  uses {
    interface ADCControl;
    interface ADC as InternalPhotoADC;
    interface ADC as InternalTempADC;
  }
}

implementation {
  enum{
    IDLE = 1,
    BUSY = 2,
    CONTINUOUS = 3
  };
  int state;

  command result_t PhotoStdControl.init() {
    call ADCControl.bindPort(TOS_ADC_PHOTO_PORT, TOSH_ACTUAL_PHOTO_PORT);
    atomic {
      state = IDLE;
    }
    dbg(DBG_BOOT, "PHOTO initialized.\n");    
    return call ADCControl.init();
  }

  command result_t PhotoStdControl.start() {
    atomic {
      TOSH_SET_PHOTO_CTL_PIN();
      TOSH_MAKE_PHOTO_CTL_OUTPUT();
    }
    return SUCCESS;
  }

  command result_t PhotoStdControl.stop() {
    atomic {
      TOSH_CLR_PHOTO_CTL_PIN();
      TOSH_MAKE_PHOTO_CTL_INPUT();
    }
    return SUCCESS;
  }

  command result_t TempStdControl.init() {
    call ADCControl.bindPort(TOS_ADC_TEMP_PORT, TOSH_ACTUAL_TEMP_PORT);
    atomic {
      state = IDLE;
    }
    dbg(DBG_BOOT, "TEMP initialized.\n");    
    return call ADCControl.init();
  }

  command result_t TempStdControl.start() {
    atomic {
      TOSH_SET_TEMP_CTL_PIN();
      TOSH_MAKE_TEMP_CTL_OUTPUT();
    }
    return SUCCESS;
  }

  command result_t TempStdControl.stop() {
    atomic {
      TOSH_CLR_TEMP_CTL_PIN();
      TOSH_MAKE_TEMP_CTL_INPUT();
    }
    return SUCCESS;
  }

  async command result_t ExternalTempADC.getData(){
    uint8_t oldState;
    atomic {
      oldState = state;
      if (state == IDLE) {
	state = BUSY;
      }
    }
    if (oldState == IDLE){
      TOSH_CLR_PHOTO_CTL_PIN();
      TOSH_MAKE_PHOTO_CTL_INPUT();
      TOSH_SET_TEMP_CTL_PIN();
      TOSH_MAKE_TEMP_CTL_OUTPUT();
      return call InternalTempADC.getData();
    }
    return FAIL;
  }

  async command result_t ExternalPhotoADC.getData(){
     uint8_t oldState;
    atomic {
      oldState = state;
      if (state == IDLE) {
	state = BUSY;
      }
    }
    if (oldState == IDLE){
      TOSH_CLR_TEMP_CTL_PIN();
      TOSH_MAKE_TEMP_CTL_INPUT();
      TOSH_SET_PHOTO_CTL_PIN();
      TOSH_MAKE_PHOTO_CTL_OUTPUT();
      return call InternalPhotoADC.getData();
    }
    return FAIL;
  }

  async command result_t ExternalTempADC.getContinuousData(){
     uint8_t oldState;
    atomic {
      oldState = state;
      if (state == IDLE) {
	state = CONTINUOUS;
      }
    }
    if (oldState == IDLE){
      TOSH_CLR_PHOTO_CTL_PIN();
      TOSH_MAKE_PHOTO_CTL_INPUT();
      TOSH_SET_TEMP_CTL_PIN();
      TOSH_MAKE_TEMP_CTL_OUTPUT();
      return call InternalTempADC.getContinuousData();
    }
    return FAIL;
  }

  async command result_t ExternalPhotoADC.getContinuousData(){
   uint8_t oldState;
    atomic {
      oldState = state;
      if (state == IDLE) {
	state = CONTINUOUS;
      }
    }
    if (oldState == IDLE){
      TOSH_CLR_TEMP_CTL_PIN();
      TOSH_MAKE_TEMP_CTL_INPUT();
      TOSH_SET_PHOTO_CTL_PIN();
      TOSH_MAKE_PHOTO_CTL_OUTPUT();
      return call InternalPhotoADC.getContinuousData();     
    }
    return FAIL;
  }

  default async event result_t ExternalPhotoADC.dataReady(uint16_t data) {
    return SUCCESS;
  }

  async event result_t InternalPhotoADC.dataReady(uint16_t data){
    uint8_t oldState;
    atomic {
      oldState = state;
      if (state == BUSY) {
	state = IDLE;
      }
    }
    if (oldState == BUSY){
	//TOSH_CLR_PHOTO_CTL_PIN();
	//TOSH_MAKE_PHOTO_CTL_INPUT();
      return signal ExternalPhotoADC.dataReady(data);
    }else if (oldState == CONTINUOUS){
      int ret;
      ret = signal ExternalPhotoADC.dataReady(data);
      if (ret == FAIL){
	//TOSH_CLR_PHOTO_CTL_PIN();
	//TOSH_MAKE_PHOTO_CTL_INPUT();
	atomic {
	  state = IDLE;
	}
      }
      return ret;
    }
    return FAIL;
  }

  default async event result_t ExternalTempADC.dataReady(uint16_t data) {
    return SUCCESS;
  }

  async event result_t InternalTempADC.dataReady(uint16_t data){
    uint8_t oldState;
    atomic {
      oldState = state;
      if (state == BUSY) {
	state = IDLE;
      }
    }
    if (oldState == BUSY){
      //TOSH_CLR_TEMP_CTL_PIN();
      //TOSH_MAKE_TEMP_CTL_INPUT();
      return signal ExternalTempADC.dataReady(data);
    }else if (oldState == CONTINUOUS){
      int ret;
      ret = signal ExternalTempADC.dataReady(data);
      if (ret == FAIL){
	//TOSH_CLR_TEMP_CTL_PIN();
	//TOSH_MAKE_TEMP_CTL_INPUT();
	atomic {
	  state = IDLE;
	}
      }
      return ret;
    }
    return FAIL;
  }

}
