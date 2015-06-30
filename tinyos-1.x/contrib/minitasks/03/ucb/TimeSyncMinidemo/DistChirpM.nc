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
//!! Config 151 {uint8_t disruptRate = 0;}

// Hack to make it work for now
//!! Config 4 { bool LowPowerStateEnabled = FALSE; }

includes Timer;

module DistChirpM
{
	provides
	{
		interface StdControl;
	}
	uses
	{
		interface Timer;
		interface GlobalTime;
		interface Leds;
		interface StdControl as SounderControl;
		interface LocalTime;
		interface Config_disruptRate;
	}
}

implementation
{
	enum
	{
		FREQ_LOG2 = 4,		// observable chirp frequency is 16 HZ
		NODES_LOG2 = 3,		// total 8 motes
		SUBTICKS_LOG2 = 4,	// subdivision of the chirp period
		SUBTICKS_BUZZER = 2,	// the length of the buzz in subdivisions

		TIMER_PERIOD = 1 << (15 - FREQ_LOG2 - SUBTICKS_LOG2),
		NODE_SHIFT = 15 - FREQ_LOG2,
		SUBTICK_SHIFT = 15 - FREQ_LOG2 - SUBTICKS_LOG2,
	};

	bool buzzing;

	command result_t StdControl.init()
	{
		call Leds.init();
		call SounderControl.init();
		buzzing = FALSE;
	
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		call Timer.start2(TIMER_PERIOD);
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	event result_t Timer.fired()
	{
		uint32_t globalTime;
		uint8_t node, subtick;

		call GlobalTime.getGlobalTime(&globalTime);
		node = (globalTime >> NODE_SHIFT) & ((1 << NODES_LOG2) - 1);
		subtick = (globalTime >> SUBTICK_SHIFT) & ((1 << SUBTICKS_LOG2) - 1);

		if( node == (TOS_LOCAL_ADDRESS-1) )
			call Leds.redOn();
		else
			call Leds.redOff();

		if( node == (TOS_LOCAL_ADDRESS-1) && subtick < SUBTICKS_BUZZER )
		{
			if (!buzzing) {
				buzzing = TRUE;
				call SounderControl.start();
			}
		}
		else if( buzzing )
		{
			buzzing = FALSE;
			call SounderControl.stop();
		}

		return SUCCESS;
	}

	event void Config_disruptRate.updated(){
		call LocalTime.randomize();
	}
}
