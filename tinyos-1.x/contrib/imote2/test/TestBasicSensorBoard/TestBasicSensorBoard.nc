// $Id: TestBasicSensorBoard.nc,v 1.1 2006/10/10 02:33:57 lnachman Exp $

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
configuration TestBasicSensorBoard {
}
implementation {
  components Main, 
    TestBasicSensorBoardM, 
    PXA27XI2CM,
    BluSHC,
    PMICC,
    LedsC; 
    
  Main.StdControl -> TestBasicSensorBoardM;
  TestBasicSensorBoardM.I2CControl -> PXA27XI2CM;
  TestBasicSensorBoardM.I2C -> PXA27XI2CM;
  TestBasicSensorBoardM.Leds -> LedsC;
  TestBasicSensorBoardM.PMIC -> PMICC;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestBasicSensorBoardM.ReadTempReg;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestBasicSensorBoardM.ReadADCChannel;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestBasicSensorBoardM.ReadLightSensor;
}

