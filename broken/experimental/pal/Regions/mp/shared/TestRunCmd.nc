includes TestRunCmd;

configuration TestRunCmd {
  uses {
    interface TestRun;
  }
} implementation {
  modules Main, TestRunCmdM, GenericComm as Comm;

  TestRun = TestRunCmdM;

  Main.StdControl -> TestRunCmdM;
  Main.StdControl -> Comm;

  TestRunCmdM.ReceiveMsg -> Comm.ReceiveMsg[AM_TESTRUN_CMDMSG];

}
