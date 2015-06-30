includes Straw;
includes DripSend;
configuration StrawC
{
  provides {
    interface StdControl;
    interface Straw[uint8_t id];
  }
}
implementation
{
  components
    TimerC,
    GenericComm as Comm,
    QueuedSend,
    DripC, DripStateC,
    DrainC as multihopM,
    new DripSendC(AM_STRAWCMDMSG),
    StrawM;

  StdControl = TimerC;
  StdControl = Comm;
  StdControl = QueuedSend;
  StdControl = DripC;
  StdControl = multihopM;
  StdControl = DripSendC;
  StdControl = StrawM;
 
  Straw = StrawM;

  StrawM.DripSendTimer -> TimerC.Timer[unique("Timer")];
  StrawM.ShootingTimer -> TimerC.Timer[unique("Timer")];
  StrawM.SendUART -> QueuedSend.SendMsg[AM_STRAWUARTMSG];

  StrawM.ReceiveGrp -> DripC.Receive[AM_STRAWGRPMSG];
  StrawM.Drip -> DripC.Drip[AM_STRAWGRPMSG];
  DripC.DripState[AM_STRAWGRPMSG] ->
    DripStateC.DripState[unique("DripState")];
  StrawM.DrainGroup -> multihopM;
  StrawM.ReceiveCmd -> DripSendC;

  StrawM.RouteControl -> multihopM;
  StrawM.DummyReply -> multihopM.Send[AM_STRAWREPLYMSG];
  StrawM.SendReply -> multihopM.SendMsg[AM_STRAWREPLYMSG];
}

