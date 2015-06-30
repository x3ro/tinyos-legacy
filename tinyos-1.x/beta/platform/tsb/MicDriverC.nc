// $Id: MicDriverC.nc,v 1.3 2005/08/04 21:59:19 jpolastre Exp $
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
 * Revision: $Revision $
 */

includes Mic;
includes sensorboard;

configuration MicDriverC
{
  provides {
    interface SplitControl;
    interface ADC as Mic;
    interface TSBInterrupt as MicInterrupt;
    interface Potentiometer as Vrc;
    interface Potentiometer as Vrg;
    interface Potentiometer as MicInterruptDrain;
    interface Potentiometer as MicInterruptThreshold;    
  }
}
implementation
{
  components MicDriverM, ADCC, AD524XC, MSP430InterruptC, LedsC;
  
  MicDriverM.Leds -> LedsC;

  SplitControl = MicDriverM;
  Mic = ADCC.ADC[TOS_ADC_MIC_PORT];
  MicInterrupt = MicDriverM;
  MicInterruptDrain = MicDriverM.MicInterruptDrain;
  MicInterruptThreshold = MicDriverM.MicInterruptThreshold;
  Vrc = MicDriverM.Vrc;
  Vrg = MicDriverM.Vrg;

  MicDriverM.ADCStdControl -> ADCC;
  MicDriverM.ADCControl -> ADCC;
  MicDriverM.AD524X -> AD524XC;
  MicDriverM.AD524XControl -> AD524XC;
  MicDriverM.MicInt -> MSP430InterruptC.Port26; // GIO3

}
