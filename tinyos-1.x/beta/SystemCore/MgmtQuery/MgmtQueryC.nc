includes SNMS;
includes MgmtAttrs;
includes MgmtQuery;

configuration MgmtQueryC {
  provides {
    interface StdControl;
  }
}
implementation {

  components 
    MgmtQueryM,
    MgmtAttrsC,
    SharedMsgBufM,
    DripC,
    RSSIMultiHopRouter as Multihop,
    TimerC,
    RandomLFSR,
    LedsC as Leds;

  StdControl = MgmtQueryM;

  MgmtQueryM.SubControl -> MgmtAttrsC;
  MgmtQueryM.SubControl -> DripC;
  MgmtQueryM.SubControl -> Multihop;
  MgmtQueryM.SubControl -> TimerC;
  MgmtQueryM.SubControl -> SharedMsgBufM;

  MgmtQueryM.MgmtAttrRetrieve -> MgmtAttrsC;

  MgmtQueryM.Leds -> Leds;
  MgmtQueryM.Timer -> TimerC.Timer[unique("Timer")];

  MgmtQueryM.Query1Receive -> DripC.Receive[AM_MGMTQUERYMSG1];
  MgmtQueryM.Query1Drip -> DripC.Drip[AM_MGMTQUERYMSG1];

  MgmtQueryM.Query2Receive -> DripC.Receive[AM_MGMTQUERYMSG2];
  MgmtQueryM.Query2Drip -> DripC.Drip[AM_MGMTQUERYMSG2];

  MgmtQueryM.Query3Receive -> DripC.Receive[AM_MGMTQUERYMSG3];
  MgmtQueryM.Query3Drip -> DripC.Drip[AM_MGMTQUERYMSG3];

  MgmtQueryM.Query4Receive -> DripC.Receive[AM_MGMTQUERYMSG4];
  MgmtQueryM.Query4Drip -> DripC.Drip[AM_MGMTQUERYMSG4];

  MgmtQueryM.ResponseSendMH -> Multihop.Send[AM_MGMTQUERYRESPONSEMSG];

  MgmtQueryM.Random -> RandomLFSR;
  
  MgmtQueryM.SharedMsgBuf -> SharedMsgBufM.SharedMsgBuf[BUF_SNMS];
}
