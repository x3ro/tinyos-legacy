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
 * Date last modified: 03/03/03
 */

module OutsideRangingActuatorM
{
	provides 
	{
		interface AcousticRangingActuator;
	}
	uses
	{
		interface AcousticBeacon;
	}
}

implementation
{
	enum
	{
		BEACON_RATE = 100,
	};

	uint8_t BEACON_TIMING[] __attribute__((C)) = 
	{
		// wait 0.5 sec for the mic to power up
		164,

		// 16 times 400 buzz with 1600-2300 jiffies silence
		4, 16, 4, 17, 4, 18, 4, 19, 4, 20, 4, 21, 4, 22, 4, 23,
		4, 23, 4, 22, 4, 21, 4, 20, 4, 19, 4, 18, 4, 17, 4, 16,

		// end
		0,
	};

	command result_t AcousticRangingActuator.send()
	{
		call AcousticBeacon.setTiming(BEACON_RATE, BEACON_TIMING);
		return call AcousticBeacon.send();
	}

	default event void AcousticRangingActuator.sendDone()
	{
	}

	event void AcousticBeacon.sendDone()
	{
		signal AcousticRangingActuator.sendDone();
	}
}
