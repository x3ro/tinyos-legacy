configuration Motlle { }
implementation {
  components Main, MotlleM, GenericComm, TimerC, LedsC, DebugC;

  Main.StdControl -> MotlleM;

  MotlleM.SubControl -> GenericComm;
  MotlleM.SubControl -> TimerC;
  MotlleM.Timer -> TimerC.Timer[unique("Timer")];
  MotlleM.Leds -> LedsC;
  MotlleM.Debug -> DebugC;
  MotlleM.dbgAvailable <- DebugC.available;
  MotlleM.ReceiveCode -> GenericComm.ReceiveMsg[42];

  DebugC.Timer -> TimerC.Timer[unique("Timer")];
  DebugC.SendMsg -> GenericComm.SendMsg[42];
}
