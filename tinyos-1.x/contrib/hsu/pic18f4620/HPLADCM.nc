// $Id: HPLADCM.nc,v 1.2 2005/05/19 11:11:13 hjkoerber Exp $

/*								
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
 * @author: Jason Hill
 * @author: David Gay
 * @author: Philip Levis 
 * @author: Hans-Joerg Koerber 
 *          <hj.koerber@hsu-hh.de>
 *	    (+49)40-6541-2638/2627
 *
 * $Date: 2005/05/19 11:11:13 $
 * $Revision: 1.2 $
 */



module HPLADCM {
  provides {
    interface StdControl;
    interface HPLADC as ADC;   
  }
  uses {
    interface PIC18F4620Interrupt as ADC_Interrupt;
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
     ADCON0bits_ADON =  0;           // power down the a/d converter module
  }

  async command result_t ADC.init() {
    init_portmap();   
    atomic { 
      TRISA_register = 0x2f;                  // make all Port A pins - except RA4 which is RX_RF_Gain - input
      
      ADCON1bits_PCFG3 = 1;          // configuration:
      ADCON1bits_PCFG2 = 0;          //        all Port A input pins become analog inputs
      ADCON1bits_PCFG1 = 1;          
      ADCON1bits_PCFG0 = 0;          
      
      ADCON1bits_VCFG1 = 0;          //        Vref- = Vss
      ADCON1bits_VCFG0 = 1;          //        Vref+ = AN3 (reference voltage supply)

      ADCON2bits_ACQT2 = 0;          //        set  aquisition time to 2*Ta = 3.2 µsec
      ADCON2bits_ACQT1 = 0;                                 
      ADCON2bits_ACQT0 = 1;
     
      ADCON2bits_ADCS2 = 1;          //        clock select:
      ADCON2bits_ADCS1 = 1;          //             Fosc/64 
      ADCON2bits_ADCS0 = 0;          //             (see PIC Datasheet, §19.1, page 229)

      ADCON2bits_ADFM = 1;           //        a/d result format = right justified

      PIR1bits_ADIF = 0;             // a/d converter module clear interrupt flag

      PIE1bits_ADIE = 1;             // a/d converter module interrupt enable
      }
    return SUCCESS;
  }

  async command result_t ADC.setSamplingRate(uint8_t rate) { // for the adjustment of the sampling rates refer to  PIC Datasheet, Table 19.1, page 229
    ADCON2bits_ADCS0 = rate & 0x1;                           // if a x-tal of 10 Mhz and PLL (->40 MHz)is used there remains just one option:
    ADCON2bits_ADCS1 = rate & 0x2;                           // rate = 6  ->  Tad = 64  Tosc -> sampling time =  12*Tad + 2*Tad = 22.4 us -> 44.64 kHz
    ADCON2bits_ADCS2 = rate & 0x4;                           // if sleep mode is enabled the sampling time is increased by 350 us, cause we need a stable Vref
                                                             // -> 372.4 us -> 2.7 kHz 
    return SUCCESS;                                         
    //                                                                                                                                                     
  }                                                          // additionally programm overhead has to be taken into account if sampling frequency shpuld be determined

  async command result_t ADC.bindPort(uint8_t port, uint8_t adcPort) {
    if (port < TOSH_ADC_PORTMAPSIZE) {
      init_portmap();
      atomic TOSH_adc_portmap[port] = adcPort;
      return SUCCESS;
    }
    else
      return FAIL;
  }

  async command result_t ADC.samplePort(uint8_t port) {
    static uint8_t startflag=0; 
    uint8_t selected_channel;
 
    selected_channel = TOSH_adc_portmap[port]<<2;      // shift 2 because the the channel select bits of ADCON0 register are bits 2-5  
  
    atomic {
 
      ADCON0_register = selected_channel |(ADCON0_register&0xC3);        // select the  a/d input channel   
    }

    ADCON0bits_ADON = 1;                               // power up the a/d converter module
    ADCON0bits_GO = 1;                                 // start the a/d conversion, bit cleared automatically after conversion has completed
    
    return SUCCESS;
  }

  async command result_t ADC.sampleAgain() { 
    ADCON0bits_GO = 1;
    return SUCCESS;
  }

  async command result_t ADC.sampleStop() {  
    ADCON0bits_ADON = 0;                              // power down the a/d converter module    
    return SUCCESS;
  }

  default async event result_t ADC.dataReady(uint16_t done) { return SUCCESS; }
 

  async event result_t ADC_Interrupt.fired(){
    uint16_t data = ADRESH_register;                            // reading the result of the conversion
    data= (data<<8) | ADRESL_register;                 
    data &= 0x3ff;
    signal ADC.dataReady(data);
    return SUCCESS;
  }
}
