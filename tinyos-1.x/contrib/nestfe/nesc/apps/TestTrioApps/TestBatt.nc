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
 * Configuration file for TestBatt. <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

includes TestTrioMsg;
includes sensorboard;

configuration TestBatt {}

implementation {
  components Main, TestBattM, PrometheusC, LedsC,
             GenericComm as Comm, ADCC, TimerC;

  Main.StdControl -> TestBattM.StdControl;

  TestBattM.PrometheusControl -> PrometheusC.StdControl;
  TestBattM.Prometheus -> PrometheusC;

  TestBattM.CommControl -> Comm;
  TestBattM.ReceiveMsg -> Comm.ReceiveMsg[AM_TESTTRIOMSG];
  TestBattM.SendMsg -> Comm.SendMsg[AM_TESTTRIOMSG];

  TestBattM.Leds -> LedsC.Leds;
  TestBattM.InitTimer -> TimerC.Timer[unique("Timer")];
}


