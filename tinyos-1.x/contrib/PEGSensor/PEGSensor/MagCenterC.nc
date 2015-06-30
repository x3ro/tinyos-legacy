
configuration MagCenterC
{
  provides interface StdControl;
  provides interface NeighborhoodManager;
}
implementation
{
  components MagCenterM
           , MagHoodC
	   , MagDataReflC
	   , MagDataAttrC
	   , MagDataAttrM
	   , MagCenterReportC
	   , PursuerCoordC
	   , TickSensorC
	   , MagStatusCmdC
	   , DataStore
	   ;

  StdControl = MagCenterM;

  MagCenterM.Init[0] -> MagDataReflC;
  MagCenterM.Init[1] -> MagDataAttrC;
  MagCenterM.Init[2] -> TickSensorC;
  MagCenterM.Init[3] -> PursuerCoordC;

  NeighborhoodManager = MagCenterM;

  MagCenterM.Neighborhood -> MagHoodC;
  MagCenterM.MagHood_private -> MagHoodC;
  MagCenterM.MagDataAttr -> MagDataAttrC;
  MagCenterM.MagPositionValid -> MagDataAttrM.PositionValid;
  MagCenterM.MagDataValid -> MagDataAttrM.DataValid;
  MagCenterM.MagDataAttrReflection -> MagDataReflC;
  MagCenterM.MagDataAttrReflectionSnoop -> MagDataReflC;
  MagCenterM.MagCenterReport -> MagCenterReportC;
  MagCenterM.MagCenterReport -> PursuerCoordC;
  MagCenterM.TickSensor -> TickSensorC;
  MagCenterM.MagStatusCmd -> MagStatusCmdC;
  MagCenterM.EvaderDemoStore -> DataStore;
}

