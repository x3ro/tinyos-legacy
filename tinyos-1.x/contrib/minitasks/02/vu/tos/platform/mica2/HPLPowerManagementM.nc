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
 * $Id: HPLPowerManagementM.nc,v 1.1 2003/06/01 19:06:06 mmaroti Exp $
 */

module HPLPowerManagementM {
    provides interface PowerManagement;
}
implementation{  
    enum {
	IDLE = 0,
	ADC_NR = (1 << SM0),
	POWER_DOWN = (1 << SM1),
	POWER_SAVE = (1 << SM0) + (1 << SM1),
	STANDBY = (1 << SM2) + (1 << SM1),
	EXT_STANDBY =  (1 << SM0) + (1 << SM1) + (1 << SM2)
    };


    uint8_t getPowerLevel() {
	int8_t diff;
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
	    return EXT_STANDBY;
	} else {
	    return POWER_DOWN;
	}
    }
    
    task void doAdjustment() {
	uint8_t foo, mcu;
	foo = getPowerLevel();
	//foo = IDLE;
	mcu = inp(MCUCR);
	mcu &= 0xe3;
	mcu |= foo;
//	VANDY: Disable power management for now because 
//		it interferes with acoustic ranging on the MICA2
//	outp(mcu, MCUCR);
//	sbi(MCUCR, SE);
    }    
    command uint8_t PowerManagement.adjustPower() {
	post doAdjustment();
	return 0;
    }
}
