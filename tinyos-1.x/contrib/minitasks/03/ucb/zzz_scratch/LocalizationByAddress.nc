
includes Routing;
includes Neighborhood;

//!! TryMe = CreateAttribute[ SillyAttr: Handmade=Chocolate, Ornaments=July ]( uint8_t = 0 );

configuration LocalizationByAddress
{
}
implementation
{
  components Main, LocalizationByAddressC, GenericComm, DomulM, TimerC, MulCmdC;
  Main.StdControl -> LocalizationByAddressC;
  Main.StdControl -> GenericComm;
  Main.StdControl -> DomulM;
  Main.StdControl -> TimerC;
  DomulM.Timer -> TimerC.Timer[unique("Timer")];
  DomulM.MulCmd -> MulCmdC;
}

