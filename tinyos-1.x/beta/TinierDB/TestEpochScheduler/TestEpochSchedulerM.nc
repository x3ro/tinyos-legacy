includes TosTime;
includes EpochScheduler;

module TestEpochSchedulerM {

  uses {
    interface Timer;
    interface Leds;

    interface Time;
    interface EpochScheduler as EpochScheduler1;
    interface EpochScheduler as EpochScheduler2;
  }
  provides interface StdControl;
}

implementation {

  tos_time_t t;

  command result_t StdControl.init() {
    dbg(DBG_USR1, "Init\n");

    call Leds.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    register ESResult esr;

    dbg(DBG_USR1, "Start EVERYTHING\n");

    esr = call EpochScheduler1.addSchedule(4096, 1024);
    esr = call EpochScheduler1.start();

    esr = call EpochScheduler2.addSchedule(3072, 1024);
    esr = call EpochScheduler2.start();

    dbg(DBG_USR1, "Starting at %lu.%lu\n", t.high32, t.low32);
 
    call Timer.start(TIMER_REPEAT,
		     1024);

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event void EpochScheduler1.beginEpoch() {

    call Leds.greenOn();

    dbg(DBG_USR1, "Start1\n");
  }

  event void EpochScheduler1.epochOver() {

    call Leds.greenOff();

    dbg(DBG_USR1, "Stop1\n");
  }


  event void EpochScheduler2.beginEpoch() {

    call Leds.yellowOn();

    dbg(DBG_USR1, "Start2\n");
  }

  event void EpochScheduler2.epochOver() {

    call Leds.yellowOff();

    dbg(DBG_USR1, "Stop2\n");
  }

  event result_t Timer.fired() {

    call Leds.redToggle();

#if defined(PLATFORM_PC)
    t = call Time.get();

    dbg(DBG_USR1, "SYNC Timer Fired at %lu.%lu\n", t.high32, t.low32);
#endif

    return SUCCESS;
  }

}
