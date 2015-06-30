includes Matchbox;
includes AM;
includes Remote;
configuration QRemote { }
implementation {
  components Main, Remote, Matchbox;
  components UARTComm as Comm, LedsC, NoDebug, ClockC;

  Main.StdControl -> Remote;
  Main.StdControl -> Matchbox;
  Remote.CommControl -> Comm;

  Remote.FileDelete -> Matchbox;
  Remote.FileDir -> Matchbox;
  Remote.FileRead -> Matchbox.FileRead[unique("FileRead")];
  Remote.FileRename -> Matchbox;
  Remote.FileWrite -> Matchbox.FileWrite[unique("FileWrite")];

  Remote.ReceiveCommandMsg -> Comm.ReceiveMsg[AM_FSOPMSG];
  Remote.SendReplyMsg -> Comm.SendMsg[AM_FSREPLYMSG];
  Remote.sendDone <- Comm;
  Remote.Leds -> LedsC;

  Matchbox.Debug -> NoDebug;
}
