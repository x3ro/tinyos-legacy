// $Id: HPLADCC.nc,v 1.8 2003/10/07 21:46:28 idgay Exp $

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
 * Revision:		$Rev$
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
module HPLADCC {
  provides interface HPLADC as ADC;
}
implementation
{
  /* The port mapping table */
  bool init_portmap_done;
  enum {
    TOSH_ADC_PORTMAPSIZE = 10
  };

  uint8_t TOSH_adc_portmap[TOSH_ADC_PORTMAPSIZE];

  void init_portmap() {
    /* The default ADC port mapping */
    atomic {
      if( init_portmap_done == FALSE ) {
	int i;
	for (i = 0; i < TOSH_ADC_PORTMAPSIZE; i++)
	  TOSH_adc_portmap[i] = i;
	init_portmap_done = TRUE;
      }
    }
  }

  async command result_t ADC.init() {
    init_portmap();

    outp(0x04, ADCSR); // 250KHz ADC clock (4MHz/16)
	
    cbi(ADCSR, ADSC);
    sbi(ADCSR, ADIF);
    sbi(ADCSR, ADIE);
    cbi(ADCSR, ADEN);

    return SUCCESS;
  }

  async command result_t ADC.setSamplingRate(uint8_t rate) {
    uint8_t current_val = inp(ADCSR);
    current_val = (current_val & 0xF8) | (rate & 0x07);
    outp(current_val, ADCSR);
    return SUCCESS;
  }
  
  async command result_t ADC.bindPort(uint8_t port, uint8_t adcPort) {
    if (port < TOSH_ADC_PORTMAPSIZE)
      {
	atomic {
	  init_portmap();
	  TOSH_adc_portmap[port] = adcPort;
	}
	return SUCCESS;
      }
    else
      return FAIL;
  }

  async command result_t ADC.samplePort(uint8_t port) {
    atomic {
      outp(TOSH_adc_portmap[port], ADMUX);
      if (TOSH_adc_portmap[port] == 8 && port == 8)
	TOSH_SET_PW2_PIN();
      sbi(ADCSR, ADEN);
      sbi(ADCSR, ADSC);
    }
    return SUCCESS;
  }

  async command result_t ADC.sampleAgain() {
    sbi(ADCSR, ADSC);
    return SUCCESS;
  }

  async command result_t ADC.sampleStop() {
    cbi(ADCSR, ADEN);
    return SUCCESS;
  }

  default async event result_t ADC.dataReady(uint16_t done) { return SUCCESS; }
  TOSH_SIGNAL(SIG_ADC) {
    uint16_t data = __inw(ADCL);

    __nesc_enable_interrupt();
    signal ADC.dataReady(data);
  }
}
