configuration NodeCommTest {


}
implementation {
  components Main, LedsC, GenericComm, TimerWrapper, NodeCommTestM;
  Main.StdControl -> NodeCommTestM.StdControl;
  NodeCommTestM.Leds -> LedsC;
  Main.StdControl -> GenericComm.Control;
  NodeCommTestM.Timer -> TimerWrapper.Timer[unique("Timer")];
  NodeCommTestM.SendMsg -> GenericComm.SendMsg[1];
  GenericComm.ReceiveMsg[1] <- NodeCommTestM.ReceiveMsg;


}
