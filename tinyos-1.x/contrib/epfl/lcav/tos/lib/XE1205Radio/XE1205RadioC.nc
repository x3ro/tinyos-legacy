/* 
 * Copyright (c) 2005, Ecole Polytechnique Federale de Lausanne (EPFL)
 * and Shockfish SA, Switzerland.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   and Shockfish SA, nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ========================================================================
 */

/*
 * Main XE1205 radio configuration.
 *
 * @author Remy Blank
 * @author Henri Dubois-Ferriere
 *
 */

configuration XE1205RadioC {
  provides {
    interface StdControl;
    interface BareSendMsg as Send;          // For sending messages
    interface ReceiveMsg as Receive;        // For receiving messages
    interface XE1205Control;                // For setting frequency, bitrate, etc.
    interface RadioCoordinator as RadioReceiveCoordinator;  // For time sync
    interface RadioCoordinator as RadioSendCoordinator;     // For time sync
    interface CSMAControl;                   // Mac parameters
    interface XE1205Stats;                  // MAC Counters
    interface XE1205LPL;
    interface MacBackoff;                   // For setting congestion backoff

  }
}


implementation {
  components XE1205RadioM, 
    XE1205ControlM, 
    HPLXE1205C, 
    LedsC, 
    CCAThreshMA, 
    XE1205RadioC, 
    TimerJiffyAsyncC,
    RandomLFSR;

  // Populate provided interfaces with module implementations		
  StdControl = XE1205RadioM;
  Send = XE1205RadioM;
  Receive = XE1205RadioM;
  XE1205Control = XE1205ControlM;
  RadioReceiveCoordinator = XE1205RadioM.RadioReceiveCoordinator;
  RadioSendCoordinator = XE1205RadioM.RadioSendCoordinator;
  CSMAControl = XE1205RadioM;
  XE1205Stats = XE1205RadioM;
  XE1205LPL = XE1205RadioM;


  MacBackoff = XE1205RadioM;


  // Wire modules between themselves
  XE1205RadioM.ConfigControl -> XE1205ControlM;
  XE1205RadioM.XE1205Control -> XE1205ControlM;
  XE1205RadioM.HPLControl -> HPLXE1205C;
  XE1205RadioM.HPLXE1205 -> HPLXE1205C;
  XE1205RadioM.IRQ0 -> HPLXE1205C.IRQ0;
  XE1205RadioM.IRQ1 -> HPLXE1205C.IRQ1;
  XE1205RadioM.Leds -> LedsC;
  XE1205ControlM.HPLXE1205 -> HPLXE1205C;
  XE1205RadioM.CCAThresh -> CCAThreshMA;

  XE1205RadioM.Random -> RandomLFSR;

  XE1205RadioM.TimerJiffy -> TimerJiffyAsyncC.TimerJiffyAsync;
  XE1205RadioM.TimerJiffyControl -> TimerJiffyAsyncC.StdControl;
}

