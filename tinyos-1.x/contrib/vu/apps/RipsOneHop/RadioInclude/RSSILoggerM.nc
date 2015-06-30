/*
 * Copyright (c) 2005, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for instruction and non-commercial research only, without
 * fee, and without written agreement is hereby granted, provided that the
 * this copyright notice including the following two paragraphs and the 
 * author's name appear in all copies of this software.
 * 
 * IN NO EVENT SHALL VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 * Date last modified: 02/02/04
 */

#include "RSSILogger.h"
includes Reset;

module RSSILoggerM
{
	provides interface RSSILogger;

	uses
	{
		interface RSSIDriver;
		interface SendBigMsg;
		interface Leds;
	}
}

implementation
{
	enum
	{
		BUFFER_LENGTH = 300,
		BASE_STATION = 0xFFFF,
	};

	norace uint16_t error = 0;
	TOS_Msg msg;
	
	async command bool RSSILogger.check(result_t result, uint16_t line)
	{
		if( error == 0 && !result )
			error = line;
		return error == 0;
	}

	inline async command bool RSSILogger.isBuggy()
	{
		return error != 0;
	}

	norace uint8_t buffer[BUFFER_LENGTH];
	norace uint16_t bufferIndex = 0;

	inline async command void RSSILogger.record8(uint8_t value)
	{
		if( CHECK(bufferIndex <= BUFFER_LENGTH-1) )
			buffer[bufferIndex++] = value;
	}

	inline async command void RSSILogger.record16(uint16_t value)
	{
		if( CHECK(bufferIndex <= BUFFER_LENGTH-2) )
		{
			buffer[bufferIndex++] = value;
			buffer[bufferIndex++] = value >> 8;
		}
	}

	inline async command void RSSILogger.record32(uint32_t value)
	{
		if( CHECK(bufferIndex <= BUFFER_LENGTH-4) )
		{
			buffer[bufferIndex++] = value;
			buffer[bufferIndex++] = value >> 8;
			buffer[bufferIndex++] = value >> 16;
			buffer[bufferIndex++] = value >> 24;
		}
	}

	inline async command void *RSSILogger.recordBuffer(uint16_t length)
	{
		uint16_t oldIndex = bufferIndex;
			
		if( CHECK(oldIndex + length <= BUFFER_LENGTH) )
		{
			bufferIndex += length;
			return &buffer[oldIndex];
		}
		else
			return 0;
	}

	task void reportBuffer()
	{
		CHECK( call RSSIDriver.restore() );
		CHECK( call SendBigMsg.send(BASE_STATION,
				&buffer, &buffer[bufferIndex]) );
	}

	event void SendBigMsg.sendDone(result_t success) 
	{
		bufferIndex = 0;
		signal RSSILogger.reportDone();
	}

	inline async command void RSSILogger.report()
	{
		post reportBuffer();
	}

	async command void RSSILogger.reset()
	{
		bufferIndex = 0;
		error = 0;
	}

	async command uint16_t RSSILogger.getLength()
	{
		return bufferIndex;
	}
	
	async command uint8_t *RSSILogger.getBufferStart()
	{
	    return buffer;
	}
}
