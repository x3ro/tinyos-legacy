/* Copyright (c) 2007, Marcus Chang, Klaus Madsen
   All rights reserved.

   Redistribution and use in source and binary forms, with or without 
   modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
      this list of conditions and the following disclaimer. 

    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution. 

    * Neither the name of the Dept. of Computer Science, University of 
      Copenhagen nor the names of its contributors may be used to endorse or 
      promote products derived from this software without specific prior 
      written permission. 

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
   POSSIBILITY OF SUCH DAMAGE.
*/  

/*
        Author:         Marcus Chang <marcus@diku.dk>
                        Klaus S. Madsen <klaussm@diku.dk>
        Last modified:  March, 2007
*/


module SamplingM {
	provides {
		interface StdControl as SamplingControl;
	}

	uses {
		interface Timer;
		interface ThreeAxisAccel;
		interface Compression;
		interface StdOut;
		interface Statistics as SampleCounter;
		interface Statistics as SampleError;
	}
}

implementation {

#include "config.h"

	/**************************************************************************
	** SamplingControl
	**************************************************************************/
	command result_t SamplingControl.init() 
	{	
		/* Initialize counter in statistical module */
		call SampleCounter.init("SampCnt", TRUE);
		call SampleError.init("SampErr", TRUE);

		return SUCCESS;
	}

	command result_t SamplingControl.start() 
	{
        // call ThreeAxisAccel.setRange(ACCEL_RANGE_3x3G);

		call Timer.start(TIMER_REPEAT, ACCEL_PERIOD);

		return SUCCESS;
	}

	command result_t SamplingControl.stop() 
	{
		call Timer.stop();

		return SUCCESS;
	}

	/**************************************************************************
	** Timer
	**************************************************************************/
	event result_t Timer.fired() 
	{
		call ThreeAxisAccel.getData();

		return SUCCESS;	
	}


	/**************************************************************************
	** ThreeAxisAccel
	**************************************************************************/
	event result_t ThreeAxisAccel.dataReady(uint16_t x, uint16_t y, uint16_t z, uint8_t status) 
	{
		uint32_t stamp;

		call SampleCounter.increment();
		stamp = call SampleCounter.getValue();

        if (status == ACCEL_STATUS_SUCCESS)
			call Compression.insertData(x, y, z, stamp);
		else
		{
			call SampleError.increment();
			call Compression.insertData(0xFFFF, 0xFFFF, 0xFFFF, stamp);	
		}

		return SUCCESS;
	}

	/**************************************************************************
	** StdOut
	**************************************************************************/
	async event result_t StdOut.get(uint8_t data) 
	{
		return SUCCESS;
	}

}
