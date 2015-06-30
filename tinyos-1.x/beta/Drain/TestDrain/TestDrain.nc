includes TestDrain;

configuration TestDrain {

}
implementation {
  
  components 
    Main, 
    TestDrainM,
    DrainC,
    TimerC,
    RandomLFSR,
    LedsC as Leds;

  Main.StdControl -> DrainC;
  Main.StdControl -> TestDrainM;

  TestDrainM.Leds -> Leds;

  TestDrainM.Drain -> DrainC.Drain;
  TestDrainM.Send -> DrainC.Send[AM_TESTDRAINMSG];
  TestDrainM.SendMsg -> DrainC.SendMsg[AM_TESTDRAINMSG];
  TestDrainM.Timer -> TimerC.Timer[unique("Timer")];
  TestDrainM.Random -> RandomLFSR;
}
