includes RollCall;

configuration RollCallC {
  uses {
    interface RouteControl;

    interface HeartBeatHandler;
  }
  provides {
    interface StdControl;
  }
}
implementation {

#define AGGR_SEND

  components 
    PowerArbiterC,
    EpochSchedulerC, 
    TimerC, GenericCommPromiscuous as Comm,
    RollCallM, 
    UsefulTimeC, 
    RandomLFSR,

#ifdef AGGR_SEND
    AggressiveSendM, 
#elif defined(QD_SEND)
    QueuedSend,
#endif

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
    CC1000RadioC,
#endif

    ExptM,
    LedsC, NoLeds;

  StdControl = Comm;
  StdControl = EpochSchedulerC;
  StdControl = TimerC;
  StdControl = RollCallM;

  StdControl = ExptM;

#ifdef AGGR_SEND
  StdControl = AggressiveSendM;

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
  AggressiveSendM.MacControl -> CC1000RadioC.MacControl;
#endif

#elif defined(QD_SEND)
  StdControl = QueuedSend;
#endif

  HeartBeatHandler = RollCallM.HeartBeatHandler;

  RollCallM.Time -> UsefulTimeC;
  RollCallM.TimeSetListener -> UsefulTimeC;

  RollCallM.RouteControl = RouteControl;

  RollCallM.ReceiveReport -> Comm.ReceiveMsg[ROLLCALL_AM];


#ifdef QD_SEND
  RollCallM.SendReport -> QueuedSend.SendMsg[ROLLCALL_AM];
  RollCallM.SendStats -> QueuedSend.SendMsg[ROLLCALL_STATS_REP_AM];  
#elif defined(AGGR_SEND)
  RollCallM.AggSendCtl -> AggressiveSendM.AggressiveSendControl;
  RollCallM.SendReport -> AggressiveSendM.SendMsg[ROLLCALL_AM];
  RollCallM.SendStats -> AggressiveSendM.SendMsg[ROLLCALL_STATS_REP_AM];
  AggressiveSendM.SendExt -> Comm.SendMsg;
  
  AggressiveSendM.Leds -> NoLeds;    
#else
  RollCallM.SendReport -> Comm.SendMsg[ROLLCALL_AM];
  RollCallM.SendStats -> Comm.SendMsg[ROLLCALL_STATS_REP_AM];
#endif

  RollCallM.EpochScheduler -> 
    EpochSchedulerC.EpochScheduler[unique("EpochScheduler")];
 
  
  RollCallM.PowerArbiter ->
    PowerArbiterC.PowerArbiter[unique("PowerArbiter")];
    
  RollCallM.Random -> RandomLFSR;

  RollCallM.Timer -> TimerC.Timer[unique("Timer")];

  RollCallM.Leds -> LedsC;

  RollCallM.Roster -> ExptM.Roster;

  ExptM.Leds -> LedsC;
  ExptM.Timer -> TimerC.Timer[unique("Timer")];

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
  ExptM.CC1KControl -> CC1000RadioC;
#endif
}
