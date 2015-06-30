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
 * Date last modified: 12/11/03
 */

#include "AM.h"

module SysTimeStampingM
{
	provides
	{
		interface TimeStamping;
#ifdef TIMESTAMPING_CALIBRATE
		command uint8_t getBitOffset();
#endif
	}
	uses
	{
		interface RadioCoordinator as RadioSendCoordinator;
		interface RadioCoordinator as RadioReceiveCoordinator;
		interface SysTime;
	}
}

implementation
{
#if defined(PLATFORM_MICA2)
	/* These are the calibrated bit offsets on the MICA2 for 38.4 Kbps transmit 
	 * rate, Manchester Encoding, using the systime with 921.6 KHz frequency.
	 * The actual values have been multiplied by two because we substract
	 * them before dividing by two. There is a noticable +-0.5 microsec bias
	 * for the bits 5 and 6 for unknown reasons, which is corrected here.
	 */
//	static const int16_t BIT_CORRECTION[8] = { 1289, 1337, 1385, 1433, 1481, 1529, 1577, 1625  };
//	enum { BYTE_TIME = 192 };

    /* if your radio stack runs 19.2 kbps, use the following settings: */
	static const int16_t BIT_CORRECTION[8] = { 2555, 2651, 2747, 2843, 2939, 3036, 3130, 3227 };
	enum { BYTE_TIME = 384 };
#elif defined(PLATFORM_XSM)
	static const int16_t BIT_CORRECTION[8] = { 2553, 2649, 2745, 2841, 2935, 3033, 3127, 3225 };
	enum { BYTE_TIME = 384 };
#elif defined(PLATFORM_MICA2DOT)
	/* These are the calibrated bit offsets on the MICA2DOR for 19.2 Kbps 
	 * transmit rate, Manchester Encoding, using the systime with 500 KHz 
	 * frequency.
	 */
	static const int16_t BIT_CORRECTION[8] = { 1388, 1442, 1492, 1545, 1598, 1651, 1702, 1754 };
	enum { BYTE_TIME = 209 };
#endif

	int8_t sendStampOffset = -1;
	TOS_MsgPtr sendMsg = 0;
	TOS_MsgPtr receiveMsg = 0;

	norace uint16_t interruptTime;

	// the offset of the time-stamp field in the message, 
	// or -1 if no stamp is necessariy.
	command result_t TimeStamping.addStamp2(TOS_MsgPtr msg, int8_t offset)
	{
		uint8_t ret = FAIL;

		if( 0 <= offset && offset <= TOSH_DATA_LENGTH - 4  )
		{
            atomic
    		{
    			sendStampOffset = offset;
    			sendMsg = msg;
    			ret = SUCCESS;
    		}
    	}
		return ret;
	}

	async event void RadioSendCoordinator.blockTimer()
	{
		interruptTime = call SysTime.getTime16();
	}

	norace uint32_t sendTime;
	norace uint16_t referenceTime;
	norace int16_t avgCorrection;

	async event void RadioSendCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff) { }

	async event void RadioSendCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount)
	{
		uint16_t time;

		if (sendMsg != 0 && sendMsg != msg)
			return; 

		if( sendStampOffset < 0 )
			return;

		time = interruptTime;

		if( byteCount == 0 )
		{
			sendTime = call SysTime.castTime16(time);
			referenceTime = time;
		}
		else if( byteCount == 3 )
		{
			avgCorrection = referenceTime - (uint16_t)sendTime;
			referenceTime = time;
		}
		else if( byteCount < 6 )
		{
			referenceTime += BYTE_TIME;
			if( (int16_t)(time - referenceTime) < 0 )
				referenceTime = time;

			if( byteCount == 5 )
			{
				avgCorrection += referenceTime - (uint16_t)sendTime;
				sendTime += (avgCorrection >> 1);

				*(uint32_t*)((int8_t*)msg->data + sendStampOffset) += sendTime;
				sendStampOffset = -1;
			}
		}
	}


	// both of these are called, so we just ignore the second
	async event void RadioReceiveCoordinator.blockTimer() { }

	// the time stamp of the last received message
	norace uint32_t receiveTime;
	norace uint8_t bitOffset;

#ifdef TIMESTAMPING_CALIBRATE
	command uint8_t getBitOffset()
	{
		return bitOffset;
	}
#endif

	async event void RadioReceiveCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff)
	{
		bitOffset = offset;
	}

	async event void RadioReceiveCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) 
	{
		uint16_t time = interruptTime;

		if( byteCount == 0 )
		{
			receiveTime = call SysTime.castTime16(time);
			referenceTime = time;
		}
		else if( byteCount == 3 )
		{
			avgCorrection = referenceTime - (uint16_t)receiveTime;
			referenceTime = time;
		}
		else if( byteCount < 6 )
		{
			referenceTime += BYTE_TIME;
			if( (int16_t)(time - referenceTime) < 0 )
				referenceTime = time;

			if( byteCount == 5 )
			{
				avgCorrection += referenceTime - (uint16_t)receiveTime;
#ifndef TIMESTAMPING_CALIBRATE
				avgCorrection -= BIT_CORRECTION[bitOffset];
#endif
				receiveTime += (avgCorrection >> 1);
				receiveMsg = msg;
			}
		}
	}

	command uint32_t TimeStamping.getStamp2(TOS_MsgPtr msg)
	{
		uint32_t time = 0;
		
		atomic
		{
			if( receiveMsg == msg )
				time = receiveTime;
		}

		return time;
	}


}
