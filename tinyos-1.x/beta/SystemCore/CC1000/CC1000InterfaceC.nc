includes CC1000Interface;

configuration CC1000InterfaceC {
  provides interface StdControl;
}
implementation {

  components 
  CC1000InterfaceM,
    CC1000RadioIntM,
    CC1000RadioC,
    MgmtAttrsC,
    AMNamingM,
    TimerC,
//    EventLoggerC,
    DripC;

  StdControl = CC1000InterfaceM;
  StdControl = DripC;
  
//  CC1000InterfaceM.EventLogger -> EventLoggerC.EventLogger;

  CC1000InterfaceM.Receive -> DripC.Receive[AM_CC1000INTERFACEDRIPMSG];
  CC1000InterfaceM.Drip -> DripC.Drip[AM_CC1000INTERFACEDRIPMSG];
  CC1000InterfaceM.Naming -> AMNamingM; 
  
  CC1000InterfaceM.CC1000Control -> CC1000RadioC.CC1000Control;
  CC1000InterfaceM.SetListeningMode -> CC1000RadioIntM.SetListeningMode;
  CC1000InterfaceM.GetListeningMode -> CC1000RadioIntM.GetListeningMode;
  CC1000InterfaceM.ChangeTimer -> TimerC.Timer[unique("Timer")];

  CC1000InterfaceM.MA_RFPower -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  CC1000InterfaceM.MA_LPLMode -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
}
