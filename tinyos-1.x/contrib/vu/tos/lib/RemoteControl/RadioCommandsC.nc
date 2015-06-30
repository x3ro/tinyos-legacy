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
 * Contact: Janos Sallai (sallai@isis.vanderbilt.edu)
 * Date last modified: 02/02/05
 */

/**
 * The RadioCommandsC component allows you to change the radio transmit
 * strength on the MICA and MICA2 platforms, and changing the radio
 * frequency on MICA2. RadioCommands uses the IntCommand interface with
 * appid is 34 (0x22) to set the transmit power, and Intcommand with
 * appid 36 (0x24) to set the frequency.
 *
 * @author Miklos Maroti
 * @modified 02/02/05
 */ 


configuration RadioCommandsC{
}

implementation{
	components RadioCommandsM,
	
    // we support MICA2, MICA2DOT and MICA
   	
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
    // we need CC1000RadioC to set the transmit power/radio freq on
    // MICA2 and MICA2DOT
		CC1000RadioC,
#elif defined(PLATFORM_MICA)
    // we need PotC to set the transmit power on MICA
    // setting the freq on MICA is not supported
		PotC,
#endif
		RemoteControlC,

    // we need a timer to defer sending the remote control response
    // after the radio frequency has been changed
		TimerC;

    // RadioCommands's appid is 34 (0x22)
	RemoteControlC.IntCommand[0x22] -> RadioCommandsM.RadioCommand;
	
    // RadioFreqCommands's appid is 36 (0x24)
	RemoteControlC.IntCommand[0x24] -> RadioCommandsM.RadioFreqCommand;

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
	RadioCommandsM.Timer	-> TimerC.Timer[unique("Timer")];
	RadioCommandsM.CC1000Control 	-> CC1000RadioC;
	RadioCommandsM.CC1000StdControl	-> CC1000RadioC;
#elif defined(PLATFORM_MICA)
	RadioCommandsM.Pot 		-> PotC;
#endif
}
