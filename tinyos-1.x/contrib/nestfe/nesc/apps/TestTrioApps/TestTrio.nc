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
 * Configuration file for TestTrio. <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

includes TestTrioMsg;

configuration TestTrio {}

implementation {
  components Main, TestTrioM, MagC, MicC, PIRC, LedsC, GenericComm as Comm
             ,IOSwitch1C, IOSwitch2C, TimerC, OscopeC;

  Main.StdControl -> TestTrioM;
  Main.StdControl -> OscopeC.StdControl;

  TestTrioM.OscopeCh1 -> OscopeC.Oscope[1]; // mag gainx_pot
  TestTrioM.OscopeCh2 -> OscopeC.Oscope[2]; // magx_data
  TestTrioM.OscopeCh3 -> OscopeC.Oscope[3]; // mag gainy_pot
  TestTrioM.OscopeCh4 -> OscopeC.Oscope[4]; // magy_data

  TestTrioM.OscopeCh5 -> OscopeC.Oscope[5]; // mic data

  TestTrioM.OscopeCh6 -> OscopeC.Oscope[6]; // PIR data

  TestTrioM.Leds -> LedsC;

  TestTrioM.Mag -> MagC;
  TestTrioM.MagControl -> MagC.StdControl; 
  TestTrioM.MagXADC -> MagC.MagXADC;
  TestTrioM.MagYADC -> MagC.MagYADC;

  TestTrioM.Mic -> MicC;
  TestTrioM.MicControl -> MicC.StdControl;
  TestTrioM.MicADC -> MicC.MicADC;

  TestTrioM.PIR -> PIRC;
  TestTrioM.PIRControl -> PIRC.StdControl;
  TestTrioM.PIRADC -> PIRC.PIRADC;

  TestTrioM.CommControl -> Comm;
  TestTrioM.ReceiveMsg -> Comm.ReceiveMsg[AM_TESTTRIOMSG];
  TestTrioM.SendMsg -> Comm.SendMsg[AM_TESTTRIOMSG];

  TestTrioM.IOSwitch1Control -> IOSwitch1C.StdControl;
  TestTrioM.IOSwitch1 -> IOSwitch1C.IOSwitch;
  TestTrioM.IOSwitch2Control -> IOSwitch2C.StdControl;
  TestTrioM.IOSwitch2 -> IOSwitch2C.IOSwitch;

  TestTrioM.SampleXTimer -> TimerC.Timer[unique("Timer")];
  TestTrioM.SampleYTimer -> TimerC.Timer[unique("Timer")];

  TestTrioM.MicSampleTimer -> TimerC.Timer[unique("Timer")];

  TestTrioM.PIRSampleTimer -> TimerC.Timer[unique("Timer")];
}



