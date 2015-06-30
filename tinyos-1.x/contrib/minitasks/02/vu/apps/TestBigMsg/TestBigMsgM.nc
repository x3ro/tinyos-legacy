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
 * Date last modified: 2/18/03
 */

module TestBigMsgM
{
	provides
	{
		interface StdControl;
	}
	uses
	{
		interface SendBigMsg;
		interface Leds;
	}
}

implementation
{
	enum
	{
		BASE_STATION = 1973,
	};

	int8_t buffer1[30];
	int8_t buffer2[40];

	uint8_t value1;
	uint8_t value2;

	command result_t StdControl.init() 
	{
		call Leds.init();

		value1 = 100;
		value2 = 200;

		return SUCCESS;
	}

	task void test()
	{
		uint8_t i;

		for(i = 0; i < 30; ++i)
			buffer1[i] = value1 + i;

		for(i = 0; i < 40; ++i)
			buffer2[i] = value2 + i;

		value1 += 1;

		call Leds.yellowToggle();
		if( call SendBigMsg.send2(BASE_STATION, 
			buffer1, buffer1 + 30, buffer2, buffer2 + 40) != SUCCESS )
		{
			call Leds.redOn();
		}
	}

	event void SendBigMsg.sendDone(result_t success)
	{
		if( success )
			call Leds.greenToggle();

		post test();
	}

	command result_t StdControl.start()
	{
		post test();

		return SUCCESS;
	}

	command result_t StdControl.stop() 
	{
		return SUCCESS;
	}
}
