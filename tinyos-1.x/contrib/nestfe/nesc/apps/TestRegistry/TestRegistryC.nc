includes DetectionEvent;

configuration TestRegistryC
{
}
implementation
{ 
  components Main; 
  components KrakenC;
  components TestRegistryM;

  components RegistryC;
  components TimerC;
  components DemoSensorC as Photo;
  components LedsC;
  components TimeSyncC;

  Main.StdControl -> KrakenC;
  Main.StdControl -> TestRegistryM;

  Main.StdControl -> TimerC;
  Main.StdControl -> Photo;

  TestRegistryM.Light -> RegistryC.Light;
  TestRegistryM.Location -> RegistryC.Location;
  TestRegistryM.SetMe -> RegistryC.SetMe;
  TestRegistryM.SetMeLocalTime -> RegistryC.SetMeLocalTime;
  TestRegistryM.SetMeGlobalTime -> RegistryC.SetMeGlobalTime;

  TestRegistryM.Timer -> TimerC.Timer[unique("Timer")];
  TestRegistryM.Photo -> Photo;
  TestRegistryM.PhotoControl -> Photo;
  TestRegistryM.Leds -> LedsC;

  TestRegistryM.GlobalTime -> TimeSyncC;
}

