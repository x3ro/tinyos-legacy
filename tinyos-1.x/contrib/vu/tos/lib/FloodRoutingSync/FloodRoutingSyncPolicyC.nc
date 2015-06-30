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
 * Author: Brano Kusy, kusy@isis.vanderbilt.edu
 * Date last modified: Jan05
 */

configuration FloodRoutingSyncPolicyC{
	provides{
		interface GradientPolicy;
		interface FloodingPolicy;
	}
}

implementation{
	components FloodRoutingSyncPolicyM, TimerC, GenericComm, Main, RemoteControlC, LedsC;

	Main.StdControl -> GenericComm;
	Main.StdControl -> TimerC;

	GradientPolicy = FloodRoutingSyncPolicyM;
	FloodingPolicy = FloodRoutingSyncPolicyM;

	FloodRoutingSyncPolicyM.SendMsg -> GenericComm.SendMsg[0x84];
	FloodRoutingSyncPolicyM.ReceiveMsg -> GenericComm.ReceiveMsg[0x84];
	FloodRoutingSyncPolicyM.Timer -> TimerC.Timer[unique("Timer")];
	FloodRoutingSyncPolicyM.Leds -> LedsC.Leds;

	RemoteControlC.IntCommand[0x84]-> FloodRoutingSyncPolicyM;
}
