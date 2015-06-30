configuration ClogC {
  provides interface StdControl;
}
implementation {
  components ClogM;
  components DrainC;
  components DripSendC;
  components RandomLFSR;
  components TimerC;
  components LedsC;

  StdControl = ClogM;

  ClogM.Drain -> DrainC;
  ClogM.DrainReceive -> DrainC.Receive[AM_CLOG];

  ClogM.DripSend -> DripSendC.Send;
  ClogM.DripSendMsg -> DripSendC.SendMsg;

  ClogM.Timer -> TimerC.Timer[unique("Timer")];
  ClogM.Random -> RandomLFSR;
  ClogM.Leds -> LedsC;
}
