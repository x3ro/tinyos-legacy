/*
 * Copyright (c) 2002, Vanderbilt University
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
 * Author: Gyorgy Balogh, Miklos Maroti
 * Date last modified: 04/11/03
 */

module OutsideRangingSensorM
{
	provides 
	{
		interface StdControl;
		interface AcousticRangingSensor;
	}
	uses
	{
		interface AcousticMultiSampler;
	}
}

implementation
{
	enum
	{
		BASE_STATION = 1973,
		FILTER_SIZE = 35,	// must match getFiltered
		BUFFER_LENGTH = 850,
		FILTERED_LENGTH = BUFFER_LENGTH - FILTER_SIZE + 1,
		SAMPLER_RATE = 100,
	};

	uint8_t SAMPLER_TIMING[] __attribute__((C)) = 
	{
		// wait 0.5 sec for the mic to power up
		164,

		// 16 times 2000-2700 jiffies recordings
		20, 21, 22, 23, 24, 25, 26, 27,
		27, 26, 25, 24, 23, 22, 21, 20,

		// this is the end my friend
		0,
	};

	norace uint16_t buffer[BUFFER_LENGTH];
	norace uint16_t bufferIndex;
	uint16_t beaconId;	// 0xFFFF if we are ready 

	task void clearBuffer()
	{
		uint16_t i = BUFFER_LENGTH;
		do { buffer[--i] = 0; } 
		while( i != 0 );

		beaconId = 0xFFFF;
	}

	command result_t StdControl.init() 
	{
		beaconId = 0;
		post clearBuffer();
		return SUCCESS; 
	}

	command result_t StdControl.start() 
	{
		call AcousticMultiSampler.setTiming(SAMPLER_RATE, SAMPLER_TIMING);

		return SUCCESS; 
	}

	command result_t StdControl.stop() { return SUCCESS; }

	event result_t AcousticMultiSampler.receive(uint16_t beacon)
	{
		if( beaconId != 0xFFFF 
			|| signal AcousticRangingSensor.receive(beacon) != SUCCESS )
		{
			return FAIL;
		}

		call AcousticMultiSampler.setGain(128);

		bufferIndex = 0;
		beaconId = beacon;

		return SUCCESS;
	}

	async event result_t AcousticMultiSampler.dataReady(uint16_t sample)
	{
		if( bufferIndex < BUFFER_LENGTH )
		{
			buffer[bufferIndex++] += sample;
			return SUCCESS;
		}

		bufferIndex = 0;
		return FAIL;
	}

	// a simple linear filter of length 35, taking the absolute value
	uint16_t getFiltered(uint16_t i)
	{
		int32_t sum1 = 0, sum2 = 0, sum3 = 0, sum4 = 0;
		uint16_t *p = buffer + i;

#ifdef PLATFORM_MICA
		sum1 -= *(p++);
		sum2 -= *(p++);
		sum4 += *(p++);
		sum2 += *(p++);
		sum4 -= *(p++);
		p++;
		sum3 += *(p++);
		sum2 -= *(p++);
		sum2 -= *(p++);
		sum1 += *(p++);
		sum3 += *(p++);
		sum3 -= *(p++);
		sum1 -= *(p++);
		sum2 += *(p++);
		sum2 += *(p++);
		sum4 -= *(p++);
		sum1 += *(p++);
		sum4 += *(p++);
		sum2 -= *(p++);
		sum4 -= *(p++);
		sum3 += *(p++);
		sum2 += *(p++);
		sum4 -= *(p++);
		p++;
		sum4 += *(p++);
		sum1 -= *(p++);
		sum4 -= *(p++);
		sum3 += *(p++);
		sum3 += *(p++);
		sum4 -= *(p++);
		sum2 -= *(p++);
		sum4 += *(p++);
		p++;
		sum4 -= *(p++);
		sum3 += *p;
#endif
#ifdef PLATFORM_MICA2
		sum1 += *(p++);
		sum1 += *(p++);
		p++;
		sum4 -= *(p++);
		p++;
		sum4 += *(p++);
		sum2 -= *(p++);
		sum2 -= *(p++);
		p++;
		sum4 += *(p++);
		sum1 -= *(p++);
		sum1 -= *(p++);
		sum1 += *(p++);
		sum2 -= *(p++);
		sum4 += *(p++);
		sum4 -= *(p++);
		sum2 -= *(p++);
		sum4 += *(p++);
		p += 2;
		sum4 -= *(p++);
		sum2 += *(p++);
		sum4 += *(p++);
		sum2 -= *(p++);
		sum4 -= *(p++);
		sum3 += *(p++);
		sum3 += *(p++);
		sum2 -= *(p++);
		sum4 -= *(p++);
		sum2 += *(p++);
		sum4 += *(p++);
		sum2 -= *(p++);
		sum4 -= *(p++);
		sum1 -= *(p++);
		sum4 += *p;
#endif

		// calculate the result
		sum1 = (sum1 + sum3) + ((sum2 + sum3 + sum4 + sum4) << 1);

		// scale it back, and take the absolute value
		sum1 >>= 3;
		if( sum1 < 0 )
			sum1 = -sum1;

		return sum1 > 65535L ? 65535U : sum1;
	}

	// we store the filtered value in the buffer
	uint16_t getAverage()
	{
		uint16_t i;
		uint32_t sum = 0;

		for(i = 0; i < FILTERED_LENGTH; ++i)
			sum += buffer[i] = getFiltered(i);

		// round and divide
		sum += (FILTERED_LENGTH >> 1);
		sum /= FILTERED_LENGTH;

		return sum;
	}

	int16_t getRange()
	{
		int16_t crossingPoint = -1, maximumPoint = -1;
		uint16_t i, energy, average, maximumEnergy = 0;
		uint32_t decayingEnergy = 0;

		average = getAverage();

		for(i = 0; i < FILTERED_LENGTH; ++i)
		{
			energy = decayingEnergy >> 7;
			decayingEnergy -= energy;
			decayingEnergy += buffer[i];

			if( energy > average && crossingPoint < 0 )
			{
				crossingPoint = i;
				maximumPoint = i;
				maximumEnergy = energy;
			}
			else if( crossingPoint >= 0 )
			{
				if( energy > maximumEnergy )
				{
					maximumEnergy = energy;
					maximumPoint = i;
				}
				else if( energy < average )
				{
					uint16_t length = i - crossingPoint;
					if( 200 <= length && length <= 350 )
					{
						if( maximumEnergy >= average + average )
							return maximumPoint;
						else
							return -1;
					}

					crossingPoint = -1;
				}
			}
		}
		
		return -1;
	}

	task void process()
	{
		int16_t range = getRange();

		// change it into centimeters
		if( range >= 0 )
		{
#ifdef PLATFORM_MICA
            int32_t a = range;
            a -= 190;       
            a *= 142835;    // = SPEED_OF_SOUND / SAMPLING_RATE * 2^16
                            // SAMPLING_RATE  is 15600 Hz
                            // SPEED_OF_SOUND is 34000 cm/s
            range = a >> 16;
#endif
#ifdef PLATFORM_MICA2
            int32_t a = range;
            a -= 207;       
            a *= 125724;    // = SPEED_OF_SOUND / SAMPLING_RATE * 2^16
                            // SAMPLING_RATE  is 17723.07692 Hz
                            // SPEED_OF_SOUND is 34000 cm/s
            range = a >> 16;
#endif
			if( range < 0 )
				range = -1;
		}

		signal AcousticRangingSensor.receiveDone(beaconId, range);

		post clearBuffer();
	}

	event void AcousticMultiSampler.receiveDone()
	{
		call AcousticMultiSampler.setGain(0);

		post process();
	}
}
