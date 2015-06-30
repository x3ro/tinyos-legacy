// $Id: HamamatsuC.nc,v 1.1.1.1 2007/11/05 19:11:34 jpolastre Exp $
/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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

#include "Hamamatsu.h"

/**
 * Sensor driver for the S1087 and S1087-01 photodiodes on Moteiv's
 * Tmote Sky.
 * <p>
 * <b>Only available on Moteiv's Tmote Sky WITH optional sensor suite</b>
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration HamamatsuC
{
  provides {
    interface ADC as PAR;
    interface ADC as TSR;
    interface ADCSingle as PARSingle;
    interface ADCSingle as TSRSingle;
    interface ADCMultiple as PARMultiple;
    interface ADCMultiple as TSRMultiple;
    interface StdControl;
  }
}
implementation
{
  components HamamatsuM, MSP430ADC12C, ADCC;

  StdControl = ADCC;
  StdControl = HamamatsuM;

  PAR = ADCC.ADC[TOS_ADC_PAR_PORT];
  TSR = ADCC.ADC[TOS_ADC_TSR_PORT];

  PARSingle = HamamatsuM.PARSingle;
  PARMultiple = HamamatsuM.PARMultiple;

  TSRSingle = HamamatsuM.TSRSingle;
  TSRMultiple = HamamatsuM.TSRMultiple;

  HamamatsuM.ADCControl -> ADCC;

  HamamatsuM.MSP430ADC12SinglePAR -> MSP430ADC12C.MSP430ADC12Single[unique("MSP430ADC12")];
  HamamatsuM.MSP430ADC12SingleTSR -> MSP430ADC12C.MSP430ADC12Single[unique("MSP430ADC12")];
  HamamatsuM.MSP430ADC12MultiplePAR -> MSP430ADC12C.MSP430ADC12Multiple[unique("MSP430ADC12")];
  HamamatsuM.MSP430ADC12MultipleTSR -> MSP430ADC12C.MSP430ADC12Multiple[unique("MSP430ADC12")];


}
