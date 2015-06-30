// $Id: TupleRouterM.nc,v 1.2 2004/07/15 22:56:32 whong Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
  The TupleRouter is the core of the TinyDB system -- it receives
  queries from the network, creates local state for them (converts them
  from Queries to ParsedQueries), and then collects results from local
  sensors and neighboring nodes and feeds them through local queries.
<p>
  Queries consist of selections and aggregates.  Results from queries
  without aggregates are simply forwarded to the root of the tree to be
  handled by the query processor.
<p>
  Queries with aggregates are processed according to the TAG approach:
  each node collects partial aggregates from its children, combines
  those aggregates with its own sensor readings, and forwards a partial
  aggregate on to its parents.
<p>
  There are three main execution paths within TUPLE_ROUTER; one for
  accepting new queries, one for accepting results from neighboring
  nodes, and one for generating local results and deliver data to parent
  nodes.
<p>
  QUERY ARRIVAL<p>
  ------------<p>
<p>
  1) New queries arrive in a TUPLE_ROUTER_QUERY_MESSAGE.  Each query
  is assumed to be identified by a globally unique ID.  Query messages
  contain a part of a query: either a single field (attribute) to
  retrieve, a single selection predicate to apply, or a single
  aggregation predicate to apply.  All the QUERY_MESSAGEs describing a
  single query must arrive before the router will begin routing tuples
  for that query.
<p>
  2) Once all the QUERY_MESSAGESs have arrived, the router calls
  parseQuery() to generate a compact representation of the query in
  which field names have been replaced with field ids that can be used
  as offsets into the sensors local catalog (SCHEMA).
  <p>
  3) Given a parsedQuery, the tuple router allocates space at the end
  of the query to hold a single, "in-flight" tuple for that query --
  this tuple will be filled in with the appropriate data fields as the
  query executes.
  <p>
  4) TupleRouter then calls setSampleRate() to start (or restart) the
  mote's 32khz clock to fire at the appropriate data-delivery rate for
  all of the queries currently in the system.  If there is only one
  query, it will fire once per "epoch" -- if there are multiple queries,
  it will fire at the GCD of the delivery intervals of all the queries.
<p>
  TUPLE DELIVERY<p>
  --------------<p><p>
  1) Whenever a clock event occurs (TUPLE_ROUTER_TIMER_EVENT), the
  router must perform four actions:
<p>
  a) Deliver tuples which were completed on the previous clock event
  (deliverTuplesTask).  If the query contains an aggregate, deliver the
  aggregate data from the aggregate operator;  if not, deliver the
  tuple filled out during the last iteration. Reset the counters that
  indicate when these queries should be fired again.
  <p>
  b) Decrement the counters for all queries.  Any queries who's
  counters reach 0 need to have data delivered.  Reset the
  expression specific state for these queries (this is specific
  to the expressions in the queries -- MAX aggregates, for instances,
  will want to reset the current maximum aggregate to some large
  negative number.)
<p>
  c) Fetch data fields for each query firing this epoch.  Loop
  through all fields of all queries, fetch them (using the SCHEMA
  interface), and fill in the appropriate values in the tuples
  on the appropriate queries.
  <p>
  d) Route filled in tuples to query operators.  First route to
  selections, then the aggregate (if it exists).  If any selection
  rejects a tuple, stop routing it.
  <p>
  NEIGHBOR RESULT ARRIVAL<p>
  -----------------------<p>
  <p>
  When a result arrives from a neighbor (TUPLE_ROUTER_RESULT_MESSAGE),
  it needs to be integrated into the aggregate values being computed
  locally.  If the result corresponds to an aggregate query, that result
  is forwarded into the AGG_OPERATOR component, otherwise it is
  simply forwarded up the routing tree towards the root.

  @author Wei Hong, Sam Madden, Joe Hellerstein
*/

includes Attr;
includes TinyDB;
includes EpochScheduler;
includes Stream;


module TupleRouterM {

  uses {
		interface EpochScheduler[uint8_t id];
    interface Network;
    interface Tuple;
    interface ParsedQueryIntf;
    interface Operator as AggOperator;
    interface Operator as SelOperator;
    interface QueryResultIntf;
    interface Leds;
    interface StdControl as ChildControl;
    interface StdControl as NetControl;
    interface StdControl as ESControl;
    interface Random;
    interface QueryProcessor;
    command TinyDBError addResults(QueryResult *qr, ParsedQuery *q, Expr *e);
#ifdef HAS_ROUTECONTROL
    interface RouteControl;
#endif
#ifdef USE_WATCHDOG
    interface StdControl as PoochHandler;
    interface WDT;
#endif

    command result_t queryResultHook(uint8_t bufferId, QueryResultPtr r,
				     ParsedQuery *pq);
  }

  provides {
    interface StdControl;
  }
}

