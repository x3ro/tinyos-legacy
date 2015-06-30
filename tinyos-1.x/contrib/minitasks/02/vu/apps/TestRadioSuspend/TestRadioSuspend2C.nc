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
 * Date last modified: 12/03/02
 */

includes TestRadioSuspendMsg;

configuration TestRadioSuspend2C
{
}

implementation
{
	components TestRadioSuspend2M, LedsC, TimerC, RadioSuspendC, GenericComm, Main;

	Main.StdControl -> TestRadioSuspend2M.StdControl;
	Main.StdControl -> GenericComm.Control;
	Main.StdControl -> TimerC.StdControl;

	TestRadioSuspend2M.RadioSuspend -> RadioSuspendC;
	TestRadioSuspend2M.Leds -> LedsC.Leds;
	TestRadioSuspend2M.Timer1 -> TimerC.Timer[unique("Timer")];
	TestRadioSuspend2M.Timer2 -> TimerC.Timer[unique("Timer")];
	TestRadioSuspend2M.ReceiveTestMsg -> GenericComm.ReceiveMsg[AM_TESTMSG];
}
