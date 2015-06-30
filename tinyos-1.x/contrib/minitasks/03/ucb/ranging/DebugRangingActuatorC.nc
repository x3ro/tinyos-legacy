includes AcousticBeaconMsg;

configuration DebugRangingActuatorC
{
  provides 
  {
      interface StdControl;
      interface AcousticRangingActuator;
  }
}

implementation
{
  components DebugRangingActuatorM, GenericComm;

  StdControl = DebugRangingActuatorM;

  AcousticRangingActuator = DebugRangingActuatorM;
  DebugRangingActuatorM.SendMsg -> GenericComm.SendMsg[AM_ACOUSTICBEACONMSG];
}
