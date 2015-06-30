includes MultiHop;

configuration RSSIMultiHopRouter {

  provides {
    interface StdControl;
    // The interface are as parameterised by the active message id
    // only the 10 active message ids defined MultiHop.h are supported.
    interface Receive[uint8_t id];
    interface Intercept[uint8_t id];
    interface Intercept as Snoop[uint8_t id];
    interface Send[uint8_t id];
    interface RouteControl;
    interface RouteStats;
  }

  uses {
    interface ReceiveMsg[uint8_t id];
  }
}

implementation {

  components
    MultiHopEngineM,
    MultiHopRSSI,
    SimpleTime,
    GenericComm as Comm,
    TimerC,
#ifdef MHOP_LEDS
    LedsC,
#else
    NoLeds as LedsC,
#endif
    RandomLFSR;

  StdControl = MultiHopEngineM;
  Receive = MultiHopEngineM;
  Send = MultiHopEngineM;
  Intercept = MultiHopEngineM.Intercept;
  Snoop = MultiHopEngineM.Snoop;
  RouteControl = MultiHopEngineM;
  RouteStats = MultiHopEngineM;

  ReceiveMsg = MultiHopEngineM;

  MultiHopEngineM.SubControl -> MultiHopRSSI.StdControl;
  MultiHopEngineM.CommStdControl -> Comm;
  MultiHopEngineM.RouteSelectCntl -> MultiHopRSSI.RouteControl;
  MultiHopEngineM.RouteSelect -> MultiHopRSSI;

  MultiHopEngineM.SendMsg -> Comm.SendMsg;

  MultiHopRSSI.Timer -> TimerC.Timer[unique("Timer")];

  MultiHopEngineM.Leds -> LedsC;

  MultiHopRSSI.SendMsg -> Comm.SendMsg[AM_BEACONMSG];
  MultiHopRSSI.ReceiveMsg -> Comm.ReceiveMsg[AM_BEACONMSG];

  MultiHopRSSI.Random -> RandomLFSR;
  MultiHopRSSI.Leds -> LedsC;

  MultiHopRSSI.RouteStats -> MultiHopEngineM;
}
