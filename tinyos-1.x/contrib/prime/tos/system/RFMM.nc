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

/*
 * This component performs bit level control over the RF Monolitics radio.
 * Addtionally, it controls the amount of time per bit by using TCNT1.
 * The sample period can be set to 1/2x, 3/4x, and x. Where x is the 
 * bit transmisison period. 1/2 and 3/4 are provided to do sampling 
 * and then read at the point half way between samples.
 * 
 */

module RFMM
{
  provides {
    interface StdControl as Control;
    interface Radio;
  }
  uses interface HPLRFM as RFM;
}
implementation
{
  enum {
    RECEIVE_MODE = 0,
    TRANSMIT_MODE = 1,
    LOW_POWER_MODE = 2,
    MYSTERIOUS_MODE = 3
  };

  uint8_t state;

  command result_t Control.init() {
    state = RECEIVE_MODE;
    return call RFM.init();
  }

  /* This command sets the RFM component (radio) into different power mode */
  command result_t Control.start() {
    return SUCCESS;
  }
  

  command result_t Control.stop() {
    call RFM.powerOff();
    call RFM.disableTimer();
    state = LOW_POWER_MODE;
    return SUCCESS;
  }
  
  
  /* This is a SIGNAL handler that timer1 generates to trigger this
     component to sample on the radio */
  event result_t RFM.bitEvent() {
    switch (state) 
      {
      case TRANSMIT_MODE:
	signal Radio.txBitDone();
	break;

      case RECEIVE_MODE:
	signal Radio.rxBit(call RFM.rxBit());
	break;
      }
    return SUCCESS;
  }

  /* This command tells the RFM to transmit bit "data" */
  command result_t Radio.txBit(uint8_t data) {
    if (state != TRANSMIT_MODE)
      return FAIL;
    return call RFM.txBit(data);
  }

  /* This command sets the RFM component (radio) into transmit mode */
  command result_t Radio.txMode() {
    if (state == LOW_POWER_MODE)
      return FAIL;

    dbg(DBG_RADIO, "RADIO: set TX mode....\n");
    state = TRANSMIT_MODE;

    return call RFM.txMode();
  }

  /* This command sets the RFM component (radio) into receiving mode */
  command result_t Radio.rxMode() {
    if (state == LOW_POWER_MODE)
      return FAIL;

    dbg(DBG_RADIO, "RADIO: set RX mode....\n");
    state = RECEIVE_MODE;

    return call RFM.rxMode();
  }

  command result_t Radio.setBitRate(char level) {
    return call RFM.setBitRate(level);
  }
}
