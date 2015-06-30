includes TestSPMsg;
#include "SPSimDbg.h"

configuration TestSP {
}
implementation {
  components GenericComm as Comm, Main,TimerC, TestSPM;

  Main.StdControl -> TimerC;
  Main.StdControl -> TestSPM;

  TestSPM.RadioControl -> Comm;
  TestSPM.SPSend -> Comm.SPSend[AM_TESTSPMSG];
  TestSPM.SPSendQueue -> Comm.SPSendQueue[AM_TESTSPMSG];
  TestSPM.SPReceive -> Comm.SPReceive[AM_TESTSPMSG];

  TestSPM.Timer -> TimerC.Timer[unique("Timer")];
}
