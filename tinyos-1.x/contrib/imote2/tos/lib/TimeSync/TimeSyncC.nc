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

includes TimeSyncMsg;
configuration TimeSyncC
{
    provides interface StdControl;
    provides interface GlobalTime;

    //interfaces for extra fcionality: need not to be wired 
    provides interface TimeSyncInfo;
    provides interface TimeSyncMode;
    provides interface TimeSyncNotify;
}

implementation 
{
    components TimeSyncM, TimerC, GenericComm, CommModuleC, LedsC, Main, BluSHC,

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
    #ifdef TIMESYNC_SYSTIME
        SysTimeC, SysTimeStampingC as TimeStampingC; 
    #else
        ClockC, ClockTimeStampingC as TimeStampingC; 
    #endif
#elif PLATFORM_MICAZ
    #ifdef TIMESYNC_SYSTIME
        SysTimeC, SysTimeStampingC as TimeStampingC; 
    #else
        #not_supported!
        //implementation of CC2420 on micaZ uses Timer0 which conflicts with 
        //Vanderbilt Clock* and Timer* components. as there is no component that 
        //would provide 4 byte local time driven by 32kHz external crystal on 
        //micaz, we support only CPU clock.
    #endif
#elif PLATFORM_IMOTE2
    #ifdef TIMESYNC_SYSTIME
        SysTimeC, SysTimeStampingC as TimeStampingC; 
    #else
        //#not_supported!
        //implementation of CC2420 on micaZ uses Timer0 which conflicts with 
        //Vanderbilt Clock* and Timer* components. as there is no component that 
        //would provide 4 byte local time driven by 32kHz external crystal on 
        //micaz, we support only CPU clock.
    #endif
#elif PLATFORM_TELOS
    TimeStampingC
 
    #ifdef TIMESYNC_SYSTIME
        ,LocalTimeMicroC;
    #else
        ;
    #endif
#endif

    GlobalTime = TimeSyncM;
    StdControl = TimeSyncM;
    TimeSyncInfo = TimeSyncM;
    TimeSyncMode = TimeSyncM;
    TimeSyncNotify = TimeSyncM;
    
    Main.StdControl -> TimerC;
    // Main.StdControl -> GenericComm;
    Main.StdControl -> CommModuleC;
    Main.StdControl -> SysTimeC;

    //TimeSyncM.SendMsg       -> GenericComm.SendMsg[AM_TIMESYNCMSG];
    //TimeSyncM.ReceiveMsg    -> GenericComm.ReceiveMsg[AM_TIMESYNCMSG];
    TimeSyncM.SendMsg       -> CommModuleC.SendMsg[AM_TIMESYNCMSG];
    TimeSyncM.ReceiveMsg    -> CommModuleC.ReceiveMsg[AM_TIMESYNCMSG];
    TimeSyncM.Timer         -> TimerC.Timer[unique("Timer")];
    TimeSyncM.Leds          -> LedsC;
    TimeSyncM.TimeStamping      -> TimeStampingC;
    TimeSyncM.ComputeByteOffset -> CommModuleC.ComputeByteOffset;

#if TIMESYNC_SYSTIME
    #ifdef PLATFORM_TELOS
        TimeSyncM.LocalTime -> LocalTimeMicroC;
    #else
        TimeSyncM.SysTime64       -> SysTimeC;
    #endif
#else
    #ifdef PLATFORM_TELOS
        TimeSyncM.LocalTime     -> TimerC;
    #else
        TimeSyncM.LocalTime     -> ClockC;
    #endif
#endif

        BluSHC.BluSH_AppI[unique("BluSH")] -> TimeSyncM.tbl;
}
