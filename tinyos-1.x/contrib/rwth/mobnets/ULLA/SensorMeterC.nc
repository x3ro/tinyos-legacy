/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */
 
/**
 *
 * Sensor Meter - senses the physical world e.g. light, temperature, etc.
 * It is used for the SmartHome Monitoring application.
 *
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/
/*
#ifndef OSCOPE
#define OSCOPE
#endif*/
/*
#ifndef TELOS_SENSOR
#define TELOS_SENSOR
#endif*/
includes UllaQuery;

configuration SensorMeterC {
  provides {
    interface StdControl;
    ///interface RequestUpdate;
    interface LinkProviderIf[uint8_t id];
  }

}
implementation {

 components
      Main
    , SensorMeterM
    , EventProcessorC
    //, LLAC
#ifdef HISTORICAL_STORAGE
    , HistoricalStorageC
#endif
    , TimerC
    , LedsC
#ifdef OSCOPE
    , OscopeC
#endif
#ifdef TELOS_SENSOR
    , HumidityC
    , HamamatsuC
    , InternalTempC
    , InternalVoltageC
#endif
    //, GenericComm as Comm
    ;
    
  Main.StdControl -> SensorMeterM;
  Main.StdControl -> TimerC;
  //Main.StdControl -> Comm;
#ifdef OSCOPE
  Main.StdControl -> OscopeC;
#endif
#ifdef TELOS_SENSOR
  Main.StdControl -> HamamatsuC;
  Main.StdControl -> InternalTempC;
  Main.StdControl -> InternalVoltageC;
#endif

  StdControl = SensorMeterM;

  SensorMeterM.Timer -> TimerC.Timer[unique("Timer")];
  SensorMeterM.Leds -> LedsC;

  ///RequestUpdate = SensorMeterM;
  LinkProviderIf = SensorMeterM;

  SensorMeterM.AttributeEvent   -> EventProcessorC.ProcessEvent[0];
  SensorMeterM.LinkEvent        -> EventProcessorC.ProcessEvent[1];
  SensorMeterM.CompleteCmdEvent -> EventProcessorC.ProcessEvent[2];

#ifdef HISTORICAL_STORAGE
  SensorMeterM.WriteToStorage  -> HistoricalStorageC;
#endif
  /////SensorMeterM.Send -> LLAC.SendInf;
#ifdef TELOS_SENSOR
  /* Sensors */
  SensorMeterM.HumidityControl -> HumidityC;

  SensorMeterM.Humidity -> HumidityC.Humidity;
  SensorMeterM.Temperature -> HumidityC.Temperature;
  SensorMeterM.TSR -> HamamatsuC.TSR;
  SensorMeterM.PAR -> HamamatsuC.PAR;
  SensorMeterM.InternalTemperature -> InternalTempC;
  SensorMeterM.InternalVoltage -> InternalVoltageC;

  SensorMeterM.HumidityError -> HumidityC.HumidityError;
  SensorMeterM.TemperatureError -> HumidityC.TemperatureError;
#endif
#ifdef OSCOPE
  SensorMeterM.OHumidity -> OscopeC.Oscope[0];
  SensorMeterM.OTemperature -> OscopeC.Oscope[1];
  SensorMeterM.OTSR -> OscopeC.Oscope[2];
  SensorMeterM.OPAR -> OscopeC.Oscope[3];
  SensorMeterM.OInternalTemperature -> OscopeC.Oscope[4];
  SensorMeterM.OInternalVoltage -> OscopeC.Oscope[5];
#endif

}


