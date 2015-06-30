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
 * Author: Miklos Maroti, Gabor Pap
 * 	   Brano Kusy, kusy@isis.vanderbilt.edu	
 * Date last modified: 07/23/03
 */

module GradientLeafPolicyM
{
	provides
	{
		interface FloodingPolicy;
	}
}

implementation
{
/* 
	very simple policy:
		whenever a new data packet is available, it will be sent 3 times
	0 --sent--> 2 --sent--> 3 --tick--> 4 --sent--> 0xFF
*/
	command uint16_t FloodingPolicy.getLocation()
	{
		return 0xFFFF;
	}

	command uint8_t FloodingPolicy.sent(uint8_t priority)
	{
		if( priority == 0 )
			return 2;
		else if( priority == 2 )
			return 3;
		else
			return 0xFF;
	}

	command result_t FloodingPolicy.accept(uint16_t location)
	{
		if( location < 0xFFFF )
			return TRUE;
		else
			return FALSE;
	}

	command uint8_t FloodingPolicy.received(uint16_t location, uint8_t priority)
	{
		return 0xFF;
	}

	command uint8_t FloodingPolicy.age(uint8_t priority)
	{
		if( priority == 3 )
			return 4;
		else
			return priority;
	}
}
