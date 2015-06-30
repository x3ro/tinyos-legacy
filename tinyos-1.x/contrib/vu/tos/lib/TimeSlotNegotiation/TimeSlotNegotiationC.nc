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
 * Author: Janos Sallai
 * Date last modified: 05/19/03
 */

includes TimeSlotNegotiation;
 
configuration TimeSlotNegotiationC
{
	provides
	{
		interface TimeSlotNegotiation;
		interface StdControl;
	}
}

implementation
{
	components TimeSlotNegotiationM, GenericComm, LedsC, TimerC, RandomLFSR, MsgListC,
			RemoteControlC;

	TimeSlotNegotiation = TimeSlotNegotiationM;
	StdControl = TimeSlotNegotiationM;
	
	TimeSlotNegotiationM.Leds -> LedsC.Leds;
	TimeSlotNegotiationM.Timer -> TimerC.Timer[unique("Timer")];	
	TimeSlotNegotiationM.Random -> RandomLFSR.Random;	
	TimeSlotNegotiationM.SendDispatchMsg -> GenericComm.SendMsg[AM_TIMESLOTMSG];
	TimeSlotNegotiationM.ReceiveDispatchMsg -> GenericComm.ReceiveMsg[AM_TIMESLOTMSG];
	TimeSlotNegotiationM.MsgList -> MsgListC;

	RemoteControlC.IntCommand[0x15] -> TimeSlotNegotiationM.IntCommand;
}
