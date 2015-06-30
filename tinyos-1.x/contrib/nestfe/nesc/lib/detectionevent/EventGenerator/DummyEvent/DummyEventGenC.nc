//$Id: DummyEventGenC.nc,v 1.2 2005/08/16 00:55:35 phoebusc Exp $

includes DetectionEvent;

configuration DummyEventGenC {
  provides interface StdControl;
}
implementation {
  components DummyEventGenM;
  components DetectionEventC;
  components TimerC;
#ifndef NO_LEDS
  components LedsC;
#else
  components NoLeds as LedsC;
#endif
  components RegistryC;

  StdControl = DummyEventGenM;
  StdControl = DetectionEventC;

  DummyEventGenM.DetectionEvent -> DetectionEventC.DetectionEvent[ITS_A_TANK];
  DummyEventGenM.Timer -> TimerC.Timer[unique("Timer")];
  DummyEventGenM.Leds -> LedsC.Leds;
  DummyEventGenM.DummyDetectionTimer -> RegistryC.DummyDetectionTimer;
  DummyEventGenM.DetectionEventAddr -> RegistryC.DetectionEventAddr;
}

