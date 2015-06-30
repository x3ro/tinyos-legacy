/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * Configuration file for TestMic. <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

includes TestTrioMsg;

configuration TestMic {}

implementation {
  components Main, TestMicM, MicC, LedsC, GenericComm as Comm
             ,IOSwitch1C, IOSwitch2C
            , TimerC, OscopeC;

  Main.StdControl -> TestMicM;
  Main.StdControl -> OscopeC.StdControl;

  TestMicM.OscopeCh0 -> OscopeC.Oscope[0];

  TestMicM.Mic -> MicC;
  TestMicM.MicControl -> MicC.StdControl;
  TestMicM.MicADC -> MicC.MicADC;
  TestMicM.Leds -> LedsC;

  TestMicM.CommControl -> Comm;
  TestMicM.ReceiveMsg -> Comm.ReceiveMsg[AM_TESTTRIOMSG];
  TestMicM.SendMsg -> Comm.SendMsg[AM_TESTTRIOMSG];

  TestMicM.IOSwitch1Control -> IOSwitch1C.StdControl;
  TestMicM.IOSwitch1 -> IOSwitch1C.IOSwitch;
  TestMicM.IOSwitch2Control -> IOSwitch2C.StdControl;
  TestMicM.IOSwitch2 -> IOSwitch2C.IOSwitch;

  TestMicM.SampleTimer -> TimerC.Timer[unique("Timer")];

}



