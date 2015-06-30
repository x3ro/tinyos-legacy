// $Id: AccelDriverC.nc,v 1.4 2005/08/04 21:20:57 jpolastre Exp $
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
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
/**
 * @author Joe Polastre <info@moteiv.com>
 *
 * $Id: AccelDriverC.nc,v 1.4 2005/08/04 21:20:57 jpolastre Exp $
 */

includes Accel;
includes sensorboard;

configuration AccelDriverC
{
  provides {
    interface SplitControl;
    interface ADC as AccelX;
    interface ADC as AccelY;
    interface TSBInterrupt as AccelInterrupt;
    interface Potentiometer as AccelInterruptSettings;
  }
}
implementation
{
  components AccelDriverM, ADCC, AD524XC, MSP430InterruptC, LedsC;
  
  AccelDriverM.Leds -> LedsC;

  SplitControl = AccelDriverM;
  AccelX = ADCC.ADC[TOS_ADC_ACCELX_PORT];
  AccelY = ADCC.ADC[TOS_ADC_ACCELY_PORT];
  AccelInterrupt = AccelDriverM;
  AccelInterruptSettings = AccelDriverM;

  AccelDriverM.ADCStdControl -> ADCC;
  AccelDriverM.ADCControl -> ADCC;
  AccelDriverM.AD524X -> AD524XC;
  AccelDriverM.AD524XControl -> AD524XC;
  AccelDriverM.AccelInt -> MSP430InterruptC.Port23; // GIO2

}
