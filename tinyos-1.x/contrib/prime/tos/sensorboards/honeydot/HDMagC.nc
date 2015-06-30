/* "Copyright (c) 2000-2002 The Regents of the University of California.  
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
 */

// Authors: Cory Sharp
// $Id: HDMagC.nc,v 1.1.1.2 2004/03/06 03:00:48 mturon Exp $

includes sensorboard;

configuration HDMagC
{
  provides interface HDMag;
  provides interface StdControl;
}
implementation
{
  components HDMagM;
#ifndef PLATFORM_PC
  components X9259C, ADCC;
#endif //PLATFORM_PC

  HDMag = HDMagM;
  StdControl = HDMagM;

#ifndef PLATFORM_PC
  HDMagM.X9259 -> X9259C;
  HDMagM.X9259Control -> X9259C;
  
  HDMagM.MagX -> ADCC.ADC[TOS_ADC_MAG_X_PORT];
  HDMagM.MagY -> ADCC.ADC[TOS_ADC_MAG_Y_PORT];
  HDMagM.ADCControl -> ADCC;
#endif //PLATFORM_PC
}

