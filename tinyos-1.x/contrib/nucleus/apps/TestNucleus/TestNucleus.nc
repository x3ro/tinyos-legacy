configuration TestNucleus {

}

implementation {
  
  components 
    Main, 
    DelugeC,
    TestNucleusM,
    TimerC,
    LedsC;

  components MgmtQueryC, EventLoggerC, RemoteSetC;
  components BoringAttrC, IdentC, LedSetC, CC2420RemoteControlC;
  //  components GrouperC;
  components DelugeStatsC;

  Main.StdControl -> DelugeC;
  Main.StdControl -> MgmtQueryC;
  Main.StdControl -> EventLoggerC;
  Main.StdControl -> RemoteSetC;

  Main.StdControl -> TestNucleusM;
  Main.StdControl -> IdentC;
  //  Main.StdControl -> GrouperC;

  TestNucleusM.Leds -> LedsC;
  TestNucleusM.Timer -> TimerC.Timer[unique("Timer")];
}
