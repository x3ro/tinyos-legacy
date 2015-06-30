

/*
 *
 * Authors:		Joe Polastre
 *
 */

includes sensorboard;

configuration SensirionHumidity
{
  provides {
    interface ADC as Humidity;
    interface ADC as Temperature;
    interface ADCError as HumidityError;
    interface ADCError as TemperatureError;
    interface SplitControl;
  }
}
implementation
{
  components SensirionHumidityM, MicaWbSwitch, TimerC, TempHum,LedsC, NoLeds;

  SplitControl = SensirionHumidityM;
  Humidity = SensirionHumidityM.Humidity;
  Temperature = SensirionHumidityM.Temperature;
  HumidityError = SensirionHumidityM.HumidityError;
  TemperatureError = SensirionHumidityM.TemperatureError;

  SensirionHumidityM.Timer -> TimerC.Timer[unique("Timer")];

  SensirionHumidityM.SensorControl -> TempHum;
  SensirionHumidityM.HumSensor -> TempHum.HumSensor;
  SensirionHumidityM.TempSensor -> TempHum.TempSensor;

  SensirionHumidityM.SwitchControl -> MicaWbSwitch.StdControl;
  SensirionHumidityM.Switch1 -> MicaWbSwitch.Switch[0];
  SensirionHumidityM.SwitchI2W -> MicaWbSwitch.Switch[1];

  SensirionHumidityM.HumError -> TempHum.HumError;
  SensirionHumidityM.TempError -> TempHum.TempError;

  SensirionHumidityM.Leds -> NoLeds;
 
}
