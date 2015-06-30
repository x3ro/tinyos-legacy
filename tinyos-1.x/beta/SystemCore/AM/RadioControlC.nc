includes RadioControl;

configuration RadioControlC {
  provides interface StdControl;
}

implementation {

  components RadioControlM, 
    DripC, 
    MgmtQueryC,
    AMNamingM, 
    DelugeC, 
    GenericComm;

  StdControl = RadioControlM;

  RadioControlM.CommControl -> GenericComm;

  RadioControlM.ComponentControl -> DripC;
  RadioControlM.ComponentControl -> MgmtQueryC;
  RadioControlM.ComponentControl -> DelugeC;

  RadioControlM.softStart -> GenericComm.softStart;
  RadioControlM.softStop -> GenericComm.softStop;

  RadioControlM.Receive -> DripC.Receive[AM_RADIOCONTROLCMDMSG];
  RadioControlM.Drip -> DripC.Drip[AM_RADIOCONTROLCMDMSG];
  RadioControlM.Naming -> AMNamingM;
}
