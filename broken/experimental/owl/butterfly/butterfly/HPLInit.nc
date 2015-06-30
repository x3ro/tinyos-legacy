// $Id: HPLInit.nc,v 1.1 2003/10/14 19:09:24 idgay Exp $

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
 *
 * Copyright (c) 2003 Atmel Corporation
 */
/*
 *
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
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
module HPLInit {
  provides command result_t init();
}
implementation
{
  /*************************************************************************
   *   Function name : OSCCAL_calibration
   *   Returns :       None
   *   Parameters :    None
   *   Purpose :       Calibrate the internal OSCCAL byte, using the external 
   *                   32,768 kHz crystal as reference
   *************************************************************************/
  void OSCCAL_calibration() {
    int temp;

    outp(0, TIMSK2);		//disable OCIE2A and TOIE2
    outp(1 << AS2, ASSR); //select asynchronous operation of timer2 (32,768kHz)
    outp(200, OCR2A);		// set timer2 compare value 

    outp(0, TIMSK0);		// delete any interrupt sources
        
    outp(1 << CS20, TCCR2A);	// start timer2 with no prescaling
    while((inp(ASSR) & 0x01) | (inp(ASSR) & 0x04)); //wait for TCN2UB and TCR2UB to be cleared
    TOSH_mwait(1000);		// wait for external crystal to stabilise
    
    for (;;)
      {
        atomic
	  {
	    outp(1 << CS10, TCCR1B); // start timer1 with no prescaling
	    outp(0xff, TIFR1);   // delete TIFR1 flags
	    outp(0xff, TIFR2);   // delete TIFR2 flags
        
	    outp(0, TCNT1H);     // clear timer1 counter
	    outp(0, TCNT1L);
	    outp(0, TCNT2);      // clear timer2 counter
           
	    while (!(inp(TIFR2) && (1<<OCF2A))); // wait for timer2 compareflag
    
	    outp(0, TCCR1B); // stop timer1
	  }
    
        if (inp(TIFR1) && (1 << TOV1))
	  temp = 0xFFFF;      // if timer1 overflows, set the temp to 0xFFFF
        else
	  {   // read out the timer1 counter value
            uint8_t tempL = inp(TCNT1L);
            temp = (inp(TCNT1H) << 8) + tempL;
	  }
    
        if (temp > 6250)
	  outp(OSCCAL - 1, OSCCAL);   // the internRC oscillator runs fast, decrease the OSCCAL
        else if (temp < 6120)
	  outp(OSCCAL + 1, OSCCAL);   // the internRC oscillator runs slow, increase the OSCCAL
        else
	  break;
      }
    // Stop timer 2
    outp(0, TCCR2A);
  }

  // Basic hardware init.
  command result_t init() {
    // default everything to inputs, each component will do its own
    // stuff beyond this
    outp(0, DDRA);
    outp(0, DDRB);
    outp(0, DDRC);
    outp(0, DDRD);
    outp(0, DDRE);
    outp(0, DDRF);
    outp(0, DDRG);

    // Set clock to 1MHz and calibrate oscillator to external 32kHz crystal
    outp(1 << CLKPCE, CLKPR);
    outp(1 << CLKPS1 | 1 << CLKPS0, CLKPR);
    OSCCAL_calibration();

    outp(1 << ACD, ACSR);	// disable ADC
    outp(7 << ADC0D, DIDR0);	// disable digital buffer on analog inputs

    // enable pullups on PB0-3, PE4-PE7
    outp(0xf << PB0, PORTB);
    outp(0xf << PE4, PORTE);

    return SUCCESS;
  }
}
