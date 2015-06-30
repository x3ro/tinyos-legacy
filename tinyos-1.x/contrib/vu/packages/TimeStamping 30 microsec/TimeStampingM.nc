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
 * Date last modified: 12/05/03
 */

includes AM;

module TimeStampingM
{
	provides
	{
		interface TimeStamping;
		interface StdControl;
#ifdef TIMESTAMPING_CALIBRATE
		command uint8_t getBitOffset();
#endif
	}
	uses
	{
		interface RadioCoordinator as RadioSendCoordinator;
		interface RadioCoordinator as RadioReceiveCoordinator;
		interface LocalTime;
		interface Timer as PrecisionTimer;
	}
}

implementation
{
#if defined(PLATFORM_MICA2)
	// 19.2 Kbps data, Manchester Encoding, time in jiffies (32768 HZ)
	int8_t correction[8] __attribute__((C)) = { 46, 48, 49, 51, 53, 55, 56, 58 };

	// 38.4 Kbps data, Manchester Encoding, time in jiffies (32768 HZ)
	//int8_t correction[8] __attribute__((C)) = { 24, 24, 25, 26, 27, 28, 28, 29 };
#elif defined(PLATFORM_MICA2DOT)
	// not yet calibrated
	int8_t correction[8] __attribute__((C)) = { 0, 0, 0, 0, 0, 0, 0, 0 };
#elif defined(PLATFORM_MICA)
	// time in jiffies (32768 HZ)
	int8_t correction __attribute__((C)) = 12;
#endif

	// the time stamp of the last received message
	norace uint32_t receiveTime;

	command uint32_t TimeStamping.getStamp()
	{
		return receiveTime;
	}

#ifdef TIMESTAMPING_CALIBRATE
	norace uint8_t bitOffset;

	command uint8_t getBitOffset()
	{
		return bitOffset;
	}
#endif

	async event void RadioReceiveCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff)
	{
		uint32_t stamp = call LocalTime.read();
#ifndef TIMESTAMPING_CALIBRATE
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
		stamp -= correction[offset];
#elif defined(PLATFORM_MICA) || defined(PLATFORM_PC)
		stamp -= correction;
#endif
#else
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
		bitOffset = offset;
#endif
#endif
		receiveTime = stamp;
	}

	async event void RadioReceiveCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) { }
	async event void RadioReceiveCoordinator.blockTimer() { }

	// the offset of the time-stamp field in the message, 
	// or -1 if no stamp is necessariy.
	norace int8_t sendStampOffset;	

#ifdef TOSH_DATA_LENGTH
#define MAX_OFFSET (TOSH_DATA_LENGTH-4)
#else
#define MAX_OFFSET 25
#endif

	command result_t TimeStamping.addStamp(int8_t offset)
	{
		// if correct value (negative value turns it off)
		if( 0 <= offset && offset <= MAX_OFFSET )
		{
			sendStampOffset = offset;
			return SUCCESS;
		}
		else
		{
			sendStampOffset = -1;
			return FAIL;
		}
	}

	async event void RadioSendCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff)
	{
		if( sendStampOffset >= 0 )
		{
			uint32_t sendTime = call LocalTime.read();
			*(uint32_t*)((int8_t*)msgBuff->data + sendStampOffset) += sendTime;
			sendStampOffset = -1;
		}
	}

	async event void RadioSendCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) { }
	async event void RadioSendCoordinator.blockTimer() { }

	command result_t StdControl.init()
	{
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		call PrecisionTimer.start2(TIMER_REPEAT, 240);
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		call PrecisionTimer.stop();
		return SUCCESS;
	}

	// just to keep the Clock running at the highest frequency
	event result_t PrecisionTimer.fired()
	{
		return SUCCESS;
	}
}
