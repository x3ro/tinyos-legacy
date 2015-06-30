// $Id: MicM.nc,v 1.1.1.1 2006/05/04 23:08:22 ucsbsensornet Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
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
 * Revision:		$Rev$
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

/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */


includes sensorboard;
module MicM {
  provides interface StdControl;
  provides interface Mic;
  provides interface MicInterrupt;
  uses {
    interface ADCControl;
    interface StdControl as PotControl;
    interface I2CPot;
  }
}
implementation {

  command result_t StdControl.init() {
    call ADCControl.bindPort(TOS_ADC_MIC_PORT, TOSH_ACTUAL_MIC_PORT);
    TOSH_MAKE_MIC_CTL_OUTPUT();
    TOSH_CLR_MIC_CTL_PIN();
    TOSH_MAKE_MIC_MUX_SEL_OUTPUT();
    TOSH_CLR_MIC_MUX_SEL_PIN();
    TOSH_MAKE_TONE_DECODE_SIGNAL_INPUT();
    call MicInterrupt.disable();
    return rcombine(call ADCControl.init(), call PotControl.init());
  }

  command result_t StdControl.start() {
    TOSH_SET_MIC_CTL_PIN();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call MicInterrupt.disable();
    TOSH_MAKE_MIC_CTL_OUTPUT();
    TOSH_CLR_MIC_CTL_PIN();
    return SUCCESS;
  }

  command result_t Mic.muxSel(uint8_t sel){
    if (sel == 0){
      TOSH_CLR_MIC_MUX_SEL_PIN();      
      return SUCCESS;
    }else if (sel == 1){
      TOSH_SET_MIC_MUX_SEL_PIN();
      return SUCCESS;
    }
    return FAIL;
  }

  async command result_t MicInterrupt.enable(){
    sbi(EIMSK, INT3);
    return SUCCESS;
  }

  async command result_t MicInterrupt.disable(){
    cbi(EIMSK, INT3);
    return SUCCESS;
  }

  command result_t Mic.gainAdjust(uint8_t val){
    return call I2CPot.writePot(TOS_MIC_POT_ADDR, 0, val);
  }

  event result_t I2CPot.readPotDone(char data, bool result){
    return SUCCESS;
  }

  event result_t I2CPot.writePotDone(bool result){
    return SUCCESS;
  }

  command uint8_t Mic.readToneDetector(){
    return TOSH_READ_TONE_DECODE_SIGNAL_PIN();
  }  


  default async event result_t MicInterrupt.toneDetected() {
    return SUCCESS;
  }
 
#ifndef PLATFORM_PC
  TOSH_SIGNAL(SIG_INTERRUPT3) {
    call MicInterrupt.disable();
    __nesc_enable_interrupt();
    signal MicInterrupt.toneDetected();
  }
#endif
}

