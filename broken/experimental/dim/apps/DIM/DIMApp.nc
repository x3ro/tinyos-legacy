includes SchemaType;
includes AM;
includes Attr;
includes Greedy;
includes Zone;
#ifdef USEGTS
includes GTS;
includes Matchbox;
#endif
#ifdef QUICKGTS
includes quickGTS;
#endif
includes DIMApp;
includes ConsoleCmdMsg;
includes DIM;

configuration DIMApp {
}

implementation {
  components Main, DIMAppM, TimerC, LedsC,
             Attr, AttrGlobal, AttrTime, AttrPhoto, AttrTemp,
             AttrAccel, AttrMag, AttrMic, //AttrVoltage,
             GreedyM, GenericComm as Comm,
#ifdef USEGTS
             GTSM, Matchbox, NoDebug,
#endif
#ifdef QUICKGTS
             quickGTSM, TinyAlloc, 
#endif
             ZoneM;

  Main.StdControl -> DIMAppM;

  DIMAppM.DIMControl -> Attr;
  DIMAppM.DIMControl -> AttrGlobal;
  DIMAppM.DIMControl -> AttrTime.StdControl;
  DIMAppM.DIMControl -> AttrPhoto;
  DIMAppM.DIMControl -> AttrTemp;
  DIMAppM.DIMControl -> AttrAccel;
  DIMAppM.DIMControl -> AttrMag;
  DIMAppM.DIMControl -> AttrMic;
  //DIMAppM.DIMControl -> AttrVoltage;

  DIMAppM.DIMControl -> GreedyM.StdControl;
  DIMAppM.Greedy -> GreedyM;
  GreedyM.BeaconTimer -> TimerC.Timer[unique("Timer")];
  GreedyM.RouterCtrl -> Comm;
  GreedyM.RouterSend -> Comm.SendMsg[78];
  GreedyM.RouterRecv -> Comm.ReceiveMsg[78];
  
  DIMAppM.DIMControl -> TimerC.StdControl;
  DIMAppM.Timer -> TimerC.Timer[unique("Timer")];
  
#if 1
  DIMAppM.Leds -> LedsC;
#endif

  DIMAppM.AttrUse -> Attr;

  DIMAppM.Zone -> ZoneM;

#ifdef USEGTS
  DIMAppM.DIMControl -> Matchbox;
  DIMAppM.DIMControl -> GTSM;
  DIMAppM.GTS -> GTSM;

  GTSM.FileDelete -> Matchbox;
  GTSM.FileRead -> Matchbox.FileRead[unique("FileRead")];
  GTSM.FileRename -> Matchbox;
  GTSM.FileWrite -> Matchbox.FileWrite[unique("FileWrite")];

  Matchbox.Debug -> NoDebug;
  Matchbox.ready -> GTSM.FSysReady;
#endif                  
#ifdef QUICKGTS
  DIMAppM.quickGTS -> quickGTSM;
  quickGTSM.MemAlloc -> TinyAlloc;
#endif  
#if 0
  GreedyM.Leds -> LedsC;
#endif
}
