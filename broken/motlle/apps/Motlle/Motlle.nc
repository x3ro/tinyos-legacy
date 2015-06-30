includes Motlle;
configuration Motlle { }
implementation {
  components Main, GenericComm, TimerC, LedsC, DebugC;
  components MotlleM, MotlleDebug, MotlleLeds, MotlleSleep, ReceiveCode;

  Main.StdControl -> MotlleM;

  MotlleM.SubControl -> GenericComm;
  MotlleM.SubControl -> TimerC;
  MotlleM.Debug -> MotlleDebug.MotlleDebug[DBG_SYS];
  MotlleM.Leds -> LedsC;

  MotlleSleep.MotlleControl -> MotlleM;
  MotlleSleep.Timer -> TimerC.Timer[unique("Timer")];

  MotlleLeds.MotlleControl -> MotlleM;
  MotlleLeds.Leds -> LedsC;

  MotlleDebug.Debug -> DebugC;
  MotlleDebug.dbgAvailable <- DebugC.available;
  MotlleDebug.MotlleControl -> MotlleM;

  ReceiveCode.ReceiveCode -> GenericComm.ReceiveMsg[42];
  ReceiveCode.MotlleControl -> MotlleM;
  ReceiveCode.Debug -> MotlleDebug.MotlleDebug[DBG_CODE];
  ReceiveCode.Leds -> LedsC;

  DebugC.Timer -> TimerC.Timer[unique("Timer")];
  DebugC.SendMsg -> GenericComm.SendMsg[42];
}
