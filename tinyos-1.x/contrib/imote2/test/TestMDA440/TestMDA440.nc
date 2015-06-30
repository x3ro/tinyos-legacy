// $Id: TestMDA440.nc,v 1.4 2006/09/09 16:05:20 radler Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Blink is a basic application that toggles the leds on the mote
 * on every clock interrupt.  The clock interrupt is scheduled to
 * occur every second.  The initialization of the clock can be seen
 * in the Blink initialization function, StdControl.start().<p>
 *
 * @author tinyos-help@millennium.berkeley.edu
 **/
configuration TestMDA440 {
}
implementation {
  components Main, 
    TestMDA440M, 
    TimerC,
    BluSHC,
    MDA440C,
    HPLFFUARTC,
    LedsC;
     	
  Main.StdControl -> TestMDA440M.StdControl;
  Main.StdControl -> MDA440C.StdControl;
  Main.StdControl -> TimerC.StdControl;
  TestMDA440M.Timer -> TimerC.Timer[unique("Timer")];
  TestMDA440M.Leds -> LedsC;
  
  TestMDA440M.MDA440 -> MDA440C.MDA440;
  
  TestMDA440M.UART -> HPLFFUARTC;

  TestMDA440M.EEPROM -> MDA440C.EEPROM;
  //BlUSH miniapps

  BluSHC.BluSH_AppI[unique("BluSH")] -> TestMDA440M.SetGPIO;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestMDA440M.ClearGPIO;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestMDA440M.TurnOffBoard;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestMDA440M.EnableHighSpeedChain;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestMDA440M.DisableHighSpeedChain;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestMDA440M.SelectMux0Channel;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestMDA440M.EnableLowSpeedChain;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestMDA440M.DisableLowSpeedChain;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestMDA440M.SelectLowSpeedChannel;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestMDA440M.GetData;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestMDA440M.SetAccelIn;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestMDA440M.SetTempIn;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestMDA440M.SetCurrentIn;

  BluSHC.BluSH_AppI[unique("BluSH")] -> TestMDA440M.StartRPMCapture;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestMDA440M.StopRPMCapture;
 
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestMDA440M.ReadCal;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestMDA440M.WriteCal;
  
}

