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
module AnomTwoThermM {
  provides interface StdControl;
  provides interface ADC as ExternalTherm1ADC;
  provides interface ADC as ExternalTherm2ADC;
  provides interface ADC as ExternalAnomADC;
  uses {
    interface ADCControl;
    interface ADC as InternalTherm1ADC;
    interface ADC as InternalTherm2ADC;
    interface ADC as InternalAnomADC;
  }
}

implementation {
  enum{
    IDLE = 1,
    BUSY = 2,
    CONTINUOUS = 3
  };
  int state;

  command result_t StdControl.init() {
    call ADCControl.bindPort(TOS_ADC_1_PORT, TOSH_ACTUAL_1_PORT);
    call ADCControl.bindPort(TOS_ADC_2_PORT, TOSH_ACTUAL_2_PORT);
    call ADCControl.bindPort(TOS_ADC_3_PORT, TOSH_ACTUAL_3_PORT);
    state = IDLE;
    dbg(DBG_BOOT, "PHOTO initialized.\n");    
    return call ADCControl.init();
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    TOSH_CLR_THERM1_CTL_PIN();
    TOSH_CLR_THERM2_CTL_PIN();
    return SUCCESS;
  }

  command result_t ExternalAnomADC.getData(){
    if (state == IDLE){
      state = BUSY;
      return call InternalAnomADC.getData();
    }
    return FAIL;
  }

  command result_t ExternalTherm2ADC.getData(){
    if (state == IDLE){
      TOSH_MAKE_THERM2_CTL_OUTPUT();
      TOSH_SET_THERM2_CTL_PIN();
      state = BUSY;
      return call InternalTherm2ADC.getData();
    }
    return FAIL;
  }

  command result_t ExternalTherm1ADC.getData(){
    if (state == IDLE){
      TOSH_MAKE_THERM1_CTL_OUTPUT();
      TOSH_SET_THERM1_CTL_PIN();
      state = BUSY;
      return call InternalTherm1ADC.getData();
    }
    return FAIL;
  }

  command result_t ExternalAnomADC.getContinuousData(){
    if (state == IDLE){
      state = CONTINUOUS;
      return call InternalAnomADC.getContinuousData();
    }
    return FAIL;
  }

  command result_t ExternalTherm2ADC.getContinuousData(){
    if (state == IDLE){
      TOSH_MAKE_THERM2_CTL_OUTPUT();
      TOSH_SET_THERM2_CTL_PIN();
      state = CONTINUOUS;
      return call InternalTherm2ADC.getContinuousData();
    }
    return FAIL;
  }

  command result_t ExternalTherm1ADC.getContinuousData(){
    if (state == IDLE){
      TOSH_MAKE_THERM1_CTL_OUTPUT();
      TOSH_SET_THERM1_CTL_PIN();
      state = CONTINUOUS;
      return call InternalTherm1ADC.getContinuousData();     
    }
    return FAIL;
  }

  default event result_t ExternalAnomADC.dataReady(uint16_t data) {
    return SUCCESS;
  }

  event result_t InternalAnomADC.dataReady(uint16_t data){
    if (state == BUSY){
      state = IDLE;
      return signal ExternalAnomADC.dataReady(data);
    }else if (state == CONTINUOUS){
      int ret;
      ret = signal ExternalAnomADC.dataReady(data);
      if (ret == FAIL){
        state = IDLE;
      }
      return ret;
    }
    return FAIL;
  }

  default event result_t ExternalTherm1ADC.dataReady(uint16_t data) {
    return SUCCESS;
  }

  event result_t InternalTherm1ADC.dataReady(uint16_t data){
    if (state == BUSY){
      TOSH_CLR_THERM1_CTL_PIN();
      state = IDLE;
      return signal ExternalTherm1ADC.dataReady(data);
    }else if (state == CONTINUOUS){
      int ret;
      ret = signal ExternalTherm1ADC.dataReady(data);
      if (ret == FAIL){
	TOSH_CLR_THERM1_CTL_PIN();
	state = IDLE;
      }
      return ret;
    }
    return FAIL;
  }

  default event result_t ExternalTherm2ADC.dataReady(uint16_t data) {
    return SUCCESS;
  }

  event result_t InternalTherm2ADC.dataReady(uint16_t data){
    if (state == BUSY){
      TOSH_CLR_THERM2_CTL_PIN();
      state = IDLE;      
      return signal ExternalTherm2ADC.dataReady(data);
    }else if (state == CONTINUOUS){
      int ret;
      ret = signal ExternalTherm2ADC.dataReady(data);
      if (ret == FAIL){
	TOSH_CLR_THERM2_CTL_PIN();
	state = IDLE;      
      }
      return ret;
    }
    return FAIL;
  }

}
