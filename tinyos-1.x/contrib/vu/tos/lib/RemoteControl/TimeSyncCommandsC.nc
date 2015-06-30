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
 * Author: Gabor Pap
 * Date last modified: 07/25/03
 */
 #define	AM_TIMESYNCCMDPOLL 0xBC

configuration TimeSyncCommandsC
{
}

implementation
{
	components Main, TimeSyncCommandsM, RemoteControlC, TimerC, GenericComm, 
		TimeSyncC, LedsC,
#ifdef TIMESYNC_SYSTIME
		SysTimeStampingC as TimeStampingC;
#else
		ClockTimeStampingC as TimeStampingC;
#endif


//	Main.StdControl -> TimerC;
//	Main.StdControl -> GenericComm;

	RemoteControlC.IntCommand[0x26] -> TimeSyncCommandsM;

	TimeSyncCommandsM.SendMsg	-> GenericComm.SendMsg[AM_TIMESYNCCMDPOLL];
	TimeSyncCommandsM.ReceiveMsg	-> GenericComm.ReceiveMsg[AM_TIMESYNCCMDPOLL];
	TimeSyncCommandsM.Timer		-> TimerC.Timer[unique("Timer")];
	TimeSyncCommandsM.TimeStamping	-> TimeStampingC;
	TimeSyncCommandsM.GlobalTime	-> TimeSyncC;
	TimeSyncCommandsM.TimeSyncInfo	-> TimeSyncC;
	TimeSyncCommandsM.Leds		-> LedsC.Leds;
	TimeSyncCommandsM.TSControl -> TimeSyncC;

}
