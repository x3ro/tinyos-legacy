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
 * Date last modified: 2/19/04
 */

includes HPLSysClock;

module HPLSysClock32M
{
	uses interface HPLSysClock16;
	provides interface HPLSysClock32;
}

implementation
{
	union time_u
	{
		struct
		{
			uint16_t low;
			uint16_t high;
		};
		uint32_t full;
	};

	norace uint16_t timeHigh;	// the high 16 bits of the current time
	norace union time_u alarm;	// the high 16 bits of the alarm time
	norace bool alarmEnabled;	// the compare interrupt is enabled

	inline async command uint32_t HPLSysClock32.getTime32()
	{
		union time_u time;

		time.low = call HPLSysClock16.getTime();
		time.high = timeHigh;

		/*
		 * Adjust time if we did not handle the overflow interrupt yet
		 * AND time.low already shows this fact.
		 */
		if( call HPLSysClock16.getOverflowFlag() && (int16_t)time.low >= 0 )
			++time.high;

		return time.full;
	}

	inline async command uint16_t HPLSysClock32.getTime16()
	{
		return call HPLSysClock16.getTime();
	}

	inline async event void HPLSysClock16.overflow()
	{
		if( ++timeHigh == 0 )
			signal HPLSysClock32.overflow();

		/*
		 * If the alarm is set during the HPLSysClock32.overflow() call
		 * then everything is already properly initialized. That is why "else if"
		 */
		else if( alarm.high == timeHigh && alarmEnabled )
		{
			/*
			 * Correct alarm time if it is too close to current time.
			 * The +1 is needed because of possible time resolution error.
			 */
			uint16_t time = call HPLSysClock16.getTime() + (HPLSYSCLOCK_CHECK_TIME + 1);
			if( alarm.low > time )
				time = alarm.low;

			call HPLSysClock16.setAlarm(time);
		}
	}

	inline async command bool HPLSysClock32.getOverflowFlag()
	{
		return (int16_t)timeHigh == -1
			&& call HPLSysClock16.getOverflowFlag();
	}

	/*
	 * Note that we have assumed that alarm time is not too close to the current time.
	 */
	inline async command void HPLSysClock32.setAlarm(uint32_t time)
	{
		if( ((union time_u)time).high == timeHigh )
			call HPLSysClock16.setAlarm(((union time_u)time).low);
		else if( alarmEnabled )
			call HPLSysClock16.cancelAlarm();

		alarm.full = time;
		alarmEnabled = TRUE;
	}

	/**
	 * The alarm will be cancelled or reset by higher level components.
	 */
	inline async event void HPLSysClock16.fired()
	{
		signal HPLSysClock32.fired();
	}

	inline async command void HPLSysClock32.cancelAlarm()
	{
		alarmEnabled = FALSE;
		call HPLSysClock16.cancelAlarm();
	}
}
