//$Id: DetectionEventC.nc,v 1.3 2005/07/22 20:37:46 phoebusc Exp $

includes DetectionEvent;

configuration DetectionEventC {
  provides interface StdControl;
  provides interface DetectionEvent[uint8_t type];
}
implementation {
  components DetectionEventM;
  components TimeSyncC;
  components DrainC;
  components RegistryC;

  StdControl = DetectionEventM;
  DetectionEvent = DetectionEventM;
  
  DetectionEventM.Location -> RegistryC.Location;
  DetectionEventM.DetectionEventAddr -> RegistryC.DetectionEventAddr;

  StdControl = TimeSyncC;
  DetectionEventM.GlobalTime -> TimeSyncC;

  DetectionEventM.SendMsg -> DrainC.SendMsg[AM_DETECTIONEVENTMSG];
  DetectionEventM.Send -> DrainC.Send[AM_DETECTIONEVENTMSG]; 
}

