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

/*
README:
	This program will set up a periodic interrupt with 9777 ticks
	per interrupts, then measure the interrupt handling delay.
	This info is then sent to the base station. The first sent number
	is the interrupt delay before anything is sent. The consecutive
	numbers are going to get larger as the alarm interrupt is happening
	during the send.

USAGE:
	Upload this application to a mote. Connect a TOSBase to your laptop.
	Run the java net.tinyos.tools.PrintDiagMsgs tool to display the reported
	interrupt handling delays in ticks (7.3728 Mhz). Then turn on the
	mote containing this application.
*/

module InterruptDelayM
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
	enum
	{
		PERIOD = 9777,		// in ticks
		DISPLAY_RATE = 113,	// 7372800/65536
		SENDRATE = 10 * DISPLAY_RATE,	// 10 sec
	};

	uint16_t alarmTime;	// the time the alarm is set
	uint16_t maxDelay = 0;	// the minimum interrupt delay

	bool displayDone = TRUE;
	uint16_t sendDelay = SENDRATE;

	// this is called at 112.5 HZ
	task void display()
	{
		uint16_t value;
		uint8_t i;

		atomic value = maxDelay;

		if( --sendDelay == 0 )
		{
			sendDelay = SENDRATE;
			if( call DiagMsg.record() )
			{
				call DiagMsg.uint16(value);
				call DiagMsg.send();
			}
		}

		value >>= 7;
		for(i = 0; value != 0 && i < 7; ++i)
			value >>= 1;

		call Leds.set(i);

		atomic displayDone = TRUE;
	}

	async event void HPLSysClock16.overflow()
	{
		if( displayDone )
		{
			displayDone = FALSE;
			post display();
		}
	}

	async event void HPLSysClock16.fired()
	{
		uint16_t time;

		time = call HPLSysClock16.getTime();

		time -= alarmTime;
		if( maxDelay < time )
			maxDelay = time;

		alarmTime += PERIOD;
		call HPLSysClock16.setAlarm(alarmTime);
	}
	
	command result_t StdControl.init()
	{
		call Leds.init();
		return SUCCESS;
	}

	task void start()
	{
		atomic
		{
			alarmTime = call HPLSysClock16.getTime();
			alarmTime += PERIOD;
			call HPLSysClock16.setAlarm(alarmTime);
		}
	}

	command result_t StdControl.start()
	{
		return post start();
	}

	command result_t StdControl.stop()
	{
		return SUCCESS;
	}
}
