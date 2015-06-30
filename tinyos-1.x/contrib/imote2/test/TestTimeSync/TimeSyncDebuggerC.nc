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
 * Author: Miklos Maroti, Brano Kusy
 * Date last modified: 3/17/03
 */

includes TestTimeSyncPollerMsg;

configuration TimeSyncDebuggerC
{
    provides interface StdControl;
}

implementation 
{
    components TimeSyncDebuggerM, TimeSyncC, GenericComm, 
#ifdef TIMESYNC_DIAG_POLLER
        DiagMsgC,
#endif
        TimerC, NoLeds as LedsC,
#ifdef PLATFORM_TELOS
    TimeStampingC;
#elif TIMESYNC_SYSTIME
        SysTimeStampingC as TimeStampingC;
#else
    l    ClockTimeStampingC as TimeStampingC;
#endif

    StdControl = TimeSyncDebuggerM;

    TimeSyncDebuggerM.ReceiveMsg    -> GenericComm.ReceiveMsg[AM_TIMESYNCPOLL];
#ifdef TIMESYNC_DIAG_POLLER
    TimeSyncDebuggerM.DiagMsg   -> DiagMsgC;
#else
    TimeSyncDebuggerM.SendMsg       -> GenericComm.SendMsg[AM_DIAGMSG-1];
#endif
    TimeSyncDebuggerM.Timer     -> TimerC.Timer[unique("Timer")];
    TimeSyncDebuggerM.GlobalTime    -> TimeSyncC;
    TimeSyncDebuggerM.TimeSyncInfo  -> TimeSyncC;
    TimeSyncDebuggerM.Leds      -> LedsC;
    TimeSyncDebuggerM.TimeStamping  -> TimeStampingC;
}
