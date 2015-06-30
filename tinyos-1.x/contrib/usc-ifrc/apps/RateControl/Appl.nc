/*
 * "Copyright (c) 2000-2005 The Regents of the University of Southern California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/*
 * Authors: Sumit Rangwala
 * Embedded Networks Laboratory, University of Southern California
 */

includes Global;
includes Appl;

configuration Appl{

}

implementation {

    components ApplM, RateControl, Main, TimerC, GenericCommPromiscuous as Comm, 
#if defined(LOG_TPUT) || defined(LOG_LATENCY)
               SerialQueuedSend,
#endif
               LedsC;


    Main.StdControl -> ApplM.StdControl; 

    ApplM.RateControl  -> RateControl; 
    ApplM.SendMsg      -> RateControl.Send[APPLMSG];
    ApplM.ReceiveMsg   -> RateControl.Receive[APPLMSG];
    ApplM.SendReady    -> RateControl;
    ApplM.setBS        -> RateControl;
    ApplM.Leds         -> LedsC;

    RateControl.ReceiveMsg[APPLMSG] -> Comm.ReceiveMsg[APPLMSG];
    RateControl.SerialSendMsg[APPLMSG] -> Comm.SendMsg[APPLMSG];


#if defined(LOG_TPUT) || defined(LOG_LATENCY)
    ApplM.LogControl  -> SerialQueuedSend;
    ApplM.LogMsg     -> SerialQueuedSend.SendMsg[AM_LOG];
#endif

#ifdef LOG_TPUT
    ApplM.LogTputTimer  -> TimerC.Timer[unique("Timer")];
#endif



}
