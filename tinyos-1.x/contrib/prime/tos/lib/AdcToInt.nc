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
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 * Authors:		Lin Gu (Modify it to be general ACD reader)
 * Date last modified:  6/25/03
 *
 */
includes sensorboard;

module AdcToInt {
  provides {
    interface StdControl;
  }
  uses {
    interface Clock;
    interface ADC;
    interface StdControl as ADCControl;
    interface IntOutput;
    interface Peek;
  }
}
implementation {
#define MIRR_READ_INTERVAL 64
#define MIRR_STABLIZE 0 /*(MIRR_READ_INTERVAL / MIRR_READ_INTERVAL)*/

  long lTick;

  command result_t StdControl.init() {
    lTick = 0;
    call ADCControl.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call ADCControl.start();
    // return call Clock.setRate(TOS_I4PS, TOS_S4PS);
    return call Clock.setRate(TOS_I16PS, TOS_S16PS);
  }

  command result_t StdControl.stop() {
    call ADCControl.stop();
    return call Clock.setRate(TOS_I0PS, TOS_S0PS);
  }

  event result_t Clock.fire() {
      if (lTick < MIRR_STABLIZE)
        { /////// ??? // need to consider snooze in net disabling and here
          lTick++;
          dbg(DBG_USR1, "lTick: %ld\n", lTick);

          return SUCCESS;
        }

    call ADC.getData();
    return SUCCESS;
  }

  event result_t ADC.dataReady(uint16_t data) {
    return call IntOutput.output(data /*>> 7*/);
    /*    static int nRepeat;

    if (data > 400)
      {
	nRepeat+=16;
	nRepeat &= 0x3f;
      }
    else
      {
	if (nRepeat > 0)
	  nRepeat--;
      }

    if (nRepeat >= 20)
      {
	// TOSH_SET_SOUNDER_CTL_PIN();
	TOSH_CLR_YELLOW_LED_PIN();
       }
    else
      {
	// TOSH_CLR_SOUNDER_CTL_PIN();
	TOSH_SET_YELLOW_LED_PIN();
     }
    return call Peek.lazyBcastInt2(data);
    */

  }

  event result_t IntOutput.outputComplete(result_t success) {
    return SUCCESS;
  }
}

