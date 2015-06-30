// $Id: Testradio.nc,v 1.3 2006/10/10 02:43:56 lnachman Exp $

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
configuration Testradio {
}
implementation {
  components Main, 
      TestradioM, 
      TimerC,
      BluSHC,
      LedsC,
      HPLCC2420C;

  Main.StdControl -> BluSHC.StdControl;
  Main.StdControl -> TimerC.StdControl;
  Main.StdControl -> TestradioM.StdControl;
  TestradioM.Timer -> TimerC.Timer[unique("Timer")];
  TestradioM.Leds -> LedsC;
  TestradioM.RadioControl -> HPLCC2420C.StdControl;
  TestradioM.HPLCC2420 -> HPLCC2420C.HPLCC2420;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestradioM.CmdRadio;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestradioM.ReadRadio;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestradioM.WriteRadio;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestradioM.ToggleCarrier;    
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestradioM.ToggleTxTest;    
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestradioM.SetTxPower;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestradioM.ToggleOscOutput;
  

}

