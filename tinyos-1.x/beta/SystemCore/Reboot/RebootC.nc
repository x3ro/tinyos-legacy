includes Reboot;

configuration RebootC {
  provides {
    interface StdControl;
    interface RebootCheck;
  }
}
implementation {
  components RebootM, MgmtAttrsC, InternalFlashC, 
    NoLeds as Leds;

  StdControl = RebootM;
  RebootCheck = RebootM;

  RebootM.IFlash -> InternalFlashC;

  RebootM.Leds -> Leds;

  RebootM.MA_PowerOnResets -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  RebootM.MA_ExternalResets -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  RebootM.MA_WatchdogResets -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  RebootM.MA_BrownoutResets -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  RebootM.MA_ProgrammingFailureResets -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  RebootM.MA_NetProgResets -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  RebootM.MA_ResetHistory -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];

}
