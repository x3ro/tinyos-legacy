includes Matchbox;
includes AM;
includes Remote;
configuration TestRemote { }
implementation {
  components Main, Remote, Matchbox, UARTComm as Comm, LedsC, DebugC, TimerC;

  Main.StdControl -> Remote;
  Main.StdControl -> Matchbox;
  Main.StdControl -> TimerC;
  Remote.CommControl -> Comm;

  Remote.FileDelete -> Matchbox;
  Remote.FileDir -> Matchbox;
  Remote.FileRead -> Matchbox.FileRead[1];
  Remote.FileRename -> Matchbox;
  Remote.FileWrite -> Matchbox.FileWrite[1];

  Remote.ReceiveCommandMsg -> Comm.ReceiveMsg[AM_FSOPMSG];
  Remote.SendReplyMsg -> Comm.SendMsg[AM_FSREPLYMSG];
  Remote.sendDone <- Comm;

  Remote.Leds -> LedsC;

  Matchbox.Debug -> DebugC;
  DebugC.SendMsg -> Comm.SendMsg[100];
  DebugC.Timer -> TimerC.Timer[unique("Timer")];
}
