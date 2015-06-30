configuration TestComm {


}

implementation {
  components Main, TimerWrapper, GenericComm, TestCommM, LedsC;
  Main.StdControl -> TestCommM.StdControl;
  Main.StdControl -> GenericComm.Control;

  TestCommM.SendMsg -> GenericComm.SendMsg[3];
  TestCommM.ReceiveMsg -> GenericComm.ReceiveMsg[3];
  TestCommM.Timer -> TimerWrapper.Timer[unique("Timer")];
  TestCommM.Leds -> LedsC;

}
