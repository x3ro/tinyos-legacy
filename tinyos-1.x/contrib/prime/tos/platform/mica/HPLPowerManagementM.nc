/*
 * @(#)HPLPowerManagementM.nc
 *
 * "Copyright (c) 2003 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Author:  Robert Szewczyk
 *
 * $Id: HPLPowerManagementM.nc,v 1.1.1.2 2004/03/06 03:00:46 mturon Exp $
 */

module HPLPowerManagementM {
    provides interface PowerManagement;
}
implementation{  
   enum {
	IDLE,
	ADC_NR,
	POWER_SAVE,
	POWER_DOWN
    };

    uint8_t io_count;
    
    uint8_t getPowerLevel() {
	if (inp(TIMSK) & (~((1<<OCIE0) | (1<<TOIE0)))) { // Are external timers
						       // running?  
	    return IDLE;
	} else if (bit_is_set(SPCR, SPIE)) { // SPI (Radio stack on mica)
	    return IDLE;
	} else if (inp(UCR) & ((1 << TXCIE) | (1 << RXCIE))) { // UART
	    return IDLE;
	    //	} else if (bit_is_set(ACSR, ACIE)) { //Analog comparator
	    //	    return IDLE;
	} else if (bit_is_set(ADCSR, ADEN)) { // ADC is enabled
	    return ADC_NR;
	} else if (inp(TIMSK) & ((1<<OCIE0) | (1<<TOIE0))) {
	    return POWER_SAVE;
	} else {
	    return POWER_DOWN;
	}
    }

    async command uint8_t PowerManagement.adjustPower() {
	uint8_t level = getPowerLevel();
	switch (level) {
	case IDLE:
	  cbi(MCUCR,SM0);
	  cbi(MCUCR,SM1);
	  break;
	case ADC_NR:
	  sbi(MCUCR,SM0);
	  cbi(MCUCR,SM1);
	  break;
	case POWER_SAVE:
	  sbi(MCUCR,SM0);
	  sbi(MCUCR,SM1);
	  break;
	case POWER_DOWN:
	  cbi(MCUCR,SM0);
	  sbi(MCUCR,SM1);
	  break;
	}
	return level;
    }
}
