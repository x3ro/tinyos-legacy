configuration TOSBase {
}
implementation {
  components Main, TOSBaseM, RadioCRCPacket as Comm, FramerM, UART, LedsC, TimerC, 
  CC1000RadioIntM, 
#ifdef TIMESYNC_SYSTIME					// for the GLOBAL_TIMING-BRANO
		SysTimeStampingC as TimeStampingC;	// for the GLOBAL_TIMING-BRANO
#else							// for the GLOBAL_TIMING-BRANO
		ClockTimeStampingC as TimeStampingC;	// for the GLOBAL_TIMING-BRANO
#endif
  
  Main.StdControl -> TOSBaseM;
  Main.StdControl -> TimerC;

  TOSBaseM.RadioSendCoordinator	 -> CC1000RadioIntM.RadioSendCoordinator; 
  TOSBaseM.TimeStamping -> TimeStampingC;
  TOSBaseM.Timer        -> TimerC.Timer[unique("Timer")];
  TOSBaseM.UARTControl -> FramerM;
  TOSBaseM.UARTSend -> FramerM;
  TOSBaseM.UARTReceive -> FramerM;
  TOSBaseM.UARTTokenReceive -> FramerM;
  TOSBaseM.RadioControl -> Comm;
  TOSBaseM.RadioSend -> Comm;
  TOSBaseM.RadioReceive -> Comm;

  TOSBaseM.Leds -> LedsC;

  FramerM.ByteControl -> UART;
  FramerM.ByteComm -> UART;
}
