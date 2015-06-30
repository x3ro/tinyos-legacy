// $Id: Voltage12M.nc,v 1.1 2005/06/17 00:06:07 jpolastre Exp $
/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * @author Joe Polsatre
 */

includes Voltage12;

module Voltage12M {
  provides {
    interface StdControl;
  }
  uses {
    interface ADCControl;
  }
}
implementation {
  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    result_t ok;
    ok = call ADCControl.init();
    ok &= call ADCControl.bindPort(TOS_ADC_VOLT12_PORT,
				   TOSH_ACTUAL_ADC_VOLT12_PORT);
    return ok;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }
}
