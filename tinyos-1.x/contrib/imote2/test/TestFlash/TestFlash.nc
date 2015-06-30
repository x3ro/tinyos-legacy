// $Id: TestFlash.nc,v 1.1 2005/09/02 22:22:35 radler Exp $

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
configuration TestFlash {
}
implementation {
  components Main, 
    TestFlashM as App, 
    TimerC,
    BluSHC,
    FlashC,
    LedsC;
     	
  Main.StdControl -> BluSHC.StdControl;
  Main.StdControl -> TimerC.StdControl;
  Main.StdControl -> App.StdControl;
  App.Timer -> TimerC.Timer[unique("Timer")];
  App.Leds -> LedsC;
  
  App.Flash -> FlashC;

  //BlUSH miniapps
  BluSHC.BluSH_AppI[unique("BluSH")] -> App.writeFlash;
  BluSHC.BluSH_AppI[unique("BluSH")] -> App.eraseFlash;
  BluSHC.BluSH_AppI[unique("BluSH")] -> App.verifyEraseFlash;
  BluSHC.BluSH_AppI[unique("BluSH")] -> App.verifyWriteFlash; 
  BluSHC.BluSH_AppI[unique("BluSH")] -> App.stressTest; 
}

