//$Id: MagC.nc,v 1.2 2005/07/06 17:25:04 cssharp Exp $
/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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

/**
 * Configuration file for the Trio magnetometer <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

includes sensorboard;

configuration MagC
{
  provides interface StdControl;
  provides interface Mag;
  provides interface ADC as MagXADC;
  provides interface ADC as MagYADC;
}
implementation
{
  components AD5242Bus1C, IOSwitch1C, IOSwitch2C, ADCC, MagM; 

  StdControl = MagM;
  Mag = MagM;
  MagXADC = ADCC.ADC[TOS_ADC_MAG0_PORT];
  MagYADC = ADCC.ADC[TOS_ADC_MAG1_PORT];

  MagM.ADCControl -> ADCC; 
  MagM.AD5242Control -> AD5242Bus1C.StdControl;
  MagM.AD5242 -> AD5242Bus1C.AD5242;

  MagM.IOSwitch1 -> IOSwitch1C;
  MagM.IOSwitch1Control -> IOSwitch1C.StdControl;
  MagM.IOSwitch2 -> IOSwitch2C;
  MagM.IOSwitch2Control -> IOSwitch2C.StdControl;
}
