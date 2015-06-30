
configuration RFPowerMaxOverrideC
{
  provides interface StdControl;
  uses interface StdControl as BottomStdControl;
}
implementation
{
  components RFPowerMaxOverrideM;

  StdControl = RFPowerMaxOverrideM;
  BottomStdControl = RFPowerMaxOverrideM;
}

