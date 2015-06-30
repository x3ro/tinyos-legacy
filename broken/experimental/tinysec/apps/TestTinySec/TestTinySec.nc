/*
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the athor appear in all copies of this software.
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
 * Authors: Naveen Sastry
 * Date:    9/26/02
 */

/**
 * Application to exercise the BlockCipher interface
 */
includes IntMsg;

configuration TestTinySec {
}
implementation {
  components Main,
    SecureGenericComm as Comm,
    //  GenericComm as Comm,
    TestTinySecM, 
    LedsC, 
    Counter, 
    TimerC;

  Main.StdControl -> TestTinySecM.StdControl;
  Main.StdControl -> Comm.Control;
  Main.StdControl -> Counter.StdControl;
  TestTinySecM.Send -> Comm.SendMsg[AM_INTMSG];
  TestTinySecM.ReceiveIntMsg -> Comm.ReceiveMsg[AM_INTMSG];
  TestTinySecM.Leds -> LedsC;
  
  Counter.Timer -> TimerC.Timer[unique("Timer")];
  Counter.IntOutput -> TestTinySecM.IntOutput;
}