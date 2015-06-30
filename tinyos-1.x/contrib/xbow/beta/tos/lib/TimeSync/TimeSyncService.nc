
configuration TimeSyncService {
  
  provides {
    interface StdControl;
    // The interface are as parameterised by the active message id
	// only the 10 active message ids defined MultiHop.h are supported.
    interface Time;
  }

}

implementation {
  
  components GenericComm as Comm, TimerC, TimeSyncM, TimeUtilC, CC1000RadioC, QueuedSend;

  StdControl = TimeSyncM;
  Time = TimeSyncM;

  TimeSyncM.TimerControl -> TimerC;
  TimeSyncM.CommControl -> Comm;
  TimeSyncM.UpdateTimer -> TimerC.Timer[unique("Timer")];  
  TimeSyncM.Timer -> TimerC.Timer[unique("Timer")];  
  TimeSyncM.ReceiveMsg -> Comm.ReceiveMsg[239];
  TimeSyncM.SendMsg -> QueuedSend.SendMsg[239];
  //TimeSyncM.SendMsg -> Comm.SendMsg[239];
  TimeSyncM.TimeUtil -> TimeUtilC;
  TimeSyncM.RadioCoordinator -> CC1000RadioC.RadioSendCoordinator;
}
