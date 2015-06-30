includes Straw;
configuration StrawC
{
  provides {
    interface StdControl;
    interface Straw;
  }
}
implementation
{
  components
    TimerC,
    GenericComm as Comm,
    QueuedSend,
    Bcast,
    ////DripC, DripStateC,
    DrainC as multihopM,
    StrawM;

  StdControl = TimerC;
  StdControl = Comm;
  StdControl = QueuedSend;
  StdControl = Bcast;
  ////StdControl = DripC;
  StdControl = multihopM;
  StdControl = StrawM;
 
  Straw = StrawM;

  StrawM.ReceiveCmd -> Bcast.Receive[AM_STRAWCMDMSG];
  Bcast.ReceiveMsg[AM_STRAWCMDMSG] -> Comm.ReceiveMsg[AM_STRAWCMDMSG];
  ////StrawM.ReceiveCmd -> DripC.Receive[AM_STRAWCMDMSG];
  ////StrawM.Drip -> DripC.Drip[AM_STRAWCMDMSG];
  ////DripC.DripState[AM_STRAWCMDMSG] ->
  ////  DripStateC.DripState[unique("DripState")];
  
  StrawM.DummyReply -> multihopM.Send[AM_STRAWREPLYMSG];
  StrawM.SendReply -> multihopM.SendMsg[AM_STRAWREPLYMSG];

  StrawM.SendUART -> QueuedSend.SendMsg[AM_STRAWUARTMSG];

  StrawM.RouteControl -> multihopM;
  StrawM.Timer -> TimerC.Timer[unique("Timer")];
}

