includes Beacon;

configuration TsyncC {
  provides interface Time;
  provides interface StdControl;
  }

implementation
{
  components TsyncM, AlarmC, ClockC;
  components GenericComm;
  components LedsC;

  StdControl = TsyncM;
  Time = TsyncM;
  TsyncM.CommControl -> GenericComm;
  TsyncM.Alarm -> AlarmC.Alarm[unique("Tsync")];
  TsyncM.AlarmControl -> AlarmC.StdControl;
  TsyncM.readClock -> ClockC;
  TsyncM.BeaconSendMsg -> GenericComm.SendMsg[AM_BEACON];
  TsyncM.BeaconReceiveMsg -> GenericComm.ReceiveMsg[AM_BEACON];
  TsyncM.Leds -> LedsC;
}

