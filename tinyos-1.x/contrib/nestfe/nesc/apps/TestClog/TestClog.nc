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
    DripSendC,
    ClogC,
    TimerC,
    LedsC as Leds;
  
  Main.StdControl -> TestClogM;
  Main.StdControl -> TimerC;
  Main.StdControl -> DrainC;
  Main.StdControl -> DripSendC;

  TestClogM.Leds -> Leds;
  TestClogM.Timer -> TimerC.Timer[unique("Timer")];
  TestClogM.Random -> RandomLFSR;

  TestClogM.ClogControl -> ClogC;

  TestClogM.Drain -> DrainC;
  TestClogM.DrainGroup -> DrainC;

  TestClogM.Send -> DrainC.Send[AM_CLOG];
  TestClogM.SendMsg -> DrainC.SendMsg[AM_CLOG];
  TestClogM.DrainReceive -> DrainC.Receive[AM_CLOG];

  TestClogM.Receive -> DripSendC.Receive;
}
