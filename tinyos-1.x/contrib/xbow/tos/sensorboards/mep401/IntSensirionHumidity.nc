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
 * $Id: IntSensirionHumidity.nc,v 1.1 2004/07/16 21:54:39 ammbot Exp $
 */

includes sensorboard;

configuration IntSensirionHumidity
{
  provides {
    interface SplitControl;
    interface ADC as Humidity;
    interface ADC as Temperature;
    interface ADCError as HumidityError;
    interface ADCError as TemperatureError;
  }
}

implementation
{
  components IntSensirionHumidityM, TimerC, IntTempHum;

  SplitControl = IntSensirionHumidityM;
  Humidity = IntSensirionHumidityM.Humidity;
  Temperature = IntSensirionHumidityM.Temperature;
  HumidityError = IntSensirionHumidityM.HumidityError;
  TemperatureError = IntSensirionHumidityM.TemperatureError;

  IntSensirionHumidityM.TimerControl -> TimerC.StdControl;
  IntSensirionHumidityM.Timer -> TimerC.Timer[unique("Timer")];

  IntSensirionHumidityM.SensorControl -> IntTempHum.StdControl;
  IntSensirionHumidityM.HumSensor -> IntTempHum.HumSensor;
  IntSensirionHumidityM.TempSensor -> IntTempHum.TempSensor;

  IntSensirionHumidityM.HumError -> IntTempHum.HumError;
  IntSensirionHumidityM.TempError -> IntTempHum.TempError;
}
