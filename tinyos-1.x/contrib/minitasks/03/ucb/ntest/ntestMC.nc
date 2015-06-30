includes Neighborhood;

configuration ntestMC {
  provides interface NeighborhoodManager;
  provides interface StdControl;
}
implementation {
  components Main, ntestM, MagHoodC, MagReadingAttrC, MagDataReflC, GenericComm,MsgBuffersC;

  NeighborhoodManager = ntestM.NeighborhoodManager;
  StdControl = ntestM.StdControl;
  
  Main.StdControl -> ntestM;
  Main.StdControl -> MagHoodC;
  Main.StdControl -> MagDataReflC;
  Main.StdControl -> MagReadingAttrC;
  Main.StdControl -> GenericComm;

  ntestM.Neighborhood -> MagHoodC;
  ntestM.MagHood_private -> MagHoodC;

  ntestM.MagReadingAttr -> MagReadingAttrC;
  ntestM.MagReadingAttrReflection -> MagDataReflC.MagReadingAttrReflection;
  ntestM.MagReadingAttrReflectionSnoop ->
    MagDataReflC.MagReadingAttrReflectionSnoop;
  

}
