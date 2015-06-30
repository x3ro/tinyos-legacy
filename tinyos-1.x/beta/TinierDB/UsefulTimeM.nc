/**
 * Got tired of a lack of adequate timestamping
 * function in TinyOS, decided to write one that will for once
 * be very useful.
 *
 * ALL units are 1/1024th of a second (binTicks), which is what
 * the arguments to Timer are.
 *
 * The code is largely based on SysTime, and the a good chunk of the
 * credit goes to Miklos Markoti.
 *
 * @author Stan Rost
 * @author Miklos Markoti
 *
 **/
includes TosTime;

module UsefulTimeM {
  uses {
    interface TimeSet as TimeSetExternal;
    interface TimeUtil;
    interface Timer;

    interface SysTime;

    interface Leds;
  }
  provides {
    interface Time;
    interface TimeSet;
    interface TimeSetListener;
    interface AbsoluteTimer[uint8_t id];

    interface TinyTimeInterval;

    interface StdControl;    
  }
}
implementation {

  // XXX:  Conversion to regular time interval
  // XXX:  getTimeDecimal() from nativeTicks
  // XXX:  Abstract conversion math into a platform-specific interface

  // The AbsoluteTimer code is shared across platforms

  enum {
    MAX_NUM_ABS_TIMERS = uniqueCount("AbsoluteTimer")
  };

  tos_time_t aTimer[MAX_NUM_ABS_TIMERS];
  uint8_t numActiveTimers = 0;
  bool timerActive = FALSE;


  task void fireTimer() {
    signal Timer.fired();
  }
  
  void fixUpTimer() {

    if (!timerActive &&
	numActiveTimers > 0) {
      uint8_t i;
      int8_t winner = -1;
      uint32_t minTimeout = 0xFFFFFFFF;
      tos_time_t now;

      now = call Time.get();

      for (i = 0; i < MAX_NUM_ABS_TIMERS; i++) {
	if ((aTimer[i].high32 ||
	     aTimer[i].low32) &&
	    call TimeUtil.compare(now, aTimer[i]) >= 0) {
	  
	  // The time for this timer has passed
	  winner = i;

	  minTimeout = 1;
	  break;
	} else {
	  uint32_t curTimeout;
	  
	  curTimeout = 
	    call TimeUtil.low32(call TimeUtil.subtract(aTimer[i], now));
	  
	  if (curTimeout < minTimeout) {
	    minTimeout = curTimeout;
	    winner = i;
	  }
	}
      }           

      if (minTimeout == 0) {

	call Timer.stop();

	// Fire the timer, see what has expired!
	post fireTimer();
	
      } else {
	dbg(DBG_USR1, 
	    "MinTimeout: [%d] won, timeout in %lu (%lu.%lu - %lu.%lu)\n", 
	    winner, minTimeout,
	    aTimer[winner].high32, aTimer[winner].low32,
	    now.high32, now.low32);
	
	call Timer.stop();
	
	if (minTimeout != 0xFFFFFFFF) {
	  
	  dbg(DBG_USR1, "--> TIMER SET!!!!!\n");
	  
	  call Timer.start(TIMER_ONE_SHOT,
			   minTimeout);
	}
      }
      
    } else {
      dbg(DBG_USR1, 
	  "--> FixUpTimer idling (timerActive %d, activeTimers %d)\n",
	  timerActive, numActiveTimers);

    }

  }
    
  command result_t AbsoluteTimer.set[uint8_t id](tos_time_t in) {

    dbg(DBG_USR1, "### TIMER %d set\n", id);

    if ( id >= MAX_NUM_ABS_TIMERS ) {
      dbg(DBG_TIME, "Atimer.set: Invalid id=\%d max=%d\n", 
	  id, MAX_NUM_ABS_TIMERS);

      return FAIL;
    }

    if (call TimeUtil.compare(call Time.get(), in) > 0)
      {
	dbg(DBG_TIME, "Atimer.set: time has passed (%lu.%lu)\n", 
	    in.high32, in.low32);
	signal AbsoluteTimer.fired[id]();

	return FAIL;
      }

    if (aTimer[id].high32 == 0 &&
	aTimer[id].low32 == 0)
      numActiveTimers++;

    aTimer[id] = in;

    dbg(DBG_USR1, "Set timer [%d] to %lu.%lu \n", id, in.high32, in.low32);

    // dbg(DBG_TIME, "Atimer.set: baseTimerIndex =\%d \n", baseTimerIndex);

    fixUpTimer();

    return SUCCESS;
  }


  command result_t AbsoluteTimer.cancel[uint8_t id]() {

    dbg(DBG_USR1, "### TIMER %d CANCEL\n", id);

    if (id >= MAX_NUM_ABS_TIMERS || 
	numActiveTimers == 0 ||
	(aTimer[id].high32 == 0 && aTimer[id].low32 == 0))
      return FAIL;

    aTimer[id].high32 = 0;
    aTimer[id].low32 = 0;
    numActiveTimers--;

    fixUpTimer();

    return SUCCESS;
  }

  default event result_t AbsoluteTimer.fired[uint8_t id]() {
    return SUCCESS ;
  }

  event result_t Timer.fired() {
    uint8_t i;
    tos_time_t now = call Time.get();

    dbg(DBG_USR1, "### TIMER FIRED at %lu.%lu\n", now.high32, now.low32);

    timerActive = TRUE;

    // The i-1 hack gets rid of a gcc warning when we have no AbsoluteTimers
    for (i = 0; i < MAX_NUM_ABS_TIMERS; i++)
      if ((aTimer[i].low32 || aTimer[i].high32) &&
	  call TimeUtil.compare(now, aTimer[i]) >= 0)
	{

	  dbg(DBG_USR1, "AbsoluteTimer %d fired\n", i);

	  aTimer[i].high32 = 0;
	  aTimer[i].low32 = 0;
	  numActiveTimers--;

	  signal AbsoluteTimer.fired[i]();

	}

    timerActive = FALSE;

    fixUpTimer();

    return SUCCESS;
  }

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)

