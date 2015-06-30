includes WakeupHeader;

configuration WakeupC {
  provides interface StdControl;
}
implementation {
  components WakeupM;
  components TimerC;
  components DripC;
  components DripStateC;
  components LedsC as Leds;
  components UserButtonC;
  components VoltageCheckM;

  StdControl = UserButtonC;
  StdControl = WakeupM;

  WakeupM.Leds -> Leds;

  WakeupM.Timer -> TimerC.Timer[unique("Timer")];

  WakeupM.Receive -> DripC.Receive[AM_WAKEUPMSG];
  WakeupM.Drip -> DripC.Drip[AM_WAKEUPMSG];
  DripC.DripState[AM_WAKEUPMSG] -> DripStateC.DripState[unique("DripState")];

  WakeupM.UserButton -> UserButtonC.UserButton;

  WakeupM.PowerSource -> VoltageCheckM;
}
