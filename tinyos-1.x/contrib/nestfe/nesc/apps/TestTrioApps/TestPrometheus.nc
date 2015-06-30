// @author Jaein Jeong

includes TestReadingMsg;
includes TestTrioMsg;

configuration TestPrometheus {}

implementation {
  components Main, TestPrometheusM, PIRC, LedsC, GenericComm as Comm
             ,PrometheusC, MSP430InterruptC
             ,TimerC;

  Main.StdControl -> TestPrometheusM;

  TestPrometheusM.PrometheusControl -> PrometheusC.StdControl;
  TestPrometheusM.Prometheus -> PrometheusC;

  TestPrometheusM.PIR -> PIRC;
  TestPrometheusM.PIRControl -> PIRC.StdControl;
  TestPrometheusM.PIRADC -> PIRC.PIRADC;
  TestPrometheusM.Leds -> LedsC;

  TestPrometheusM.CommControl -> Comm;
  TestPrometheusM.SendMsg -> Comm.SendMsg[AM_TESTREADINGMSG];
  TestPrometheusM.ReceiveMsg -> Comm.ReceiveMsg[AM_TESTTRIOMSG];

  TestPrometheusM.InitTimer -> TimerC.Timer[unique("Timer")];

  TestPrometheusM.LocalTime -> TimerC.LocalTime;
}