#if defined(PLATFORM_MICA2)   
  // There are 921600 TCNT3L ticks per second on a mica2
  // There are 1024 binTicks per second

  // Question:  how many binTicks are in x TCNT3L ticks?
  // 921600 TCNT3L TCNT3L ticks/sec
  // 1024 binTicks/sec
#define TICKS2BINTICKS(x) (((x) >> 2) / 225)
  //#define TICKS2BINTICKS(x) ((x) * 1024) / 921600)
#define BINTICKS2TICKS(x) ((x) * 900)
  //#define BINTICKS2TICKS(x) ((x) * 921600 / 1024)

#elif defined(PLATFROM_MICA2DOT)
  // There are 500000 TCNT3L ticks per second on a mica2dot
  // There are 1024 binTicks per second

  // Question:  how many binTicks are in x TCNT3L ticks?
  // 500000 TCNT3L ticks/sec
  // 1024 binTicks/sec
#define TICKS2BINTICKS(x) (((x) << 2 )/1953)
  //#define TICKS2BINTICKS(x) ((((uint32_t)(x)) * 1024 )/(uint32_t)500000)
#define BINTICKS2TICKS(x) (((x) * 15625) / 32)
  // #define BINTICKS2TICKS(x) (((x) * 500000) / 1024)

#endif

  uint64_t nativeTicks = 0;

  // Has the quantity of nativeTicks been updated
  // via an interrupt, since the last call to .get?
  uint16_t lastCounterVal = 0;

  typedef union {
    struct {
      uint32_t low;
      uint32_t high;
    };
    uint64_t full;
  } TickCast;

  command result_t StdControl.init() {

    uint8_t etimsk;
    
    outp(0x00, TCCR3A);
    outp(0x00, TCCR3B);
    
    atomic
      {
	etimsk = inp(ETIMSK);
	etimsk &= (1<<OCIE1C);
	etimsk |= (1<<TOIE3);
	outp(etimsk, ETIMSK);
	
      }
    
    return SUCCESS;
  }

  command result_t StdControl.start() {

    outp(0x02, TCCR3B);
      
    return SUCCESS;
  }

  command result_t StdControl.stop() {

    outp(0x00, TCCR3B);

    return SUCCESS;
  }

  // Use SIGNAL instead of INTERRUPT to get atomic update of time
  TOSH_SIGNAL(SIG_OVERFLOW3)
    {
      nativeTicks += 0xFFFF;
    }

  // Correct the remainder to get an accurate
  // timestamp of NOW

  /**
   * Get the full value of the
   * system-wide time counter.
   *
   **/
  async command tos_time_t Time.get() {
    uint64_t ts = 0;

    atomic {	
      ts = nativeTicks + __inw(TCNT3L);
      
      // maybe there was a pending interrupt
      if( bit_is_set(ETIFR, TOV3) && 
	  ((int16_t)(nativeTicks & 
		     0xFFFF)) >= 0 )
	ts += 0xFFFF;
    }
    
    {
      tos_time_t result;
      // Compute the new timestamp value

      ts = TICKS2BINTICKS(ts);

      result.low32 = ((TickCast *)&ts)->low;
      result.high32 = ((TickCast *)&ts)->high;

      return result;
    }
  }

  async command uint16_t Time.getUs() {
    tos_time_t result;

    result = call Time.get();

    return (uint16_t)result.low32;
  }

  async command uint32_t Time.getHigh32() {
    tos_time_t result;

    result = call Time.get();

    return result.high32;
  
  }

  async command uint32_t Time.getLow32() {
    tos_time_t result;

    result = call Time.get();

    return result.low32;
  
  }

  command void TimeSet.set(tos_time_t timeBuf) {
    tos_time_t diff;
    tos_time_t result;
    char sign = 0;

    // Last timestamp in the current timeline, 
    // clobbers curTime
    result = call Time.get();

    if ((sign = call TimeUtil.compare(result, timeBuf)) < 0) {
      // Current time less, it's an increment
      diff = call TimeUtil.subtract(result, timeBuf);
    } else {
      // Current time more, it's a decrement
      diff = call TimeUtil.subtract(timeBuf, result);
    }

    // Set the timer
    atomic {
      // Reset timer
      nativeTicks = BINTICKS2TICKS(timeBuf.low32 + 
				   ((uint64_t)timeBuf.high32 << 32));

      outw(TCNT3L, 0);
    }

    call TimeSetExternal.set(timeBuf);

    signal TimeSetListener.timeAdjusted((int64_t)(diff.low32 + 
					       ((uint64_t)diff.high32 << 32)) 
				     * sign);

  }

  command void TimeSet.adjust(int16_t n) {
    call TimeSet.adjustNow(n);
  }


  /**
   * Adjust the timestamp relative to current time.
   *
   * @param binTicks Amount of change (note: signed)
   **/
  command void TimeSet.adjustNow(int32_t binTicks) {
    tos_time_t result;

    result = call Time.get();

    if (binTicks >= 0) {
      call TimeUtil.addUint32(result, (uint32_t)binTicks);
    } else {
      call TimeUtil.subtractUint32(result, ((uint32_t)(-binTicks)));
    }

    atomic {
      nativeTicks = BINTICKS2TICKS((((uint64_t)result.high32) << 32) 
				   + result.low32);

      outw(TCNT3L, 0);
    }

    call TimeSetExternal.set(result);

    signal TimeSetListener.timeAdjusted((int64_t)binTicks);
  }

  async command void TinyTimeInterval.startNow(uint16_t *startTS) {
    *startTS = __inw(TCNT3L);
  }

  async command uint16_t TinyTimeInterval.passedSince(uint16_t *startTS) {
    uint16_t now = __inw(TCNT3L);

    return TICKS2BINTICKS(now - *startTS);
  }

