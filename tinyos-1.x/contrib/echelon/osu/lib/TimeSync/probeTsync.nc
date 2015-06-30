includes OTime;
includes Beacon;

configuration probeTsync {}

implementation
{
  components Main, probeTsyncM, AlarmC, LedsC, GenericComm;
  Main.StdControl -> probeTsyncM.StdControl;
  probeTsyncM.CommControl -> GenericComm;
  probeTsyncM.Alarm -> AlarmC.Alarm[unique("Alarm")];
  probeTsyncM.AlarmControl -> AlarmC.StdControl;
  probeTsyncM.SendMsg -> GenericComm.SendMsg[AM_BEACON_PROBE];
  probeTsyncM.Leds -> LedsC;
}


