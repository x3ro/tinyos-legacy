includes DripDrainPing;

configuration DripDrainPingC {
  provides interface StdControl;
}
implementation {
  components DrainC;
  components DripC;
  components DripStateC;
  components DripDrainPingM;
  components LedsC;

  StdControl = DrainC;
  StdControl = DripC;
  StdControl = DripDrainPingM;
  
  DripDrainPingM.Send -> DrainC.Send[AM_DRIPDRAINPINGMSG];
  DripDrainPingM.SendMsg -> DrainC.SendMsg[AM_DRIPDRAINPINGMSG];
  
  DripDrainPingM.Receive -> DripC.Receive[AM_DRIPDRAINPINGMSG];
  DripDrainPingM.Drip -> DripC.Drip[AM_DRIPDRAINPINGMSG];
  DripC.DripState[AM_DRIPDRAINPINGMSG] -> DripStateC.DripState[unique("DripState")];  

  DripDrainPingM.Leds -> LedsC;
}
