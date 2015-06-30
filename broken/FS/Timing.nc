includes Matchbox;
includes AM;
includes Remote;
configuration Timing { }
implementation {
  components Main, Matchbox, TimingM;
  components UARTNoCRCPacket as Comm, NoDebug, ClockC;

  Main.StdControl -> TimingM;
  Main.StdControl -> Matchbox;
  Main.StdControl -> Comm;

  Matchbox.ready -> TimingM.matchboxReady;
  TimingM.Clock -> ClockC;
  TimingM.BareSendMsg -> Comm.Send;
  TimingM.ReceiveMsg -> Comm.Receive;
  TimingM.FileRead -> Matchbox.FileRead[unique("FileRead")];
  TimingM.FileWrite -> Matchbox.FileWrite[unique("FileRead")];

  Matchbox.Debug -> NoDebug;
}
