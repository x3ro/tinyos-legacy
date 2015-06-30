configuration LocalizationControlC
{
  provides interface LocalizationControl;
}
implementation
{
  components LocalizationControlM, SystemGenericCommC as GenericComm;

  LocalizationControl = LocalizationControlM;

  LocalizationControlM.ResetMsg -> GenericComm.ReceiveMsg[AM_RESETMSG_T];
  LocalizationControlM.StartMsg -> GenericComm.ReceiveMsg[AM_INITIATERANGINGSCHEDULEMSG_T];
  LocalizationControlM.RangeOnceMsg -> GenericComm.ReceiveMsg[AM_RANGEONCEMSG_T];
  LocalizationControlM.StopMsg -> GenericComm.ReceiveMsg[AM_STOPMSG_T];
  // LocalizationControlM.LocQueryMsg -> GenericComm.ReceiveMsg[AM_LOCQUERYMSG_T];
  LocalizationControlM.ReportRangingHoodMsg -> GenericComm.ReceiveMsg[AM_REPORTRANGINGHOODMSG_T];
  LocalizationControlM.ReportAnchorHoodMsg -> GenericComm.ReceiveMsg[AM_REPORTANCHORHOODMSG_T];
  LocalizationControlM.BuffersResetMsg -> GenericComm.ReceiveMsg[AM_BUFFERSRESETMSG_T];
  LocalizationControlM.BuffersReportMsg -> GenericComm.ReceiveMsg[AM_BUFFERSREPORTMSG_T];
  
}

