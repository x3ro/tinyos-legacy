// $Id: PhotoDriverC.nc,v 1.2 2005/08/04 21:20:37 jpolastre Exp $
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
 * $Id: PhotoDriverC.nc,v 1.2 2005/08/04 21:20:37 jpolastre Exp $
 */

includes Photo;
includes sensorboard;

configuration PhotoDriverC
{
  provides {
    interface SplitControl;
    interface ADC as Photo;
    interface Potentiometer;
  }
}
implementation
{
  components PhotoDriverM, ADCC, AD524XC, LedsC;
  
  PhotoDriverM.Leds -> LedsC;

  SplitControl = PhotoDriverM;
  Potentiometer = PhotoDriverM;
  Photo = ADCC.ADC[TOS_ADC_PHOTO_PORT];

  PhotoDriverM.ADCStdControl -> ADCC;
  PhotoDriverM.ADCControl -> ADCC;
  PhotoDriverM.AD524X -> AD524XC;
  PhotoDriverM.AD524XControl -> AD524XC;

}
