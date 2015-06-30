/*
 * Copyright (c) 2003, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 * Date last modified: 4/02/03
 */

/*
 * Based on the work of: Jason Hill, David Gay, Philip Levis
 */

module HPLADCC 
{
	provides interface HPLADC as ADC;
}

implementation
{
	enum
	{
		HPLADC_PORTMAPSIZE = 10,
#if defined(PLATFORM_MICA) || defined(PLATFORM_MICA2DOT)
		HPLADC_DEFAULT_RATE = 4,
#elif defined(PLATFORM_MICA2)
		HPLADC_DEFAULT_RATE = 5,
#endif
	};

	bool init_portmap_done;
	uint8_t TOSH_adc_portmap[HPLADC_PORTMAPSIZE];

	void init_portmap() 
	{
		/* The default ADC port mapping */
		if( init_portmap_done == FALSE ) 
		{
			int i;
			for (i = 0; i < HPLADC_PORTMAPSIZE; i++)
				TOSH_adc_portmap[i] = i;
			init_portmap_done = TRUE;
		}
	}
	
	// what to write to ADCSR when the conversion completes
	uint8_t nextADCSR;

	enum
	{
		BITMASK_RATE = 0x07,
	};

	command result_t ADC.init() 
	{
		init_portmap();

		// turn off the ADC, set the default rate to 4
		outp(HPLADC_DEFAULT_RATE, ADCSR);

		return SUCCESS;
	}

	command result_t ADC.setSamplingRate(uint8_t rate)
	{
		// stop the conversion and change the rate
		outp(rate & BITMASK_RATE, ADCSR);
		
		return SUCCESS;
	}

	command result_t ADC.bindPort(uint8_t port, uint8_t adcPort) 
	{
		if (port < HPLADC_PORTMAPSIZE)
		{
			// should be already initialized (???)
			init_portmap();

			TOSH_adc_portmap[port] = adcPort;
			return SUCCESS;
		}

		return FAIL;
	}

	enum
	{
		BUFFER_LENGTH = 32,
		BUFFEREND_EMPTY = 256 - 2, // value of bufferEnd when no data is stored
	};

	uint16_t buffer[BUFFER_LENGTH];
	volatile uint8_t bufferEnd;	// BUFFEREND_EMPTY if the buffer is empty

	command result_t ADC.samplePort(uint8_t port)
	{
		// set the port
		outp(TOSH_adc_portmap[port], ADMUX);

		// stop the ADC after the conversion
		nextADCSR = inp(ADCSR) & BITMASK_RATE;

		// clear all pending data
		bufferEnd = BUFFEREND_EMPTY;

		// start the sampling, clear pending interrupts
		outp(nextADCSR | (1<<ADEN)|(1<<ADSC)|(1<<ADIE)|(1<<ADIF), ADCSR);
		
		return SUCCESS;
	}

	command result_t ADC.streamPort(uint8_t port)
	{
		// set the port
		outp(TOSH_adc_portmap[port], ADMUX);

		// sample again
#if defined(PLATFORM_MICA)
		nextADCSR = (inp(ADCSR) & BITMASK_RATE) | (1<<ADEN)|(1<<ADSC)|(1<<ADIE);
#elif defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
		nextADCSR = (inp(ADCSR) & BITMASK_RATE) | (1<<ADEN)|(1<<ADFR)|(1<<ADIE);
#endif

		// clear all pending data
		bufferEnd = BUFFEREND_EMPTY;

		// start the sampling, clear pending interrupts
#if defined(PLATFORM_MICA)
		outp(nextADCSR | (1<<ADIF), ADCSR);
#elif defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
		outp(nextADCSR | (1<<ADSC)|(1<<ADIF), ADCSR);
#endif

		return SUCCESS;
	}

	command result_t ADC.sampleStop() 
	{
		// keep the rate
		nextADCSR = inp(ADCSR) & BITMASK_RATE;

		// turn of the ADC
		outp(nextADCSR, ADCSR);

		// clear all pending data
		bufferEnd = BUFFEREND_EMPTY;

		return SUCCESS;
	}

	default event result_t ADC.dataReady(uint16_t done) { return SUCCESS; }

	// Use SIGNAL to disable interrupts
	TOSH_SIGNAL(SIG_ADC) __attribute__((signal))
	{
		uint16_t data;
		uint8_t bufferIndex;

		// sample again, or stop the ADC
		outp(nextADCSR, ADCSR);

		// get the sampled value
		data = __inw(ADCL);

		// get our index in the waiting list
		bufferIndex = ++bufferEnd;

		// enable the interrupts
		sei();

		if( bufferIndex == BUFFEREND_EMPTY + 1 )
		{
			for(;;)
			{
				signal ADC.dataReady(data);

				// check if we are done
				cli();
				if( bufferIndex == bufferEnd )
				{
					bufferEnd = BUFFEREND_EMPTY;
					sei();
					break;
				}
				sei();

				// get the next stored value
				data = buffer[++bufferIndex];
			}
		}
		else if( bufferIndex < BUFFER_LENGTH )
			buffer[bufferIndex] = data;	// store it here
	}
}
