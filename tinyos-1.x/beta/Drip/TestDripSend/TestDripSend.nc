includes TestDripSend;

configuration TestDripSend {

}
implementation {
  
  components 
    Main, 
    TestDripSendM,
    DripSendC,
    GroupManagerC,
    TimerC,
    LedsC as Leds;
  
  Main.StdControl -> TestDripSendM;
  Main.StdControl -> DripSendC;
  Main.StdControl -> TimerC;
  Main.StdControl -> GroupManagerC;

  TestDripSendM.Leds -> Leds;
  TestDripSendM.Timer -> TimerC.Timer[unique("Timer")];

  TestDripSendM.Send -> DripSendC;
  TestDripSendM.SendMsg -> DripSendC;
  TestDripSendM.Receive -> DripSendC;
  TestDripSendM.GroupManager -> GroupManagerC;
}
