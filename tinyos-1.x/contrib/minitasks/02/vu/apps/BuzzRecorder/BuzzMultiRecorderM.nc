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
 * Author: Miklos Maroti
 * Date last modified: 03/03/03
 */

module BuzzMultiRecorderM
{
	provides 
	{
		interface StdControl;
	}
	uses
	{
		interface AcousticMultiSampler;
		interface SendBigMsg;
		interface Leds;
	}
}

implementation
{
	enum
	{
		STOP = 0,		// STOP,
		SKIP = 1,		// SKIP,
		ADD = 2,		// ADD, <sample num>, <start index>, <increment>,
		SUB = 3,		// SUB, <sample num>, <start index>, <increment>,
	};

	enum
	{
		BASE_STATION = 1973,
	};

	uint8_t rangerRate __attribute__((C)) = 40;
	uint8_t rangerTiming[] __attribute__((C)) = 
	{
		// wait 40 jiffies
		1,		

		// 16 times 2000 jiffies recordings
		50, 50, 50, 50, 50, 50, 50, 50,
		50, 50, 50, 50, 50, 50, 50, 50,

		// end
		0,
	};

	#define BUFFER_LENGTH 800

	uint16_t program[] __attribute__((C)) =
	{
		// 8 times 800 samples, around 1680 jiffies recording
		ADD, 800, 0, 1,
		ADD, 800, 0, 1,
		ADD, 800, 0, 1,
		ADD, 800, 0, 1,
		ADD, 800, 0, 1,
		ADD, 800, 0, 1,
		ADD, 800, 0, 1,
		ADD, 800, 0, 1,

		// 8 times 800 samples, around 1680 jiffies recording
		ADD, 800, 0, 1,
		ADD, 800, 0, 1,
		ADD, 800, 0, 1,
		ADD, 800, 0, 1,
		ADD, 800, 0, 1,
		ADD, 800, 0, 1,
		ADD, 800, 0, 1,
		ADD, 800, 0, 1,

		STOP,
	};

	uint16_t buffer[BUFFER_LENGTH];
	uint16_t bufferIndex;

	void clearBuffer()
	{
		uint16_t i = BUFFER_LENGTH;
		do { buffer[--i] = 0; } 
		while( i != 0 );
	}

	command result_t StdControl.init() 
	{
		clearBuffer();
		return SUCCESS; 
	}

	command result_t StdControl.start() 
	{ 
		call AcousticMultiSampler.setGain(128);
		call AcousticMultiSampler.setTiming(rangerRate, rangerTiming);

		return SUCCESS; 
	}

	command result_t StdControl.stop() { return SUCCESS; }

	uint8_t programIndex;		// the next command
	uint8_t currentCommand;		// the current command
	uint16_t counter;		// the remaining samples of the current command
	uint16_t bufferIndex;		// the current pointer into the buffer
	uint8_t bufferIncrement;	// increment of the buffer index

	task void nextCommand()
	{
		currentCommand = program[programIndex++];
		switch( currentCommand )
		{
			case STOP:
				--programIndex;
				break;

			case ADD:
			case SUB:
				counter = program[programIndex++];
				bufferIndex = program[programIndex++];
				bufferIncrement = program[programIndex++];
				break;
		}
	}
	
	event result_t AcousticMultiSampler.receive(uint16_t beacon)
	{
		call Leds.redToggle();

		programIndex = 0;
		post nextCommand();

		return SUCCESS;
	}

	event result_t AcousticMultiSampler.dataReady(uint16_t mic)
	{
		switch( currentCommand )
		{
			case ADD:
				buffer[bufferIndex] += mic;
				bufferIndex += bufferIncrement;

				if( --counter != 0 )
					return SUCCESS;
				break;
			
			case SUB:
				buffer[bufferIndex] -= mic;
				bufferIndex += bufferIncrement;

				if( --counter != 0 )
					return SUCCESS;
				break;
		}

		post nextCommand();
		return FAIL;
	}

	event void AcousticMultiSampler.receiveDone()
	{
		call Leds.redOff();
		call Leds.yellowOn();

		call SendBigMsg.send(BASE_STATION, 
			buffer, buffer + BUFFER_LENGTH);
	}

	event void SendBigMsg.sendDone(result_t success)
	{
		clearBuffer();
		call Leds.yellowOff();
	}
}
