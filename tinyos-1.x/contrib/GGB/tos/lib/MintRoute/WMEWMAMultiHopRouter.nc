includes MultiHop;

configuration WMEWMAMultiHopRouter {
  
  provides {
    interface StdControl;
    // The interface are as parameterised by the active message id
	// only the 10 active message ids defined MultiHop.h are supported.
    interface Receive[uint8_t id];
    interface Intercept[uint8_t id];
    interface Intercept as Snoop[uint8_t id];
    interface Send[uint8_t id];
    interface RouteControl;
  }

  uses {
    interface ReceiveMsg[uint8_t id];
  }

}

implementation {
  
  // Uncomment for use with mh6
  components MultiHopEngineM, MultiHopWMEWMA, GenericCommPromiscuous as Comm, 
    QueuedSend, TimerC, 
#ifdef USE_WATCHDOG
	WDTC,
#endif
	NoLeds;

  StdControl = MultiHopEngineM;
  Receive = MultiHopEngineM;
  Send = MultiHopEngineM;
  Intercept = MultiHopEngineM.Intercept;
  Snoop = MultiHopEngineM.Snoop;
  RouteControl = MultiHopEngineM;

  ReceiveMsg = MultiHopEngineM;

  MultiHopEngineM.SubControl -> QueuedSend.StdControl;
  MultiHopEngineM.SubControl -> MultiHopWMEWMA.StdControl;
  MultiHopEngineM.CommStdControl -> Comm;
  MultiHopEngineM.CommControl -> Comm;
  MultiHopEngineM.RouteSelectCntl -> MultiHopWMEWMA.RouteControl;
  MultiHopEngineM.RouteSelect -> MultiHopWMEWMA;


  MultiHopEngineM.SendMsg -> QueuedSend.SendMsg;
  
  MultiHopWMEWMA.Timer -> TimerC.Timer[unique("Timer")];  
  MultiHopWMEWMA.ATimer -> TimerC.Timer[unique("Timer")];  
  MultiHopWMEWMA.ReceiveMsg -> Comm.ReceiveMsg[AM_MULTIHOPMSG];
  MultiHopWMEWMA.Snoop -> MultiHopEngineM.Snoop;
  MultiHopWMEWMA.SendMsg -> QueuedSend.SendMsg[AM_MULTIHOPMSG];
  MultiHopWMEWMA.DebugSendMsg -> MultiHopEngineM.Send[3];
  MultiHopEngineM.ReceiveMsg[3] -> Comm.ReceiveMsg[3];
  MultiHopWMEWMA.Leds -> NoLeds;
#ifdef USE_WATCHDOG
  MultiHopWMEWMA.PoochHandler -> WDTC.StdControl;
  MultiHopWMEWMA.WDT -> WDTC.WDT;
#endif
}
