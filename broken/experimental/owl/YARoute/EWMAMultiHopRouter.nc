includes MultiHop;

configuration EWMAMultiHopRouter {
  
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
    interface SendMsg[uint8_t id];
  }

}

implementation {
  
  // Uncomment for use with mh6
  components MultiHopEngineM, MultiHopEWMA, GenericCommPromiscuous as Comm, 
    QueuedSend, 
#ifdef PLATFORM_MICA2
    CC1000RadioC as Radio,
#endif
#if defined(PLATFORM_MICAZ) || defined(PLATFORM_TELOS)
    CC2420RadioC as Radio,
#endif
#ifdef USE_WATCHDOG
	WDTC,
#endif
	TimerC;

  StdControl = MultiHopEngineM;
  Receive = MultiHopEngineM;
  Send = MultiHopEngineM;
  Intercept = MultiHopEngineM.Intercept;
  Snoop = MultiHopEngineM.Snoop;
  RouteControl = MultiHopEngineM;

  ReceiveMsg = MultiHopEngineM;
  SendMsg = MultiHopEngineM;

  MultiHopEngineM.SubControl -> QueuedSend.StdControl;
  MultiHopEngineM.SubControl -> MultiHopEWMA.StdControl;
  MultiHopEngineM.CommStdControl -> Comm;
  MultiHopEngineM.CommControl -> Comm;
  MultiHopEngineM.RouteSelectCntl -> MultiHopEWMA.RouteControl;
  MultiHopEngineM.RouteSelect -> MultiHopEWMA;
  MultiHopEngineM.MacControl -> Radio;

  MultiHopEWMA.Timer -> TimerC.Timer[unique("Timer")];  
  MultiHopEWMA.ReceiveMsg -> Comm.ReceiveMsg[AM_MULTIHOPMSG];
  MultiHopEWMA.UpdateNeighbor -> MultiHopEngineM.UpdateNeighbor;
  MultiHopEWMA.SendMsg -> QueuedSend.SendMsg[AM_MULTIHOPMSG];
  MultiHopEWMA.DebugSendMsg -> MultiHopEngineM.Send[3];
  MultiHopEngineM.ReceiveMsg[3] -> Comm.ReceiveMsg[3];
  MultiHopEngineM.SendMsg[3] -> QueuedSend.SendMsg[3];
#ifdef USE_WATCHDOG
  MultiHopEWMA.PoochHandler -> WDTC.StdControl;
  MultiHopEWMA.WDT -> WDTC.WDT;
#endif
}
