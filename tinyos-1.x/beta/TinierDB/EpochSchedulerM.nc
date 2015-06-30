
includes EpochScheduler;
includes AM;

/** EpochScheduler provides a "epoch" abstraction -- clients
    register an epoch durtation and waking period in each epoch,
    and receive events at the appropriate time.
    
    EpochScheduler runs a time synchronization process to ensure
    that epochs on other nodes start and stop at the same time.

    @author Sam Madden
    @author Stan Rost
*/

module EpochSchedulerM {
  provides {
    interface StdControl as ESControl;
    interface StdControl[uint8_t id];
    interface EpochScheduler[uint8_t id];
  }
 
  uses {
    interface TimeSetListener;

    interface Time;
    interface ServiceScheduler;
    interface Leds;
  }
}

implementation {

  /* ------------ Types --------------- */

#define NUM_SCHEDULES uniqueCount("EpochScheduler")

  typedef struct {
    uint32_t epochDur; // ms
    uint32_t wakingDur; // ms
    bool valid; //is this a valid entry?
    bool stopping;  // flag used to prevent re-scheduling on stop
  } EpochSched;

  /* ------------ Prototypes --------------- */

  ESResult resched(uint8_t id);
  task void reschedTask();

  /* ------------ Module Variables --------------- */

  EpochSched mScheds[NUM_SCHEDULES];

  /* ------------ Code --------------- */
  command result_t ESControl.init() {
    int i;
    for (i = 0; i < NUM_SCHEDULES; i++) {
      mScheds[i].valid = FALSE;
      mScheds[i].stopping = FALSE;
    }
    
    call Leds.init();

    return SUCCESS;
  }

  command result_t ESControl.start() {
    return SUCCESS;
  }

  command result_t ESControl.stop() {
    return SUCCESS;
  }

  /* ----------------- Schedule Routines ------------------- */

  /** Add or change the specific schedule id to have the specified 
      epochDur and wakingDur.

      epochDurMs must be >= wakingDurMs

      @param id The id of the service
      @param epochDurMs The duration, in ms, of this epcoh
      @param wakingDurMs The duration, ms, of the waking period for this epcoh
  */

  command ESResult EpochScheduler.addSchedule[uint8_t id](uint32_t epochDurMs, 
							  uint32_t wakingDurMs)
    {
      if (wakingDurMs > epochDurMs) {

	return ES_INVALID_TIME;      
      }

      mScheds[id].epochDur = epochDurMs;
      mScheds[id].wakingDur = wakingDurMs;
      mScheds[id].valid = TRUE;
    
      return ES_SUCCESS;
    }

  /** Start the specified schedule */
  command ESResult EpochScheduler.start[uint8_t id]() {

    ESResult result;

    result = resched(id);

    return result;
  }

  /** Internal routine -- set up the specified schedule according to the
      epochDur and wakingDur parameters
  */
  ESResult resched(uint8_t id) {
    tos_service_schedule sched;
    uint32_t ed = mScheds[id].epochDur;
    uint32_t wd = mScheds[id].wakingDur;
    tos_time_t t;

    t = call Time.get();

    if (!mScheds[id].valid) {
      
      return ES_INVALID_SCHED;
    }

    // start at the next time in the future that is "aligned"
    // dbg(DBG_USR1, "was = %d, now = %d\n", t.low32, t.low32 + ed - (t.low32 % ed));
    t.low32 += ed - (t.low32 % ed);

    sched.start_time = t; 
    sched.on_time = wd; 
    sched.off_time = 0;
    sched.flags = 0;
    //sched.off_time = ed - wd;

    if (call ServiceScheduler.reschedule(id, sched) == SUCCESS) {

#if defined(PLATFORM_PC)
      t = call Time.get();
      dbg(DBG_USR1, "sched'd %d, start %d, now %d\n", 
	  id, sched.start_time.low32, t.low32);
#endif

      return ES_SUCCESS;

    } else {
      dbg(DBG_USR1, "FAIL\n");

      return ES_CANT_SCHEDULE;    
    }

  }

  /** Stop the specified service */
  command ESResult EpochScheduler.stop[uint8_t id]() {

    dbg(DBG_USR1, "~ STOPPING SERVICE %d\n", id);

    mScheds[id].valid = FALSE;
    if (call ServiceScheduler.remove(id) == SUCCESS)
      return ES_SUCCESS;
    else
      return ES_FAIL;
  }


  /** Command that is fired from the ServiceScheduler indicating that 
      a particular epoch is starting 
  */
  command result_t StdControl.start[uint8_t id]() {
#if defined(PLATFORM_PC)
    tos_time_t t = call Time.get();

    dbg(DBG_USR1, "~ STARTING, ID %d, TIME %d\n", id, t.low32);
#endif

    signal EpochScheduler.beginEpoch[id]();

    return SUCCESS;
  }

  default  event void EpochScheduler.beginEpoch[uint8_t id]() {
    
  }

  default event void EpochScheduler.epochOver[uint8_t id]() {

  }

  /** Task looks for services that have been stopped and 
      need to be rescheduled.
   */
  task void reschedTask() {
    int i;

    dbg(DBG_USR1, "~ RESCHEDTASK (%d schedules)\n", NUM_SCHEDULES);

    for (i = 0; i < NUM_SCHEDULES; i ++ )
      {

	if (mScheds[i].valid) {

	  if (mScheds[i].stopping) {

	    dbg(DBG_USR1, "~ RESCHED(%d)\n", i);
	    
	    resched(i);
	    mScheds[i].stopping = FALSE;
	  } else {
	    dbg(DBG_USR1, "~ TASK %d VALID, BUT NOT STOPPING\n", i);
	  }
	} else {
	  dbg(DBG_USR1, "~ TASK %d INVALID\n", i);
	}
      }
    
  }

  /** Command called from ServiceScheduler telling us that
      the waking period of a given epoch is ending.

  */
  command result_t StdControl.stop[uint8_t id]() {

#if defined(PLATFORM_PC)
    tos_time_t t = call Time.get();
    dbg(DBG_USR1, "~ STOPPING id %d, %d\n", id, t.low32);
#endif    

    if (!mScheds[id].valid || mScheds[id].stopping) 
      return SUCCESS;

    signal EpochScheduler.epochOver[id]();

    mScheds[id].stopping = TRUE;

    post reschedTask();  // reschedule this service for the appropriate time

    return SUCCESS;
  }

  command result_t StdControl.init[uint8_t id]() {
    return SUCCESS;
  }

  event void TimeSetListener.timeAdjusted(int64_t msTicks) {
    uint8_t i;
    bool gotOne = FALSE;

    dbg(DBG_USR1, "TS: TIMESETLISTENER INVOKED\n");

    for (i = 0; i < NUM_SCHEDULES; i++) {
      if (mScheds[i].valid) {
	mScheds[i].stopping = TRUE;
	gotOne = TRUE;
      }
    }

    if (gotOne)
      post reschedTask();
  }

}
