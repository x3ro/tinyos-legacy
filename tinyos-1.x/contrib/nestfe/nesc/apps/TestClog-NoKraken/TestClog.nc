includes Drain;
includes Drip;
includes DripSend;
includes Clog;
includes TestClog;

configuration TestClog {

}
implementation {
  
  components 
    Main, 
    TestClogM,
    RandomLFSR,
    DrainC,
//    ClogC,
    TimerC,
    LedsC as Leds;

  components new DripSendC(AM_DRIPSEND);

#ifndef PLATFORM_PC
  components DelugeC;
  components DelugeStatsC;
#endif

  components MgmtQueryC, EventLoggerC, RemoteSetC;
  components BoringAttrC, IdentC, LedSetC;

#ifdef _CC2420CONST_H
  components CC2420RemoteControlC;
#endif

#ifndef PLATFORM_PC
  Main.StdControl -> DelugeC;
#endif
  Main.StdControl -> MgmtQueryC;
  Main.StdControl -> EventLoggerC;
  Main.StdControl -> RemoteSetC;
  Main.StdControl -> IdentC;

  Main.StdControl -> TestClogM;
  Main.StdControl -> TimerC;
  Main.StdControl -> DrainC;
  Main.StdControl -> DripSendC;

  TestClogM.Leds -> Leds;
  TestClogM.Timer -> TimerC.Timer[unique("Timer")];
  TestClogM.Random -> RandomLFSR;

//  TestClogM.ClogControl -> ClogC;

  TestClogM.Drain -> DrainC;
  TestClogM.DrainGroup -> DrainC;

  TestClogM.Send -> DrainC.Send[AM_CLOG];
  TestClogM.SendMsg -> DrainC.SendMsg[AM_CLOG];

  TestClogM.Receive -> DripSendC.Receive;
}