#elif defined(PLATFORM_PC)

  // 4000000 ticks per sec
  // 1024 binTicks per sec
  // 
#define TICKS2BINTICKS(x) ((((uint64_t)x) << 2) / (uint64_t)15625)


  int64_t zeroPoint;

  command result_t StdControl.init() {

    return SUCCESS;
  }

  command result_t StdControl.start() {

    return SUCCESS;
  }

  command result_t StdControl.stop() {

    return SUCCESS;
  }

  async command tos_time_t Time.get() {
    uint64_t t;
    tos_time_t res;

    t = TICKS2BINTICKS(tos_state.tos_time);

    //    dbg(DBG_USR1, "T from timer is %llu\n", t);
    
    atomic {  
	t = (uint64_t)((int64_t)t + zeroPoint);

	/*
	dbg(DBG_USR1, "zeroPoint is %lld, T after addition is %llu\n", 
	    zeroPoint, t);
	*/

    }


    res.low32 = (uint32_t)(t & 0xFFFFFFFF);
    res.high32 = (uint32_t)(t >> 32);

    return res;
  }

  async command uint16_t Time.getUs() {
    tos_time_t result;

    result = call Time.get();

    return (uint16_t)result.low32;
  }

  async command uint32_t Time.getHigh32() {
    tos_time_t result;

    result = call Time.get();

    return result.high32;
  
  }

  async command uint32_t Time.getLow32() {
    tos_time_t result;

    result = call Time.get();

    return result.low32;
  
  }

  command void TimeSet.set(tos_time_t timeBuf) {
    int64_t zeroPointCopy;
    
    atomic {
      zeroPointCopy = zeroPoint;
      zeroPoint = (int64_t)(timeBuf.low32 + ((uint64_t)timeBuf.high32 << 32) 
			    - (int64_t)TICKS2BINTICKS(tos_state.tos_time));
    }

    call TimeSetExternal.set(timeBuf);

    signal TimeSetListener.timeAdjusted(zeroPoint - zeroPointCopy);
  }

  command void TimeSet.adjust(int16_t n) {
    call TimeSet.adjustNow(n);
  }



  /**
   * Adjust the timestamp relative to current time.
   *
   * @param binTicks Amount of change (note: signed)
   **/
  command void TimeSet.adjustNow(int32_t binTicks) {
    tos_time_t curTime;

    atomic {
      zeroPoint += binTicks;
    }

    curTime = call Time.get();
    call TimeSetExternal.set(curTime);

    signal TimeSetListener.timeAdjusted((int64_t)binTicks);
  }

  async command void TinyTimeInterval.startNow(uint16_t *startTS) {
    *startTS = (uint16_t)call Time.getLow32();
  }

  async command uint16_t TinyTimeInterval.passedSince(uint16_t *startTS) {
    uint16_t now = (uint16_t)call Time.getLow32();

    return now - *startTS;
  }



#else

#warning "UsefulTime will revert to inaccurate timing for this platform"

#endif

}
