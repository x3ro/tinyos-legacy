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
 * Author: Miklos Maroti, Branislav Kusy
 * Date last modified: 03/31/03
 */

module BuzzRecorderM
{
	provides 
	{
		interface StdControl;
	}
	uses
	{
		interface AcousticSampler;
		interface SendBigMsg;
		interface Leds;
	}
}

implementation
{
	enum
	{
		BASE_STATION = 1973,
		BUFFER_LENGTH = 3000,
	};

	uint8_t buffer[BUFFER_LENGTH];

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
		return SUCCESS; 
	}

	command result_t StdControl.stop() { return SUCCESS; }

	int16_t bufferIndex;		// the current pointer into the buffer
	
	event result_t AcousticSampler.receive(uint16_t beacon)
	{
		call Leds.redOn();
		call AcousticSampler.setGain(128);

		bufferIndex = 0;

		return SUCCESS;
	}

	uint8_t prescaler;

	event result_t AcousticSampler.dataReady(uint16_t mic)
	{
		// record every 4th sample
		prescaler = (prescaler + 1) & 0x03;
		if( prescaler != 0 )
			return SUCCESS;

		if( bufferIndex < BUFFER_LENGTH )
			buffer[bufferIndex++] = mic >> 2;
		else
			return FAIL;

		return SUCCESS;
	}

	event void AcousticSampler.receiveDone()
	{
		call Leds.redOff();
		call Leds.yellowOn();
		call AcousticSampler.setGain(0);

		call SendBigMsg.send(BASE_STATION, 
			buffer, buffer + BUFFER_LENGTH);
	}

	event void SendBigMsg.sendDone(result_t success)
	{
		clearBuffer();
		call Leds.yellowOff();
	}
}
