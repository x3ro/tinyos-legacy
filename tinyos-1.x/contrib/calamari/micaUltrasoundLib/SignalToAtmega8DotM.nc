// $Id: SignalToAtmega8DotM.nc,v 1.1 2003/10/09 23:36:23 fredjiang Exp $

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

module SignalToAtmega8DotM {
  provides interface StdControl;
  provides interface SignalToAtmega8;
}
implementation 
{
  uint8_t state=0;

  command result_t StdControl.init() {
	  if (state == 0){ 
	    TOSH_MAKE_PWM1B_OUTPUT();
	    TOSH_SET_PWM1B_PIN();
	    TOSH_uwait(6);
	    state = 1;
	  }
	  return SUCCESS;
  }

  command result_t StdControl.start() {
	  return SUCCESS;
  }
  
  command result_t StdControl.stop() {
	  return SUCCESS;
  }
  
  command result_t SignalToAtmega8.sendSignal(){
	  TOSH_CLR_PWM1B_PIN();
	  TOSH_uwait(6);
	  TOSH_SET_PWM1B_PIN();
	  return SUCCESS;
  }	  
}





