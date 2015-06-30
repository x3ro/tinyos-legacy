/*
 * Copyright (c) 2003, Vanderbilt University
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
 * Date last modified: 07/03/03
 */

module BroadcastPolicyM
{
	provides interface FloodingPolicy;
}

/*
	0 --sent--> 3
	0 --received--> 2 --sent--> 3
	3 --tick--> 5 --tick--> 7 --tick--> 9 --tick--> 11 --tick--> 0xFF
	5,7,9,11 --received--> 3
*/

implementation
{
	command uint16_t FloodingPolicy.getLocation()
	{
		// this value is not used, only for debugging purposes
		return TOS_LOCAL_ADDRESS;
	}

	command uint8_t FloodingPolicy.sent(uint8_t priority)
	{
		return 3;
	}

	command result_t FloodingPolicy.accept(uint16_t location)
	{
		return TRUE;
	}

	command uint8_t FloodingPolicy.received(uint16_t location, uint8_t priority)
	{
		if( priority <= 2 )
			return 2;
		else
			return 3;
	}

	command uint8_t FloodingPolicy.age(uint8_t priority)
	{
		if( (priority & 0x01) == 0 )
			return priority;
		else if( priority < 11 )
			return priority + 2;
		else
			return 0xFF;
	}
}
