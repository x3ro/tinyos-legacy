// $Id: HPLADCM.nc,v 1.2 2004/06/01 15:29:45 jlhill Exp $

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
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Version:		$Id: HPLADCM.nc,v 1.2 2004/06/01 15:29:45 jlhill Exp $
 *
 */

// The hardware presentation layer. See hpl.h for the C side.
// Note: there's a separate C side (hpl.h) to get access to the avr macros

// The model is that HPL is stateless. If the desired interface is as stateless
// it can be implemented here (Clock, FlashBitSPI). Otherwise you should
// create a separate component


/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */
module HPLADCM {
  provides {
    interface StdControl;
    interface HPLADC as ADC;
  }
}
implementation
{
  /* The port mapping table */
  bool init_portmap_done;
  uint8_t TOSH_adc_portmap[TOSH_ADC_PORTMAPSIZE];
  
  void init_portmap() {
    /* The default ADC port mapping */
    atomic {
      if( init_portmap_done == FALSE ) {
	int i;
	for (i = 0; i < TOSH_ADC_PORTMAPSIZE; i++)
	  TOSH_adc_portmap[i] = i;
	
	// Setup fixed bindings associated with ATmega128 ADC 
	TOSH_adc_portmap[TOS_ADC_BANDGAP_PORT] = TOSH_ACTUAL_BANDGAP_PORT;
	TOSH_adc_portmap[TOS_ADC_GND_PORT] = TOSH_ACTUAL_GND_PORT;
	init_portmap_done = TRUE;
      }
    }
  }

  command result_t StdControl.init() {
    call ADC.init();
  }

  command result_t StdControl.start() {
  }

  command result_t StdControl.stop() {
    cbi(ADCSR,ADEN);
  }

  async command result_t ADC.init() {
    init_portmap();

    // Enable ADC Interupts, 
    // Set Prescaler division factor to 64 
    atomic {
      //outp(((1 << ADIE) | (6 << ADPS0)),ADCSR); 
      outp(((1 << ADIE) | (4 << ADPS0)),ADCSR); 
      
      outp(0,ADMUX);
    }
    return SUCCESS;
  }

  async command result_t ADC.setSamplingRate(uint8_t rate) {
    uint8_t current_val = inp(ADCSR);
    current_val = (current_val & 0xF8) | (rate & 0x07);
    outp(current_val, ADCSR);
    return SUCCESS;
  }

  async command result_t ADC.bindPort(uint8_t port, uint8_t adcPort) {
    if (port < TOSH_ADC_PORTMAPSIZE &&
	port != TOS_ADC_BANDGAP_PORT &&
	port != TOS_ADC_GND_PORT) {
      init_portmap();
      atomic TOSH_adc_portmap[port] = adcPort;
      return SUCCESS;
    }
    else
      return FAIL;
  }

  async command result_t ADC.samplePort(uint8_t port) {
    atomic {
      outp((TOSH_adc_portmap[port] & 0x1F), ADMUX);
    }
    sbi(ADCSR, ADEN);
    sbi(ADCSR, ADSC);
    
    return SUCCESS;
  }

  async command result_t ADC.sampleAgain() {
    sbi(ADCSR, ADSC);
    return SUCCESS;
  }

  async command result_t ADC.sampleStop() {
    // SIG_ADC does the stop
    return SUCCESS;
  }

  default async event result_t ADC.dataReady(uint16_t done) { return SUCCESS; }

  TOSH_SIGNAL(SIG_ADC) {
    uint16_t data = inw(ADCL);
    data &= 0x3ff;
    sbi(ADCSR, ADIF);
    cbi(ADCSR, ADEN);
    __nesc_enable_interrupt();
    signal ADC.dataReady(data);
  }
}
