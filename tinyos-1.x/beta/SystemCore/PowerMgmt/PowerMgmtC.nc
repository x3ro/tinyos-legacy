includes PowerMgmt;

configuration PowerMgmtC {
  provides { 
    interface StdControl;
    command result_t setPowerMode(uint8_t);
  }
}

implementation {

  components 
    PowerMgmtM, 
    DripC,
    MgmtQueryC,
    MgmtAttrsC,
    RSSIMultiHopRouter,
    AMNamingM,
    GenericComm, 
    HPLPowerManagementM as Power,
    LedsC as Leds,
    SimpleTime,
    TimerC;
  
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)
  components CC1000RadioIntM, CC1000RadioC as Radio;
#endif

#if defined(PLATFORM_TELOS)
  components CC2420RadioC as Radio;
#endif
  
  components DelugeC;

  StdControl = PowerMgmtM;
  setPowerMode = PowerMgmtM.setPowerMode;

  PowerMgmtM.Leds -> Leds;

  PowerMgmtM.PowerEnable -> Power.Enable;
  PowerMgmtM.PowerDisable -> Power.Disable;

  PowerMgmtM.CommControl -> GenericComm;

  PowerMgmtM.ComponentControl -> MgmtQueryC;
  PowerMgmtM.ComponentControl -> DripC;
  PowerMgmtM.ComponentControl -> DelugeC;

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)
  PowerMgmtM.SetListeningMode -> CC1000RadioIntM.SetListeningMode;
  PowerMgmtM.GetListeningMode -> CC1000RadioIntM.GetListeningMode;
#endif

  PowerMgmtM.RadioControl -> Radio;

  PowerMgmtM.softStart -> GenericComm.softStart;
  PowerMgmtM.softStop -> GenericComm.softStop;

  PowerMgmtM.Receive -> DripC.Receive[AM_POWERMGMTCMDMSG];
  PowerMgmtM.Drip -> DripC.Drip[AM_POWERMGMTCMDMSG];
  PowerMgmtM.Naming -> AMNamingM;

  PowerMgmtM.PowerChangeTimer -> TimerC.Timer[unique("Timer")];

  PowerMgmtM.Time -> SimpleTime.Time;

  PowerMgmtM.MA_LPLMode -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
}
