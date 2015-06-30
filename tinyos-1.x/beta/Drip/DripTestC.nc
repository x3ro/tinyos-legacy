includes DripTest;

configuration DripTestC {
  provides interface StdControl;
}
implementation {
  
  components 
    Main, 
    DripTestM,
    DripC,
    DripStateC,
//    TimeSyncC,
    TimerC,
    NoLeds as Leds;
  
  StdControl = DripTestM;

  DripTestM.Leds -> Leds;
  DripTestM.Timer -> TimerC.Timer[unique("Timer")];

  DripTestM.ReceiveDrip -> DripC.Receive[AM_DRIPTESTMSG];
  DripTestM.Drip -> DripC.Drip[AM_DRIPTESTMSG];
  DripC.DripState[AM_DRIPTESTMSG] -> DripStateC.DripState[unique("DripState")];

//  DripTestM.GlobalTime -> TimeSyncC.GlobalTime;
}
