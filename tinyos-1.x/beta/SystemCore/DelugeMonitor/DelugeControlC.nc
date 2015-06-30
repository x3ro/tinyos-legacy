includes DelugeControl;

configuration DelugeControlC {
  provides interface StdControl;
  
}
implementation {
  components DelugeControlM, 
    DripC, 
    NetProgC, 
    InternalFlashC, 
    AMNamingM, 
    TimerC, 
    RandomLFSR;

  StdControl = TimerC;
  StdControl = DelugeControlM;

  DelugeControlM.NetProg -> NetProgC.NetProg;
  
  DelugeControlM.IFlash -> InternalFlashC;

  DelugeControlM.Timer -> TimerC.Timer[unique("Timer")];
  DelugeControlM.Random -> RandomLFSR;

  DelugeControlM.Receive -> DripC.Receive[AM_NETPROGCMDMSG];
  DelugeControlM.Drip -> DripC.Drip[AM_NETPROGCMDMSG];
  DelugeControlM.Naming -> AMNamingM;
}
