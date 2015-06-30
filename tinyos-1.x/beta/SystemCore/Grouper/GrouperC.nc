includes Grouper;

configuration GrouperC {
  provides interface StdControl;
}

implementation {

  components GrouperM, DripC, AMNamingM, MultiHopRSSI;

  StdControl = GrouperM;

  GrouperM.Receive -> DripC.Receive[AM_GROUPERCMDMSG];
  GrouperM.Drip -> DripC.Drip[AM_GROUPERCMDMSG];
  GrouperM.Naming -> AMNamingM;

  GrouperM.getTreeID -> MultiHopRSSI.getTreeID;
}
