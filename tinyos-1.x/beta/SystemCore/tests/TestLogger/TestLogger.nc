configuration TestLogger {

}

implementation {
  components Main, 
    TestLoggerM,
    SNMS,
    EventLoggerC,
    MgmtAttrsC,
    TimerC, 
    LedsC, 
    RandomLFSR;

  Main.StdControl -> SNMS;
  Main.StdControl -> TestLoggerM;

  TestLoggerM.Timer -> TimerC.Timer[unique("Timer")];
  TestLoggerM.Leds -> LedsC;

  TestLoggerM.Random -> RandomLFSR;

  TestLoggerM.EventLogger -> EventLoggerC.EventLogger;

  TestLoggerM.MA_Seqno -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  TestLoggerM.MA_SeqnoSlow -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
}
