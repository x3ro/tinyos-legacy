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
 * Date last modified: 03/03/03
 */

includes Timer;

module BuzzBeaconM
{
	provides 
	{
		interface StdControl;
	}
	uses
	{
		interface AcousticBeacon;
		interface Timer;
	}
}

implementation
{
	uint8_t buzzRate __attribute__((C)) = 40;
	uint8_t buzzTiming[] __attribute__((C)) = 
	{
		// initial 80 jiffies silence
		2,

		// 17 times 400 buzz 1600 silence
		10, 40, 10, 40, 10, 40, 10, 40, 10, 40, 10, 40, 10, 40, 10, 40,
		10, 40, 10, 40, 10, 40, 10, 40, 10, 40, 10, 40, 10, 40, 10, 40,
		10, 40,

		// end
		0,
	};

/*
	// RECORD ONE BUZZ (6x undersampling, 8x averaging)
	uint8_t buzzRate __attribute__((C)) = 7;
	uint8_t buzzTiming[] __attribute__((C)) = 
	{
		120,	// initial 840 jiffies silence

		50,	// 350 jiffies buzz	(start 0)
		165,	// 1155 jiffies silence, total 1505
		50,	// 350 jiffies buzz	(start 1505)
		165,	// 1155 jiffies silence
		50,	// 350 jiffies buzz	(start 3010)
		165,	// 1155 jiffies silence
		50,	// 350 jiffies buzz	(start 4515)
		165,	// 1155 jiffies silence
		50,	// 350 jiffies buzz	(start 6020)
		165,	// 1155 jiffies silence
		50,	// 350 jiffies buzz	(start 7525)
		165,	// 1155 jiffies silence
			// TOTAL: 9030

		50, 165, 50, 165, 50, 165, 50, 165, 50, 165, 50, 165,	// 2
		50, 165, 50, 165, 50, 165, 50, 165, 50, 165, 50, 165,	// 3
		50, 165, 50, 165, 50, 165, 50, 165, 50, 165, 50, 165,	// 4
		50, 165, 50, 165, 50, 165, 50, 165, 50, 165, 50, 165,	// 5
		50, 165, 50, 165, 50, 165, 50, 165, 50, 165, 50, 165,	// 6
		50, 165, 50, 165, 50, 165, 50, 165, 50, 165, 50, 165,	// 7
		50, 165, 50, 165, 50, 165, 50, 165, 50, 165, 50, 165,	// 8

		0	// termination symbol
	};
*/
/*
	// RECORD ONE BUZZ MINUS ANOTHER SHORTER ONE
	uint8_t buzzRate __attribute__((C)) = 7;
	uint8_t buzzTiming[] __attribute__((C)) = 
	{
		120,	// initial 840 jiffies silence

		25, 190,	// 175 buzz, 1330 silence, total 1505, start 0
		25, 190,	// start 1505
		25, 190,	// start 3010
		25, 190,	// start 4515
		25, 190,	// start 6020
		25, 190,	// start 7525, TOTAL: 9030

		37, 178, 37, 178, 37, 178, 37, 178, 37, 178, 37, 178,

		25, 190, 25, 190, 25, 190, 25, 190, 25, 190, 25, 190,
		37, 178, 37, 178, 37, 178, 37, 178, 37, 178, 37, 178,

		25, 190, 25, 190, 25, 190, 25, 190, 25, 190, 25, 190,
		37, 178, 37, 178, 37, 178, 37, 178, 37, 178, 37, 178,

		25, 190, 25, 190, 25, 190, 25, 190, 25, 190, 25, 190,
		37, 178, 37, 178, 37, 178, 37, 178, 37, 178, 37, 178,

		0	// termination symbol
	};
*/
/*
	// RECORD ONE BUZZ MINUS ONE SHORTER, 4 TIMES WITH ECHO CANCELLATION
	uint8_t buzzRate __attribute__((C)) = 7;
	uint8_t buzzTiming[] __attribute__((C)) = 
	{
		6,	// initial 42 jiffies silence

		37, 104,	// 259 buzz, 728 silence, start 0, length 987
		37, 104,	// 259 buzz, 728 silence, start 987, length 987
		25, 116,	// 175 buzz, 812 silence, start 1974, length 987
		25, 117,	// 175 buzz, 819 silence, start 2961, length 994
		37, 104,	// 259 buzz, 728 silence, start 3955, length 987
		37, 104,	// 259 buzz, 728 silence, start 4942, length 987
		25, 116,	// 175 buzz, 812 silence, start 5929, length 987
		25, 117,	// 175 buzz, 819 silence, start 6916, length 994
		37, 104,	// 259 buzz, 728 silence, start 7910, length 987
		37, 104,	// 259 buzz, 728 silence, start 8897, length 987
		25, 116,	// 175 buzz, 812 silence, start 9884, length 987
		25, 120,	// 175 buzz, 840 silence, start 10871, length 1015,
				// TOTAL: 11886

		37, 104, 37, 104, 25, 116, 25, 117, 37, 104, 37, 104, 
		25, 116, 25, 117, 37, 104, 37, 104, 25, 116, 25, 120,

		37, 104, 37, 104, 25, 116, 25, 117, 37, 104, 37, 104, 
		25, 116, 25, 117, 37, 104, 37, 104, 25, 116, 25, 120,

		37, 104, 37, 104, 25, 116, 25, 117, 37, 104, 37, 104, 
		25, 116, 25, 117, 37, 104, 37, 104, 25, 116, 25, 120,

		0		// termination symbol
	};
*/
/*
	// RECORD ONE BUZZ MINUS ONE SHORTER, 4 TIMES WITH ECHO CANCELLATION
	uint8_t buzzRate __attribute__((C)) = 7;
	uint8_t buzzTiming[] __attribute__((C)) = 
	{
		6,	// initial 42 jiffies silence

		50,  91,	// 350 buzz, 637 silence, start 0, length 987
		50,  91,	// 350 buzz, 637 silence, start 987, length 987
		25, 116,	// 175 buzz, 812 silence, start 1974, length 987
		25, 117,	// 175 buzz, 819 silence, start 2961, length 994
		50,  91,	// 259 buzz, 637 silence, start 3955, length 987
		50,  91,	// 259 buzz, 637 silence, start 4942, length 987
		25, 116,	// 175 buzz, 812 silence, start 5929, length 987
		25, 117,	// 175 buzz, 819 silence, start 6916, length 994
		50,  91,	// 259 buzz, 637 silence, start 7910, length 987
		50,  91,	// 259 buzz, 637 silence, start 8897, length 987
		25, 116,	// 175 buzz, 812 silence, start 9884, length 987
		25, 120,	// 175 buzz, 840 silence, start 10871, length 1015,
				// TOTAL: 11886

		50,  91, 50,  91, 25, 116, 25, 117, 50,  91, 50,  91, 
		25, 116, 25, 117, 50,  91, 50,  91, 25, 116, 25, 120,

		50,  91, 50,  91, 25, 116, 25, 117, 50,  91, 50,  91, 
		25, 116, 25, 117, 50,  91, 50,  91, 25, 116, 25, 120,

		50,  91, 50,  91, 25, 116, 25, 117, 50,  91, 50,  91, 
		25, 116, 25, 117, 50,  91, 50,  91, 25, 116, 25, 120,

		0		// termination symbol
	};
*/
	command result_t StdControl.init() 
	{
		call AcousticBeacon.setTiming(buzzRate, buzzTiming);

		return SUCCESS; 
	}

	int8_t delay;	// the delay between beacon signals

	command result_t StdControl.start()
	{
		delay = 30;				// 3 seconds
		call Timer.start2(TIMER_REPEAT, 3277);	// 10 ticks per seconds

		return SUCCESS;
	}

	command result_t StdControl.stop() { return SUCCESS; }
	
	event void AcousticBeacon.sendDone()
	{
		delay = 100;			// 10 seconds
		call Timer.start2(3277);	// 10 ticks per seconds
	}

	event result_t Timer.fired()
	{
		if( --delay == 0 )
		{
			call Timer.stop();
			call AcousticBeacon.send();
		}

		return SUCCESS;
	}
}
