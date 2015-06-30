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
 * Configuration file for TestPIR. <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

includes TestTrioMsg;

configuration TestPIR {}

implementation {
  components Main, TestPIRM, PIRC, LedsC, GenericComm as Comm
             ,IOSwitch1C, IOSwitch2C
            , TimerC, OscopeC;

  Main.StdControl -> TestPIRM;
  Main.StdControl -> OscopeC.StdControl;

  TestPIRM.OscopeCh3 -> OscopeC.Oscope[3];

  TestPIRM.PIR -> PIRC;
  TestPIRM.PIRControl -> PIRC.StdControl;
  TestPIRM.PIRADC -> PIRC.PIRADC;
  TestPIRM.Leds -> LedsC;

  TestPIRM.CommControl -> Comm;
  TestPIRM.ReceiveMsg -> Comm.ReceiveMsg[AM_TESTTRIOMSG];
  TestPIRM.SendMsg -> Comm.SendMsg[AM_TESTTRIOMSG];

  TestPIRM.IOSwitch1Control -> IOSwitch1C.StdControl;
  TestPIRM.IOSwitch1 -> IOSwitch1C.IOSwitch;
  TestPIRM.IOSwitch2Control -> IOSwitch2C.StdControl;
  TestPIRM.IOSwitch2 -> IOSwitch2C.IOSwitch;

  TestPIRM.SampleTimer -> TimerC.Timer[unique("Timer")];
}



