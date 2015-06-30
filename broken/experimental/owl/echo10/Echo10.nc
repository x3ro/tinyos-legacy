configuration Echo10 {
  provides {
    interface SplitControl;
    interface ADConvert;
  }
}
implementation {
  components IBADC, Echo10M, TimerC;

  ADConvert = IBADC.ADConvert[4];
  SplitControl = Echo10M;
  Echo10M.Power -> IBADC.EXCITATION25;
  Echo10M.SetParam -> IBADC.SetParam[4];
  //Echo10M.SubControl -> TimerC;
  Echo10M.SubControl -> IBADC;
  Echo10M.Timer -> TimerC.Timer[unique("Timer")];
}
