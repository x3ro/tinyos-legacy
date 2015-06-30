includes DrainTest;

configuration DrainTestC {
  provides interface StdControl;
}
implementation {
  
  components 
    Main, 
    DrainTestM,
    DrainC,
//    TimeSyncC,
    TimerC,
    RandomLFSR,
    NoLeds as Leds;

  StdControl = DrainTestM;

  DrainTestM.Leds -> Leds;
  DrainTestM.Send -> DrainC.Send[AM_DRAINTESTMSG];
  DrainTestM.SendMsg -> DrainC.SendMsg[AM_DRAINTESTMSG];
  DrainTestM.Timer -> TimerC.Timer[unique("Timer")];
  DrainTestM.Random -> RandomLFSR;
  
//  DrainTestM.GlobalTime -> TimeSyncC.GlobalTime;
}
