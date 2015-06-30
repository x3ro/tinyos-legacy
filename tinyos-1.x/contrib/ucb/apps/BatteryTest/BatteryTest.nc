includes BatteryTest;

configuration BatteryTest {
} 
implementation {
  
  components Main, BatteryTestM, GenericComm, TimerC, LedsC;

#ifdef PLATFORM_TELOS
  components InternalVoltageC as VoltageC;
#endif

  Main.StdControl -> BatteryTestM;
  Main.StdControl -> VoltageC;
  Main.StdControl -> GenericComm;
  Main.StdControl -> TimerC;  
  
  BatteryTestM.VoltageADC -> VoltageC;
  BatteryTestM.SendMsg -> GenericComm.SendMsg[AM_BATTERYTESTMSG];
  BatteryTestM.Leds -> LedsC;
  BatteryTestM.Timer -> TimerC.Timer[unique("Timer")];
}
