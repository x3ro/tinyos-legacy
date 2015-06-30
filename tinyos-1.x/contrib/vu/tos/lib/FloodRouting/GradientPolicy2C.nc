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
 * Date last modified: 06/30/03
 */

configuration GradientPolicy2C
{
	provides
	{
		interface GradientPolicy;
		interface FloodingPolicy;
	}
}

implementation
{
	components GradientPolicy2M, TimerC, Main, RemoteControlC,
		FloodRoutingC, BroadcastPolicyM;

	Main.StdControl -> TimerC;
	Main.StdControl -> GradientPolicy2M;

	GradientPolicy = GradientPolicy2M;
	FloodingPolicy = GradientPolicy2M;

	GradientPolicy2M.FloodRouting -> FloodRoutingC.FloodRouting[0x71];
	FloodRoutingC.FloodingPolicy[0x71] -> BroadcastPolicyM;

	GradientPolicy2M.Timer -> TimerC.Timer[unique("Timer")];

	RemoteControlC.IntCommand[0x71]-> GradientPolicy2M;
}
