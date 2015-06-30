//$Id: McuVoltageAttrC.nc,v 1.1 2005/06/19 01:52:39 cssharp Exp $

configuration McuVoltageAttrC
{
  provides interface StdControl;
  provides interface Attr<uint16_t> as VoltageAttr @nucleusAttr("McuVoltage");
}
implementation
{
  components InternalVoltageC;
  components new AdcAttrC();

  StdControl = InternalVoltageC;
  StdControl = AdcAttrC;
  VoltageAttr = AdcAttrC;

  AdcAttrC.ADC -> InternalVoltageC;
}

