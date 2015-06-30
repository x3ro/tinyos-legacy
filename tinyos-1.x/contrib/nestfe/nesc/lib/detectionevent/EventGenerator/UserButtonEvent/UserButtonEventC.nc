//$Id: UserButtonEventC.nc,v 1.1 2005/07/22 20:37:46 phoebusc Exp $

includes DetectionEvent;

configuration UserButtonEventC
{
  provides interface StdControl;
}
implementation
{
  components UserButtonEventM;
  components UserButtonC;
  components RegistryC;
  components DetectionEventC;

  StdControl = UserButtonC;
  StdControl = DetectionEventC;

  UserButtonEventM.DetectionEvent -> DetectionEventC.DetectionEvent[BUTTON_PRESS];
  UserButtonEventM.UserButtonEventEnable -> RegistryC.UserButtonEventEnable;
  UserButtonEventM.UserButton -> UserButtonC.UserButton;
}

