includes SNMS;
includes Hello;

configuration HelloC {
  provides interface StdControl;
  uses interface StdControl as SNMSControl;
}

implementation {
  components 
    HelloM, 
    TimerC, 
    LedsC, 
    MgmtAttrsC, 
    DripC,
    AMNamingM,
    RandomLFSR,
    GenericComm as Comm;

#ifndef PLATFORM_PC
  components PowerMgmtC, RebootC, InternalFlashC;
#endif

#if defined(PLATFORM_MICA2)
    components SerialId;
#elif defined(PLATFORM_XSM)
    components SerialIDC;
#endif

#if defined(BOARD_MICASB) 
    components Sounder;
#elif defined(BOARD_XSM) 
    components SounderC;
#endif

  StdControl = HelloM;
  StdControl = TimerC;
  StdControl = Comm;
  StdControl = MgmtAttrsC;

  SNMSControl = HelloM.SNMSControl;

  HelloM.Leds -> LedsC.Leds;

#if defined(BOARD_MICASB)
  HelloM.Sounder -> Sounder.StdControl;
#elif defined(BOARD_XSM)
  HelloM.Sounder -> SounderC;
#endif

  HelloM.Random -> RandomLFSR;

  HelloM.BlinkTimer -> TimerC.Timer[unique("Timer")];

  HelloM.SendMsg -> Comm.SendMsg[AM_HELLOMSG];
  HelloM.ReceiveMsg -> Comm.ReceiveMsg[AM_HELLOREQMSG];

  HelloM.Receive -> DripC.Receive[AM_HELLOCMDMSG];
  HelloM.Drip -> DripC.Drip[AM_HELLOCMDMSG];
  HelloM.Naming -> AMNamingM;

#ifndef PLATFORM_PC
  HelloM.setPowerMode -> PowerMgmtC;
  HelloM.IFlash -> InternalFlashC;
#endif

#if defined(PLATFORM_MICA2)
  StdControl = SerialId;
  HelloM.HardwareId -> SerialId;
#elif defined(PLATFORM_XSM)
  HelloM.HardwareId -> SerialIDC;
#endif


  HelloM.MA_Group -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  HelloM.MA_ProgramName -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  HelloM.MA_ProgramCompileTime -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  HelloM.MA_ProgramCompilerID -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  HelloM.MA_MoteSerialID -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
}
