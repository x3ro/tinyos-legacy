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

#include "PrintfRadioMsgs.h"
#include "PrintfUART.h"

#define PRINTFRADIO_DELAYEDSEND_ENABLED

configuration PrintfRadioC
{             
    provides interface PrintfRadio;
} 
implementation
{
    components Main, GenericComm, TimerC, NoLeds as LedsC;
    components PrintfRadioM;

    PrintfRadio = PrintfRadioM;

    Main.StdControl -> PrintfRadioM;
    Main.StdControl -> TimerC;
    Main.StdControl -> GenericComm;
    

    PrintfRadioM.Timer -> TimerC.Timer[unique("Timer")];            
    PrintfRadioM.Leds -> LedsC;            
    PrintfRadioM.SendMsg -> GenericComm.SendMsg[AM_PRINTFRADIOMSG];

    components new QueueM(PrintfRadioMsg, PRINTFRADIO_QUEUE_SIZE) as QueueM;
    PrintfRadioM.Queue -> QueueM;

#ifdef PRINTFRADIO_DELAYEDSEND_ENABLED
    PrintfRadioM.Timer_DelayedSend -> TimerC.Timer[unique("Timer")];            
#endif

#if defined(TOSMSG_MACACK_ENABLED)
    components CC2420RadioM;
    PrintfRadioM.MacControl -> CC2420RadioM;
#endif
}
