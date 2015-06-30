includes AcousticBeaconMsg;

configuration DebugRangingSensorC
{
  provides 
  {
      interface StdControl;
      interface AcousticRangingSensor;
  }
}

implementation
{
  components DebugRangingSensorM, LedsC, GenericComm;

  StdControl = DebugRangingSensorM;
  
  AcousticRangingSensor = DebugRangingSensorM;

  DebugRangingSensorM.ReceiveMsg -> GenericComm.ReceiveMsg[AM_ACOUSTICBEACONMSG];
  DebugRangingSensorM.Leds -> LedsC;
}
