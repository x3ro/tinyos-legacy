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
/*
 *
 * Authors:		Joe Polastre
 *
 * $Id: IntersemaPressure.nc,v 1.1 2004/06/16 16:47:13 mturon Exp $
 */

includes sensorboard;

configuration IntersemaPressure
{
  provides {
    interface ADC as Temperature;
    interface ADC as Pressure;
    interface ADCError as TemperatureError;
    interface ADCError as PressureError;
    interface Calibration;
    interface SplitControl;
  }
}
implementation
{
  components IntersemaPressureM, IntersemaLower, TimerC, LedsC;

  SplitControl = IntersemaPressureM;
  Temperature = IntersemaPressureM.Temperature;
  Pressure = IntersemaPressureM.Pressure;
  Calibration = IntersemaPressureM;

  PressureError = IntersemaPressureM.PressureError;
  TemperatureError = IntersemaPressureM.TemperatureError;

  IntersemaPressureM.LowerControl -> IntersemaLower.StdControl;

  IntersemaPressureM.LowerPressure -> IntersemaLower.Pressure;
  IntersemaPressureM.LowerTemp -> IntersemaLower.Temp;

  IntersemaPressureM.PressError -> IntersemaLower.PressError;
  IntersemaPressureM.TempError -> IntersemaLower.TempError;

  IntersemaPressureM.LowerCalibrate -> IntersemaLower.Calibration;

  IntersemaPressureM.Timer -> TimerC.Timer[unique("Timer")];
  IntersemaPressureM.TimerControl -> TimerC;

  IntersemaPressureM.Leds -> LedsC;
}
