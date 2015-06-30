//$Id: MgmtQueryC.nc,v 1.8 2005/06/16 21:56:16 cssharp Exp $

includes Attrs;
includes DestMsg;
includes MgmtQuery;
includes AM;

/**
 * This component is the main engine for processing remote attribute
 * and RAM queries, accessing the attributes, and returning the
 * results.
 *
 * @author Gilman Tolle
 */
configuration MgmtQueryC {
  provides {
    interface StdControl;
  }
}
implementation {

  components 
    MgmtQueryM,
    AttrsC,
    TimerC,
    RandomLFSR,
    GenericComm,
    DestC;

#ifdef NUCLEUS_NO_LEDS
  components NoLeds as Leds;
#else
  components LedsC as Leds;
#endif

  components DrainC;
  components DripC, DripStateC;

  StdControl = MgmtQueryM;

  MgmtQueryM.SubControl -> TimerC;
  MgmtQueryM.SubControl -> GenericComm;
  MgmtQueryM.SubControl -> AttrsC;

  MgmtQueryM.SubControl -> DrainC;
  MgmtQueryM.SubControl -> DripC;

  MgmtQueryM.Leds -> Leds;
  MgmtQueryM.Timer -> TimerC.Timer[unique("Timer")];
  MgmtQueryM.Random -> RandomLFSR;
  
  MgmtQueryM.AttrClient -> AttrsC.AttrClient;

  MgmtQueryM.QueryReceiveLocal -> GenericComm.ReceiveMsg[AM_MGMTQUERYMSG];
  MgmtQueryM.ResponseSend -> GenericComm.SendMsg[AM_MGMTQUERYRESPONSEMSG];  

  MgmtQueryM.ResponseSendMsgMH -> DrainC.SendMsg[AM_MGMTQUERYRESPONSEMSG];
  MgmtQueryM.ResponseSendMH -> DrainC.Send[AM_MGMTQUERYRESPONSEMSG];

  MgmtQueryM.QueryReceiveDrain -> DrainC.Receive[AM_MGMTQUERYMSG];

  MgmtQueryM.QueryReceive -> DripC.Receive[AM_MGMTQUERYMSG];
  MgmtQueryM.QueryDrip -> DripC.Drip[AM_MGMTQUERYMSG];
  DripC.DripState[AM_MGMTQUERYMSG] -> DripStateC.DripState[unique("DripState")];

  MgmtQueryM.Dest -> DestC;
}
