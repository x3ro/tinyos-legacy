includes GenericDutyCycle;
includes WakeupComm;

configuration GenericDutyCycleC {
  provides interface StdControl;
}
implementation {
  components GenericDutyCycleM, DripC, DripStateC, GenericComm, TimerC, LedsC;
  
  StdControl = GenericDutyCycleM;
  StdControl = TimerC;

  GenericDutyCycleM.CommControl -> GenericComm;
  GenericDutyCycleM.Timer -> TimerC.Timer[unique("Timer")];  
  GenericDutyCycleM.Leds -> LedsC;

  GenericDutyCycleM.Receive -> DripC.Receive[AM_GENERICDUTYCYCLEMSG];

  GenericDutyCycleM.Drip -> DripC.Drip[AM_GENERICDUTYCYCLEMSG];
  DripC.DripState[AM_GENERICDUTYCYCLEMSG] -> DripStateC.DripState[unique("DripState")];
}

