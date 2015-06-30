/*
 * Copyright (c) 2007
 *	The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/**
 * Description - Main Driver for the Spaulding project.
 * 
 * @author Konrad Lorincz
 * @version 1.0 - February 15, 2006
 */
#include "PrintfUART.h"
#include "MultiChanSampling.h"
#include "SampleChunk.h"
//#include "DataStore.h"
#include "DriverMsgs.h"

configuration DriverC 
{
} 
implementation 
{
    components Main, DriverM, LedsC, TimerC, ErrorToLedsC, GenericComm;
    components MultiChanSamplingC as SamplingC;
    components SamplingToDataStoreC, DataStoreC;
    components FetchC;
    components TimeSyncC;

#ifdef REALTIMESAMPLES_ENABLED
    components RealTimeSamplesC;
    Main.StdControl -> RealTimeSamplesC;
#endif

    Main.StdControl -> DriverM;
    Main.StdControl -> TimerC;
    Main.StdControl -> GenericComm;
    Main.StdControl -> SamplingToDataStoreC;
    Main.StdControl -> DataStoreC;
    Main.StdControl -> FetchC;
    Main.StdControl -> TimeSyncC;

    DriverM.Leds -> LedsC;
    DriverM.ErrorToLeds -> ErrorToLedsC;
    DriverM.SendMsg -> GenericComm.SendMsg[AM_REPLYMSG];
    DriverM.ReceiveMsg -> GenericComm.ReceiveMsg[AM_REQUESTMSG];
    DriverM.LocalTime -> TimerC;            // Available on MSP430
    DriverM.Timer_Heartbeat -> TimerC.Timer[unique("Timer")];
    DriverM.Timer_MoteTurnedOn -> TimerC.Timer[unique("Timer")];
    DriverM.Timer_DataCollection -> TimerC.Timer[unique("Timer")];
    DriverM.Timer_StopDataCollection -> TimerC.Timer[unique("Timer")];
    DriverM.GlobalTime -> TimeSyncC;
    DriverM.Sampling -> SamplingC;
    DriverM.DataStore -> DataStoreC; 

    SamplingToDataStoreC.Sampling -> SamplingC;


#ifdef PLATFORM_SHIMMER
    components MMA7260_AccelM;
    components GyroIDG300C;

    Main.StdControl -> MMA7260_AccelM;
    DriverM.GyroIDG300 -> GyroIDG300C;
    DriverM.MMA7260_Accel -> MMA7260_AccelM;
#endif
}
