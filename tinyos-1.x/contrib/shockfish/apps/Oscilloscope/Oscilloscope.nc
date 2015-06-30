// $Id: Oscilloscope.nc,v 1.9 2005/09/02 19:23:14 rogmeier Exp $

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
 * This configuration describes the Oscilloscope application,
 * a simple TinyOS app that periodically takes sensor readings
 * and sends a group of readings over the radio. 
 */
 
configuration Oscilloscope { }
implementation
{
  components Main,
    OscilloscopeM,
    OscopeC,
    TimerC,
    LedsC,
    HumidityC,
    ExTempC,
    VbatC,
    LightC,
    InternalTempC,
    InternalVoltageC,
    GenericComm as Comm;

  Main.StdControl -> TimerC;
  Main.StdControl -> Comm;

  Main.StdControl -> ExTempC;
  Main.StdControl -> LightC;
  Main.StdControl -> InternalTempC;
  Main.StdControl -> InternalVoltageC;
  Main.StdControl -> OscilloscopeM;
  
  Main.StdControl -> VbatC;
  
  OscilloscopeM.Timer -> TimerC.Timer[unique("Timer")];
  OscilloscopeM.Leds -> LedsC;

  OscilloscopeM.HumidityControl -> HumidityC;

  OscilloscopeM.Humidity -> HumidityC.Humidity;
  OscilloscopeM.Temperature -> HumidityC.Temperature;
  OscilloscopeM.ExTempADC -> ExTempC;
  OscilloscopeM.VoltageADC -> VbatC;
  OscilloscopeM.LightADC -> LightC;
  OscilloscopeM.InternalTempADC -> InternalTempC;
  OscilloscopeM.InternalVoltageADC -> InternalVoltageC;
  
  OscilloscopeM.HumidityError -> HumidityC.HumidityError;
  OscilloscopeM.TemperatureError -> HumidityC.TemperatureError;
  
  OscilloscopeM.OExTemp -> OscopeC.Oscope[0];
  OscilloscopeM.OVoltage -> OscopeC.Oscope[1];
  OscilloscopeM.OLight -> OscopeC.Oscope[2];
  OscilloscopeM.OInternalTemperature -> OscopeC.Oscope[3];
  OscilloscopeM.OInternalVoltage -> OscopeC.Oscope[4];
  OscilloscopeM.OHumidity -> OscopeC.Oscope[5];
  OscilloscopeM.OTemperature -> OscopeC.Oscope[6];
}


