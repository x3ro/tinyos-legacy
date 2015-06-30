// $Id: HPLPowerManagementM.nc,v 1.1 2006/03/06 10:07:40 palfrey Exp $

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

/* Author:  Robert Szewczyk
 *
 * $Id: HPLPowerManagementM.nc,v 1.1 2006/03/06 10:07:40 palfrey Exp $
 */

/**
 * @author Robert Szewczyk
 */


module HPLPowerManagementM {
    provides {
      interface PowerManagement;
    }
}
implementation{  

    bool disabled = TRUE;

    enum {
	IDLE = 0,
	ADC_NR = (1 << SM0),
	POWER_DOWN = (1 << SM1),
	POWER_SAVE = (1 << SM0) + (1 << SM1),
	STANDBY = (1 << SM2) + (1 << SM1),
	EXT_STANDBY =  (1 << SM0) + (1 << SM1) + (1 << SM2)
    };


    uint8_t getPowerLevel() {
	uint8_t diff;
	if (inp(TIMSK) & (~((1<<OCIE0) | (1<<TOIE0)))) { // Are external timers
						       // running?  
	    return IDLE;
	} else if (inp(EIMSK) & (1<<1)) { //GPH: is the sensirion sensor busy?
		return IDLE;
	} else if (bit_is_set(SPCR, SPIE)) { // SPI (Radio stack on mica)
	    return IDLE;
	    //	} else if (bit_is_set(ACSR, ACIE)) { //Analog comparator
	    //	    return IDLE;
	} else if (bit_is_set(ADCSR, ADEN)) { // ADC is enabled
	    return ADC_NR;
	} else if (inp(TIMSK) & ((1<<OCIE0) | (1<<TOIE0))) {
	    diff = inp(OCR0) - inp(TCNT0);
	    if (diff < 16) 
		return EXT_STANDBY;
	    return POWER_SAVE;
	} else {
	    return POWER_DOWN;
	}
    }
    
    async command uint8_t PowerManagement.adjustPower() {
      uint8_t mcu;
	  mcu = inp(MCUCR);
	  mcu &= 0xe3;
	  mcu |= disabled ? IDLE : getPowerLevel();
	  outp(mcu, MCUCR);
	  return 0;
    }

    async command result_t PowerManagement.enable() {
      atomic disabled = FALSE;
      return SUCCESS;
    }

    async command result_t PowerManagement.disable() {
      atomic disabled = TRUE;
      return SUCCESS;
    }
}
