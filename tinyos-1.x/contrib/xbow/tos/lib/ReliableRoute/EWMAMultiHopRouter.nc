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
  }

}

implementation {
  
  // Uncomment for use with mh6
  components MultiHopEngineM, MultiHopEWMA, GenericCommPromiscuous as Comm, 
    QueuedSend, TimerC;

  StdControl = MultiHopEngineM;
  Receive = MultiHopEngineM;
  Send = MultiHopEngineM;
  Intercept = MultiHopEngineM.Intercept;
  Snoop = MultiHopEngineM.Snoop;
  RouteControl = MultiHopEngineM;

  ReceiveMsg = MultiHopEngineM;

  MultiHopEngineM.SubControl -> QueuedSend.StdControl;
  MultiHopEngineM.SubControl -> MultiHopEWMA.StdControl;
  MultiHopEngineM.CommStdControl -> Comm;
  MultiHopEngineM.CommControl -> Comm;
  MultiHopEngineM.RouteSelectCntl -> MultiHopEWMA.RouteControl;
  MultiHopEngineM.RouteSelect -> MultiHopEWMA;


  MultiHopEngineM.SendMsg -> QueuedSend.SendMsg;
  
  MultiHopEWMA.Timer -> TimerC.Timer[unique("Timer")];  
  MultiHopEWMA.ReceiveMsg -> Comm.ReceiveMsg[AM_MULTIHOPMSG];
  MultiHopEWMA.Snoop -> MultiHopEngineM.Snoop;
  MultiHopEWMA.SendMsg -> QueuedSend.SendMsg[AM_MULTIHOPMSG];
  MultiHopEWMA.DebugSendMsg -> MultiHopEngineM.Send[3];
  MultiHopEngineM.ReceiveMsg[3] -> Comm.ReceiveMsg[3];
}
