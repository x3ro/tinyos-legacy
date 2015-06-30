configuration LocationNode {
}
implementation {
  components Main, LocationNodeM, GenericComm as Comm, LedsC, TimerC, RandomLFSR, CC1000ControlM, Bap, Bcast, BaseStationStatus, XnpC;

  Main.StdControl -> LocationNodeM;

  Main.StdControl -> Comm;
  Main.StdControl -> Bcast;
  Main.StdControl -> Bap;
  Main.StdControl -> BaseStationStatus;

  Bap.IsBaseStation -> BaseStationStatus;

  LocationNodeM.Xnp -> XnpC;

  LocationNodeM.IsBaseStation -> BaseStationStatus;
  LocationNodeM.RadioControl -> Comm;

  LocationNodeM.SendGradient -> Comm.SendMsg[2];
  LocationNodeM.ReceiveGradient -> Comm.ReceiveMsg[2];

  LocationNodeM.CommandToBase -> Bap.SendData;
  LocationNodeM.CommandFromBase -> Bcast.Receive[3];

  LocationNodeM.SendPot -> Comm.SendMsg[14];
  LocationNodeM.ReceivePot -> Comm.ReceiveMsg[14];

  LocationNodeM.BaseToHost -> Comm.SendMsg[5];
  LocationNodeM.HostToBase -> Comm.ReceiveMsg[5];

  LocationNodeM.BaseReceiveCommand -> Bap.Receive;
  LocationNodeM.BaseSendCommand -> Bcast.SendData[3]; // same as above

  Bcast.ReceiveMsg[3] -> Comm.ReceiveMsg[3];

  LocationNodeM.ReceiveTag -> Comm.ReceiveMsg[13];

  LocationNodeM.Leds -> LedsC;
  LocationNodeM.Timer -> TimerC.Timer[unique("Timer")];
  LocationNodeM.Random -> RandomLFSR;
  LocationNodeM.CC1000Control -> CC1000ControlM;
}
