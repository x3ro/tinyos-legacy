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
 * Date last modified: 11/19/02
 */

/*	CONCULSION:

	if scale = 1 then time = (max(interval,1) + 1) / 32768 secs
	if scale > 1 then time = max(interval,1) * 2^exp / 32768 secs
*/

module VerifyClock1M
{
	provides
	{
		interface StdControl;
	}
	uses
	{
		interface Clock;
		interface Leds;
	}
}

implementation
{
/*	COUNTER 0 scaling:

	scale = 0 : off
	scale = 1 : divide = 1,    exp = 0,  time = 1/32768 sec
	scale = 2 : divide = 8,    exp = 3,  time = 1/4096 sec
	scale = 3 : divide = 32,   exp = 5,  time = 1/1024 sec
	scale = 4 : divide = 64,   exp = 6,  time = 1/512 sec
	scale = 5 : divide = 128,  exp = 7,  time = 1/256 sec
	scale = 6 : divide = 256,  exp = 8,  time = 1/128 sec
	scale = 7 : divide = 1024, exp = 10, time = 1/32 sec
*/
	enum
	{
//		INTERVAL = 32, SCALE = 7, NUMBER = 1u,		// blinks ~ 1 sec	(standard)
//		INTERVAL = 0, SCALE = 7, NUMBER = 32u,		// blinks ~ 1 sec
//		INTERVAL = 1, SCALE = 7, NUMBER = 32u,		// blinks ~ 1 sec
//		INTERVAL = 2, SCALE = 7, NUMBER = 16u,		// blinks ~ 1 sec
//		INTERVAL = 0, SCALE = 1, NUMBER = 16384u,	// blinks ~ 1 sec
//		INTERVAL = 1, SCALE = 1, NUMBER = 16384u,	// blinks ~ 1 sec
//		INTERVAL = 2, SCALE = 1, NUMBER = 16384u,	// blinks ~ 3/2 sec
		INTERVAL = 3, SCALE = 1, NUMBER = 8192u,	// blinks ~ 1 sec
//		INTERVAL = 128, SCALE = 1, NUMBER = 256u,	// blinks ~ 1 sec
//		INTERVAL = 0, SCALE = 2, NUMBER = 4096u,	// blinks ~ 1 sec
//		INTERVAL = 1, SCALE = 2, NUMBER = 4096u,	// blinks ~ 1 sec
//		INTERVAL = 2, SCALE = 2, NUMBER = 2048u,	// blinks ~ 1 sec
	};

	uint16_t counter;

	command result_t StdControl.init()
	{
		counter = NUMBER;
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		// compare register, scale register
		call Clock.setRate(INTERVAL, SCALE);
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		call Clock.setRate(0, 0);
		return SUCCESS;
	}

	event result_t Clock.fire()
	{
		if( --counter == 0 )
		{
			call Leds.redToggle();
			counter = NUMBER;
		}

		return SUCCESS;
	}
}
