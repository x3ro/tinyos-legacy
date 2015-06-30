includes Matchbox;
includes AM;
includes Remote;
configuration ETiming { }
implementation {
  components Main, ETimingM, PageEEPROMC;
  components UARTNoCRCPacket as Comm, NoDebug, ClockC;

  Main.StdControl -> ETimingM;
  Main.StdControl -> PageEEPROMC;
  Main.StdControl -> Comm;

  ETimingM.Clock -> ClockC;
  ETimingM.BareSendMsg -> Comm.Send;
  ETimingM.ReceiveMsg -> Comm.Receive;
  ETimingM.PageEEPROM -> PageEEPROMC;

  PageEEPROMC.Debug -> NoDebug;
}
