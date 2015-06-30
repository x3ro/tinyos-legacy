//$Id: VoltageHysteresisC.nc,v 1.4 2005/08/01 21:29:44 jaein Exp $

configuration VoltageHysteresisC
{
  provides interface StdControl;
  provides interface SplitInit as Init;
}
implementation
{
  components VoltageHysteresisM;
  components PrometheusC;
  components TimerC;
  components SounderC;
  //components InternalVoltageC;

  StdControl = TimerC;
  //StdControl = InternalVoltageC;
  StdControl = PrometheusC;

  Init = VoltageHysteresisM;
  VoltageHysteresisM.Prometheus -> PrometheusC;
  //VoltageHysteresisM.ADC -> InternalVoltageC;
  VoltageHysteresisM.InitTimer -> TimerC.Timer[unique("Timer")];
  VoltageHysteresisM.DelayTimer -> TimerC.Timer[unique("Timer")];
  VoltageHysteresisM.Sounder -> SounderC.Sounder;
}

