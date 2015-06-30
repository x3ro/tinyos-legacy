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
/*
 *
 * Authors:	        Kamin Whitehouse, Fred Jiang
 * Date last modified:  3/21/2003
 *
 */

includes sensorboard;

module USoundTxrM {
  provides interface StdControl;
  provides interface UltrasoundTransmit;
}
implementation 
{
  command result_t StdControl.init() {
    TOSH_MAKE_5V_ENABLE_OUTPUT();
	TOSH_MAKE_USOUND_TXR_CTL_OUTPUT();
    TOSH_MAKE_USOUND_SWITCH_OUTPUT();
	
    dbg(DBG_BOOT, "ULTRASOUND transmitter initialized.\n");
    return SUCCESS;
  }

  command result_t StdControl.start() {
	TOSH_SET_5V_ENABLE_PIN();
    TOSH_SET_USOUND_SWITCH_PIN();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
//	  TOSH_CLR_5V_ENABLE_PIN();  // set in MICA board !
	  TOSH_CLR_USOUND_SWITCH_PIN(); 
	  return SUCCESS;
  }

  command result_t UltrasoundTransmit.sendUltrasoundPulse(uint8_t numPulses)
  {
	while(numPulses > 0) {
 		TOSH_SET_USOUND_TXR_CTL_PIN();
		TOSH_uwait(4);
		TOSH_wait_1us();
		TOSH_CLR_USOUND_TXR_CTL_PIN();
		TOSH_uwait(3);
		TOSH_wait_1us();
		TOSH_wait_1us();
		numPulses--;
	}
        return SUCCESS;
  }
}













