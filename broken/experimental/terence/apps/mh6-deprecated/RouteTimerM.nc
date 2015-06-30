#include "fatal.h"

/**
 * A simple, PERCISE timer (in accuracy of 25 ms)
 * author: Terence Tong
 */

module RouteTimerM {
  provides {
    interface Timer[uint8_t id];
    interface StdControl;
  }
  uses {
    interface Clock;
    interface Leds;
  }
}
implementation {
#define NUM_TIMERS 32
#define TIMER_DEAD 3
  struct timer_s {
    uint8_t type;		// one-short or repeat
    uint32_t repeatInterval; // just a place holder of the original setting
    uint32_t msFired;		// ticks that a fired event will trigger
  } mTimerList[NUM_TIMERS];

  uint32_t currentMiliSec;
  uint32_t minTimerFired;

  uint8_t lastTimerIndex; // just a optimization
  
  uint8_t processingOverflow;

  uint8_t interruptOff() {
    return TOSH_interrupt_disable();
  }
  void interruptOn(uint8_t oldState) {
    if (oldState == 1) {
      TOSH_interrupt_enable();
    }
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * The intention is to find the next time a timer should be fired
   * this should be exectued in an interrupt off context
   * @author: terence
   * @param: void
   * @return: void
   */

  void adjustMinTimerFired() {
    uint32_t nextMinTimerFired = -1;
    uint8_t i;
    for (i = 0; i <= lastTimerIndex; i++) {
      // if this is not dead and this is smaller than our current min
      if (mTimerList[i].type != TIMER_DEAD && nextMinTimerFired > mTimerList[i].msFired) {
	// then save it
	nextMinTimerFired = mTimerList[i].msFired;
      }
    }
    // save our result
    minTimerFired = nextMinTimerFired;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * To prevent overflow, we scale down everything and try to find the mintime again
   * @author: terence
   * @param: void
   * @return: void
   */

  task void preventOverflow() {
    int i = 0;
    uint8_t oldState = interruptOff();
    if (processingOverflow == 0) { interruptOn(oldState); return; }
    // for each slot, we scale it down
    for (i = 0; i <= lastTimerIndex; i++) {
      mTimerList[i].msFired = mTimerList[i].msFired - currentMiliSec;
    }
    // adjust the min time
    adjustMinTimerFired();
    // set current time to be zero and we are not processing this anymore
    currentMiliSec = 0;
    processingOverflow = 0;
    interruptOn(oldState);
  }

  struct FiringTimer {
    uint8_t id;
    uint32_t time;
  }; 
  /*////////////////////////////////////////////////////////*/
  /**
   * sort in terms of ascending order
   * @author: terence
   * @param: 
   * @return: -1 for x to be on the left, -1 for x to be on the right
   */

  int sortFcn(const void *x, const void *y) {
    struct FiringTimer *ftx = (struct FiringTimer *) x;
    struct FiringTimer *fty = (struct FiringTimer *) y;
    if (ftx->time < fty->time) {
      return -1;
    } else if (ftx->time > fty->time) {
      return 1;
    } else {
      return 0;
    }
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * search through each one of them to see which one expired
   * @author: terence
   * @param: void
   * @return: void
   */

  void clockFired() {
    int i = 0;
    uint8_t isExpired;
    uint8_t firingTimerSize = 0;
    struct FiringTimer firingTimer[NUM_TIMERS];
    uint8_t oldState = interruptOff();
    // serach through each one of them
    for (i = 0; i <= lastTimerIndex; i++) {
      // is this expired?
      isExpired = (mTimerList[i].msFired <= currentMiliSec); 
      // if it is
      if (isExpired == 1) {
	// if it is dead
	if (mTimerList[i].type == TIMER_DEAD) {
	  // then don't do anything
	  // if this is repeat timer
	} else if (mTimerList[i].type == TIMER_REPEAT) {
	  // save it to our list
	  firingTimer[firingTimerSize].id = i;
	  firingTimer[firingTimerSize].time = mTimerList[i].msFired;
	  firingTimerSize++;	  
	  // set the next tick
	  mTimerList[i].msFired = currentMiliSec + mTimerList[i].repeatInterval;
	} else if (mTimerList[i].type == TIMER_ONE_SHOT) {
	  // save it to our list
	  firingTimer[firingTimerSize].id = i;
	  firingTimer[firingTimerSize].time = mTimerList[i].msFired;
	  firingTimerSize++;
	  // set the timer to be dead
	  mTimerList[i].type = TIMER_DEAD;
	  
	}
      }
    }
    // find the next one given that some of them is dead and the msfired time changed
    adjustMinTimerFired();
    interruptOn(oldState);
    // just want to make sure signaling is in the right order
    qsort(firingTimer, firingTimerSize, sizeof(struct FiringTimer), sortFcn);
    for (i = 0; i < firingTimerSize; i++) {
      signal Timer.fired[firingTimer[i].id]();
    }
  }
  command result_t StdControl.init() {
    int i = 0;
    for (i = 0; i < NUM_TIMERS; i++) {
      mTimerList[i].type = TIMER_DEAD;
    }
    lastTimerIndex = 0;
    return SUCCESS;
  }
  command result_t StdControl.start() {
    // tick every 1 ms
    call Clock.setRate(102, 3);
    minTimerFired = -1;
    processingOverflow = 0;
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * save it to our list, adjust the mintime
   * @author: terence
   * @param: id, the parametrized interface
   * @param: type, TIMER_REPEAT, TIMER_ONE_SHOT, TIMER_DEAD
   * @param: interval, how much in ms
   * @return: SUCCESS if okay
   */

  command result_t Timer.start[uint8_t id](char type, uint32_t interval) {
    uint32_t timerFired = currentMiliSec + interval;
    if (NUM_TIMERS <= id) {
      return FAIL;
    } 
    if (interval == 0) {
      FATAL("RouteTimer: interval is 0");
      return FAIL;
    }

    mTimerList[id].type = type;
    mTimerList[id].msFired = timerFired;
    mTimerList[id].repeatInterval = timerFired;
    minTimerFired = (minTimerFired > timerFired) ? timerFired : minTimerFired;
    lastTimerIndex = (id > lastTimerIndex) ? id : lastTimerIndex;
    return SUCCESS;
  }

  command result_t Timer.stop[uint8_t id]() {
    mTimerList[id].type = TIMER_DEAD;
    return SUCCESS;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * check if it overflow, if so post a task to do a prevent overflow
   * then check if currentMiliTime passed any timer that supposed to be expired
   * @author: terence
   * @param: void
   * @return: void
   */

  event result_t Clock.fire() {
    currentMiliSec += 100;
    // if currentMiliSec is bigger than that and a task is not posted
    if (currentMiliSec >= 1000 && processingOverflow == 0) {
      processingOverflow = 1;
      post preventOverflow();
    }
    // if it past some timer, we search for it
    if (currentMiliSec >= minTimerFired) {
      clockFired();
    }
    return SUCCESS;
  }
  default event result_t Timer.fired[uint8_t id]() {
    return FAIL;
  }

}
