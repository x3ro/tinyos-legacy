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
 * Author: Miklos Maroti, Janos Sallai
 * Date last modified: 08/26/03
 */

configuration AcousticLocalizationC
{
}

implementation
{
	components
		Main,
#ifdef WITH_XNP
		XnpC,
#endif		
		AcousticLocalizationM,
		GenericComm, TimerC, LedsC,

		TimeSlotNegotiationC,
		OutsideRangingActuatorC as AcousticRangingActuatorC,
		OutsideRangingSensorC as AcousticRangingSensorC, 
	
		FloodRoutingC, RemoteControlC, StackCommandsC, LedCommandsC, 
		GradientPolicyC;

#ifdef WITH_XNP
	Main.StdControl			-> XnpC;
	AcousticLocalizationM.Xnp	-> XnpC;
#endif	

	Main.StdControl			-> AcousticLocalizationM;
	Main.StdControl			-> GenericComm.Control;
	Main.StdControl			-> TimerC;
	Main.StdControl			-> TimeSlotNegotiationC;			
	Main.StdControl			-> AcousticRangingActuatorC;
	Main.StdControl			-> AcousticRangingSensorC;
	Main.StdControl			-> FloodRoutingC;	

	AcousticLocalizationM.Timer	-> TimerC.Timer[unique("Timer")];
	AcousticLocalizationM.Leds	-> LedsC;

	AcousticLocalizationM.TimeSlotNegotiationControl	-> TimeSlotNegotiationC;
	AcousticLocalizationM.TimeSlotNegotiation		-> TimeSlotNegotiationC;
	AcousticLocalizationM.AcousticRangingActuator		-> AcousticRangingActuatorC;
	AcousticLocalizationM.AcousticRangingSensor		-> AcousticRangingSensorC;
   
	AcousticLocalizationM.FloodRouting	-> FloodRoutingC.FloodRouting[0x02];
	FloodRoutingC.FloodingPolicy[0x02]	-> GradientPolicyC;

	RemoteControlC.IntCommand[0x02]		-> AcousticLocalizationM.IntCommand;   
}