implementation {
  /* ----------------------------- Type definitions ------------------------------ */

  enum {UDF_WAIT_LOOP = 100}; //number of times we pass through main timer loop before giving up on a fetch...
  enum {EPOCHS_TIL_DELETION = 5}; //number of epochs we wait before deleting a "ONCE" query

  /** A data structure for tracking the next tuple field to fill
      needed since some fields come from base sensors (attrs), and some
      come from nested queries
  */
  typedef struct {
      bool isAttr;
      bool isNull;
      union {
	  AttrDescPtr attr;
	  uint8_t tupleIdx;
      } u;
  } TupleFieldDesc;
  
  /* ------------------- Bits used in mPendingMask to determine current state ----------------- */
  enum { FETCHING_BIT = 0x0008, //fetching the value of an attribute via the schema api
	 ROUTING_BIT = 0x0010, //routing tuples to queries
	 DELIVERING_BIT = 0x0020, //deliver tuples to parents
	 SENDING_BIT = 0x0040, //are sending a message buffer
	 AGGREGATING_BIT = 0x0080, //are computing an aggregate result
	 IN_QUERY_MSG_BIT = 0x0200, //are we in the query message handler?

	 SETTING_SAMPLE_RATE_BIT = 0x0400, //are we setting the sample rate
	 SNOOZING_BIT = 0x0800, //are we snoozing 
	 ATTR_STARTING_BIT = 0x1000, // are we starting attributes?
	 FORCE_WAKE_BIT = 0x8000 // are we staying awake

  };

#undef qADAPTIVE_RATE //adapt sample rate based on contention



  //enum {kSIMPLE_TIME_SLEEP_INTERVAL = 512};
#ifdef HAS_ROUTECONTROL
	// default automatic route update interval 180 seconds
	enum { DEFAULT_ROUTE_UPDATE_INTERVAL = 180};
#endif


  /* ----------------------------- Module Variables ------------------------------- */

#ifdef kUART_DEBUGGER
  char mDbgMsg[20];
#endif

  TOS_Msg mMsg;
  uint16_t mPendingMask;
  uint8_t mCycleToSend; //cycle number on which we send
  uint8_t mFetchingFieldId; //the field we are currently fetching
  char mCurExpr;  //the last operator in curRouteQuery we routed to
  Tuple *mCurTuple; /* The tuple currently being routed (not the same as the tuple in the
		     query, since operators may allocated new tuples!)
		  */
  QueryListHandle mCurRouteQuery; //the query we are currently routing tuples for
  QueryResult mResult, mEnqResult; //result we are currently delivering or enqueueing
  short mFetchTries;

  
  char *mResultBuf;

  ParsedQuery *mLastQuery; //last query we fetched an attribute for


  //constants for split-phase voltage reading
  //before setting the sample rate based on a lifetime
  //goal
  uint16_t mLifetime;
  uint8_t mCurSampleRateQuery;
  uint16_t mVoltage;

  uint16_t mNumBlocked; //number of cycles we haven't been able to send over the radio for

  uint16_t mClockCount;
  
  bool mStopped ; //service scheduler called "stop"
  bool mRadioWaiting;
  bool mSendingResult;
  uint8_t mCurTupleIdx;

  uint8_t mNumAttrs; // number of attributes to start
  
  typedef enum {
    TS_NO = 0,
    TS_QUERY_MESSAGE = 1,
    TS_QUERY_RESULT_MESSAGE = 2
  } TimeStampState;

  uint16_t mCurSchedTime;
  
  #define kHEARD_DEC 2
  #define kHEARD_THRESH 10
  uint16_t mLastHeard;
  
  uint8_t mSendFailed;  //number of consecutive sends that have failed
  #define MAX_FAILURES 10 //number of sends that must fail before we reset

  uint8_t mStoppedQid;

  uint8_t mDeliverWait;
  bool mWaitIsDummy;
  bool mIsFirstStart;

	ParsedQueryPtr mCurrentQueries[MAX_QUERIES];
	
  /* ----------------- Functions to modify pending mask --------------------- */
 
  
  bool IS_FETCHING_ATTRIBUTE() { return (mPendingMask & FETCHING_BIT) != 0; }
  void UNSET_FETCHING_ATTRIBUTE() { (mPendingMask &= (FETCHING_BIT ^ 0xFFFF)); }
  void SET_FETCHING_ATTRIBUTE() { (mPendingMask |= FETCHING_BIT); }
 
  bool IS_STARTING_ATTRIBUTE() { return (mPendingMask & ATTR_STARTING_BIT) != 0; }
  void UNSET_STARTING_ATTRIBUTE() { (mPendingMask &= (ATTR_STARTING_BIT ^ 0xFFFF)); }
  void SET_STARTING_ATTRIBUTE() { (mPendingMask |= ATTR_STARTING_BIT); }
 
  bool IS_ROUTING_TUPLES() { return (mPendingMask & ROUTING_BIT) != 0; }
  void UNSET_ROUTING_TUPLES() { (mPendingMask &= (ROUTING_BIT ^ 0xFFFF)); }
  void SET_ROUTING_TUPLES() { (mPendingMask |= ROUTING_BIT); }
  
  bool IS_DELIVERING_TUPLES() { return (mPendingMask & DELIVERING_BIT) != 0; }
  void UNSET_DELIVERING_TUPLES() { (mPendingMask &= (DELIVERING_BIT ^ 0xFFFF)); }
  void SET_DELIVERING_TUPLES() { (mPendingMask |= DELIVERING_BIT); }
  
  bool IS_SENDING_MESSAGE() { return (mPendingMask & SENDING_BIT) != 0; }
  void UNSET_SENDING_MESSAGE() { (mPendingMask &= (SENDING_BIT ^ 0xFFFF)); }
  void SET_SENDING_MESSAGE() { (mPendingMask |= SENDING_BIT); }
  
  bool IS_AGGREGATING_RESULT() { return (mPendingMask & AGGREGATING_BIT) != 0; }
  void UNSET_AGGREGATING_RESULT() { (mPendingMask &= ( AGGREGATING_BIT ^ 0xFFFF)); }
  void SET_AGGREGATING_RESULT() { (mPendingMask |= AGGREGATING_BIT); }
  

  bool IS_SETTING_SAMPLE_RATE() { return (mPendingMask & SETTING_SAMPLE_RATE_BIT) != 0; }
  void UNSET_SETTING_SAMPLE_RATE() { (mPendingMask &= ( SETTING_SAMPLE_RATE_BIT ^ 0xFFFF)); }
  void SET_SETTING_SAMPLE_RATE() { (mPendingMask |= SETTING_SAMPLE_RATE_BIT); }

 bool IS_SNOOZING() { return (mPendingMask & SNOOZING_BIT) != 0; }
  void UNSET_SNOOZING() { (mPendingMask &= ( SNOOZING_BIT ^ 0xFFFF)); }
  void SET_SNOOZING() { (mPendingMask |= SNOOZING_BIT); }


  bool IS_FORCE_WAKE() { return (mPendingMask & FORCE_WAKE_BIT) != 0; }
  void UNSET_FORCE_WAKE() { (mPendingMask &= ( FORCE_WAKE_BIT ^ 0xFFFF)); }
  void SET_FORCE_WAKE() { (mPendingMask |= FORCE_WAKE_BIT); }




  /* ----------------------------- Prototypes for Internal Routines ------------------------------ */



  bool fetchNextAttr();
  TupleFieldDesc getNextQueryField(ParsedQuery **q);
  QueryListHandle nextQueryToRoute(QueryListHandle curQuery);
  bool routeToQuery(ParsedQuery *q, Tuple *t);
  Expr *nextExpr(ParsedQuery *q);

  void startFetchingTuples();
  void resetTupleState(ParsedQuery *q);
  void fillInAttrVal(SchemaErrorNo errorNo);
  void aggregateResult(ParsedQuery *q, QueryResult *qr, char exprId);
  TinyDBError dequeueMessage(TOS_Msg *msg);
  int chooseQueueVictim(const char *data, int len);
  

  void keepRouting();

  void sendDummyQueryResult(uint8_t qid, uint8_t numFields, uint16_t curEpoch);
  TinyDBError sendTuple(ParsedQuery *pq, QueryResultPtr qr, bool *pending);
  result_t outputDone(TOS_MsgPtr msg);
  
  uint16_t max(uint16_t a, uint16_t b) {
    return a<b?b:a;
  }

  void startQueryAttrs(ParsedQuery *pq)
  {
  	short i;
	for (i = 0; i < pq->numFields; i++)
	{
		if (call AttrUse.startAttr(pq->queryToSchemaFieldMap[i]) == FAIL)
			mNumAttrs--; // won't get a startAttrDone in this case
	}
	if (mNumAttrs == 0) {
	  UNSET_STARTING_ATTRIBUTE();
	}
  }

  void startAllQueryAttrs()
  {
    QueryListHandle curq;
    
    SET_STARTING_ATTRIBUTE();
    // first add up total number of attributes
    for (curq = call QueryProcessor.getQueryList(); curq != NULL; curq = (QueryListHandle)(**curq).next)
      {
        if ((**curq).q.clocksPerSample > 0) //this query is ready to go
	  mNumAttrs += (**curq).q.numFields;
      }
    
    for (curq = call QueryProcessor.getQueryList(); curq != NULL; curq = (QueryListHandle)(**curq).next)
      {
        if ((**curq).q.clocksPerSample > 0) //this query is ready to go
	  startQueryAttrs(&((**curq).q));
      }
  }

  //  void statusMessage(char *m);

  /* Tasks */

  task void deliverTuplesTask();
  task void routeTask();
  task void fillInTask();
  task void mainTask();

/* -----------------------------------------------------------------------------*/
/* --------------------------------- Functions ---------------------------------*/
/* -----------------------------------------------------------------------------*/

  /** Intialize the tuple router */
  command result_t StdControl.init() {
    mPendingMask = 0;
    mCycleToSend = 0;

    mNumBlocked = 0;
    mFetchTries = 0; //hangs in fetch sometimes -- retry count

    mLastQuery = NULL;

    mRadioWaiting = FALSE;
    mSendingResult = FALSE;
    
    call ChildControl.init();
    call NetControl.init();
    call ESControl.init();

    mStopped = TRUE;

    mSendFailed = 0;
    mCurSchedTime = 0;
    mLastHeard = 0;

	mIsFirstStart = TRUE;
    return SUCCESS;
  }

  command result_t StdControl.start() {

    mDeliverWait = 0; //reset xmission wait cycles every time through
    mWaitIsDummy = FALSE;
    UNSET_FETCHING_STREAM();
    UNSET_STARTING_STREAM();
    UNSET_ROUTING_TUPLES();
    UNSET_AGGREGATING_RESULT();


    //send networking update event
    


    if (!isRoot() || !IS_SNOOZING()) {
      
      call ChildControl.start();
      call NetControl.start();

			// start all streams
      XXX startAllQueryAttrs();
    }

#ifdef HAS_ROUTECONTROL
	  if (!mIsFirstStart)
		  call RouteControl.manualUpdate();
#endif
	  mIsFirstStart = FALSE;

   if (IS_SNOOZING()) {
	   mStopped = FALSE;
	   // signal AbsoluteTimer.fired();
   } else {
      call ESControl.start();
   }

   return SUCCESS;
  }

  command result_t StdControl.stop() {
		call ChildControl.stop();
		call NetControl.stop();
		call ESControl.stop();
		// XXX more components to shutdown?
    return SUCCESS;
  }

	// XXX signalled per epoch scheduler??
	event EpochScheduler[uint8_t id].allSleeping() {
    QueryListHandle qlh = call QueryProcessor.getQueryList();
    
    mStopped = TRUE;

    if (!isRoot()) {
			call Leds.set(0); //all off
			call ChildControl.stop();
			// must leave radio on if there is no query running, or if
			//we haven't heard from our parent for awhile
			if (call QueryProcessor.getQueryList() != NULL && !IS_SENDING_MESSAGE() /* ??? */ && mLastHeard
	      <= kHEARD_THRESH) {
				call NetControl.stop();
			}
      
			if (IS_SENDING_MESSAGE()) { //???
				outputDone(&mMsg);
			}
      
			if (IS_DELIVERING_TUPLES())
				UNSET_DELIVERING_TUPLES();
    }

    if (mLastHeard > kHEARD_THRESH)
      mLastHeard -= kHEARD_DEC;

    return SUCCESS;
	}

  event result_t Network.querySub(QueryMessagePtr qmsg) {
    return SUCCESS;
  }

  event result_t Network.queryRequestSub(QueryRequestMessagePtr qmsg) {
    return SUCCESS;
  }

  /** A message not directly addressed to us that we overhead
      Use this for time synchronization with our parent, and
      to snoop on queries.

      @param msg The message
      @param amId The amid of the message
      @param isParent If the message is from our parent
  */
  event result_t Network.snoopedSub(QueryResultPtr qrMsg, bool isParent, uint16_t senderid) {
    ParsedQuery *q;
    uint8_t qid;

    //did this message come from our parent?

    if (isParent || senderid == 0) {
      QueryResult qr;

      //epoch sync with parent
      qid = call QueryResultIntf.queryIdFromMsg(qrMsg);


      if (call QueryProcessor.getQuery(qid, &q)) {
	call QueryResultIntf.fromBytes(qrMsg, &qr, q);

	if (qr.epoch > q->currentEpoch + 1) //make sure epoch is monotonically increasing;  off by one OK?
	 q->currentEpoch = qr.epoch;
      }

      mLastHeard = 0;
    }
  
    return SUCCESS;
  }

  /* --------------------------------- Tuple / Data Arrival ---------------------------------*/

  /** Continue processing a tuple  after a selection operator
      Basically, if the tuple passed the selection, we continue routing it to
      additional operators.  Otherwise, we move on to the next query for routing.
   @param t The tuple that has been processed by the operator,
   @param q The query that this tuple belongs to
   @param e The expression that processed the tuple
   @param passed Indicates whether the tuple passed the operator --
   if not, the tuple should not be output.
   @return err_NoError
*/

  event TinyDBError SelOperator.processedTuple(Tuple *t,
					ParsedQuery *q,
					Expr *e,
					bool passed)
    {
      if (!passed) {
	e->success = FALSE;
	mCurRouteQuery = nextQueryToRoute(mCurRouteQuery);
      }
      post routeTask();
      return err_NoError;
    }

  event TinyDBError SelOperator.processedResult(QueryResult *qr, ParsedQuery *q, Expr *e) {
      return err_NoError; //not implemented
  }

  /** Continue processing a tuple after an aggregation operator has been applied
      @param t The tuple passed into the operator
      @param q The query that the tuple belongs to
      @param e The expression that processed the tuple
      @param passed (Should be true for aggregates)
  */
  event TinyDBError AggOperator.processedTuple(Tuple *t, ParsedQuery *q,
					 Expr *e, bool passed)
    {
      post routeTask();
      return err_NoError;
    }

  /** Called every time we route a query result through an aggregate operator.
      @param qr The query result we processed
      @param q The query it belongs to
      @param e The expression that processed it
      
      Need to route to the next aggregation operator.
  */
  event TinyDBError AggOperator.processedResult(QueryResult *qr, ParsedQuery *q, Expr *e) {
    //maybe unset a status variable?

    aggregateResult(q, qr, e->idx+1);
    return err_NoError;
  }


  /** Received a result from a neighbor -- need to
      either:<p>
      
      1) process it, if is an aggregate result<p>
        or<p>
      2) forward it, if it is a non-aggregate result<p>
      @param msg The message that was received
  */
  event result_t Network.dataSub(QueryResultPtr qrMsg) {
    QueryResult qr;
    ParsedQuery *q;
    bool gotAgg = FALSE;
    bool pending;


    // call Leds.greenToggle();


    if (call QueryProcessor.getQuery(call QueryResultIntf.queryIdFromMsg(qrMsg), &q)) {
      //if this query is going to be deleted, reset the counter until
      //deletion since we're still hearing neighbors results about it...
      dbg(DBG_USR2, "Got query result for query %d\n", q->qid);

      if (q->markedForDeletion) {
	q->markedForDeletion = EPOCHS_TIL_DELETION;
      }
      call QueryResultIntf.fromBytes(qrMsg, &qr, q);
      //now determine where to route this result to -- either an
      //aggregation operator or to our parent

      gotAgg = q->hasAgg;

      if (!gotAgg) { //didn't give to an aggregate, so just pass it on...
	TinyDBError err;
	dbg(DBG_USR2, "forwarding result for query %d to buffer %d\n", q->qid, q->bufferId);

	mEnqResult = *(QueryResultPtr)qrMsg;
	call queryResultHook(q->bufferId, &mEnqResult, q);
	err = call DBBuffer.enqueue(q->bufferId, &mEnqResult, &pending, q);
	//ignore result buffer busy items for now, since they just mean
	//we can't keep up with the sample rate the user is requested , but we
	//shouldn't abort
	if (err != err_ResultBufferBusy && err != err_NoError) TDB_SIG_ERR(err);
      } else { //got an agg -- do all the aggregation expressions
	mResult = qr;
#ifdef HSN_ROUTING
	mNumMerges++;
#endif
	if (!IS_AGGREGATING_RESULT()) //don't double aggregate!
	  aggregateResult(q, &mResult, 0);
      }
    } 

    return SUCCESS;
  }

  default command result_t queryResultHook(uint8_t bufferId, QueryResultPtr r,
					   ParsedQuery *pq) {
    return SUCCESS;
  }

  /** Apply all aggregate operators to this result.
    Apply them one after another, starting with exprId.
    <p>
    This is called from TUPLE_ROUTER_RESULT_MESSAGE and from
    AGGREGATED_RESULT_EVENT
    @param q The query that the result applies to
    @param qr The query result
    @param exprID The expression to apply to qr

*/
  void aggregateResult(ParsedQuery *q, QueryResult *qr, char exprId) {
    Expr *e;

    if (exprId >= q->numExprs) { //no more aggregation expressions
      UNSET_AGGREGATING_RESULT();
      return;
    }

    e = call ParsedQueryIntf.getExprPtr(q,exprId);
    if (e->opType != kSEL) {
      SET_AGGREGATING_RESULT();
      if (call AggOperator.processPartialResult(qr, q, e) != err_NoError) {
	UNSET_AGGREGATING_RESULT(); //error, just do the next one
	//(errors may just mean the result doesn't apply to the agg)
	aggregateResult(q,qr,exprId+1);
      }
    } else
      aggregateResult(q,qr,exprId+1); //move on to the next one
  }

  /** Clock fired event --<br>
   Works as follows:<br>
   1) Output tuples from previous epochs<br>
   2) Deterimine what queries fire in this epoch<br>
   3) Collect samples from those queries<br>
   4) Fill in the tuples in those queries<br>
   5) Apply operators to those tuples<br>
   <p>
   While this is happening, results may arrive from other sensors
   nodes representing results from the last epoch.  Those results need
   to be forwarded (if we're just selection), or stored (if we're aggregating)
   <p>
   Question:  What to do if next time event goes off before this one is
   complete?  Right now, this we'll simply ignore later events if this
   one hasn't finished processing
   <p>
   As of 10/5/2002, moved main body into a task.
*/
event result_t AbsoluteTimer.fired() {

    if (mIsRunning) {
#ifdef qSNOOZE
      //set up the service scheduler on our first time through here
      if (call QueryProcessor.allQueriesSameRate() && 
	  !IS_SNOOZING() &&
	  call QueryProcessor.getQueryList() != NULL) {
	result_t r;
	
	ParsedQueryPtr pq = &(**call QueryProcessor.getQueryList()).q;
	tos_time_t t = call Time.get();
	tos_service_schedule sched;
	short sleepClocks = (pq->clocksPerSample);

	//don't sleep if the clock rate is fast
	if (pq->clocksPerSample <= WAKING_CLOCKS) {
	  mStopped = FALSE;
	  goto dontSleep;
	}

	
	t.low32 += ((int32_t)pq->clocksPerSample * kMS_PER_CLOCK_EVENT) - (t.low32 % ((int32_t)pq->clocksPerSample* kMS_PER_CLOCK_EVENT));

	sched.start_time = t; 
	sched.on_time = (((uint32_t)WAKING_CLOCKS + 1)* (uint32_t)kMS_PER_CLOCK_EVENT); //and stop will be called after WAKING_CLOCKS
	sched.off_time =(((uint32_t)sleepClocks - ((uint32_t)WAKING_CLOCKS + 1)) * (uint32_t)kMS_PER_CLOCK_EVENT);
	
	SET_SNOOZING();	
	r = call ServiceScheduler.reschedule(kTINYDB_SERVICE_ID, sched); //wait til this fires before we start...
      } else {
#endif
      dontSleep:

	if (!mStopped) {
	  
	  tos_time_t cur_time = call Time.get();
	  uint32_t rateUs = ((uint32_t)kMS_PER_CLOCK_EVENT); //convert to microsecs
	  
	  // call Leds.redToggle(); 
	  cur_time.low32 -= (cur_time.low32 % rateUs);
	  cur_time.low32 += rateUs; //schedule for this time in the future
	  atomic {
	    call AbsoluteTimer.set(cur_time);
	  }
	  decrementQueryCounter();
	  post mainTask();
	}
#ifdef qSNOOZE
      }
#endif
    }
    return SUCCESS;
  }

  task void mainTask() {
    //dbg(DBG_USR3,"IN CLOCK \n"); //fflush(stdout);

    //don't do anything if we're currently sending (shouldn't need this, but...)

    if (mStopped) { 
      call AbsoluteTimer.cancel();
      return;

    }

    if(IS_SENDING_MESSAGE())  {
      
      call NetworkMonitor.updateContention(TRUE, SEND_BUSY_FAILURE);
      mNumBlocked++;
      if (mNumBlocked > 32){
	mNumBlocked = 0;
	outputDone(&mMsg);
	//UNSET_SENDING_MESSAGE();
      } else {
	//call statusMessage("sending");
	return;
      }
    }
    
    mNumBlocked = 0;


    if (mDeliverWait) {
      mDeliverWait--;
      if (mDeliverWait == 0) {
	ParsedQuery *pq;
	bool pending = FALSE;
	TinyDBError err;
	
	if (TOS_LOCAL_ADDRESS == 0) dbg(DBG_USR1, "deliver wait is 0\n");
	if (isRoot() && mWaitIsDummy) {
	  if (call QueryProcessor.getQueryList() != NULL) sendDummyQueryResult((**call QueryProcessor.getQueryList()).q.qid, (**call QueryProcessor.getQueryList()).q.numFields, (**call QueryProcessor.getQueryList()).q.currentEpoch);
	} else {
	  if (call QueryProcessor.getQuery(mEnqResult.qid, &pq)) {
	    
	    err = call DBBuffer.enqueue(pq->bufferId, &mEnqResult, &pending, pq);
	    
	    //ignore result buffer busy items for now, since they just mean
	    //we can't keep up with the sample rate the user is requested , but we
	    //shouldn't abort
	    if (err != err_ResultBufferBusy && err !=  err_NoError)
	      TDB_SIG_ERR(err);
	  }
	  if (!pending) post deliverTuplesTask();
	}

      }else
	return;
    }
    //test to see if we're already sampling, in which case we better
    //not reinvoke sampling!
    if (IS_FETCHING_ATTRIBUTE() || IS_STARTING_ATTRIBUTE()) {
      //call statusMessage("fetching");
      mFetchTries++;
      //so we can escape a blocked fetch
      if (mFetchTries < UDF_WAIT_LOOP)
	return;
      else
	{
	  if (IS_FETCHING_ATTRIBUTE())
	    UNSET_FETCHING_ATTRIBUTE();
	  if (IS_STARTING_ATTRIBUTE())
	    UNSET_STARTING_ATTRIBUTE();
	}
    } else if (IS_ROUTING_TUPLES()) {
      //call statusMessage("routing");
      return;
    } else if ( IS_DELIVERING_TUPLES()) { 
      //call statusMessage("delivering");
      return;
    }  else if (IS_AGGREGATING_RESULT()) {
      //call statusMessage("aggregating");
      return;
    }


    mFetchTries = 0;


    //  TOS_SIGNAL_EVENT(TUPLE_ROUTER_NEW_EPOCH)();
    mCurRouteQuery = NULL; //find the first query we need to deliver results for
    mCurExpr = -1;
    dbg(DBG_USR3,"POSTING TASK.");//fflush(stdout);



#ifdef qADAPTIVE_RATE
    {
      QueryListHandle qlh = call QueryProcessor.getQueryList();
      
      while (qlh != NULL) {
	uint16_t contention = call NetworkMonitor.getContention();
	//reselect the sample rate if contention is high
	if (contention > HIGH_CONTENTION_THRESH) {
	  if ((**qlh).q.savedEpochDur < 1024) { //don't adapt to slower than once per second
	    (**qlh).q.savedEpochDur += (**qlh).q.savedEpochDur >> 4; //8% slowdown
	    call QueryProcessor.setRate((**qlh).q.qid, (**qlh).q.savedEpochDur);
	  }
	} else if (contention < LOW_CONTENTION_THRESH) { //and crank it back up as contention goes low
	  if ((**qlh).q.savedEpochDur > (**qlh).q.epochDuration) {
	    (**qlh).q.savedEpochDur -= (**qlh).q.savedEpochDur >> 4; //8% speedup
	    if ((**qlh).q.savedEpochDur < (**qlh).q.epochDuration)
	      (**qlh).q.savedEpochDur = (**qlh).q.epochDuration;
	    call QueryProcessor.setRate((**qlh).q.qid, (**qlh).q.savedEpochDur);
	  }
	}
	qlh = (QueryListHandle)(**qlh).next;
      }
    }
#endif


    post deliverTuplesTask();

  }

  /* --------------------------------- Tuple Output Routines ---------------------------------*/

  /** Walk through queries, finding ones that have gone off (timer reached 0), and
      where the tuples are complete.  Output said tuples to the appropriate
      output buffers.
      <p>
      mCurRouteQuery contains the last query routed, or NULL if starting at
      the first query (it's not a parameter, since this task needs to be rescheduled
      as successive tuples are delivered)
  */
  task void deliverTuplesTask() {
    bool success;
    bool didAgg = FALSE;
    bool pending = FALSE;
  
    // if (IS_SENDING_MESSAGE()) return; //wait til networking send is done...
    dbg(DBG_USR3,"IN DELIVER TUPLES TASK.\n");//fflush(stdout);
    SET_DELIVERING_TUPLES();
    
    if (mCurRouteQuery != NULL) {
      dbg(DBG_USR2, "end of epoch\n");
	if (!pending) resetTupleState(&(**mCurRouteQuery).q); //done with this tuple...
    }

    mCurRouteQuery = nextQueryToRoute(mCurRouteQuery);
    if (mCurRouteQuery != NULL) {

      ParsedQuery *pq = &(**mCurRouteQuery).q;
      Expr *e = nextExpr(pq);
      TinyDBError err = err_NoError;
      QueryResult qr;
      uint16_t size;

      //init success
#ifndef ROOT_SAMPLE
      success = (TOS_LOCAL_ADDRESS == pq->queryRoot)? FALSE : TRUE; //don't deliver tuples for root
#else
      success = TRUE;
#endif
      pq->needsData = FALSE;
      call QueryResultIntf.initQueryResult(&qr);
      // stamp current epoch number
      if (TOS_LOCAL_ADDRESS==0)
	  dbg(DBG_USR1, "stamping epoch number %d\n", pq->currentEpoch);
      qr.epoch = pq->currentEpoch;
      qr.qid = pq->qid;

      //scan the query, looking for an aggregate operator --
      //if we find it, output all the tuples it knows about --
      //otherwise, just output the tuple associated with the query
      while (e != NULL) {
	if (e->opType != kSEL) {
	  //add all of the aggregate results to the query result data structure

	  err = call addResults(&qr, pq, e);
	  didAgg = TRUE;
	  //break;
	} else {
	  if (!e->success) success = FALSE;
	}
	e = nextExpr(pq);
      }

      //then output the query result
      //call Leds.redToggle();
      if (didAgg && err == err_NoError && call QueryResultIntf.numRecords(&qr,pq) > 0) {
	//enqueue all the results from this aggregate

	mEnqResult = qr;
	mWaitIsDummy = FALSE;
	err = sendTuple(pq, &mEnqResult, &pending);

      }  else if (success && !didAgg) {       //just a selection query -- enqueue appropriate results


	mEnqResult = qr;

	call QueryResultIntf.fromTuple( &mEnqResult, pq , call ParsedQueryIntf.getTuplePtr(pq));

	
	mWaitIsDummy = FALSE;
      	call Leds.redToggle();
	err = sendTuple(pq, &mEnqResult, &pending);

      }


      //one shot queries may have finished scanning their buffer
      if (pq->fromBuffer != kNO_QUERY && pq->epochDuration == kONE_SHOT)
	{
	  uint8_t fromBuf;
	  err = call DBBuffer.getBufferId(pq->fromBuffer, pq->fromCatalogBuffer, &fromBuf);
	  //stop queries that have scanned the entire buffer
	  err = call DBBuffer.size(fromBuf, &size);
	  if (err != err_NoError || pq->curResult++ >= size)
	    {
	      //if this is an event based query, stop the query running but
	      //don't delete it
	      if (pq->hasEvent)
		{
		  pq->running = FALSE;
		  pq->curResult = 0;
		}
	      else
		{
		//wait a little while before actually deleting queries so that
		//pending results can filter up the routing tree.
		  pq->markedForDeletion = EPOCHS_TIL_DELETION; //we need to destroy this query asap
		}
	    }
	}

      else if (pq->hasForClause && pq->numEpochs > 0 && pq->currentEpoch > pq->numEpochs)
	{
	  //wait a little while before actually deleting queries so that
	  //pending results can filter up the routing tree.
	  pq->markedForDeletion = EPOCHS_TIL_DELETION; //we need to destroy this query asap
	}
      //send tuples for next query
      if (!pending) post deliverTuplesTask();
      mCurExpr = -1; //reset for next query

    } else {
      UNSET_DELIVERING_TUPLES(); //now that tuples from last epoch are delivered, start fetching
                                //new tuples
      dbg(DBG_USR3,"FETCTHING TUPLES\n"); //fflush(stdout);

      startFetchingTuples();
    }
  }

  /** Event that's signalled when a send is complete */
  result_t outputDone(TOS_MsgPtr msg) {



    if (IS_SENDING_MESSAGE() ) {
      UNSET_SENDING_MESSAGE();

    }
    
    //if radio is supposed to be off, turn it off
    if (mRadioWaiting) {
      mRadioWaiting = FALSE;
    }

    if (mSendingResult) {
      mSendingResult = FALSE;
      if (!signal RadioQueue.enqueueDone()) 
	post deliverTuplesTask();

    }

    return SUCCESS;

  }


  //send a tuple -- either delaying it a little if the epoch is 
  //long enough or sending it directly
  TinyDBError sendTuple(ParsedQuery *pq, QueryResultPtr qr, bool *pending) {
    TinyDBError err = err_NoError;

    if (pq->clocksPerSample > kMIN_SLEEP_CLOCKS_PER_SAMPLE) {
      if (TOS_LOCAL_ADDRESS == 0)
	dbg(DBG_USR1, "enqueuing tuple \n");
      mDeliverWait = (call Random.rand() % kMAX_WAIT_CLOCKS) + 1; //number of kCLOCK_MS_PER_SAMPLE ms periods to wait
      *pending = TRUE;
    } else {
      err = call DBBuffer.enqueue(pq->bufferId, qr, pending, pq);
      
      //ignore result buffer busy items for now, since they just mean
      //we can't keep up with the sample rate the user is requested , but we
      //shouldn't abort
      if (err != err_ResultBufferBusy && err !=  err_NoError)
	TDB_SIG_ERR(err);
    }

    return err;
  }

  event result_t Network.sendDataDone(TOS_MsgPtr msg, result_t success)
    {
      return outputDone(msg);
    }

  event result_t Network.sendQueryRequestDone(TOS_MsgPtr msg, result_t success)
    {
      return SUCCESS;
    }
  
  event result_t Network.sendQueryDone(TOS_MsgPtr msg, result_t success)
    {
      return SUCCESS;
    }
  
  void sendDummyQueryResult(uint8_t qid, uint8_t numFields, uint16_t curEpoch) {
    if (!IS_SENDING_MESSAGE()) {
      QueryResultPtr newQrMsg;

      SET_SENDING_MESSAGE();
      call Leds.redToggle();
      newQrMsg = call Network.getDataPayLoad(&mMsg);
      newQrMsg->qid = qid;
      newQrMsg->result_idx = 0;
      newQrMsg->epoch = curEpoch;
      newQrMsg->qrType = kNOT_AGG;
      newQrMsg->d.t.notNull = 0;
      newQrMsg->d.t.numFields = numFields;
      newQrMsg->d.t.qid = qid;
      if (call Network.sendDataMessageTo(&mMsg,TOS_BCAST_ADDR) != err_NoError) {
	outputDone(&mMsg);
      } 
    }
  }

  void startFetchingTuples() {
    QueryListHandle qlh = call QueryProcessor.getQueryList();
    bool mustSample = FALSE;
    bool didReset = FALSE;
    bool needsNoData = TRUE;
    ParsedQueryPtr firstQ = NULL;

    //update queries, determine if any needs to sample data this epoch
    while (qlh != NULL) {
      //reset queries that just restarted
      if ((**qlh).q.clocksPerSample > 0 && !(**qlh).q.needsData &&
#ifdef qSNOOZE
	  (((**qlh).q.clockCount == WAKING_CLOCKS) ||
#endif
	  (**qlh).q.clockCount == (int16_t)((**qlh).q.clocksPerSample)
#ifdef qSNOOZE
	   )
#endif
	  )
	{


	  didReset = TRUE;

	  if (!isRoot() || (**qlh).q.hasAgg) {
	    (**qlh).q.needsData = TRUE;
	  }
	  //else (**qlh).q.clockCount = 0;
	}

      if ((**qlh).q.hasAgg) {
	needsNoData = FALSE;
      }

      if ((**qlh).q.running && (**qlh).q.clocksPerSample > 0) {
	
	if (didReset) {
	  didReset = FALSE;
	  mLastHeard ++;  //increment count since we last heard something
	  call Leds.yellowToggle();
	  //call Leds.redToggle();
	  //call UartDebugger.writeLine("epoch");
#ifdef HAS_ROUTECONTROL
	  // force a route update every epoch if we are not sleeping
	  // if ((**qlh).q.clocksPerSample <= WAKING_CLOCKS)
		  // call RouteControl.manualUpdate();
#endif
	  if ((**qlh).q.markedForDeletion > 0) {
	    if (--(**qlh).q.markedForDeletion == 0) { //delete the query
	      //force removal, since we know it's OK...
		  call QueryProcessor.removeQuery((**qlh).q.qid, TRUE);
	    } else {
	      (**qlh).q.clockCount += (**qlh).q.clocksPerSample; // just reschedule this query...
	    }
	  } else {
	    //only actually process local tuples if we're not the root.
#ifndef ROOT_SAMPLE
	    if ((**qlh).q.queryRoot != TOS_LOCAL_ADDRESS)
#endif
	      {
		mustSample = TRUE;
		if (firstQ == NULL)
		  firstQ = &(**qlh).q;
	      }
	    (**qlh).q.currentEpoch++;
	  }
	}

	(**qlh).q.clockCount -= mClockCount;	  
#ifdef qSNOOZE
	if (!call QueryProcessor.allQueriesSameRate() || (**qlh).q.clocksPerSample <= WAKING_CLOCKS) {
#endif
	  if ((**qlh).q.clockCount <= 0) {
	    (**qlh).q.clockCount = (**qlh).q.clocksPerSample;
	  }
#ifdef qSNOOZE
	}
#endif
	//break;
      }
      qlh = (QueryListHandle)(**qlh).next;
    }
    mClockCount = 0;

    if (call QueryProcessor.getQueryList() != NULL) {
      qlh = call QueryProcessor.getQueryList();
      if (isRoot() && needsNoData && (**qlh).q.clocksPerSample > kMIN_SLEEP_CLOCKS_PER_SAMPLE) {
	mWaitIsDummy = TRUE;
	dbg(DBG_USR1,"DUMMY WAIT\n");
	//call Leds.redToggle();
#ifdef qSNOOZE
	if ((**qlh).q.clocksPerSample >= WAKING_CLOCKS)
	  mDeliverWait = WAKING_CLOCKS / 2; //half way through waking period...
	else
#endif
	  mDeliverWait = (**qlh).q.clocksPerSample/2;
      }
    }


    if (mustSample) {
      //ParsedQueryPtr q;
      //(void)getNextQueryField(&q);
      if (firstQ != NULL) {
	mNumAttrs = firstQ->numFields;
	SET_STARTING_ATTRIBUTE();
	startQueryAttrs(firstQ);
      }
      // fetchNextAttr();
    }
  

  }

  void resetTupleState(ParsedQuery *q) {
    short i;
    Expr *e;
#ifdef HSN_ROUTING
	bool gotAgg = FALSE;
#endif

    //clear out this tuple
    call TupleIntf.tupleInit(q,call ParsedQueryIntf.getTuplePtr(q));
    for (i = 0; i < q->numExprs; i++) {
      e = call ParsedQueryIntf.getExprPtr(q, i);
      call AggOperator.endOfEpoch(q, e);
#ifdef HSN_ROUTING
	  if (e->opType != kSEL)
	  	gotAgg = TRUE;
#endif
    }
#ifdef HSN_ROUTING
	if (gotAgg)
	{
		mHSNValue = mHSNValue - (mHSNValue >> 1) + (mNumMerges >> 1);
		mNumMerges = 0;
	}
#endif
  }

  /* --------------------------------- Tuple Building Routines ---------------------------------*/

  /** Fetch the next needed attribute, and
      @return TRUE if an attribute was found and (possibly)
      more attributes exist.

      Does this by scanning the current queries, finding those
      that have fired and need fields filled in, and filling in those
      fields.

      Uses mLastQuery to track the last query that results were fetched
      for, and mFetchingField to track the last field that was filled in.
      
      Note that a return value of TRUE doesn't
      mean the recent attribute was actually found
  */
  bool fetchNextAttr() {
    AttrDescPtr queryField;
    TupleFieldDesc fieldDesc;
    SchemaErrorNo errorNo;
    ParsedQuery *q;
    short i, fieldId = -1;
    bool pending;
    TinyDBError tdberr;
    uint8_t bufId;

    dbg(DBG_USR3,"in fetchNextAttr\n"); //fflush(stdout);

    //at least one query needs samples -- but which ones?
    fieldDesc = getNextQueryField(&q);
    if (fieldDesc.isNull == FALSE) {

      //get the result that we'll disassemble if this query fetches its
      //result from a buffer
      if (q->fromBuffer != kNO_QUERY) {
	mCurTupleIdx = fieldDesc.u.tupleIdx;
	//call UartDebugger.writeLine("noquery", 7);
	if (mLastQuery == NULL || mLastQuery != q) { //did we already read a result row?	  
	  mLastQuery = q; //no!

	  //call UartDebugger.writeLine("nolastquery", 11);
	  tdberr = call DBBuffer.getBufferId(q->fromBuffer, q->fromCatalogBuffer, &bufId);
	  if (tdberr != err_NoError) {
	    TDB_SIG_ERR(tdberr);
	    return FALSE;
	  }
	  if (q->epochDuration == kONE_SHOT) {
	    tdberr = call DBBuffer.getResult(bufId, q->curResult, &mResult, &pending); 
	  } else {
	    //call UartDebugger.writeLine("peek",4);
	    tdberr = call DBBuffer.peek(bufId, &mResult, &pending);
	  }
	  if (tdberr == err_ResultBufferBusy) {
	    TDB_SIG_ERR(tdberr);
	    return TRUE; //try again?
	  }
	  if (tdberr != err_NoError) {
	    TDB_SIG_ERR(tdberr);
	    return FALSE;
	  }

	  if (!pending) post fillInTask();

	} else { //yes, so copy the next result
	  post fillInTask();
	}
	return TRUE;
      } else if (q->fromBuffer == kNO_QUERY) {

	queryField = fieldDesc.u.attr;
	  mFetchingFieldId = queryField->idx;
	  //figure out this field's local query index


	//CAREFUL:  Invoke command can return very quickly, such that
	//we best have set this value before we call it, since if we do it
	//afterwards, it may completion before we have a chance to set the flag
	//So, we have to make sure to unset the flag below, when needed.
	SET_FETCHING_ATTRIBUTE();

	mLastQuery  = q;

	for (i = 0; i < q->numFields;i++) {
	    if (q->queryToSchemaFieldMap[i] == queryField->idx)
		fieldId = i;
	}
	if (fieldId != -1) {
	    // use pre-allocated tuple space
	    mResultBuf = call TupleIntf.getFieldPtr(q, call ParsedQueryIntf.getTuplePtr(q), fieldId);
	    if (call AttrUse.getAttrValue(queryField->name, mResultBuf, 
					  &errorNo) == SUCCESS) {
	      if (errorNo != SCHEMA_RESULT_PENDING) {

		post fillInTask();
	      }
	      if (errorNo != SCHEMA_ERROR)
		return TRUE;
	    }
	}

      }
    } else {
      
      //call UartDebugger.writeLine("wasnull", 7);
    }
    mLastQuery = NULL;
    return FALSE;
  }

  /** Scan queries, looking for fields that haven't been defined yet */
  TupleFieldDesc getNextQueryField(ParsedQuery **pq) {
    QueryListHandle qlh = call QueryProcessor.getQueryList();
    AttrDescPtr attr = NULL;
    TupleFieldDesc d;
    TinyDBError err;
    uint8_t idx;

    d.isNull = TRUE;

    while (qlh != NULL) {
      if ((**qlh).q.clocksPerSample > 0 &&  (**qlh).q.needsData) { //is this query's time up?
	Tuple *t = call ParsedQueryIntf.getTuplePtr(&(**qlh).q);
	ParsedQuery *q = &(**qlh).q;
	dbg(DBG_USR3,"q->qid = %d, t->qid = %d, t->numFields = %d\n", q->qid, t->qid, t->numFields);
	dbg(DBG_USR3,"calling GET_NEXT_QUERY_FIELD\n"); //fflush(stdout); 
	
	if (q->fromBuffer == kNO_QUERY) {
	    attr = call TupleIntf.getNextQueryField(q,t);
	    if (attr != NULL) {
		d.isAttr = TRUE;
		d.u.attr = attr;
		d.isNull = FALSE;
		break;
	    } 
	} else {

	  err = call TupleIntf.getNextEmptyFieldIdx(q,t, &idx);
	  if (err == err_NoError) {
	    d.isAttr = FALSE;
	    d.u.tupleIdx = idx;
	    d.isNull = FALSE;
	    break;
	  }
	}
      }
      qlh = (QueryListHandle)(**qlh).next;
    }
    if (qlh == NULL)
      *pq = NULL;
    else
      *pq = &(**qlh).q;

    return d;
  }

  /** Continue filling in tuple attributes and (if done with that)
      routing completed tuples to operators
  */
  void keepRouting() {
      if (! fetchNextAttr()) {
	UNSET_FETCHING_ATTRIBUTE(); //clear, and try again
	// XXX HACK should only turn off attributes in the current query
	call AttrControl.stop();
	SET_ROUTING_TUPLES();
	//no more attributes to fetch, start processing tuples....
	mCurRouteQuery = nextQueryToRoute(NULL);
	mCurExpr = -1;
	
	post routeTask();
      }
  }

  /** If this is not a read from a buffer, 
      Set the value of field mFetchingFieldId (which is the id of an attribute
      in the schema) in all queries that need the field to the data contained
      in mResultBuf
    
      If this is from a buffer, copy the field in mCurTupleIdx of mResult
      into the current tuple

      @param errorNo An error (if any) returned by the schema in response to the getAttr command
  */
  void fillInAttrVal( SchemaErrorNo errorNo)
    {
      ParsedQuery *pq = mLastQuery;
      char *resultBuf ;
      TinyDBError err;
	
	if (pq == NULL) return;

      if (pq->fromBuffer == kNO_QUERY) {
	short id = mFetchingFieldId; //the mote-specific field this command has data for
	short i;
	QueryListHandle qlh = call QueryProcessor.getQueryList();

	resultBuf = mResultBuf;

	//dbg(DBG_USR3,"GOT DATA, COMMAND data = %d, errorNo = %d\n", *(short *)resultBuf, errorNo);

	while (qlh != NULL) {
	  ParsedQuery *q = &(**qlh).q;
	  if (q->clocksPerSample > 0 && q->needsData &&
	      q->fromBuffer == kNO_QUERY) { //this query needs ADC data
	    Tuple *t = call ParsedQueryIntf.getTuplePtr(q);
	    for (i = 0; i < q->numFields; i++) {
	      if (q->queryToSchemaFieldMap[i] == id) { //the correct field in this query
		call TupleIntf.setField(q, t, i, resultBuf);

		//dbg(DBG_USR3,"SET QUERY FIELD : %d\n", i);
	      }
	    }
	  }
	  qlh = (QueryListHandle)(**qlh).next;
	}

      } else {
	Tuple *t = call ParsedQueryIntf.getTuplePtr(pq);
	uint8_t bufId;

	resultBuf = call TupleIntf.getFieldPtr(pq,t, mCurTupleIdx);

	if (resultBuf == NULL) {
	  //call UartDebugger.writeLine("NULL", 4);
	  // keepRouting();
	   return;
	}
	err = call DBBuffer.getBufferId(pq->fromBuffer, pq->fromCatalogBuffer, &bufId);
	if (err != err_NoError) {
	  TDB_SIG_ERR(err);
	  return;
	}

	err = call DBBuffer.getField(bufId,
				     &mResult, 
				     pq->queryToSchemaFieldMap[mCurTupleIdx], 
				     resultBuf);
	if (err != err_NoError) {
	  TDB_SIG_ERR(err);
	  return;
	}

	//already wrote the data there, but need to twiddle bits
	call TupleIntf.setField(pq, t, mCurTupleIdx, resultBuf); 

      }
      keepRouting();
    }

  /** Used to make attribute setting split phase even when its not ... */
  task void fillInTask() {
    fillInAttrVal(SCHEMA_RESULT_READY);
  }

  /** Completion event after some data was fetched
      Params should be filled out with the result of the command
      @param name The name of the attribute that was fetched
      @param resultBuf The value of the attribute
      @param errorNo Errors that occurred while fetching the result
  */
  event result_t AttrUse.getAttrDone(char *name, char *resultBuf, SchemaErrorNo errorNo)
    {
      if (resultBuf == (char *)&mVoltage)
	continueSetSampleRate();
      else 
	fillInAttrVal( errorNo);
      return SUCCESS;
    }

  /* --------------------------------- Tuple Routing Routines ---------------------------------*/


  /** routeTask does the heavy lifting of routing tuples to queries.
      It assumes the tuples stored in each query that needs to be routed
      during this epoch have been initialized.  It then iterates through the
      operators in each query, routing tuples to them in succession.
   
      Tuples are routed through a query at a time, and always in a fixed order.
      mCurRouteQuery is set to the query for which tuples are currently being routed.
  */
  task void routeTask() {
    if (mCurRouteQuery != NULL) {
      ParsedQuery *q = &(**mCurRouteQuery).q;
      if (!routeToQuery(q,  mCurTuple)) {
	//false here means move on to the next query
	mCurRouteQuery = nextQueryToRoute(mCurRouteQuery);
	post routeTask();
      }
    } else {

      UNSET_ROUTING_TUPLES(); //all done routing
    }
  }

  /** @return the next query in the query list that needs to be output<br>
      Aassumes that all attributes have already been filled out (e.g. fetchNextAttr() returned false)

      mCurTuple is changed to point at the tuple corresponding to the returned query.
  */
  QueryListHandle nextQueryToRoute(QueryListHandle curQuery) {
    mCurTuple = NULL;
    if (curQuery == NULL) {
      curQuery = call QueryProcessor.getQueryList();
    } else
      curQuery = (QueryListHandle)(**curQuery).next;

    while (curQuery != NULL) {
      if ((**curQuery).q.clocksPerSample > 0 && (**curQuery).q.needsData) { //this query is ready to go
	mCurTuple = call ParsedQueryIntf.getTuplePtr(&(**curQuery).q);

	break;
      } else {
	curQuery = (QueryListHandle)(**curQuery).next;
      }
    }

    return curQuery;
  }

  /** Route the specified tuple to the first operator of the
      specified query.  This will send the tuple to an operator,
      which will return the tuple when it is done.
      @param q The query that t should be routed to
      @param t The tuple to route
      @return TRUE if the tuple was routed, FALSE otherwise
  */
  bool routeToQuery(ParsedQuery *q, Tuple *t) {
    Expr *e = nextExpr(q);

    if (e != NULL) {   //assume expressions are listed in the order
      e->success = TRUE; //they should be executed! (e.g. selections before aggs)
      if (e->opType != kSEL) {
	call AggOperator.processTuple(q,t,e);
      } else {
	call SelOperator.processTuple(q,t,e);
      }
      return TRUE; //more routing to be done
    } else {
      return FALSE; //routing all done
    }
  }


  /** Uses mCurExpr to track the current expression
      in q that is being applied.
      <br>
      mCurExpr should be set to -1 to get the first expression
      in q.
      <br>
      The expression id is not an explicit parameter since expression
      routing needs to be resumed after the previous split phase
      expression application.
      <br>
      @return the next expression in q, or null if no such expression
      exists.
  */
  Expr *nextExpr(ParsedQuery *q) {
    if (++mCurExpr >= q->numExprs) {
      mCurExpr = -1;
      return NULL;
    } else {
      Expr *e;
      e =  (call ParsedQueryIntf.getExprPtr(q,mCurExpr));
      return e;
    }
    
  }


  void doTimeSync(uint8_t timeSyncData[5], uint16_t clockCount) {
    tos_time_t mytime;
    
    
    mytime.high32 = (timeSyncData[0] & 0x000000FF);
    mytime.low32 = *(uint32_t *)(&timeSyncData[1]);
    call TimeSet.set(mytime);
    
    checkTime();

  }
 
  /* --------------------------------- Message Queuing ---------------------------------*/
  /** Copy the specified bytes into the message queue.  Messages are always data
      (tuple) messages.  Messages of more than kMSG_LEN
      will be truncated.

      Legacy routine from days when we TupleRouterM used to maintain its own
      routing queue.  This has now been moved in low levels of the networking
      code.

      @param msg The data payload of the message to enqueue
      @param len The length (in bytes) of the data
      @return err_MessageSendFailed if the queue is full
  */
  command TinyDBError RadioQueue.enqueue(const QueryResultPtr qrMsg, bool *pending) {
	if (!IS_SENDING_MESSAGE())
	{
		QueryResultPtr newQrMsg;
		SET_SENDING_MESSAGE();
		
		newQrMsg = call Network.getDataPayLoad(&mMsg);
		*newQrMsg = *qrMsg;
		*pending = TRUE;
		mSendingResult = TRUE;
		if (call Network.sendDataMessage(&mMsg) != err_NoError) {
		  //call PowerMgmtEnable();
		  mSendFailed ++;

#ifndef PLATFORM_PC
		  if (mSendFailed > MAX_FAILURES)
		    wdt_enable(WDTO_15MS);  //watchdog reset
#endif
		  
		  *pending = FALSE;
		  //outputDone(&mMsg);
		  UNSET_SENDING_MESSAGE();
		  mSendingResult=FALSE;
		  return err_MSF_SendWaitingBusy;
		} else 
		  mSendFailed = 0;
		
	}
	else {
	  *pending = FALSE;
	  return err_MSF_SendWaitingBusy;
	}
	return err_NoError;
  }

  /* --------------------------------- Error Handling  ---------------------------------*/
  #if defined(PLATFORM_PC) //itoa not on pc
  void itoa(int err, char *errNo, int radix) {
    errNo[0] = 0;
  }
  #endif

  command void signalError(TinyDBError err, int lineNo) {
    char errStr[sizeof(TOS_Msg)];
    char errNo[10],lineNoStr[10];

    
    //    int i, j, k, l;

    errStr[0] = 0;
#ifdef PLATFORM_PC
    dbg(DBG_USR3, "Error : %d at line %d\n", err, lineNo);
    dbg(DBG_USR2, "Error : %d at line %d\n", err, lineNo);    
    dbg(DBG_USR3, "Error : %d at line %d\n", err, lineNo);
    sprintf(errNo,"%d", err);

#else
    itoa(err, errNo, 10);
    itoa(lineNo, lineNoStr, 10);
#endif

    strcat(errStr, "Err: ");
    strcat(errStr, errNo);
    strcat(errStr, "(L:");
    strcat(errStr, lineNoStr);
    strcat(errStr, ")");
    strcat(errStr, "\0");
    
    call statusMessage(errStr);
  }
  
  bool mStatus;

  command void statusMessage(CharPtr m) {
    if (TOS_LOCAL_ADDRESS != 0) {
#ifdef kUART_DEBUGGER
      int len = strlen(m) >= 20?20:strlen(m);
      memcpy(mDbgMsg, m, strlen(m));
      atomic {
	mStatus = TRUE;
      }
      call UartDebugger.writeLine(mDbgMsg,(uint8_t)len);
#endif
      //call Network.sendUart(m,1 /* debugging msg id */);
    }
  }

#ifdef kUART_DEBUGGER
  async event result_t  UartDebugger.writeDone(char * string, result_t success) {
    atomic {
      if (mStatus) {
	mStatus = FALSE;
      } 
    }
    return SUCCESS;
  }
#endif
  
  /* --------------------------------- Event Handlers ---------------------------------*/


  event result_t CommandUse.commandDone(char *commandName, char *resultBuf, SchemaErrorNo err) {
    return SUCCESS;
  }
#ifdef kSUPPORTS_EVENTS
  event result_t EventFiredCommand.commandFunc(char *commandName, char *resultBuf, SchemaErrorNo *errorNo, ParamVals *params) {
    //find the appropriate query to fire...
    int qid = atoi(commandName);
    ParsedQuery *q;
    
    dbg(DBG_USR2,"got event command for query %d\n", qid);
    

    //is a valid query
    if (call QueryProcessor.getQuery(qid, &q)) {
      dbg(DBG_USR2, "started query running\n");
      q->running = TRUE;
    }
    *errorNo = SCHEMA_SUCCESS;
    return SUCCESS;
  }

  event result_t EventUse.eventDone(char *name, SchemaErrorNo errorNo) {
    return SUCCESS;
  }
#endif


#ifdef kLIFE_CMD
  event result_t SetLifetimeCommand.commandFunc(char *commandName, char *resultBuf, SchemaErrorNo *errorNo, ParamVals *params) {
    dbg(DBG_USR2, "setting sample rate!\n");
    *errorNo = setSampleRateForLifetime(*(uint8_t *)params->paramDataPtr[0], *(uint16_t *)params->paramDataPtr[1]);

    if (*errorNo != SCHEMA_SUCCESS && *errorNo != SCHEMA_RESULT_PENDING)
      return FAIL;
    else {
      if (*errorNo == SCHEMA_RESULT_PENDING)
	mLifetimeCommandPending = TRUE;
      return SUCCESS;
    }
  }
#endif
  

  event result_t QueryProcessor.queryComplete(ParsedQueryPtr q) {

    if (IS_FETCHING_ATTRIBUTE()) {
      if (mLastQuery != NULL && mLastQuery == q) {
	UNSET_FETCHING_ATTRIBUTE();
	mLastQuery = NULL;
      }
    }
    if (IS_ROUTING_TUPLES()) {
      if (mCurRouteQuery != NULL && (**mCurRouteQuery).q.qid == q->qid) {
 	mCurRouteQuery = NULL;
 	UNSET_ROUTING_TUPLES();
      }
    }
    
    if (IS_DELIVERING_TUPLES()) {
      if (mCurRouteQuery != NULL && (**mCurRouteQuery).q.qid == q->qid) {
 	mCurRouteQuery = NULL;
 	UNSET_DELIVERING_TUPLES();
      }
    }
    
    if (mCurRouteQuery != NULL && q == &(**mCurRouteQuery).q)
      mCurRouteQuery=NULL;
    
#ifdef HSN_ROUTING
    mHSNValue = 20; // reset to initial value, XXX again 20 is arbitrary
#endif

    return SUCCESS;
  }

  event result_t QueryProcessor.allQueriesStopped() {
    if (mStopped) {
      call StdControl.start();
    }
    
    mStopped = TRUE;
    
#ifdef HAS_ROUTECONTROL
    // enable automatic route updates by routing layer
    call RouteControl.setUpdateInterval(DEFAULT_ROUTE_UPDATE_INTERVAL);
#endif
    
    call Leds.redOff();
    call Leds.yellowOff();
    call Leds.greenOff();
    
    return SUCCESS;
  }

  event result_t QueryProcessor.startedQuery(ParsedQueryPtr pq) {

	short i;
#ifdef USE_WATCHDOG
    call PoochHandler.stop();
    call PoochHandler.start();
    call WDT.start((uint32_t)minEpochDur * kBASE_EPOCH_RATE * 5L);
#endif

		// allocate a free EpochScheduler
		for (i = 0; i < MAX_QUERIES; i++) {
			if (!call EpochScheduler[i].isBusy())
				break;
    }
		if (i >= MAX_QUERIES)
			return FAIL; // reached limit of maximum number of queries
		mCurrentQueries[i] = pq;
		call EpochScheduler[i].addSchedule(pq->epochDuration * kBASE_EPOCH_RATE, WAKING_TIME_MS);
		call EpochScheduler[i].start();
    return SUCCESS;
  }

	event void EpochScheduler[uint8_t id].beginEpoch() {
		ParsedQueryPtr pq = mCurrentQueries[id];
	}

	event void EpochScheduler[uint8_t id].sleep() {
		ParsedQueryPtr pq = mCurrentQueries[id];
	}

  event result_t DBBuffer.resultReady(uint8_t bufferId) {
    return SUCCESS;
  }

  event result_t DBBuffer.getNext(uint8_t bufferId) {
    return SUCCESS;
  }

  event result_t DBBuffer.allocComplete(uint8_t bufferId, TinyDBError result) {
    return SUCCESS;
  }

  /* Signalled when a get is complete */
  event result_t DBBuffer.getComplete(uint8_t bufferId, QueryResult *buf, TinyDBError err) {
    //who to do with error?
    if (err != err_NoError) {
      TDB_SIG_ERR(err);
    } else {
#ifdef kUART_DEBUGGER
      if (TOS_LOCAL_ADDRESS != 0) call UartDebugger.writeLine("got ok", 6);
#endif
    }
    fillInAttrVal(SCHEMA_RESULT_READY);
    return SUCCESS;
  }
  
  /* Signalled when a put is complete */
  event result_t DBBuffer.putComplete(uint8_t bufferId, QueryResult *buf, TinyDBError err) {
    //keep enqueueing results
#ifdef kUART_DEBUGGER
    if (err == err_NoError) {
      //call UartDebugger.writeLine("put ok",6);
    } else {
      //call UartDebugger.writeLine("put fail",8);
    }
#endif
    post deliverTuplesTask();
    return SUCCESS;
  }

#ifdef kMATCHBOX
  event result_t DBBuffer.loadBufferDone(char *name, uint8_t id, TinyDBError err) {
    return SUCCESS;
  }

  event result_t DBBuffer.writeBufferDone(uint8_t bufId, TinyDBError err) {
    return SUCCESS;
  }

  event result_t DBBuffer.deleteBufferDone(uint8_t bufId, TinyDBError err) {
    return SUCCESS;
  }

  event result_t DBBuffer.cleanupDone(result_t success) {

    return SUCCESS;
  }
#endif

  event result_t DBBuffer.openComplete(uint8_t bufId, TinyDBError err) {
    return SUCCESS;
  }



  event result_t AttrUse.startAttrDone(uint8_t id)
  {
    mNumAttrs--;
    if (mNumAttrs == 0)
      {
	UNSET_STARTING_ATTRIBUTE();
	fetchNextAttr();
      }
    return SUCCESS;
  }
}
