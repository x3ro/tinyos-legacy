
module TestRunCmdM {
  provides {
    interface StdControl;
  } 
  uses {
    interface TestRun;
    interface ReceiveMsg;
  }
} implementation {

  command result_t StdControl.init() {
    return SUCCESS;
  }
  command result_t StdControl.init() {
    return SUCCESS;
  }
  command result_t StdControl.init() {
    return SUCCESS;
  }

  event void TestRun.runComplete(uint32_t code) {
    dbg(DBG_USR1, "TestRun: runComplete: code %d\n", code);
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msg) {
    TestRun_CmdMsg *cmd = (TestRun_CmdMsg)msg->data;

    if (cmd->type == TESTRUN_CMD_START) {
      bool result = call TestRun.startRun(cmd->code);
      if (!result) {
	dbg(DBG_USR1, "TestRun: startRun(%d) failed\n", cmd->code);
      }
    } else if (cmd->type == TESTRUN_CMD_STOP) {
      bool result = call TestRun.stopRun(cmd->code);
      if (!result) {
	dbg(DBG_USR1, "TestRun: stopRun(%d) failed\n", cmd->code);
      }
    } 
    return msg;
  }


}

