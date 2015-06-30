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
    GenericCommPromiscuous as Comm, 
    QueuedSend, 
    TimerC, 
    RandomLFSR;

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
  components CC1000RadioIntM as RadioCoord;
#else
  components MicaHighSpeedRadioM as RadioCoord;
#endif

  StdControl = MultiHopEngineM;
  Receive = MultiHopEngineM;
  Send = MultiHopEngineM;
  Intercept = MultiHopEngineM.Intercept;
  Snoop = MultiHopEngineM.Snoop;
  RouteControl = MultiHopEngineM;
  RouteStats = MultiHopEngineM;

  ReceiveMsg = MultiHopEngineM;

  MultiHopEngineM.SubControl -> QueuedSend.StdControl;
  MultiHopEngineM.SubControl -> SimpleTime.StdControl;
  MultiHopEngineM.SubControl -> MultiHopRSSI.StdControl;
  MultiHopEngineM.CommStdControl -> Comm;
  MultiHopEngineM.CommControl -> Comm;
  MultiHopEngineM.RouteSelectCntl -> MultiHopRSSI.RouteControl;
  MultiHopEngineM.RouteSelect -> MultiHopRSSI;

  MultiHopEngineM.SendMsg -> QueuedSend.SendMsg;
  
  MultiHopRSSI.Timer -> TimerC.Timer[unique("Timer")];  

  MultiHopRSSI.SendMsg -> QueuedSend.SendMsg[AM_BEACONMSG];
  MultiHopRSSI.ReceiveMsg -> Comm.ReceiveMsg[AM_BEACONMSG];

  MultiHopRSSI.Random -> RandomLFSR;

  MultiHopRSSI.RouteStats -> MultiHopEngineM;

  // TimeSync-related Components
  MultiHopRSSI.Time -> SimpleTime.Time;
  MultiHopRSSI.TimeUtil -> SimpleTime.TimeUtil;
  MultiHopRSSI.TimeSet -> SimpleTime.TimeSet;
  MultiHopRSSI.RadioCoordinator -> RadioCoord.RadioSendCoordinator;
}
