includes SNMS;
includes MultiHopLayer;

configuration RSSIMultiHopRouter {
  
  provides {
    interface StdControl;

    interface Send[uint8_t id];

    interface Receive[uint8_t id];
    interface Intercept[uint8_t id];
    interface Intercept as Snoop[uint8_t id];

    interface RouteControl;
    interface RouteStats;
  }
}

implementation {

  components 
    MultiHopLayerEngineM, 
    MultiHopRSSI, 
    EventLoggerC,
    MgmtAttrsC,
    SharedMsgBufM,
    GenericComm as Comm, 
    TimerC, 
    NoLeds as Leds,
    RandomLFSR;

#ifdef TIMESYNC
  components SimpleTime;
#endif

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)
  components CC1000RadioIntM as RadioCoord;
  components CC1000RadioC as RadioC;
#elif defined(PLATFORM_MICA)
  components MicaHighSpeedRadioM as RadioCoord;
#endif

  StdControl = MultiHopLayerEngineM;
  Receive = MultiHopLayerEngineM;
  Send = MultiHopLayerEngineM;
  Intercept = MultiHopLayerEngineM.Intercept;
  Snoop = MultiHopLayerEngineM.Snoop;
  RouteControl = MultiHopLayerEngineM;
  RouteStats = MultiHopLayerEngineM;
  
  MultiHopLayerEngineM.SubControl -> MultiHopRSSI.StdControl;
  MultiHopLayerEngineM.CommStdControl -> Comm;

  MultiHopLayerEngineM.Leds -> Leds;

  MultiHopLayerEngineM.RouteSelectCntl -> MultiHopRSSI.RouteControl;
  MultiHopLayerEngineM.RouteSelect -> MultiHopRSSI;

  MultiHopLayerEngineM.SendMsg -> Comm.SendMsg[AM_MULTIHOPLAYERMSG];
  MultiHopLayerEngineM.ReceiveMsg -> Comm.ReceiveMsg[AM_MULTIHOPLAYERMSG];

  MultiHopLayerEngineM.MA_LocalSendRequests -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  MultiHopLayerEngineM.MA_LocalSendFailures -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  MultiHopLayerEngineM.MA_ForwardSendRequests -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  MultiHopLayerEngineM.MA_ForwardSendFailures -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  MultiHopLayerEngineM.MA_ForwardQueueDiscards -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)
  MultiHopLayerEngineM.MacControl -> RadioC.MacControl;
#endif

  MultiHopLayerEngineM.forwardResult -> MultiHopRSSI.forwardResult;

  MultiHopRSSI.Timer -> TimerC.Timer[unique("Timer")];
  MultiHopRSSI.AgingTimer -> TimerC.Timer[unique("Timer")];  

  MultiHopRSSI.SendMsg -> Comm.SendMsg[AM_MULTIHOPBEACONMSG];
  MultiHopRSSI.ReceiveMsg -> Comm.ReceiveMsg[AM_MULTIHOPBEACONMSG];

  MultiHopRSSI.Random -> RandomLFSR;

  MultiHopRSSI.RouteStats -> MultiHopLayerEngineM;

  MultiHopRSSI.SharedMsgBuf -> SharedMsgBufM.SharedMsgBuf[BUF_SNMS];

#ifdef TIMESYNC
  // TimeSync-related Components
  MultiHopLayerEngineM.SubControl -> SimpleTime.StdControl;

  MultiHopRSSI.Time -> SimpleTime.Time;
  MultiHopRSSI.TimeUtil -> SimpleTime.TimeUtil;
  MultiHopRSSI.TimeSet -> SimpleTime.TimeSet;
#endif

#if defined(PLATFORM_MICA) || defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)
  MultiHopRSSI.RadioCoordinator -> RadioCoord.RadioSendCoordinator;
#endif

  MultiHopRSSI.MA_Parent -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  MultiHopRSSI.MA_CurrentTreeID -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  MultiHopRSSI.MA_CurrentParentCost -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  MultiHopRSSI.MA_CurrentParentLinkEst -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  MultiHopRSSI.MA_CurrentParentAckEst -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  MultiHopRSSI.MA_BeaconSeqno -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  MultiHopRSSI.MA_SuccessCounter -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  MultiHopRSSI.MA_FailCounter -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  MultiHopRSSI.MA_PacketTTLDrops -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];

#ifdef MH_DEBUG
  MultiHopRSSI.EventLogger -> EventLoggerC.EventLogger;
#endif
}






