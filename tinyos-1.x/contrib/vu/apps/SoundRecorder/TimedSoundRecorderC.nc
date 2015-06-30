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
 * Date last modified: 04/11/03
 */

configuration TimedSoundRecorderC
{
}

implementation
{
	components TimedSoundRecorderM, Main, TimerC, MicC, LedsC,
		RadioSuspendC, GenericComm, FlashBigMsgC as SendBigMsgC,
		TimeSyncC, FlashBackBigMsg2C, RemoteControlC, RemoteTimeC, 
		CC1000ControlM,	DiagMsgC, ClockC, TimeSyncDebuggerC;

	Main.StdControl	-> TimedSoundRecorderM;
	Main.StdControl	-> TimerC;
	Main.StdControl	-> GenericComm;
	Main.StdControl	-> SendBigMsgC;
	Main.StdControl	-> TimeSyncC;
	Main.StdControl -> TimeSyncDebuggerC;

    TimedSoundRecorderM.CC1000Control	-> CC1000ControlM;
	TimedSoundRecorderM.MicControl		-> MicC;
	TimedSoundRecorderM.Mic				-> MicC;
	TimedSoundRecorderM.MicADC			-> MicC;
	TimedSoundRecorderM.Leds			-> LedsC.Leds;
	TimedSoundRecorderM.RadioSuspend	-> RadioSuspendC;
	TimedSoundRecorderM.SendBigMsg		-> SendBigMsgC.SendBigMsg;
	TimedSoundRecorderM.TimeoutTimer	-> TimerC.Timer[unique("Timer")];
	TimedSoundRecorderM.GlobalTime		-> TimeSyncC;
	TimedSoundRecorderM.LocalTime		-> ClockC;
	TimedSoundRecorderM.DiagMsg			-> DiagMsgC;
	TimedSoundRecorderM.RemoteControl	-> RemoteControlC.RemoteControl[0xBB];
	TimedSoundRecorderM.TimeSyncControl -> TimeSyncC;
}
