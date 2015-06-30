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
 * Author: Andras Nadas
 * Date last modified: 04/30/03
 */

includes AM;

configuration RemoteControlC
{
	uses
	{
		interface IntCommand[uint8_t id];
		interface DataCommand[uint8_t id];
		interface StdControl as StdControlCommand[uint8_t id];
	}
}

implementation
{
	components Main, RemoteControlM, GenericComm, TimerC, FloodRoutingC, 
#ifdef LEAF_NODE
		GradientLeafPolicyC as GradientPolicyC;
#else
		GradientPolicyC;
#endif

	Main.StdControl -> RemoteControlM;
	Main.StdControl -> GenericComm;
	Main.StdControl -> TimerC;
	Main.StdControl -> FloodRoutingC;
	
	IntCommand = RemoteControlM;
	DataCommand = RemoteControlM;
	StdControlCommand = RemoteControlM;

	RemoteControlM.ReceiveMsg -> GenericComm.ReceiveMsg[0x5E];
	RemoteControlM.SendMsg -> GenericComm.SendMsg[0x5E];
	RemoteControlM.Timer -> TimerC.Timer[unique("Timer")];

	RemoteControlM.FloodRouting -> FloodRoutingC.FloodRouting[0x5E];
	FloodRoutingC.FloodingPolicy[0x5E] -> GradientPolicyC;
}
