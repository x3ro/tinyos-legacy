/*
 * Copyright (c) 2004, Vanderbilt University
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
 * Date last modified: 2/09/04
 */

module TestHPLSysClock32M
{
	provides
	{
		interface StdControl;
	}
	uses
	{
		interface HPLSysClock32;
		interface Leds;
		interface DiagMsg;
	}
}

implementation
{
	uint8_t reportDelay;

	uint16_t minGetTime16 = 0xFFFF;
	uint16_t maxGetTime16 = 0;
	uint16_t minGetTime32 = 0xFFFF;
	uint16_t maxGetTime32 = 0;
	uint16_t minSetAlarm = 0xFFFF;
	uint16_t maxSetAlarm = 0;

	void setMinMax(uint32_t value, uint16_t *min, uint16_t *max)
	{
		if( value < *min )
			*min = value;

		if( value > 0xFFFF )
			*max = 0xFFFF;
		else if( value > *max )
			*max = value;
	}

	task void test()
	{
		uint16_t loop;
		uint16_t timea, timeb;
		uint32_t time1, time2;

		for(loop = 0; loop < 50; ++loop)
		{
			atomic
			{
				// wait a little to trigger the overflow case
				TOSH_uwait(5);

				timea = call HPLSysClock32.getTime16();
				timeb = call HPLSysClock32.getTime16();
			}
			setMinMax(timeb - timea, &minGetTime16, &maxGetTime16);

			atomic
			{
				// wait a little to trigger the overflow case
				TOSH_uwait(5);

				time1 = call HPLSysClock32.getTime32();
				time2 = call HPLSysClock32.getTime32();
			}
			setMinMax(time2 - time1, &minGetTime32, &maxGetTime32);

			// test both cases
			atomic time1 = call HPLSysClock32.getTime32();
			if( (uint16_t)time1 > 0x2000 )
				time1 += 0x7000;
			else
				time1 += 0x1F000;

			atomic
			{
				// measure the time difference
				timea = call HPLSysClock32.getTime16();

				call HPLSysClock32.setAlarm(time1);

				timeb = call HPLSysClock32.getTime16();

				call HPLSysClock32.cancelAlarm();
			}
			setMinMax(timeb - timea, &minSetAlarm, &maxSetAlarm);
		}

		if( --reportDelay == 0 )
		{
			call Leds.greenToggle();

			// test the alarm
			atomic
			{
				time1 = call HPLSysClock32.getTime32() + 200;
				call HPLSysClock32.setAlarm(time1);
			}

			// wait a little for the alarm
			TOSH_uwait(50);

			if( call DiagMsg.record() )
			{
				call DiagMsg.str("HSC32");
				call DiagMsg.uint16(minGetTime16);
				call DiagMsg.uint16(maxGetTime16);
				call DiagMsg.uint16(minGetTime32);
				call DiagMsg.uint16(maxGetTime32);
				call DiagMsg.uint16(minSetAlarm);
				call DiagMsg.uint16(maxSetAlarm);
				call DiagMsg.send();
			}	
		}

		post test();
	}

	async event void HPLSysClock32.overflow()
	{
		call Leds.yellowToggle();
	}

	async event void HPLSysClock32.fired()
	{
		call Leds.redToggle();
		call HPLSysClock32.cancelAlarm();
	}
	
	command result_t StdControl.init()
	{
		call Leds.init();
		return SUCCESS;
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
