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

includes HPLSysClock;

module TestHPLSysClock16M
{
	provides
	{
		interface StdControl;
	}
	uses
	{
		interface HPLSysClock16;
		interface Leds;
		interface DiagMsg;
	}
}

implementation
{
	uint16_t minGetTime = 0xFFFF;
	uint16_t maxGetTime = 0;
	uint16_t minCheckTime = 0xFFFF;
	uint16_t maxCheckTime = 0;
	float uwaitTicks;
	float uwaitTime;

	uint8_t reportDelay;
		
	void setMinMax(uint16_t value, uint16_t *min, uint16_t *max)
	{
		if( value < *min )
			*min = value;
		if( value > *max )
			*max = value;
	}

	task void test()
	{
		uint16_t loop;
		uint16_t time1, time2;

		for(loop = 0; loop < 100; ++loop)
		{
			atomic
			{
				// wait a little to trigger the overflow case
				TOSH_uwait(1);

				time1 = call HPLSysClock16.getTime();
				time2 = call HPLSysClock16.getTime();
			}
			setMinMax(time2 - time1, &minGetTime, &maxGetTime);

			atomic
			{
				// we start counting from here
				time1 = call HPLSysClock16.getTime();

				// this will trigger both execution paths
				time2 = call HPLSysClock16.getTime() - 0x8000;
				if( time1 > time2 )
					time2 = time1;

				call HPLSysClock16.setAlarm(time2);

				// we stop counting here
				time2 = call HPLSysClock16.getTime();

				call HPLSysClock16.cancelAlarm();
			}
			setMinMax(time2 - time1, &minCheckTime, &maxCheckTime);
		}

		if( --reportDelay == 0 )
		{
			call Leds.greenToggle();

			atomic
			{
				time1 = call HPLSysClock16.getTime();
				TOSH_uwait(100);
				time2 = call HPLSysClock16.getTime();
			}

			uwaitTicks = 0.01 * (time2 - time1);
			uwaitTime = uwaitTicks * 1000000.0 / HPLSYSCLOCK_SECOND;

			// test the alarm
			atomic
			{
				time1 = call HPLSysClock16.getTime() + 100;
				call HPLSysClock16.setAlarm(time1);
			}
			
			if( call DiagMsg.record() )
			{
				call DiagMsg.str("HSC16");
				call DiagMsg.uint16(minGetTime);
				call DiagMsg.uint16(maxGetTime);
				call DiagMsg.uint16(minCheckTime);
				call DiagMsg.uint16(maxCheckTime);
				call DiagMsg.real(uwaitTicks);
				call DiagMsg.real(uwaitTime);
				call DiagMsg.send();
			}
		}

		post test();
	}

	uint8_t divider;

	async event void HPLSysClock16.overflow()
	{
		if( --divider == 0 )
			call Leds.yellowToggle();
	}

	async event void HPLSysClock16.fired()
	{
		call Leds.redToggle();
		call HPLSysClock16.cancelAlarm();
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
