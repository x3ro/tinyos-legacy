//$Id: PIRM.nc,v 1.2 2005/08/23 21:15:04 jwhui Exp $

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
 * @author Jonathan Hui
 */

includes sensorboard;

module PIRM {
  provides {
    interface PIR;
    interface StdControl;
  }
  uses {
    interface ADCControl;
    interface StdControl as PIRControl;
  }
}

implementation {

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call ADCControl.init();
    call ADCControl.bindPort ( TOS_ADC_PIR_PORT, TOSH_ACTUAL_ADC_PIR_PORT );
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t PIR.PIROn() {
    call PIRControl.start();
    return SUCCESS;
  }

  command result_t PIR.PIROff() {
    call PIRControl.stop();
    return SUCCESS; 
  }

  command result_t PIR.adjustDetect(uint8_t val) {
    return FAIL;
  }

  command result_t PIR.adjustQuad(uint8_t val) {
    return FAIL;
  }

  command result_t PIR.readDetect() {
    return FAIL;
  }

  command result_t PIR.readQuad() {
    return FAIL;
  }

}

