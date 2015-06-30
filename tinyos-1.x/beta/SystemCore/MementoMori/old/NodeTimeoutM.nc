includes DFDTypes;
includes AM;

module NodeTimeoutM {
  provides {
    interface StdControl;
    interface NodeTimeout;

  }
  uses {
    interface Time;
    interface TinyTimeInterval;

    interface AbsoluteTimer;
    interface TimeSetListener;

  }
}
implementation {

  // ------------- Local data ---------------------

  typedef struct {
    uint16_t addr;

    uint8_t timedOut:1;
    uint8_t type:7;

    TimeStamp lastUpdate;

    TimeStamp timeOut;

    uint32_t avgInterval;
    uint32_t varInterval;

  } TimeoutStruct;

  enum {
    MAX_TIMEOUTS = MAX_WATCHED * 2 + MAX_COVERAGE
  };

  // There should be 2 timeout structs / monitoring target
  // 1 timeout struct / my monitor
  TimeoutStruct tOuts[MAX_TIMEOUTS];

  TimeoutStruct *earliest = NULL;

  void printTable() {
    uint8_t i;

    dbg(DBG_USR1, "Node timeout ---------------------\n");
    dbg(DBG_USR1, "==================================\n");

    for (i = 0; i < MAX_TIMEOUTS; i++) {
      if (tOuts[i].addr != TOS_BCAST_ADDR) {
	dbg(DBG_USR1, "%u\t%u\t%s\t%u\t%u\t%u\n",
	    tOuts[i].addr,
	    tOuts[i].type,
	    (tOuts[i].timedOut ? "TOUT" : "LIVE"),
	    tOuts[i].avgInterval,
	    tOuts[i].varInterval,
	    call NodeTimeout.getTimeout(tOuts[i].addr, tOuts[i].type));
      }
    }

    dbg(DBG_USR1, "\n");

  }

  // ------------- StdControl ---------------------

  command result_t StdControl.init() {
    uint8_t i;

    for (i = 0; i < MAX_TIMEOUTS; i++) {
      tOuts[i].addr = TOS_BCAST_ADDR;
      tOuts[i].type = 0x7F;
    }

    return SUCCESS;
  }
  command result_t StdControl.start() {
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  // ------------- NodeTimeout --------------------

  TimeoutStruct *findTO(uint16_t addr, uint8_t type) {
    uint8_t i;

    for (i = 0; i < MAX_TIMEOUTS; i++) {
      if (tOuts[i].type == type &&
	  tOuts[i].addr == addr)
	return &tOuts[i];
    }

    return NULL;
  }

   void curTimeStamp(TimeStamp t) {
    // Timestamp the message
    tos_time_t now = call Time.get();
    
    tos2timeStamp(now, t);
  }
   
   inline uint32_t timeoutEstimate(TimeoutStruct *tos) {
     return tos->avgInterval + 
       (tos->varInterval << 2);
   }

  void calcTimeout(TimeoutStruct *tos) {
    
#define TIMER_INFLATE 10

    timeStampCopy(tos->timeOut, 
		  tos->lastUpdate);
    
    timeStampAdd32(tos->timeOut,
		   2 * timeoutEstimate(tos));

    timeStampAdd16(tos->timeOut,
		   TIMER_INFLATE);
  }

  // Is lastHeard(idx1) earlier than leastHeard(idx2)?
  bool earlierThan(TimeoutStruct *r1,
		   TimeoutStruct *r2) {

    return (timeStampCompare(r1->timeOut,
			     r2->timeOut) < 0);
  }

  void resetTimer() {
    uint8_t i;
    TimeoutStruct *cur, *winner = NULL;

    for (i = 0; i < MAX_TIMEOUTS; i++) {
      
      cur = &tOuts[i];

      if (cur->addr != TOS_BCAST_ADDR &&
	  !cur->timedOut &&
	  (winner == NULL ||
	   earlierThan(cur, winner)))
	winner = cur;
    }

    if (winner != NULL) {

      call AbsoluteTimer.set(timeStamp2tos(winner->timeOut));

      earliest = winner;
    } else {
      call AbsoluteTimer.cancel();

      earliest = NULL;
    }

  }


  void correctTimer(TimeoutStruct *tos) {
    
    if (tos == earliest)
      resetTimer();
    else if ((earliest == NULL ||
	      earlierThan(tos, earliest))) {

      call AbsoluteTimer.cancel();
      
      call AbsoluteTimer.set(timeStamp2tos(tos->timeOut));

      earliest = tos;
    }
    // Otherwise, no need to do anything
  }

  command result_t NodeTimeout.add(uint16_t addr, uint8_t type, 
				   uint32_t initialTO) {
    TimeoutStruct *res;

    if (findTO(addr, type) != NULL)
      return SUCCESS;

    if ((res = findTO(TOS_BCAST_ADDR, 0x7F)) == NULL)
      return FAIL;

    res->addr = addr;
    res->type = type;

    res->timedOut = FALSE;

    res->avgInterval = initialTO;
    res->varInterval = 0;

    curTimeStamp(res->lastUpdate);

    calcTimeout(res);
    correctTimer(res);

    dbg(DBG_USR1, "NodeTimeout: ADD\n");
    printTable();

    return SUCCESS;
  }

  command result_t NodeTimeout.remove(uint16_t addr, uint8_t type) {
    TimeoutStruct *res;

    if ((res = findTO(addr, type)) == NULL)
      return FAIL;

    res->addr = TOS_BCAST_ADDR;
    res->type = 0x7F;

    if (res == earliest)
      resetTimer();

    dbg(DBG_USR1, "NodeTimeout: REMOVE\n");
    printTable();

    return SUCCESS;
  }

  command result_t NodeTimeout.update(uint16_t addr, uint8_t type) {
    TimeoutStruct *res;
    uint32_t diff, *a, *v;
    TimeStamp ts;

      dbg(DBG_USR1, "UPDATE CALLED\n");

    if ((res = findTO(addr, type)) == NULL) {

      dbg(DBG_USR1, "UPDATE:  %u, %u not found\n", addr, type);

      return FAIL;
    }

    curTimeStamp(ts);    
    
    diff = (uint32_t)timeStampDiff(ts, 
				   res->lastUpdate);

    a = &res->avgInterval;
    v = &res->varInterval;
    
    // The TCP-like timeout estimator
    if (diff < *a &&
	(*a - diff) > *v) {
      // This is to negate the effects
      // of an unexpectedly small diff
      // due to, for example, time synchronization
      *v = (31 * (*v) + (*a > diff ? 
			 *a - diff :
			 diff - *a)) / 32;
    } else {
      *v = (3 * (*v) + (*a > diff ? 
			*a - diff : 
			diff - *a)) / 4;
    }
    *a = (7 * (*a) + diff) / 8;
    
    if (res->timedOut) {
      signal NodeTimeout.timeoutReset(res->addr, res->type);

      res->timedOut = FALSE;
    }

    timeStampCopy(res->lastUpdate, ts);

    calcTimeout(res);
    correctTimer(res);

    dbg(DBG_USR1, "NodeTimeout: UPDATE\n");
    printTable();

    return SUCCESS;
  }

  command result_t NodeTimeout.postpone(uint16_t addr, uint8_t type,
					uint32_t delay) {
    TimeoutStruct *res;

    if ((res = findTO(addr, type)) == NULL)
      return FALSE;
    
    timeStampAdd32(res->timeOut, delay);
    correctTimer(res);
  }

  command bool NodeTimeout.hasTimedOut(uint16_t addr, uint8_t type) {
    TimeoutStruct *res;

    if ((res = findTO(addr, type)) == NULL)
      return FALSE;

    return (res->timedOut != 0);
  }

  command uint32_t NodeTimeout.getTimeout(uint16_t addr, uint8_t type) {
    TimeoutStruct *res;

    if ((res = findTO(addr, type)) == NULL)
      return 0xFFFFFFFF;
    else
      return timeoutEstimate(res);
  }

  // ----------- AbsoluteTimer -----------------------

  event result_t AbsoluteTimer.fired() {
    uint8_t i;

    TimeStamp now, nowUpdated;
    uint16_t tinyIntStart;

    curTimeStamp(now);
    call TinyTimeInterval.startNow(&tinyIntStart);

    dbg(DBG_USR1, "AbsoluteTimer fired at\n");
    timeStampPrint(now);

    for (i = 0; i < MAX_TIMEOUTS; i++) {

      if (tOuts[i].addr != TOS_BCAST_ADDR &&
	  !tOuts[i].timedOut) {
	
	timeStampCopy(nowUpdated, now);
	timeStampAdd16(nowUpdated, 
		       call TinyTimeInterval.passedSince(&tinyIntStart));

	if (timeStampCompare(now, tOuts[i].timeOut) >= 0) {
	  tOuts[i].timedOut = TRUE;

	  signal NodeTimeout.timedOut(tOuts[i].addr,
				      tOuts[i].type);
	}
      }
    }

    printTable();

    resetTimer();

    return SUCCESS;
  }

  // ------- TimeSetListener --------------------------
  event void TimeSetListener.timeAdjusted(int64_t msTicks) {

    if (earliest != NULL) {
      uint8_t i;

      for (i = 0; i < MAX_TIMEOUTS; i++) {
	if (tOuts[i].addr != TOS_BCAST_ADDR) {
	  int64_t t;
	  
	  t = timeStamp2ulint(tOuts[i].lastUpdate);
	  
	  t += msTicks;
	  
	  ulint2timeStamp((uint64_t)t, tOuts[i].lastUpdate);
	}
      }

      // Only one node's timer needs to be corrected, really
      correctTimer(earliest);
    }
  }
}
