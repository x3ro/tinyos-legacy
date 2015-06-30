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
 * Configuration file for TestMag. <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong, Cory Sharp
 */

includes TestTrioMsg;

configuration TestMag {}

implementation {
  components Main, TestMagM, MagC, LedsC, GenericComm as Comm
             ,IOSwitch1C, IOSwitch2C, TimerC, OscopeC;

  Main.StdControl -> TestMagM;
  Main.StdControl -> OscopeC.StdControl;

  TestMagM.OscopeCh1 -> OscopeC.Oscope[1];
  TestMagM.OscopeCh2 -> OscopeC.Oscope[2];
  TestMagM.OscopeCh3 -> OscopeC.Oscope[3];
  TestMagM.OscopeCh4 -> OscopeC.Oscope[4];

  TestMagM.Mag -> MagC;
  TestMagM.MagControl -> MagC.StdControl; 
  TestMagM.MagXADC -> MagC.MagXADC;
  TestMagM.MagYADC -> MagC.MagYADC;
  TestMagM.Leds -> LedsC;

  TestMagM.CommControl -> Comm;
  TestMagM.ReceiveMsg -> Comm.ReceiveMsg[AM_TESTTRIOMSG];
  TestMagM.SendMsg -> Comm.SendMsg[AM_TESTTRIOMSG];

  TestMagM.IOSwitch1Control -> IOSwitch1C.StdControl;
  TestMagM.IOSwitch1 -> IOSwitch1C.IOSwitch;
  TestMagM.IOSwitch2Control -> IOSwitch2C.StdControl;
  TestMagM.IOSwitch2 -> IOSwitch2C.IOSwitch;

  TestMagM.SampleXTimer -> TimerC.Timer[unique("Timer")];
  TestMagM.SampleYTimer -> TimerC.Timer[unique("Timer")];
}



