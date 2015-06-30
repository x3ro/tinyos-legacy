/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:		Su Ping <sping@intel-research.net>
 * Date last modified:  9/19/02
 *
 */

includes TimeSyncMsg;

configuration TimeSyncC {
    provides interface TimeSync;
    provides interface StdControl;
}
implementation {
    components TimeSyncM, LogicalTime, LedsC, RadioTimingC, GenericComm as Comm, AbsoluteTimerC;

    TimeSync = TimeSyncM;
    StdControl = TimeSyncM;
    TimeSyncM.AtimerControl -> AbsoluteTimerC.StdControl;
    TimeSyncM.AbsoluteTimer0 -> AbsoluteTimerC.AbsoluteTimer[unique("AbsoluteTimer")];
    TimeSyncM.Leds -> LedsC;
    TimeSyncM.Time -> LogicalTime;
    TimeSyncM.TimeUtil -> LogicalTime;
    TimeSyncM.TimeSet -> LogicalTime;
    TimeSyncM.TimeControl -> LogicalTime;
    TimeSyncM.RadioTiming ->RadioTimingC;	
    TimeSyncM.CommControl -> Comm;
    TimeSyncM.SendSyncMsg -> Comm.SendMsg[AM_TIMESYNCMSG];
    TimeSyncM.TimeSyncReceive -> Comm.ReceiveMsg[AM_TIMESYNCMSG];
    
}