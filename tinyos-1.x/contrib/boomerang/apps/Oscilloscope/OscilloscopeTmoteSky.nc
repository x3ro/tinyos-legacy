// $Id: OscilloscopeTmoteSky.nc,v 1.1.1.1 2007/11/05 19:08:58 jpolastre Exp $

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
 *
 */

/**
 * This configuration describes the Oscilloscope application,
 * a simple TinyOS app that periodically takes sensor readings
 * and sends a group of readings over the radio. 
 * <p>
 * See README.TmoteSky for more information
 * 
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration OscilloscopeTmoteSky { }
implementation
{
  components Main
           , OscilloscopeTmoteSkyM as OscilloscopeM
           , TimerC
           , LedsC
           , HumidityC
           , HamamatsuC
           , InternalTempC
           , VoltageC
           , OscopeC
           , GenericComm as Comm
           ;
  components DelugeC;

  Main.StdControl -> TimerC;
  Main.StdControl -> Comm;
  Main.StdControl -> OscopeC;
  Main.StdControl -> HamamatsuC;
  Main.StdControl -> InternalTempC;
  Main.StdControl -> VoltageC;
  Main.StdControl -> OscilloscopeM;
  
  OscilloscopeM.Timer -> TimerC.Timer[unique("Timer")];

  OscilloscopeM.Leds -> LedsC;

  OscilloscopeM.HumidityControl -> HumidityC;

  OscilloscopeM.Humidity -> HumidityC.Humidity;
  OscilloscopeM.Temperature -> HumidityC.Temperature;
  OscilloscopeM.TSR -> HamamatsuC.TSR;
  OscilloscopeM.PAR -> HamamatsuC.PAR;
  OscilloscopeM.InternalTemperature -> InternalTempC;
  OscilloscopeM.InternalVoltage -> VoltageC;

  OscilloscopeM.HumidityError -> HumidityC.HumidityError;
  OscilloscopeM.TemperatureError -> HumidityC.TemperatureError;

  OscilloscopeM.OHumidity -> OscopeC.Oscope[0];
  OscilloscopeM.OTemperature -> OscopeC.Oscope[1];
  OscilloscopeM.OTSR -> OscopeC.Oscope[2];
  OscilloscopeM.OPAR -> OscopeC.Oscope[3];
  OscilloscopeM.OInternalTemperature -> OscopeC.Oscope[4];
  OscilloscopeM.OInternalVoltage -> OscopeC.Oscope[5];

}
