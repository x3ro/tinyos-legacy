module TestM {
  uses interface TestIF; 
  uses interface Timer;
  provides interface StdControl;
  provides interface CommandIF;
} implementation {

  event result_t Timer.fired() {
    dbg(DBG_USR1, "MDW: TestM: Timer.fire()\n");
    call TestIF.doTest(11);
    return SUCCESS;
  }

  command result_t StdControl.init() {
    return SUCCESS;
  }
  command result_t StdControl.start() {
    call Timer.start(TIMER_REPEAT, 1000);
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command void CommandIF.doCommand(int somearg) {
    dbg(DBG_USR1, "MDW: TestM: CommandIF.doCommand(%d)\n", somearg);
  }


}
