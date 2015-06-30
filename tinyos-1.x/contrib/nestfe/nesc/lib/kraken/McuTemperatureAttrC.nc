//$Id: McuTemperatureAttrC.nc,v 1.1 2005/06/19 01:52:39 cssharp Exp $

configuration McuTemperatureAttrC
{
  provides interface StdControl;
  provides interface Attr<uint16_t> as TemperatureAttr @nucleusAttr("McuTemperature");
}
implementation
{
  components InternalTempC;
  components new AdcAttrC();

  StdControl = InternalTempC;
  StdControl = AdcAttrC;
  TemperatureAttr = AdcAttrC;

  AdcAttrC.ADC -> InternalTempC;
}

