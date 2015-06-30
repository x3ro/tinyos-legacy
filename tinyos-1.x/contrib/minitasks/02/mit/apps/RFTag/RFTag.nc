configuration RFTag {
}
implementation {
  components Main, RFTagM, GenericComm as Comm, LedsC, TimerC, CC1000ControlM;

  Main.StdControl -> RFTagM;
  Main.StdControl -> Comm;

  RFTagM.RadioControl -> Comm;

  RFTagM.Send -> Comm.SendMsg[13];

  RFTagM.Leds -> LedsC;
  RFTagM.Timer -> TimerC.Timer[2]; // should be unique id
  RFTagM.CC1000Control -> CC1000ControlM;
}
