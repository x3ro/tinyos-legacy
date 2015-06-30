/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *

 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// @author Shawn Schaffert <sms@eecs.berkeley.edu>

configuration TestSonar {
}

implementation {
  //components Main, TestSonarM, MSP430I2CC, LedsC, TimerC, BusArbitrationC;
  components Main, TestSonarM, I2CPacketC, LedsC, TimerC;
  //components Main, TestSonarM, LedsC, TimerC, BusArbitrationC;

  Main.StdControl -> TestSonarM;
  Main.StdControl -> TimerC;

  TestSonarM.Leds -> LedsC;
  TestSonarM.Timer -> TimerC.Timer[unique("Timer")];

  //TestSonarM.BusArbitration -> BusArbitrationC.BusArbitration[unique("BusArbitration")];
  //TestSonarM.I2C -> MSP430I2CC;
  //TestSonarM.I2CPacket -> MSP430I2CC;
  //TestSonarM.I2CControl -> MSP430I2CC;
  //TestSonarM.I2CEvents -> MSP430I2CC;

  TestSonarM.I2CPacket -> I2CPacketC;
}

