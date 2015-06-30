includes MultiHop;

configuration GridRouter {
  
  provides {
    interface StdControl;
    // The interface are as parameterised by the active message id
	// only the 10 active message ids defined MultiHop.h are supported.
    interface Receive[uint8_t id];
    interface Intercept[uint8_t id];
    interface Intercept as Snoop[uint8_t id];
    interface Send[uint8_t id];
    interface RouteControl;
    interface RouteQuery;
    command result_t fillInAddr(uint16_t addr, TOS_MsgPtr msg);
  }

  uses {
    interface ReceiveMsg[uint8_t id];
  }

}

implementation {
  
  // Uncomment for use with mh6
  components MultiHopEngineGridM, MultiHopGrid, GenericCommPromiscuous as Comm, 
    QueuedSend, TimerC, RandomLFSR, NoLeds as LedsC;

  StdControl = MultiHopEngineGridM;
  Receive = MultiHopEngineGridM;
  Send = MultiHopEngineGridM;
  Intercept = MultiHopEngineGridM.Intercept;
  Snoop = MultiHopEngineGridM.Snoop;
  RouteControl = MultiHopEngineGridM;
  RouteQuery = MultiHopEngineGridM;
  ReceiveMsg = MultiHopEngineGridM;

  Receive = MultiHopEngineGridM;
  
  MultiHopEngineGridM.SubControl -> QueuedSend.StdControl;
  MultiHopEngineGridM.SubControl -> MultiHopGrid.StdControl;
  MultiHopEngineGridM.CommStdControl -> Comm;
  MultiHopEngineGridM.CommControl -> Comm;
  MultiHopEngineGridM.RouteSelectCntl -> MultiHopGrid.RouteControl;
  MultiHopEngineGridM.RouteSelectQuery -> MultiHopGrid.RouteQuery;
  MultiHopEngineGridM.RouteSelect -> MultiHopGrid;

  fillInAddr = MultiHopGrid.fillInAddr;

  MultiHopEngineGridM.SendMsg -> QueuedSend.SendMsg;
  
  MultiHopGrid.Timer -> TimerC.Timer[unique("Timer")];  
  MultiHopGrid.ATimer -> TimerC.Timer[unique("Timer")];  
  MultiHopGrid.ReceiveMsg -> Comm.ReceiveMsg[AM_MULTIHOPMSG];
  MultiHopGrid.Snoop -> MultiHopEngineGridM.Snoop;
  MultiHopGrid.SendMsg -> QueuedSend.SendMsg[AM_MULTIHOPMSG];
  MultiHopGrid.DebugSendMsg -> MultiHopEngineGridM.Send[3];
  MultiHopGrid.Random -> RandomLFSR;
  MultiHopEngineGridM.ReceiveMsg[3] -> Comm.ReceiveMsg[3];
  MultiHopGrid.Leds -> LedsC;
}
