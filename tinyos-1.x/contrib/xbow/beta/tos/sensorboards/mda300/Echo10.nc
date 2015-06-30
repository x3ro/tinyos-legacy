/**
 * $Id: Echo10.nc,v 1.1 2004/05/11 21:22:00 jdprabhu Exp $
 */

#ifndef MDA300_CHANNEL_ECHO
#define MDA300_CHANNEL_ECHO 4
#endif

configuration Echo10 {
  provides {
    interface SplitControl;
    interface ADConvert;
  }
}
implementation {
  components IBADC, Echo10M, TimerC;

  ADConvert = IBADC.ADConvert[MDA300_CHANNEL_ECHO];
  SplitControl = Echo10M;
  Echo10M.Power -> IBADC.EXCITATION25;
  Echo10M.SetParam -> IBADC.SetParam[MDA300_CHANNEL_ECHO];
  //Echo10M.SubControl -> TimerC;
  Echo10M.SubControl -> IBADC;
  Echo10M.Timer -> TimerC.Timer[unique("Timer")];
}
