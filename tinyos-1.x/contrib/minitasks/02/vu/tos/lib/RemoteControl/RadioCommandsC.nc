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
 * Date last modified: 04/30/03
 */

configuration RadioCommandsC{
}

implementation{
	components RadioCommandsM,
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
		CC1000RadioC,
#elif defined(PLATFORM_MICA)
		PotC,
#endif
		RemoteControlC, TimerC;

	RemoteControlC.IntCommand[0x22] -> RadioCommandsM.RadioCommand;
	RemoteControlC.IntCommand[0x24] -> RadioCommandsM.RadioFreqCommand;
	RadioCommandsM.Timer	-> TimerC.Timer[unique("Timer")];

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
	RadioCommandsM.CC1000Control 	-> CC1000RadioC;
	RadioCommandsM.CC1KStdCtl 	-> CC1000RadioC;
#elif defined(PLATFORM_MICA)
	RadioCommandsM.Pot 		-> PotC;
#endif
}
