/* 
 * Authors:  Matt Welsh, mdw@cs.berkeley.edu
 * Date:     10/30/2002
 */


abstract module AbstractTimerM() {
  provides interface Timer;
  provides interface static StdControl;
  uses interface static Clock;
  uses interface static Leds;

} implementation {

  static int TIMER_HIGHEST_RATE = 12;
  static int TIMER_MIN_TICKS = 10;
  static int TIMER_THRESHOLD = 20;
  static long MAX_TICKS = 0xffffffff;

  static uint8_t clockRate;	// current clock setting
  static int minTimer;		// the index of the shortest timer
  static long minTicks;		// shortest timer interval in ticks

  bool started;			// Whether this timer has been started
  uint8_t type;			// one-shot or repeat
  long ticks;			// total number of ticks for repeat
  long ticksLeft;		// ticks left before timer expires

  command result_t StdControl.init() {
    dbg(DBG_USR1, "AbstractTimerM.StdControl.init()\n");
    if (clockRate != 0) return FAIL;
    minTicks = MAX_TICKS;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    dbg(DBG_USR1, "AbstractTimerM.StdControl.start()\n");
    call Clock.setRate(TOS_I1PS, TOS_S1PS);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    dbg(DBG_USR1, "AbstractTimerM.StdControl.stop()\n");
    call Clock.setRate(TOS_I0PS, TOS_S0PS);
    return SUCCESS;
  }

  // supported clock rates in the powers of 2 so that we can use shift 
  //  clockRate[13]={0,1, 2, 3, 4,5,6,7,8,9,10,11,12};
  // because the value are the same as the array index, I only need to use 
  // one byte to represent clock rate.
  static void initClock(uint8_t setting)
    {
      switch(setting) {
      case 0: call Clock.setRate(TOS_I1PS, TOS_S1PS) ; break;
      case 1: call Clock.setRate(TOS_I2PS, TOS_S2PS) ; break;
      case 2: call Clock.setRate(TOS_I4PS, TOS_S4PS) ; break;
      case 3: call Clock.setRate(TOS_I8PS, TOS_S8PS) ; break;
      case 4: call Clock.setRate(TOS_I16PS, TOS_S16PS) ; break;
      case 5: call Clock.setRate(TOS_I32PS, TOS_S32PS) ; break;
      case 6: call Clock.setRate(TOS_I64PS, TOS_S64PS) ; break;
      case 7: call Clock.setRate(TOS_I128PS, TOS_S128PS) ; break;
      case 8: call Clock.setRate(TOS_I256PS, TOS_S256PS) ; break;
      case 9: call Clock.setRate(TOS_I512PS, TOS_S512PS) ; break;
      case 10: call Clock.setRate(TOS_I1024PS, TOS_S1024PS) ; break;
      case 11: call Clock.setRate(TOS_I2048PS, TOS_S2048PS) ; break;
      case 12: call Clock.setRate(TOS_I4096PS, TOS_S4096PS); break;
      }
    }

  /**
   * Algorithm to convert time interval in milliseconds to clock ticks.
   * 
   * input:     interval, clockrate 
   * algorithm: ticks = clockRate(in ticks/sec)*interval/1000 
   * return:    ticks for this rate
   */
  static inline long convertMStoTicks(long  interval, int rate) {
    return (((interval<<rate)+500)/1000);
  }

  /**
   * Algorithm to adjust clock rate or change clock rate upwards
   * 
   * input argument : interval in ms
   * output argument: ticks under the new clock rate 
   * return new clock rate 
   *
   * algorithm decription: 
   * new_rate = current clockRate +1
   * while new_rate <= TIMER_HIGHEST_RATE
   * calculate ticks at new_rate 
   * if ticks >=TIMER_MIN_TICKS  break 
   * else new_rate++
   * return new_rate
   */
  static uint8_t  scaleUp(long interval, long *newticks) {
    long temp = 0;
    uint8_t new_rate = clockRate +1;
    while (new_rate <= TIMER_HIGHEST_RATE) {
      temp = convertMStoTicks(interval, new_rate);
      if (temp >= TIMER_MIN_TICKS ) break;
      new_rate++;
    }
    *newticks = temp ;
    return new_rate;
  }

  /**
   * Algorithm to adjust clock rate or change clock rate downward
   * 
   * return new clock rate 
   * algorithm decription: 
   * find the minimum timer ticks 
   * save its value and index 
   * calculate the number of levels we need to scale down 
   * ( thresthold set at 20 ticks )
   * return new_rate 
   */
  static uint8_t  scaleDown() {
    long temp = MAX_TICKS;
    uint8_t i, diff = 0;
    dbg(DBG_CLOCK, "scale down\n");

    for (i = 0; i < _NUMINSTANCES; i++) {

      //SRM 6/28/02 -- I'm highly skeptical that ticksLeft is the right thing
      //to be comparing against below, though Phil changed it to be this 
      // claiming it fixed a bug.
      if (instance(i).started && (instance(i).ticksLeft < temp)) {
	temp = instance(i).ticksLeft;
	minTimer = i;
      }
    }

    if (temp == MAX_TICKS) {
      // All timers stopped
      clockRate = 0;
      minTicks = MAX_TICKS;
      dbg(DBG_CLOCK, "scaleDown(): All timers stopped\n");
    } else {
      minTicks = temp;
      while (temp > TIMER_THRESHOLD) { temp >>= 1; diff++; }
    }
    dbg(DBG_CLOCK, "scaleDown() %d levels minTicks=%d index=%d\n", diff, minTicks, minTimer);

    return (clockRate-diff);
  }


  /**
   * Algorithm to adjust ticks left for all running timers
   * 
   * input argument: new_rate
   * return:  none
   *
   * Algorithm description: 
   * if new_rate is lower
   * multiple = new clockRate (tickps)/old clockRate (ticksps);
   * for every active timer  
   * left shift ticksLeft by "multiple" 
   * else
   * multiple = old clock rate (ticksps) / new clock rate ( ticksps)
   */
  static void adjustTicks(char new_rate) {
      short i; 
      int multiple;

      dbg(DBG_CLOCK, "adjustTicks new rate=%d old rate=%d\n", new_rate, clockRate);

      if ( new_rate > clockRate ) {
	multiple = new_rate - clockRate;
	for (i=0; i < _NUMINSTANCES; i++) { 
	  instance(i).ticksLeft <<= multiple;
	  instance(i).ticks <<= multiple;
	}
	minTicks <<= multiple;
      } else {
	multiple = clockRate - new_rate;	
	for (i=0; i < _NUMINSTANCES; i++) { 
	  instance(i).ticksLeft >>= multiple;
	  instance(i).ticks >>= multiple;
	}
	minTicks >>= multiple;
      }
      dbg(DBG_CLOCK, "adjustTicks(): multiple=%d min ticks=%d\n", multiple, minTicks);

    }
  
  /**
   * Description of logic for TIMER_START(timer_id, ticks, interval):
   * ===============================================================
   *
   * convert interval to clock ticks 
   * if ticks < TIMER_MIN_TICKS 
   * change rate (output: new_rate, ticks)
   * adjust ticksLeft for all running timers
   * set rate = new_rate // can not do this before adjust ticksLeft
   * 
   * set ticksLeft for this timer to ticks
   * set this timer's runing bit to 1
   * set this timer's.type bit to type argument
   * return SUCCESS
   */
  command result_t Timer.start(char thetype, uint32_t interval) {
    long new_ticks;  
    int new_rate = clockRate;

    dbg(DBG_USR1, "AbstractTimerM.Timer(%d).start()\n", _INSTANCENUM);

    if (type != TIMER_REPEAT && type != TIMER_ONE_SHOT) return FAIL;
    if (started) return SUCCESS;
    new_ticks = convertMStoTicks(interval, new_rate);
    dbg(DBG_USR1, "AbstractTimerM.Timer(%d).start(): newticks %ld\n", _INSTANCENUM, new_ticks);
    if (new_ticks == 0 && new_rate == TIMER_HIGHEST_RATE) return FAIL;
    if (new_ticks < TIMER_MIN_TICKS && new_rate < TIMER_HIGHEST_RATE) {
      new_rate = scaleUp(interval, &new_ticks);
      dbg(DBG_CLOCK, "Timer.start(): scale up to %d\n", new_rate);
      adjustTicks(new_rate);
      initClock(new_rate);
      clockRate = new_rate;
    }
    
    ticksLeft = new_ticks;
    ticks = new_ticks;
    type = thetype;
    started = TRUE;

    dbg(DBG_CLOCK, "Timer.start(): timer %d started rate=%d ticks=%d\n", _INSTANCENUM, clockRate, ticks);
    if (ticks < minTicks) {
      minTicks = ticks;
      minTimer = _INSTANCENUM;
      dbg(DBG_CLOCK,"Timer.start(): minTicks=%d id=%d\n", minTicks, _INSTANCENUM);
    }
    return SUCCESS;
  }

  /**
   * Description of logic for TIMER_STOP(timer_id)
   *
   *
   * if timer_id >=NUM_TIMERS  return FAIL;
   * if timer with id=timer_id is running 
   * set the state bit representing this timer to 0 
   * return SUCCESS
   * else
   * return FAIL
   */
  static void stopTimer(int theinstance) {
    instance(theinstance).started = FALSE;
    dbg(DBG_CLOCK, "stop timer %d\n", theinstance);
    if (theinstance == minTimer) {
      // scale down clock rate 
      int new_rate = scaleDown();
      if (new_rate != clockRate) {
	adjustTicks(new_rate);
	initClock(new_rate);
      }
    }   
  }

  command result_t Timer.stop() {
    dbg(DBG_USR1, "AbstractTimerM.Timer(%d).stop()\n", _INSTANCENUM);
    if (started) {
      stopTimer(_INSTANCENUM);
      return SUCCESS;
    } else {
      return FAIL;
    }
  }

  /**
   * Description of logic for Clock interrupt handler 
   * 
   * loop  from i=0 to NUM_TIMERS
   * if timer i is running and ticksLeft[i] is non-zero
   * decrement ticksLeft by 1 
   * if timer i expires now       
   * call user timer event handler 
   * if the timer is one-shot timer   
   * stop the timer 
   * else reset ticketLeft 
   */
  event result_t Clock.fire() {
    int i;
    dbg(DBG_USR1, "AbstractTimerM.Clock.fire()\n");

    for (i = 0; i < _NUMINSTANCES; i++) {
      dbg(DBG_USR1, "AbstractTimerM.Clock.fire(): timer %d ticks %d\n",
	  i, instance(i).ticksLeft);
      if (instance(i).started && (--instance(i).ticksLeft) == 0) {
	if (instance(i).type == TIMER_REPEAT) {
	  instance(i).ticksLeft = instance(i).ticks;
	} else {
	  stopTimer(i);
	}

	signal instance(i).Timer.fired();
      }
    }
    return SUCCESS;
  }
}

