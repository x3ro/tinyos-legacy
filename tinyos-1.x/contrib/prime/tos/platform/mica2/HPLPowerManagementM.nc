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
 * $Id: HPLPowerManagementM.nc,v 1.1.1.2 2004/03/06 03:00:47 mturon Exp $
 */

module HPLPowerManagementM {
    provides {
      interface PowerManagement;
      command result_t Enable();
      command result_t Disable();
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
    
    task void doAdjustment() {
	uint8_t foo, mcu;
	foo = getPowerLevel();
	mcu = inp(MCUCR);
	mcu &= 0xe3;
	if ((foo == EXT_STANDBY) || (foo == POWER_SAVE)) {
	    mcu |= IDLE;
	    while ((inp(ASSR) & 0x7) != 0) {
		asm volatile("nop");
	    }
	    mcu &= 0xe3;
	}
	mcu |= foo;
	outp(mcu, MCUCR);
	sbi(MCUCR, SE);
	
    }    
    async command uint8_t PowerManagement.adjustPower() {
        uint8_t mcu;
        if (!disabled)
          post doAdjustment();
        else {
	  mcu = inp(MCUCR);
	  mcu &= 0xe3;
	  mcu |= IDLE;
	  outp(mcu, MCUCR);
   	  sbi(MCUCR, SE);
        }
	return 0;
    }

    command result_t Enable() {
      disabled = FALSE;
      return SUCCESS;
    }

    command result_t Disable() {
      disabled = TRUE;
      return SUCCESS;
    }
}
