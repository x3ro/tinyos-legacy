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

configuration TestTimeSyncPollerC
{
}

implementation 
{
    components TestTimeSyncPollerM, Main, GenericComm, TimerC, LedsC;

    Main.StdControl -> TestTimeSyncPollerM;
    Main.StdControl -> GenericComm;
    Main.StdControl -> TimerC;

    TestTimeSyncPollerM.SendMsg     -> GenericComm.SendMsg[AM_TIMESYNCPOLL];
    TestTimeSyncPollerM.ReceiveMsg  -> GenericComm.ReceiveMsg[AM_DIAGMSG];
    TestTimeSyncPollerM.Timer       -> TimerC.Timer[unique("Timer")];
    TestTimeSyncPollerM.Leds        -> LedsC;
}
