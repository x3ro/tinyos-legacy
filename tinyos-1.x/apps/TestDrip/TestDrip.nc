includes TestDrip;

configuration TestDrip {

}
implementation {
  
  components 
    Main, 
    TestDripM,
    DripC,
    DripStateC,
    TimerC,
    LedsC as Leds;
  
  Main.StdControl -> TestDripM;
  Main.StdControl -> DripC;
  Main.StdControl -> TimerC;

  TestDripM.Leds -> Leds;
  TestDripM.Timer -> TimerC.Timer[unique("Timer")];

  TestDripM.ReceiveDrip -> DripC.Receive[AM_TESTDRIPMSG];
  TestDripM.Drip -> DripC.Drip[AM_TESTDRIPMSG];
  DripC.DripState[AM_TESTDRIPMSG] -> DripStateC.DripState[unique("DripState")];
}
