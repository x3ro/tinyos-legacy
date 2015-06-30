//includes Clock;

abstract module AbstractTimerM(int atnum) {
  provides interface StdControl;
  provides interface Timer;
  uses interface static Clock;
} implementation {

  int numticks = 2;
  static int NUMINSTANCES = 10;

  command result_t StdControl.init() {
    dbg(DBG_USR1, "AbstractTimerM (%d, %d): StdControl.init\n", _INSTANCENUM, atnum);
    return SUCCESS;
  }
  command result_t StdControl.start() {
    dbg(DBG_USR1, "AbstractTimerM (%d): StdControl.start\n", _INSTANCENUM);
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    dbg(DBG_USR1, "AbstractTimerM (%d): StdControl.stop\n", _INSTANCENUM);
    return SUCCESS;
  }

  command result_t Timer.start(char type, uint32_t interval) {
    dbg(DBG_USR1, "AbstractTimerM (%d): Timer.start interval %d\n", _INSTANCENUM, interval);
    call Clock.setRate(TOS_I1PS, TOS_S1PS);
    return SUCCESS;
  }

  command result_t Timer.stop() {
    dbg(DBG_USR1, "AbstractTimerM (%d): Timer.stop\n", _INSTANCENUM);
    call Clock.setRate(TOS_I0PS, TOS_S0PS);
    return SUCCESS;
  }

  event result_t Clock.fire() {
    int i;
    dbg(DBG_USR1, "AbstractTimerM (): Clock.fire\n");
    for (i = 0; i < NUMINSTANCES; i++) {
      instance(i).numticks --;
      if (instance(i).numticks == 0) {
	signal instance(i).Timer.fired();
	instance(i).numticks = 2;
      }
    }
    return SUCCESS;
  }


}
