//$Id: SensirionHumTempC.nc,v 1.2 2005/06/14 18:22:21 gtolle Exp $

configuration SensirionHumTempC {
  provides interface StdControl;
}
implementation {
  components SensirionHumTempM;
  components HumidityC;

  StdControl = SensirionHumTempM;

  SensirionHumTempM.SplitControl -> HumidityC;

  SensirionHumTempM.Humidity -> HumidityC.Humidity;
  SensirionHumTempM.Temperature -> HumidityC.Temperature;
}

