configuration HumidityC {
  provides {
    interface ADC as Humidity;
    interface ADC as Temperature;
    interface ADCError as HumidityError;
    interface ADCError as TemperatureError;
    interface SplitControl;
  }
}
implementation {
  components SensirionHumidity;

  SplitControl = SensirionHumidity;
  Humidity = SensirionHumidity.Humidity;
  Temperature = SensirionHumidity.Temperature;
  HumidityError = SensirionHumidity.HumidityError;
  TemperatureError = SensirionHumidity.TemperatureError;
}
