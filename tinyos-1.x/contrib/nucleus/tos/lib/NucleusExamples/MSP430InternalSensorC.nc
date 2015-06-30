//$Id: MSP430InternalSensorC.nc,v 1.2 2005/06/14 18:22:21 gtolle Exp $

configuration MSP430InternalSensorC {
  provides interface StdControl;
}
implementation {
  components MSP430InternalSensorM, InternalVoltageC, InternalTempC;
  
  StdControl = MSP430InternalSensorM;
  
  MSP430InternalSensorM.SubControl -> InternalVoltageC;
  MSP430InternalSensorM.SubControl -> InternalTempC;
  
  MSP430InternalSensorM.VoltageADC -> InternalVoltageC.InternalVoltageADC;
  MSP430InternalSensorM.TemperatureADC -> InternalTempC.InternalTempADC;
}
