/*
  This module parses many compile-time 
  options and parameters and sets up the experiment.

  The parameters include

  BASE_STATION_ADDRESS = which node is the base station in this expt

  RADIO_POWER = transmission power

  An include file <failureSched.h> which defines this array

  uint16_t *timeOutSched[2] = {
  {nodeId, secondsToTimeout},
  ...
  {0xFFFF, 0xFFFF}
  }

  EXPT_DURATION = xxx, duration of the experiment, in seconds
  In reality, the duration is 5 minutes more which we allow to collect
  results from nodes programmed at different times

  Any node mentioned in this array makes it into the node roster

  Any node whose secondsToTimeout = 0xFFFF never fails
  
  Any other node dies (i.e. turns off the radio) 
  after exactly secondsToTimeout seconds

*/
includes CommonParams;

module ExptM {
  uses {

    interface Timer;

    interface Leds;

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
    interface CC1000Control as CC1KControl;
#endif
  }
  provides {
    interface StdControl;

    interface Roster;
  }

}
implementation {

#include "failureSched.h"

  uint16_t timeOutSched[][2] = {
    TIME_OUT_SCHED
  };

  // The set itself
  uint8_t liveRoster[MAX_LIVE_BITMAP_BYTES];

  uint16_t timeOut = 0xFFFF;

  command result_t StdControl.init() {
    uint16_t i;
    Set *liveRSet;

    call Leds.init();

    liveRSet = initSet(liveRoster, MAX_LIVE_BITMAP_BYTES);

    for (i = 0; ; i++) {

      if (timeOutSched[i][0] == 0xFFFF) {
	
	dbg(DBG_USR1, "EX Reached the end (%d th entry)\n", i);

	break;
      }

      setBit(liveRSet, timeOutSched[i][0]);

      if (timeOutSched[i][0] == TOS_LOCAL_ADDRESS &&
	  timeOutSched[i][1] != 0xFFFF) {

	dbg(DBG_USR1, "EX My timeout is %u\n", timeOutSched[i][1]);

	timeOut = timeOutSched[i][1];
      }
	
    }

    dbg(DBG_USR1, 
	"EX In the end, the roster (len=%d) of network nodes is:\n",
	liveRSet->len);
    printSet(liveRSet);

    return SUCCESS;
  }

  command result_t StdControl.start() {

    // Set the radio power
#ifdef PLATFORM_MICA2
#warning "Setting RADIO POWER..."
    call CC1KControl.SetRFPower(RADIO_POWER);

#endif

    if (timeOut != 0xFFFF)
      call Timer.start(TIMER_ONE_SHOT,
		       (uint32_t)timeOut * (uint32_t)1024);

  
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command Set *Roster.getRoster() {
    return (Set *)liveRoster;

    return NULL;
  }

  event result_t Timer.fired() {

    dbg(DBG_USR1, "EX Node DED\n\n\n");

    call Leds.redOn();

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)

    // Crash the mote

    __asm volatile ("cli");
    for (;;);
#endif

    return SUCCESS;
  }
}
