
configuration RFPowerC
{
  provides interface StdControl;
}
implementation
{
  components RFPowerM;
  StdControl = RFPowerM;
}

