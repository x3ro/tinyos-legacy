/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
includes Attr;
includes MemAlloc;


/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
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
  --------------<p>
<p>
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

  @author Sam Madden (madden@cs.berkeley.edu)	
*/
module TupleRouterM {
  uses {
    interface Network;
    interface AttrUse;
    interface TupleIntf;
    interface QueryIntf;
    interface ParsedQueryIntf;
    interface Operator as AggOperator;
    interface Operator as SelOperator;
    interface QueryResultIntf;
    interface MemAlloc;
    interface Leds;
    interface Timer;
    interface Random;
    interface Interrupt;
    interface StdControl as ChildControl;
    interface StdControl as TimerControl;
    interface StdControl as RadioControl;
    interface DBBuffer;
    interface CommandUse;

    command TinyDBError addResults(QueryResult *qr, ParsedQuery *q, Expr *e);
  }

  provides {
    interface QueryProcessor;
    interface StdControl;
    interface RadioQueue;
    
    command result_t setFixedComm(bool fixed);

    command void signalError(TinyDBError err);
    command void statusMessage(CharPtr m);

  }
}

implementation {

  /* ----------------------------- Type definitions ------------------------------ */
  /** number of clocks events that dictate size of interval -- every 3 seconds */
  enum {NUM_TICKS_PER_INTERVAL = 128};
  enum {UDF_WAIT_LOOP = 100}; //number of times we pass through main timer loop before giving up on a fetch...
  enum {EPOCHS_TIL_DELETION = 5}; //number of epochs we wait before deleting a "ONCE" query

  /* AllocState is used to track what we're currently allocing */
  typedef enum {
    STATE_ALLOC_PARSED_QUERY = 0,
    STATE_ALLOC_IN_FLIGHT_QUERY,
    STATE_RESIZE_QUERY,
    STATE_NOT_ALLOCING,
    STATE_ALLOC_QUERY_RESULT
  } AllocState;
  
  /** Linked list to track queries currently being processed */
  typedef struct {
    void **next;
    ParsedQuery q;
  } *QueryListPtr, **QueryListHandle, QueryListEl;
  
  /** Completion routine for memory allocation complete */
  typedef void (*MemoryCallback)(Handle *memory);
  
  //these messages sent from remote motes requesting a query
  typedef struct {
    DbMsgHdr hdr;
    char qid; //note that this byte must be query id
  } QueryRequestMessage;
  
  //we maintain a queue of messages waiting to be delivered
  enum {MSG_Q_LEN = 8};
  typedef struct {
    short start;
    short end;
    short size;
    TOS_Msg msgs[MSG_Q_LEN];
  } MsgQ;


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
  enum { READING_BIT = 0x0001,  // reading fields for Query from network
         PARSING_BIT = 0x0002, //parsing the query
         ALLOCED_BIT = 0x0004, //reading fields, space is alloced
         FETCHING_BIT = 0x0008, //fetching the value of an attribute via the schema api
	 ROUTING_BIT = 0x0010, //routing tuples to queries
	 DELIVERING_BIT = 0x0020, //deliver tuples to parents
	 SENDING_BIT = 0x0040, //are sending a message buffer
	 AGGREGATING_BIT = 0x0080, //are computing an aggregate result
	 SENDING_QUERY_BIT = 0x0100, //are we sending a query
	 IN_QUERY_MSG_BIT = 0x0200 //are we in the query message handler?

  };


  uint16_t max(uint16_t a, uint16_t b) {
    return a<b?b:a;
  }

  /* ----------------------------- Module Variables ------------------------------- */

  char mDbgMsg[20];
  TOS_Msg mMsg;
  MsgQ mMsgq;
  uint16_t mPendingMask;
  uint8_t mCycleToSend; //cycle number on which we send
  QueryListHandle mQs;
  QueryListHandle mTail;
  Query **mCurQuery; //dynamically allocated query handle

  Handle mTmpHandle;


  MemoryCallback mAllocCallback; //function to call after allocation

  uint8_t mFetchingFieldId; //the field we are currently fetching
  char mCurExpr;  //the last operator in curRouteQuery we routed to
  Tuple *mCurTuple; /* The tuple currently being routed (not the same as the tuple in the
		     query, since operators may allocated new tuples!) 
		  */ 
  QueryListHandle mCurRouteQuery; //the query we are currently routing tuples for


  QueryResult mResult, mEnqResult; //result we are currently delivering or enqueueing
  short mOutputCount;
  short mFetchTries;
  AllocState mAllocState;

  short mOldRate; //previous clock rate

  QueryListHandle mCurSendingQuery;
  char mCurSendingField;
  char mCurSendingExpr;
  TOS_Msg mQmsg;

  bool mTriedAllocWaiting; //tried to create a new query, but allocation flag was true
  bool mTriedQueryRequest;  //received a request for query from a neighbor, but was buys

  unsigned char mXmitSlots;
  unsigned char mNumSenders;

  short mTicksThisInterval;
  short mMsgsThisInterval;

  bool mFixedComm;
  bool mSendQueryNextClock;  
  bool mSending;

  ParsedQuery *mLastQuery; //last query we fetched an attribute for

  enum {kDEBUG = 0};

  /* ----------------- Functions to modify pending mask --------------------- */
 
  void SET_READING_QUERY() {(mPendingMask |= READING_BIT); }
  void UNSET_READING_QUERY() { (mPendingMask &= (READING_BIT ^ 0xFFFF)); }
  bool IS_READING_QUERY() { return (mPendingMask & READING_BIT) != 0; }
  
  void SET_PARSING_QUERY() { (mPendingMask |= PARSING_BIT); }
  void UNSET_PARSING_QUERY() { (mPendingMask &= (PARSING_BIT ^ 0xFFFF)); }
  bool IS_PARSING_QUERY() { return (mPendingMask & PARSING_BIT) != 0; }
  
  bool IS_SPACE_ALLOCED() { return (mPendingMask & ALLOCED_BIT) != 0; }
  void UNSET_SPACE_ALLOCED() { (mPendingMask &= (ALLOCED_BIT ^ 0xFFFF)); }
  void SET_SPACE_ALLOCED() { (mPendingMask |= ALLOCED_BIT); }
  
  bool IS_FETCHING_ATTRIBUTE() { return (mPendingMask & FETCHING_BIT) != 0; }
  void UNSET_FETCHING_ATTRIBUTE() { (mPendingMask &= (FETCHING_BIT ^ 0xFFFF)); }
  void SET_FETCHING_ATTRIBUTE() { (mPendingMask |= FETCHING_BIT); }
 
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
  
  bool IS_SENDING_QUERY() { return (mPendingMask & SENDING_QUERY_BIT) != 0; }
  void UNSET_SENDING_QUERY() { (mPendingMask &= ( SENDING_QUERY_BIT ^ 0xFFFF)); }
  void SET_SENDING_QUERY() { (mPendingMask |= SENDING_QUERY_BIT); }
  
  bool IS_IN_QUERY_MSG() { return (mPendingMask & IN_QUERY_MSG_BIT) != 0; }
  void UNSET_IS_IN_QUERY_MSG() { (mPendingMask &= ( IN_QUERY_MSG_BIT ^ 0xFFFF)); }
  void SET_IS_IN_QUERY_MSG() { (mPendingMask |= IN_QUERY_MSG_BIT); }


  /* ----------------------------- Prototypes for Internal Routines ------------------------------ */

  void continueQuery(Handle *memory);
  bool addQueryField(TOS_MsgPtr msg);
  bool allocPendingQuery(MemoryCallback callback, Query *q);
  bool allocQuery(MemoryCallback callback, Query *q);
  void parsedCallback(Handle *memory);
  bool parseQuery(Query *q, ParsedQuery *pq);
  bool queryComplete(Query q);
  bool reallocQueryForTuple(MemoryCallback callback, QueryListHandle qlh);
  void resizedCallback(Handle *memory);
  void setSampleRate();
  short gcd(short a, short b);
  bool fetchNextAttr();
  TupleFieldDesc getNextQueryField(ParsedQuery **q);
  QueryListHandle nextQueryToRoute(QueryListHandle curQuery);
  bool routeToQuery(ParsedQuery *q, Tuple *t);
  Expr *nextExpr(ParsedQuery *q);
  bool getQuery(uint8_t qid, ParsedQuery **q);
  void startFetchingTuples();
  void resetTupleState(ParsedQuery *q);
  void fillInAttrVal(char *resultBuf, SchemaErrorNo errorNo);
  void aggregateResult(ParsedQuery *q, QueryResult *qr, char exprId);
  void computeOutputRate();
  TinyDBError dequeueMessage(TOS_Msg *msg);
  void sendWaitingMessages();
  TinyDBError removeQuery(uint8_t qid, BoolPtr success);
  TinyDBError forwardQuery(TOS_MsgPtr msg);

  void finishedBufferSetup();

  void keepRouting();

  //  void statusMessage(char *m);

  task void deliverTuplesTask();
  task void routeTask();
  task void sendQuery();


/* -----------------------------------------------------------------------------*/
/* --------------------------------- Functions ---------------------------------*/
/* -----------------------------------------------------------------------------*/

  /** Intialize the tuple router */
  command result_t StdControl.init() {
  
    call RadioControl.init();
    mPendingMask = 0;
    mCycleToSend = 0;
    mQs = NULL;
    mTail = NULL;
    mCurQuery = NULL;
    
    mMsgq.start = 0;
    mMsgq.end = 0;
    mMsgq.size = 0;
    
    mOldRate = 0;
    mOutputCount = 0;
    mFetchTries = 0; //hangs in fetch sometimes -- retry count
    
    mTriedAllocWaiting = FALSE;
    mTriedQueryRequest = FALSE;
    mFixedComm = FALSE;
    mNumSenders = 16; //something fairly long
    
    mSendQueryNextClock = FALSE;
    
    mTicksThisInterval = NUM_TICKS_PER_INTERVAL;
    mMsgsThisInterval = 0;

    mSending = FALSE;
    

    mAllocState = STATE_NOT_ALLOCING;

    mLastQuery = NULL;
    
    call ChildControl.init();
    call TimerControl.init();
    call Random.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call ChildControl.start();

    return SUCCESS;
  }


  command result_t StdControl.stop() {
    call ChildControl.stop();

    return SUCCESS;
  }

  /* --------------------------------- Query Handling ---------------------------------*/

  /** Message indicating the arrival of (part of) a query */
  event TOS_MsgPtr Network.querySub(TOS_MsgPtr msg) {
    QueryMessage *qmsg = (QueryMessage *)msg->data;
    ParsedQuery *q;
    short i;
    bool success;
    bool oldField = TRUE;


    //is a request to delete an existing query
    if (qmsg->msgType == DEL_MSG) {
      TinyDBError err;
      ParsedQuery *pq;
      bool isRoot;
      
      
      if (getQuery(qmsg->qid, &pq)) 
	isRoot = TOS_LOCAL_ADDRESS == pq->queryRoot;
      else
	isRoot = FALSE;

      call Leds.redOn();
      call Leds.greenOn();
      call Leds.yellowOn();
      err = removeQuery(qmsg->qid, &success);
      if (err != err_NoError)
	call signalError(err);

      if (success || isRoot) { //only forward if we know about the query, or if we're the root
	if (!IS_SENDING_MESSAGE()) {
	  mMsg = *msg;
	  SET_SENDING_MESSAGE();
	  if (call Network.sendQueryMessage(&mMsg) != err_NoError) {
	    UNSET_SENDING_MESSAGE();
	    call signalError(err_MSF_DelMsg);      
	  }
	}else
	  call signalError(err_MSF_DelMsgBusy);
      }
      return msg;
    }

    //otherwise, assume its an ADD_MSG, for now
    if (!IS_IN_QUERY_MSG()) { 
    
      if (!getQuery(qmsg->qid, &q)) { //ignore if we already know about this query 
	SET_IS_IN_QUERY_MSG();

	if (IS_READING_QUERY()) {
	  if (qmsg->qid != (**mCurQuery).qid) {
	    if (IS_SPACE_ALLOCED() || mTriedAllocWaiting) {
	      //query is alloced, but heard about a new one
	      //forget old one
	      if (IS_SPACE_ALLOCED()) call MemAlloc.free((Handle)mCurQuery);
	      UNSET_SPACE_ALLOCED();
	      UNSET_READING_QUERY();
	    } else {
	      mTriedAllocWaiting = TRUE;
	      UNSET_IS_IN_QUERY_MSG();
	      return msg; //waiting for query to be alloced -- dont interrupt
	    }
	  } else if (! IS_SPACE_ALLOCED()) {
	    UNSET_IS_IN_QUERY_MSG();
	    return msg; //failure -- space not alloced for this query yet!
	  }  else {  
	    oldField = addQueryField(msg);
	  }
	
	  //go ahead and forward this guy on, as long as it's new, or we're the root
	  if (!oldField || TOS_LOCAL_ADDRESS == qmsg->queryRoot)
	    forwardQuery(msg);
	}

	//note that we can fall through from previous clause
	if (!IS_READING_QUERY() /*&& !IS_SENDING_MESSAGE()*/) {
	
	  Query pq;
	
	
	  SET_READING_QUERY();
	  UNSET_SPACE_ALLOCED();
	  mTriedAllocWaiting = FALSE;
	  pq.qid = qmsg->qid;
	  pq.numFields=qmsg->numFields;
	  pq.numExprs=qmsg->numExprs;    
	  pq.epochDuration = qmsg->epochDuration;
	  pq.fromQid = qmsg->fromQid;
	  pq.bufferType = qmsg->bufferType;
	  pq.knownFields = 0;
	  pq.knownExprs = 0;
	  pq.queryRoot = qmsg->queryRoot;

	  for (i = qmsg->numFields; i < MAX_FIELDS; i++)
	    pq.knownFields |= (1 << i);
	  for (i = qmsg->numExprs; i < MAX_EXPRS; i++)
	    pq.knownExprs |= (1 << i);
	
	  dbg(DBG_USR1,"completeMask = %x, %x\n",pq.knownFields, pq.knownExprs);//fflush(stdout);
	
	  mMsg = *msg; //save a copy
	  //allocate space for query
	  allocPendingQuery(&continueQuery, &pq);
	}
      }  else if (TOS_LOCAL_ADDRESS == qmsg->queryRoot)  //forward on if we're the root
	forwardQuery(msg);
      UNSET_IS_IN_QUERY_MSG();
    }

    return msg;
  }
  
  /** Forward out a query message, setting errors as appropriate if the radio is already
      busy.

      Note, this uses the mMsg module variable.
      @param msg The message to send (a copy is made into mMsg, so the application can overwrite after this call)
      @return err_MSF_ForwardKnownQuery if message send failed, err_MSG_ForwardKnownQueryBusy if radio was busy
  */
  TinyDBError forwardQuery(TOS_MsgPtr msg) {
    TinyDBError err = err_NoError;
    if (!IS_SENDING_MESSAGE()) {
      mMsg = *msg;
      SET_SENDING_MESSAGE();
      if (call Network.sendQueryMessage(&mMsg) != err_NoError) {
	UNSET_SENDING_MESSAGE();
	err = err_MSF_ForwardKnownQuery;
	goto done;
      }
      
    } else
      err = err_MSF_ForwardKnownQueryBusy;

  done:
    if (err != err_NoError)
      call signalError(err);
    return err;

  }

  /** Continuation after query is successfully alloc'ed
      @param memory The newly allocated handle (must to be non-null)
  */
  void continueQuery(Handle *memory) {
    QueryMessage *qmsg = (QueryMessage *)(mMsg.data);
    short i; 

    mCurQuery = (Query **)*memory;
    (**mCurQuery).qid = qmsg->qid;
    (**mCurQuery).numFields=qmsg->numFields;
    (**mCurQuery).numExprs=qmsg->numExprs;    
    (**mCurQuery).epochDuration=qmsg->epochDuration;
    (**mCurQuery).fromQid = qmsg->fromQid;
    (**mCurQuery).bufferType = qmsg->bufferType;
    (**mCurQuery).queryRoot = qmsg->queryRoot;
    (**mCurQuery).knownFields = 0;
    (**mCurQuery).knownExprs = 0;

    if ((**mCurQuery).bufferType != kRADIO) {
      //special buffer info
      (**mCurQuery).hasBuf = FALSE;
      (**mCurQuery).buf.cmd.hasParam = FALSE;
    }
  
    dbg (DBG_USR1, "num fields = %d\n", qmsg->numFields);

    for (i = qmsg->numFields; i < MAX_FIELDS; i++)
      (**mCurQuery).knownFields |= (1 << i);
    for (i = qmsg->numExprs; i < MAX_EXPRS; i++)
      (**mCurQuery).knownExprs |= (1 << i);
  
    dbg (DBG_USR1, "completeMask = %x, %x\n",(**mCurQuery).knownFields, (**mCurQuery).knownExprs);

    SET_SPACE_ALLOCED();
    addQueryField(&mMsg);

    //now forward the message on
    forwardQuery(&mMsg);

  }

  /** Given a query message, add the corresponding
      field or expression to a partially completed query
      @return true iff we already knew about this field
      @param msg The query message 
  */
  bool addQueryField(TOS_MsgPtr msg) {
    QueryMessage *qmsg = (QueryMessage *)msg->data;
    bool knewAbout = FALSE;

    if (qmsg->type == kFIELD) {
      call QueryIntf.setField(*mCurQuery, (short)qmsg->idx, qmsg->u.field);
      knewAbout = (**mCurQuery).knownFields & (1 << qmsg->idx);
      (**mCurQuery).knownFields |= (1 << qmsg->idx);
      dbg (DBG_USR1,"Setting field idx %d\n",qmsg->idx); //fflush(stdout);
    } else if (qmsg->type == kEXPR) {
      qmsg->u.expr.opState = NULL; //make sure we clear this out
      call QueryIntf.setExpr(*mCurQuery, qmsg->idx, qmsg->u.expr);
      //call statusMessage(((char *)*mCurQuery) + 24);
      dbg (DBG_USR1, "Setting expr idx %d\n",qmsg->idx); //fflush(stdout);
      knewAbout = (**mCurQuery).knownExprs & (1 << qmsg->idx);
      (**mCurQuery).knownExprs |= (1 << qmsg->idx);
    } else if (qmsg->type == kBUF_MSG) {
      knewAbout = (**mCurQuery).hasBuf;
      (**mCurQuery).hasBuf = TRUE;
      (**mCurQuery).buf = qmsg->u.buf;
    }

    if (queryComplete(**mCurQuery)) {
      SET_PARSING_QUERY();

      //allocate a parsed query for this query, initialize it
      dbg(DBG_USR1,"Query is complete!\n");//fflush(stdout);

      //lock this down, since we'll be using it for awhile
      call MemAlloc.lock((Handle)mCurQuery);

      allocQuery(&parsedCallback, *mCurQuery);
    }
    return knewAbout;
  }

  /** Called when the buffer has been allocated */
  void finishedBufferSetup() {
    setSampleRate(); //adjust clock rate to be gcd of rate of all queries
    //all done
    UNSET_READING_QUERY();
    UNSET_PARSING_QUERY();
  }

  /** Continuation after parsed query is successfully alloc'ed
      NOTE: after we setup query, need to resize for tuple at end of query...
      @param memory Newly allocated handle for the parsed query
  */
  void parsedCallback(Handle *memory) {
    QueryListHandle h = (QueryListHandle)*memory;  //this has already been allocated
    bool success;
    Expr e;

    dbg(DBG_USR1,"in parsed callback \n");//fflush(stdout);

    e = call QueryIntf.getExpr(*mCurQuery, 0);
    call MemAlloc.lock((Handle)h);
    dbg(DBG_USR1,"parsing \n");//fflush(stdout);
    if (!parseQuery(*mCurQuery, &((**h).q))) { //failure?
      call MemAlloc.unlock((Handle)h);
      (**h).q.qid = (**mCurQuery).qid;   //cleanup
      removeQuery((**h).q.qid, &success);
      call MemAlloc.free((Handle)mCurQuery);
      return;
    }
    dbg(DBG_USR1,"unlocking \n");//fflush(stdout);
    call MemAlloc.unlock((Handle)h);
    //locked this earlier
    call MemAlloc.unlock((Handle)mCurQuery);
    call MemAlloc.free((Handle)mCurQuery);
    dbg(DBG_USR1,"finished, now resizing\n");//fflush(stdout);

    reallocQueryForTuple(&resizedCallback, (QueryListHandle)h);
    
  }
  
  /** Continuation after the query is realloced to include space for a tuple
      @param memory Resized parsed query 
  */
  void resizedCallback(Handle *memory) {
    QueryListHandle h = (QueryListHandle)*memory;  //this has already been allocated
    ParsedQuery *pq = &((**h).q);
    bool pending = FALSE, success;
    TinyDBError err;

    dbg(DBG_USR1,"finished with resizing\n");//fflush(stdout);
    

    //set up the output buffer for this query

    
    switch (pq->bufferType) {
    case kRADIO:
      pq->bufferId = kRADIO_BUFFER;
      break;
    case kRAM: 
      {
	RamBufInfo ram = pq->buf.ram;
	

	err = call DBBuffer.nextUnusedBuffer(&pq->bufferId);
	if (err == err_NoError) {
	  err = call DBBuffer.alloc(pq->bufferId, kRAM, ram.numRows, ram.policy, pq , &pending, 0);
	}
	if (err != err_NoError) {
	  call signalError(err);
	  goto fail;
	}
      }
      break;
    case kCOMMAND: 
      {
	long cmd_param;
	uint8_t *cmd_buf = (uint8_t *)&cmd_param;
	CommandDescPtr cmd = call CommandUse.getCommand(pq->buf.cmd.name);
	
	if (cmd == NULL) {
	  call signalError(err_UnknownCommand);
	  goto fail;
	}
	
	cmd_buf[0] = cmd->idx;
	*(short *)(&cmd_buf[1]) = pq->buf.cmd.param;
	
	err = call DBBuffer.nextUnusedBuffer(&pq->bufferId);
	if (err == err_NoError)
	  err = call DBBuffer.alloc(pq->bufferId, kCOMMAND, 0, 0, NULL, &pending, cmd_param);
	if (err != err_NoError) { 
	  call signalError(err);
	  goto fail;
	}
      }
      break;
    default:
	call signalError(err_UnknownError);
	goto fail;
    }
    
    if (!pending) finishedBufferSetup();
    return;

  fail:
    
    removeQuery(pq->qid, &success);
  
  }

  /** Remove a query from the tuple router 

     @param qid The query to remove
     @param success Set TRUE if the query was succesfully removed, FALSE if the query
     couldn't be found or an error occurred.
     @return err_RemoveRouterFailed if router is in a state such that the
     query may be use, err_NoError otherwise.
  */
  TinyDBError removeQuery(uint8_t qid, BoolPtr success) {
    //remove information about the specified query id
    QueryListHandle curq;
    QueryListHandle last = NULL;

    *success = FALSE;

    if (IS_FETCHING_ATTRIBUTE() || IS_ROUTING_TUPLES() || 
	IS_DELIVERING_TUPLES() || IS_SENDING_MESSAGE()) return err_RemoveFailedRouterBusy;

    curq = mQs;
    while (curq != NULL) {
      if ((**curq).q.qid == qid) {       //this is the one to remove
	*success = TRUE;
	if (last != NULL) {       //not the first element
	  (**last).next = (**curq).next;
	} else {  //the first element
	  mQs = (QueryListHandle)(**curq).next;
	}

	if (mTail == curq) //was the last element
	  mTail = last; //ok if this is also the first element, since this will now be NULL
	if (mQs == NULL) { //no more queries, stop the clock!
	  call Timer.stop();
	  mOldRate = 0; //clear rate info...
	  call Leds.redOff();
	  call Leds.yellowOff();
	  call Leds.greenOff();
	} else 
	  computeOutputRate(); //adjust number of comm slots

	//notify children (e.g. AGG_OPERATOR) that this query is complete
	signal QueryProcessor.queryComplete(&(**curq).q);
	call MemAlloc.free((Handle)curq);


	return err_NoError;
      } else {
	last = curq;
	curq = (QueryListHandle)(**curq).next;
      }
    }
    return err_NoError; //not an error if query doesn't exist

  }

  /** Send mCurSendingQuery to a neighbor (we assume the query is in
   mCurSendingQuery because the sending must be done in multiple phases)
  */
  task void sendQuery() {
    //this task assembles the query one field / attribute at a time,
    //send each out in a separate radio message (just like they are delivered).
    //task is resceduled after SEND_DONE_EVENT fires
    QueryListHandle curq = mCurSendingQuery;
    QueryMessage *qmsg = (QueryMessage *)mQmsg.data;

    
    if (mCurSendingField < (**curq).q.numFields) {
      char fieldId = call ParsedQueryIntf.getFieldId(&(**curq).q, (short)mCurSendingField);

      qmsg->msgType = ADD_MSG;
      qmsg->qid = (**curq).q.qid;
      qmsg->numFields = (**curq).q.numFields;
      qmsg->numExprs = (**curq).q.numExprs;
      qmsg->fromQid = (**curq).q.fromQid;
      qmsg->epochDuration = (**curq).q.epochDuration;
      qmsg->bufferType = (**curq).q.bufferType;
      qmsg->queryRoot = (**curq).q.queryRoot;

      mCurSendingField++;
      if (!(call ParsedQueryIntf.queryFieldIsNull(fieldId))) {
	AttrDescPtr attr = call AttrUse.getAttrById(fieldId);

	qmsg->type = kFIELD;
	qmsg->idx = mCurSendingField-1;
	strcpy(qmsg->u.field.name, attr->name);
	
	call Leds.greenToggle();

	if (!IS_SENDING_MESSAGE()) {
	  SET_SENDING_MESSAGE();
	
	  if (call Network.sendQueryMessage(&mQmsg) != err_NoError)
	    UNSET_SENDING_MESSAGE();
	}

      } else {
	//field is null (we don't know what it's name should be) -- do the next one
	post sendQuery();


      }
    } else if (mCurSendingExpr < (**curq).q.numExprs) {
      Expr e = call ParsedQueryIntf.getExpr(&(**curq).q, mCurSendingExpr);
      mCurSendingExpr++;

      qmsg->type = kEXPR;
      qmsg->idx = mCurSendingExpr-1;
      qmsg->u.expr = e; //this could be bad! (extra bytes on end of expression might overwrite memory)

      call Leds.redToggle();

      if (!IS_SENDING_MESSAGE()) {
	SET_SENDING_MESSAGE();
	
	if (call Network.sendQueryMessage(&mQmsg) != err_NoError)
	  UNSET_SENDING_MESSAGE();
      }

    } else if ((**curq).q.bufferType != kRADIO) { //send the command that should be invoked in response to this query
      qmsg->type =  kBUF_MSG;
      qmsg->u.buf = (**curq).q.buf;

      call Leds.yellowToggle();

      if (!IS_SENDING_MESSAGE()) {
	SET_SENDING_MESSAGE();
	
	if (call Network.sendQueryMessage(&mQmsg) != err_NoError)
	  UNSET_SENDING_MESSAGE();
      }


    }
    else {
      UNSET_SENDING_QUERY();
    }
    
  
  }


  /** Message indicating neighbor requested a query from us 
      If we know about the query, and aren't otherwise
      occupied with sending / routing, send the query back

      @param The QueryResultMessage from the neighbor
   */
  event TOS_MsgPtr Network.queryRequestSub(TOS_MsgPtr msg) {
    QueryRequestMessage *qmsg = (QueryRequestMessage *)(msg->data);
    char qid = qmsg->qid;

    QueryListHandle curq;
  
    //triedQueryRequest flag set to true when a neighbor requests a 
    //query but we're sending another one

    //if we get another such request, we'll abort the current one (ick)
    if (!IS_SENDING_MESSAGE() && (!IS_SENDING_QUERY() || mTriedQueryRequest)) {
      mTriedQueryRequest = FALSE;
      SET_SENDING_QUERY();
    } else {
      mTriedQueryRequest = TRUE;
      return msg;
    }
  

    curq = mQs;
    while (curq != NULL) {

      if ((**curq).q.qid == qid) {
	//the query we're supposed to send
	mCurSendingField = 0;
	mCurSendingExpr = 0;
	mCurSendingQuery = curq;
	post sendQuery();

	break;
      }
      curq = (QueryListHandle)(**curq).next;
    }
  
    return msg;
  }


  /** A message not directly addressed to us that we overhead
      Use this for time synchronization with our parent, and
      to snoop on queries.

      @param msg The message
      @param amId The amid of the message
      @param isParent If the message is from our parent 
  */
  event TOS_MsgPtr Network.snoopedSub(TOS_MsgPtr msg, uint8_t amId, bool isParent) {
    ParsedQuery *q;
    char qid;
    DbMsgHdr *hdr = (DbMsgHdr *)msg->data;
    //check and see if it has information about a query we haven't head before
    //don't snoop on queries from the root (it wont reply)!

    mMsgsThisInterval++;
    if (amId == kDATA_MESSAGE_ID && hdr->senderid != 0) {
      QueryRequestMessage *qreq = (QueryRequestMessage *)mMsg.data;

      qid = call QueryResultIntf.queryIdFromMsg((char *)msg->data);
      //is this a query we've never heard of before?

      if (!getQuery(qid, &q)) {
	qreq->qid = qid;
	if (!IS_SENDING_MESSAGE()) {
	  SET_SENDING_MESSAGE();
	  if (call Network.sendQueryRequest(&mMsg, hdr->senderid) != err_NoError)
	    UNSET_SENDING_MESSAGE();
	}
      }
    }

    //did this message come from our parent?

    if (isParent) {
      QueryResult qr;

      //epoch sync with parent
      qid = call QueryResultIntf.queryIdFromMsg((char *)msg->data);


      if (getQuery(qid, &q)) {
	call QueryResultIntf.fromMsgBytes((char *)msg->data, &qr, q);
	if (qr.epoch > q->currentEpoch + 1) //make sure epoch is monotonically increasing;  off by one OK?
	  q->currentEpoch = qr.epoch;
	if (hdr->timeRemaining != 0xFF) {
	  if (q->clockCount > hdr->timeRemaining + 1 ||
	      q->clockCount < hdr->timeRemaining - 1) 
	    {
	      q->clockCount = (q->clockCount & 0xFF00) | hdr->timeRemaining;
	    }
	}
      }

      // Each node now estimates its local neighborhood size (so we don't do the following)
      //      mNumSenders = hdr->xmitSlots;
    }

  
    return msg;
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
  event TOS_MsgPtr Network.dataSub(TOS_MsgPtr msg) {
    QueryResult qr;
    ParsedQuery *q;
    short i;
    bool gotAgg = FALSE;
    bool pending;


    call Leds.greenToggle();
    mMsgsThisInterval++;

    if (getQuery(call QueryResultIntf.queryIdFromMsg((char *)msg->data), &q)) {
      //if this query is going to be deleted, reset the counter until
      //deletion since we're still hearing neighbors results about it...
      if (q->markedForDeletion) {
	q->markedForDeletion = EPOCHS_TIL_DELETION;
      }
      call QueryResultIntf.fromMsgBytes((char *)msg->data, &qr, q);
      //now determine where to route this result to -- either an
      //aggregation operator or to our parent

      for (i = 0; i < q->numExprs; i++) {
	Expr e = call ParsedQueryIntf.getExpr(q, i);
	if (e.opType != kSEL) {
	  gotAgg = TRUE;
	  break;
	}
      }
      if (!gotAgg) { //didn't give to an aggregate, so just pass it on...
	TinyDBError err;

      	err = call DBBuffer.enqueue(q->bufferId, (QueryResultPtr)(msg->data + sizeof(DbMsgHdr)), &pending, q);
	
	//ignore result buffer busy items for now, since they just mean
	//we can't keep up with the sample rate the user is requested , but we 
	//shouldn't abort
	if (err != err_ResultBufferBusy && err != err_NoError) call signalError(err);
      } else { //got an agg -- do all the aggregation expressions
	mResult = qr;
	if (!IS_AGGREGATING_RESULT()) //don't double aggregate!
	  aggregateResult(q, &mResult, 0);
      }
    } else {
      signal Network.snoopedSub(msg,kDATA_MESSAGE_ID, FALSE);
      //    statusMessage("unknown neighbor q!");
    }

    return msg;
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



  /* --------------------------------- Timer Events ---------------------------------*/

  /** Adjust the rate that the main tuple router clock fires at based
      on EPOCH DURATION of all of the queries that are currently installed
  */
  void setSampleRate() {
    QueryListHandle qlh;
    short rate = -1;
    bool prev;


    //walk through queries, choose lowest sample rate
/*      qlh = mQs; */
/*      while (qlh != NULL) { */
/*        if (rate == -1)  */
/*  	rate = (**qlh).q.epochDuration; */
/*        else  */
/*  	rate = gcd((**qlh).q.epochDuration,rate); */
/*        qlh = (QueryListHandle)(**qlh).next; */
/*      } */
  
/*      //throttle rate to maximum */
/*      if (rate <= MIN_SAMPLE_RATE) { */
/*        //    rate = gcd(MIN_SAMPLE_RATE,rate); */
/*        rate = MIN_SAMPLE_RATE; */
/*      } */
/*      dbg(DBG_USR1,"rate = %d\n", rate); //fflush(stdout); */


  
    //HACK
    rate = 32; //hardcode!
    //now set the rate at which we have to deliver tuples to each query
    //as a multiple of this rate
    qlh = mQs;

    while (qlh != NULL) {
      if ((**qlh).q.epochDuration == kONE_SHOT) { //read it fast!
	(**qlh).q.clocksPerSample = 16;
	(**qlh).q.curResult = 0;
      } else
	(**qlh).q.clocksPerSample = (**qlh).q.epochDuration / rate;
      

      prev = call Interrupt.disable();
      (**qlh).q.clockCount = (**qlh).q.clocksPerSample; //reset counter
      if (prev) call Interrupt.enable();


      qlh = (QueryListHandle)(**qlh).next;
    }


    //rate is now the number of milliseconds between clock ticks
    //need to set the clock appropriately
    /*    if (rate < 255) { */
    /*      TOS_CALL_COMMAND(CLOCK_INIT)(rate, ONE_MS_CLOCK_CONST); */
    /*    } else { */
    /*      rate >>= 3; */
    /*      rate += 1; */
    /*      rate &= 0x00FF; */
    /*      TOS_CALL_COMMAND(CLOCK_INIT)(rate, EIGHT_MS_CLOCK_CONST); */
    /*    } */

    if (rate != mOldRate) { //restart the clock if rate changed
      mOldRate = rate;
      //WARNING: is this needed?
      //      call Timer.init();
      //stop timer 0
      //make this a critical section too -- if a timer event goes off while this is happening, who knows what that means?
      prev = call Interrupt.disable();
      call Timer.stop();
      if (prev) call Interrupt.enable();

      //restart it at the new rate
      //TOS_CALL_COMMAND(TUPLE_ROUTER_TIMER_START)(0,0,32); //timer for outputting results
      //TOS_CALL_COMMAND(TUPLE_ROUTER_TIMER_START)(1,0,rate); //timer for outputting results
      
      call Timer.start(TIMER_REPEAT, rate);
    }
    computeOutputRate();
  }

  /** Determine how many communication slots there are in the
   shortest duration query -- this will determine how long we can 
   afford to maximally wait before sending a result.
  */
  void computeOutputRate() {
    QueryListHandle qlh = mQs;
    short minSlots = 0x7FFF;

    
    while (qlh != NULL) {
      if (minSlots > (**qlh).q.clocksPerSample)
	minSlots = (**qlh).q.clocksPerSample;

      qlh = (QueryListHandle)(**qlh).next;
    }
    
    mXmitSlots = minSlots;
    
  }


  /** Find the GCD of two non-negative integers
      @param a The first integer
      @param b The secnd integer
      @return the GCD of a and b
  */
  short gcd(short a, short b) {
    short r = -1, temp;

    if (a > b) {
      temp = a;
      a = b;
      b = temp;
    }
  
    while (TRUE) {
      r = b % a;
      if (r == 0) break;
      b = a;
      a = r;
    }

    return a;
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
*/
  event result_t Timer.fired() {
    dbg(DBG_USR1,"IN CLOCK \n"); //fflush(stdout);
    //test to see if we're already sampling, in which case we better
    //not reinvoke sampling!

    mTicksThisInterval--;
    if (mTicksThisInterval <= 0) {
      //numSenders is used to determine the backoff period between message sends
      //xmitSlots tracks the epoch duration of the shortest query in clock ticks
      //msgsThisInterval is the number of messages heard during the last NUM_TICKS_PER_INTERVAL clock ticks
      //idea here is that we want to backoff more if :
      // 1) there is more network traffic
      // 2) there is more time between epochs
      mNumSenders = ((((mMsgsThisInterval + 1) * 2) * mXmitSlots) >> 7); //(2^7 == 128 == NUM_TICKS_THIS_INTERVAL)
      mMsgsThisInterval = 0;
      mTicksThisInterval = NUM_TICKS_PER_INTERVAL;
    }



    sendWaitingMessages();
    
    if (mSendQueryNextClock) {
      mSendQueryNextClock = FALSE;
      post sendQuery();
    }

    if (IS_FETCHING_ATTRIBUTE()) {
      call statusMessage("fetching");
      mFetchTries++;
      //so we can escape a blocked fetch
      if (mFetchTries < UDF_WAIT_LOOP)
	return SUCCESS;
      else
	UNSET_FETCHING_ATTRIBUTE();
    } else if (IS_ROUTING_TUPLES()) {
      call statusMessage("routing");
      return SUCCESS;
    } else if ( IS_DELIVERING_TUPLES()) { 
      call statusMessage("delivering");
      return SUCCESS;
    }  else if (IS_AGGREGATING_RESULT()) {
      call statusMessage("aggregating");
      return SUCCESS;
    }



    //Since all transmission now happens through the message queue, I think
    //its ok to proceed even if we are currently sending a message...
    //else if(IS_SENDING_MESSAGE())  {
    //    statusMessage("sending");
    //    return;
    //  }

    mFetchTries = 0;


    //  TOS_SIGNAL_EVENT(TUPLE_ROUTER_NEW_EPOCH)();
    mCurRouteQuery = NULL; //find the first query we need to deliver results for
    mCurExpr = -1;
    dbg(DBG_USR1,"POSTING TASK.");//fflush(stdout);

    post deliverTuplesTask();
    return SUCCESS;
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
    dbg(DBG_USR1,"IN DELIVER TUPLES TASK.\n");//fflush(stdout);
    SET_DELIVERING_TUPLES();
    
    mCurRouteQuery = nextQueryToRoute(mCurRouteQuery); 
    if (mCurRouteQuery != NULL) {

      ParsedQuery *pq = &(**mCurRouteQuery).q;
      Expr *e = nextExpr(pq);
      TinyDBError err = err_NoError;
      QueryResult qr;
      uint16_t size;

      //init success
      success = (TOS_LOCAL_ADDRESS == pq->queryRoot)? FALSE : TRUE; //don't deliver tuples for root

      call QueryResultIntf.initQueryResult(&qr);
      // stamp current epoch number
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
      if (didAgg && err == err_NoError && call QueryResultIntf.numRecords(&qr,pq) > 0) {
	//enqueue all the results from this aggregate
	//err = call RadioQueue.enqueue((const char *)&mResult, DATA_LENGTH-sizeof(DbMsgHdr));

	mEnqResult = qr;

	err = call DBBuffer.enqueue(pq->bufferId, &mEnqResult, &pending, pq);
	//ignore result buffer busy items for now, since they just mean
	//we can't keep up with the sample rate the user is requested , but we 
	//shouldn't abort
	if (err != err_ResultBufferBusy && err !=  err_NoError) 
	  call signalError(err);
      }
      //just a selection query -- enqueue appropriate results
      if (success && !didAgg) {
	
	mEnqResult = qr;

	call QueryResultIntf.fromTuple( &mEnqResult, pq , call ParsedQueryIntf.getTuplePtr(pq));
	//err = call RadioQueue.enqueue((const char *)&mResult, DATA_LENGTH-sizeof(DbMsgHdr));
	
	err = call DBBuffer.enqueue(pq->bufferId, &mEnqResult, &pending, pq);
	if (err != err_ResultBufferBusy && err !=  err_NoError) {
	  call signalError(err);
	}
      }

      pq->clockCount = pq->clocksPerSample; //reschedule this query

      //one shot queries may have finished scanning their buffer
      if (pq->fromQid != kNO_QUERY && pq->epochDuration == kONE_SHOT) {
	uint8_t fromBuf;

	err = call DBBuffer.qidToBuffer(pq->fromQid, &fromBuf);
	//stop queries that have scanned the entire buffer
	err = call DBBuffer.size(fromBuf, &size);
	if (err != err_NoError || pq->curResult++ >= size) {
	  //bool ok,prev;

	  //prev = call Interrupt.disable();	  
	  //UNSET_DELIVERING_TUPLES();
	  pq->markedForDeletion = EPOCHS_TIL_DELETION; //we need to destroy this query asap
	  //removeQuery(pq->qid, &ok);
	  //SET_DELIVERING_TUPLES();
	  //if (prev) call Interrupt.enable();	  
	}
      }

      

      //send tuples for next query
      if (!pending) post deliverTuplesTask();
      mCurExpr = -1; //reset for next query

    } else {
      UNSET_DELIVERING_TUPLES(); //now that tuples from last epoch are delivered, start fetching
                                //new tuples
      dbg(DBG_USR1,"FETCTHING TUPLES\n"); //fflush(stdout);

      startFetchingTuples();
    }
  }

  /** Called from the main timer loop -- task that drains
      the internal message queue.

      Uses mOutputCount to track the time until the next
      message should be sent.
  */
  void sendWaitingMessages() {
    if (mOutputCount > 0) {
      mOutputCount--;
    }

        
    if (mOutputCount <= 0) {

      
      TinyDBError err = dequeueMessage(&mMsg);
      DbMsgHdr *hdr;
      ParsedQuery *q;

      if (err == err_NoError) {
	getQuery(call QueryResultIntf.queryIdFromMsg((char *)mMsg.data), &q);
	call Leds.redToggle();
	      
	hdr = (DbMsgHdr *)mMsg.data;
	//hdr->xmitSlots = mNumSenders;
	if (q != NULL)
	  hdr->timeRemaining = (unsigned char)(q->clockCount & 0x00FF);
	else
	  hdr->timeRemaining = 0xFF;
	
	if (!IS_SENDING_MESSAGE()) {
	  SET_SENDING_MESSAGE();
	  if (call Network.sendDataMessage(&mMsg) != err_NoError) {
	    UNSET_SENDING_MESSAGE();
	    call signalError(err_MSF_SendWaiting);
	  }
	} else {
	  call signalError(err_MSF_SendWaitingBusy);
	}
	//schedule the next result to deliver
	if (TOS_LOCAL_ADDRESS == q->queryRoot) {
	  mOutputCount = 4;
	} else {
	  if (mFixedComm) {
	    mOutputCount = TOS_LOCAL_ADDRESS * 2;
	  }	else {
	    mOutputCount = max(4,(((call Random.rand() & 0x7FFF) % 
			     ((mNumSenders >> 1)+1)) << 1)); 
	  }
	  //mOutputCount = 16;
	}
      } else if (err != err_NoMoreResults)
	call signalError(err);
    }
  }

  /** Event that's signalled when a send is complete */
  event result_t Network.outputDone(TOS_MsgPtr msg, uint8_t amId) {

    if (IS_SENDING_MESSAGE() ) {
      UNSET_SENDING_MESSAGE();



      if (/*msg == &mQmsg &&*/ IS_SENDING_QUERY()) {

	mSendQueryNextClock = TRUE;
      } 

    }

    return SUCCESS;

  }


  void startFetchingTuples() {
    QueryListHandle qlh = mQs;
    bool mustSample = FALSE;


    //update queries, determine if any needs to sample data this epoch
    while (qlh != NULL) {
      //reset queries that just restarted
      if ((**qlh).q.clocksPerSample > 0 && (**qlh).q.clockCount == (**qlh).q.clocksPerSample) {
	resetTupleState(&(**qlh).q); //clear it out
      }
      if ((**qlh).q.clocksPerSample > 0 && --(**qlh).q.clockCount <= 0) {
	call Leds.yellowToggle();
	if ((**qlh).q.markedForDeletion > 0) {
	  if (--(**qlh).q.markedForDeletion == 0) { //delete the query
	    bool success;
	    removeQuery((**qlh).q.qid, &success);
	  } 
	  (**qlh).q.clockCount = (**qlh).q.clocksPerSample; // just reschedule this query...
	} else {
	  //only actually process local tuples if we're not the root.
	  if ((**qlh).q.queryRoot != TOS_LOCAL_ADDRESS) mustSample = TRUE;
	  (**qlh).q.currentEpoch++;
	}
	break;
      }
      qlh = (QueryListHandle)(**qlh).next;
    }

    if (mustSample) {

      fetchNextAttr();
    }
  

  }

  void resetTupleState(ParsedQuery *q) {
    short i;
    Expr *e;

    //clear out this tuple
    call TupleIntf.tupleInit(q,call ParsedQueryIntf.getTuplePtr(q));
    for (i = 0; i < q->numExprs; i++) {
      e = call ParsedQueryIntf.getExprPtr(q, i);
      call AggOperator.endOfEpoch(q, e);
    }
  }

  /* --------------------------------- Tuple Building Routines ---------------------------------*/

  /** Fetch the next needed attribute, and 
      @return TRUE if an attribute was found and (possibly)
      more attribute exist.  

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
    TinyDBError err;
    char *resultBuf;
    ParsedQuery *q;
    short i, fieldId = -1;
    bool pending;
    TinyDBError tdberr;
    uint8_t bufId;

    dbg(DBG_USR1,"in fetchNextAttr\n"); //fflush(stdout);

    //at least one query needs samples -- but which ones?
    fieldDesc = getNextQueryField(&q);



    if (fieldDesc.isNull == FALSE) {

      //get the result that we'll disassemble if this query fetches its
      //result from a buffer
      if ((mLastQuery == NULL || mLastQuery != q) && q->fromQid != kNO_QUERY) {
	mLastQuery = q;
	tdberr = call DBBuffer.qidToBuffer(q->fromQid, &bufId); 
	if (tdberr != err_NoError) return FALSE; 
	if (q->epochDuration == kONE_SHOT) {
	  tdberr = call DBBuffer.getResult(bufId, q->curResult, &mResult, &pending); 
	} else
	  tdberr = call DBBuffer.peek(bufId, &mResult, &pending); 
	if (tdberr == err_ResultBufferBusy) return TRUE; //try again?
	if (tdberr != err_NoError) return FALSE; 
      }


      if (q->fromQid == kNO_QUERY) {
	  queryField = fieldDesc.u.attr;
	  mFetchingFieldId = queryField->idx;
	  //figure out this field's local query index


	//CAREFUL:  Invoke command can return very quickly, such that
	//we best have set this value before we call it, since if we do it
	//afterwards, it may completion before we have a chance to set the flag
	//So, we have to make sure to unset the flag below, when needed.
	SET_FETCHING_ATTRIBUTE();


	for (i = 0; i < q->numFields;i++) {
	    if (q->queryToSchemaFieldMap[i] == queryField->idx)
		fieldId = i;
	}
	if (fieldId != -1) {
	    // use pre-allocated tuple space
	    resultBuf = call TupleIntf.getFieldPtr(q, call ParsedQueryIntf.getTuplePtr(q), fieldId);
	    if (call AttrUse.getAttrValue(queryField->name, resultBuf, 
					  &errorNo) == SUCCESS) {
		if (errorNo != SCHEMA_RESULT_PENDING)
		    fillInAttrVal(resultBuf, errorNo);
		if (errorNo != SCHEMA_ERROR)
		    return TRUE;
	    }
	}

      } else if (q->fromQid != kNO_QUERY) {
	  ParsedQuery **fromPq = NULL;
	  Tuple *t = call ParsedQueryIntf.getTuplePtr(q);

	  
  	  resultBuf = call TupleIntf.getFieldPtr(q,t, fieldDesc.u.tupleIdx);
	  err = call DBBuffer.qidToBuffer(q->fromQid, &bufId); 
	  if (err != err_NoError) return FALSE; 
  	  fromPq = call DBBuffer.getSchema(bufId);  
	  err = call ParsedQueryIntf.getResultField(*fromPq, 
						    &mResult, 
						    q->queryToSchemaFieldMap[fieldDesc.u.tupleIdx], 
						    resultBuf);
	  //already wrote the data there, but need to twiddle bits

	  //these two lines instead of fillInAttrVal() like above above...
	  call TupleIntf.setField(q, t, fieldDesc.u.tupleIdx, resultBuf); 
	  keepRouting();
      }
    }
    mLastQuery = NULL;
    return FALSE;
  }

  /** Scan queries, looking for fields that haven't been defined yet */
  TupleFieldDesc getNextQueryField(ParsedQuery **pq) {
    QueryListHandle qlh = mQs;
    AttrDescPtr attr = NULL; 
    TupleFieldDesc d;
    TinyDBError err;
    uint8_t idx;

    d.isNull = TRUE;

    while (qlh != NULL) {
      if ((**qlh).q.clocksPerSample > 0 &&  (**qlh).q.clockCount <= 0) { //is this query's time up?
	Tuple *t = call ParsedQueryIntf.getTuplePtr(&(**qlh).q);
	ParsedQuery *q = &(**qlh).q;
	dbg(DBG_USR1,"q->qid = %d, t->qid = %d, t->numFields = %d\n", q->qid, t->qid, t->numFields);
	dbg(DBG_USR1,"calling GET_NEXT_QUERY_FIELD\n"); //fflush(stdout); 
	
	if (q->fromQid == kNO_QUERY) {
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
	SET_ROUTING_TUPLES();
	//no more attributes to fetch, start processing tuples....
	mCurRouteQuery = nextQueryToRoute(NULL);
	mCurExpr = -1;
	
	post routeTask();
      }
  }

  /** Set the value of field mFetchingFieldId (which is the id of an attribute
      in the schema) in all queries that need the field to the data contained
      in resultBuf
    
      @param resultBuf The data to be placed in the field
      @param errorNo An error (if any) returned by the schema in response to the getAttr command
      that generated resultBuf
  */
  void fillInAttrVal(char *resultBuf, SchemaErrorNo errorNo)
    {
      short id = mFetchingFieldId; //the mote-specific field this command has data for
      short i;
      QueryListHandle qlh = mQs;

      dbg(DBG_USR1,"GOT DATA, COMMAND data = %d, errorNo = %d\n", *(short *)resultBuf, errorNo);

      while (qlh != NULL) {
	if ((**qlh).q.clocksPerSample > 0 &&  (**qlh).q.clockCount <= 0) { //this query needs data
	  ParsedQuery *q = &(**qlh).q;
	  Tuple *t = call ParsedQueryIntf.getTuplePtr(&(**qlh).q);
	  for (i = 0; i < q->numFields; i++) {
	    if (q->queryToSchemaFieldMap[i] == id) { //the correct field in this query
	      call TupleIntf.setField(q, t, i, resultBuf);

	      dbg(DBG_USR1,"SET QUERY FIELD : %d\n", i);
	    }
	  }
	}
	qlh = (QueryListHandle)(**qlh).next;
      }
      keepRouting();
    }

  /** Completion event after some data was fetched
      Params should be filled out with the result of the command
      @param name The name of the attribute that was fetched
      @param resultBuf The value of the attribute
      @param errorNo Errors that occurred while fetching the result
  */
  event result_t AttrUse.getAttrDone(char *name, char *resultBuf, SchemaErrorNo errorNo) 
    {
      fillInAttrVal(resultBuf, errorNo);
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
      curQuery = mQs;
    } else 
      curQuery = (QueryListHandle)(**curQuery).next;

    while (curQuery != NULL) {
      if ((**curQuery).q.clocksPerSample > 0 && (**curQuery).q.clockCount <= 0) { //this query is ready to go
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

  /* --------------------------------- Query Utility Routines ---------------------------------*/
  /** @return TRUE if the query exists.
      @param qid The query to fetch
      @param q Will point to the query pointer upon return if the return
      value is TRUE.
  */
  bool getQuery(uint8_t qid, ParsedQuery **q) {
    QueryListHandle curq;

    curq = mQs;
    while (curq != NULL) {
      if ((**curq).q.qid == qid) {
	*q = &(**curq).q;
	return TRUE;
      } else
	curq = (QueryListHandle)(**curq).next;
    }
    return FALSE;
  }

  command ParsedQueryPtr QueryProcessor.getQueryCmd(uint8_t qid) {
    ParsedQueryPtr pq;
    if (getQuery(qid,&pq))
      return pq;
    else
      return NULL;
  }

  /** Given a processor message return the owner (origninating node) of the query, or
      -1 if the query is unknown or the message is a query processor message.

      @param msg The query for which the root is sought
  */
  command short QueryProcessor.msgToQueryRoot(TOS_MsgPtr msg) {
    uint8_t msgType = msg->type;
    uint8_t qid;
    short root;
    ParsedQueryPtr pq;
    

    if (msgType != kDATA_MESSAGE_ID && msgType != kQUERY_MESSAGE_ID && msgType != kQUERY_REQUEST_MESSAGE_ID)
      return -1;

    //hack :  assume first byte after header is query id!
    qid = (uint8_t)msg->data[sizeof(DbMsgHdr)];

    pq = call QueryProcessor.getQueryCmd(qid);

    if (pq == NULL) {
      root =  -1;
    }
    else {
      root =pq->queryRoot;
    }
    return root;
  }


  /** Given a query, parse it into pq
      @param q The query to convert
      @param pq The parsed query to fill in.  Assumes that
      pq has been allocated with ParsedQueryIntf.pqSize(q) bytes.
      @return TRUE if successful
  */
  bool parseQuery(Query *q, ParsedQuery *pq) {
    AttrDesc *attr;
    int i;
    uint8_t bufferId;
    ParsedQuery **fromPq = NULL;
    TinyDBError err;


    pq->qid = q->qid;
    pq->numFields = q->numFields;
    pq->numExprs = q->numExprs;
    pq->epochDuration = q->epochDuration;
    pq->fromQid = q->fromQid;
    pq->bufferType = q->bufferType;
    pq->bufferId = q->bufferId;
    pq->markedForDeletion = 0;
    pq->currentEpoch = 0;
    pq->buf = q->buf;
    pq->queryRoot = q->queryRoot;

    if ((uint8_t)pq->fromQid != kNO_QUERY) {

      err = call DBBuffer.qidToBuffer(pq->fromQid, &bufferId);
      if (err != err_NoError) return FALSE;
      fromPq = call DBBuffer.getSchema(bufferId);
      if (fromPq == NULL) return FALSE;
    }

    for (i = 0; i < q->numFields; i++) {
      Field f = call QueryIntf.getField(q,i);
      dbg(DBG_USR1,"Setting field %d (%s)\n", i, f.name);//fflush(stdout);

      if (pq->fromQid == kNO_QUERY) {
	attr = call AttrUse.getAttr(f.name);
	
	if (attr != NULL) {
	  pq->queryToSchemaFieldMap[i] = attr->idx;
	} else {
	  pq->queryToSchemaFieldMap[i] = NULL_QUERY_FIELD;
	}
      } else { //fromPq initialized above
	err = call ParsedQueryIntf.getResultId(*fromPq, &f, &pq->queryToSchemaFieldMap[i]);
	if (err != err_NoError)
	  pq->queryToSchemaFieldMap[i] = NULL_QUERY_FIELD;
      }
    }
    for (i = 0; i < q->numExprs; i++) {
      Expr e = call QueryIntf.getExpr(q,i);

      e.idx = i;
      dbg(DBG_USR1," e.opType = %d, e.opVal.field = %d, e.opVal.value = %d\n",
	      e.opType, e.ex.opval.field, e.ex.opval.value); //fflush(stdout);
      call ParsedQueryIntf.setExpr(pq, i, e);
      e = call ParsedQueryIntf.getExpr(pq,i);
      dbg(DBG_USR1," e.opType = %d, e.opVal.field = %d, e.opVal.value = %d\n",
	      e.opType, e.ex.opval.field, e.ex.opval.value); //fflush(stdout);
    }
    return TRUE;
  }


  /** Allocates space for a query, given a query with numExprs and numFields filled in
      @param q The query to allocate a query data structure for
      @param callback The callback to fire when the allocation is complete
      @return TRUE if the allocation was successfully initiated (e.g. a callback is expected)
  */
  bool allocPendingQuery(MemoryCallback callback, Query *q) {
    mAllocState = STATE_ALLOC_IN_FLIGHT_QUERY;
    mAllocCallback = callback;
    return call MemAlloc.allocate(&mTmpHandle, call QueryIntf.size(q));
  }

  /** Allocate space for a parsed query
      After request compltes, add the result to qs linked list, and then
      call callback.

      @param callback Callback fired once allocation is complete
      @param q The query to use to initialize the parsed query
      @return true if request succesfully made (e.g. a callback is expected)
  */
  bool allocQuery(MemoryCallback callback, Query *q) {
    short size = (sizeof(QueryListEl) - sizeof(ParsedQuery)) + call ParsedQueryIntf.baseSize(q);

    mAllocState = STATE_ALLOC_PARSED_QUERY;
    mAllocCallback = callback;
    
    return call MemAlloc.allocate((Handle *)&mTmpHandle, size);
  
  }

  /** Resize qlh to have space for tuple at the end */
  bool reallocQueryForTuple(MemoryCallback callback, QueryListHandle qlh) {
    ParsedQuery *q = &(**qlh).q;
    short size = call MemAlloc.size((Handle)(qlh)) + call TupleIntf.tupleSize(q);

    dbg(DBG_USR1,"resizing query for tuple to :  %d \n", size);//fflush(stdout);
    mAllocState = STATE_RESIZE_QUERY;
    mAllocCallback = callback;
    dbg(DBG_USR1,"set alloc state to %d\n", mAllocState);
    return call MemAlloc.reallocate((Handle)qlh, size);

  }

  /** Return TRUE if we've heard about all the fields for the specified query */
  bool queryComplete(Query q) {
    dbg(DBG_USR1,"completeMask = %x, %x\n",q.knownFields, q.knownExprs);//fflush(stdout);

    if (q.bufferType != kRADIO && !q.hasBuf) return FALSE;

    return (call QueryIntf.fieldsComplete(q) && call QueryIntf.exprsComplete(q));
  }

  /** "fixed communication" means that we transmit during a time slot
   proportional to our mote id, rather than learning about the neighborhood
   size from the root and choosing a random time slot based on that size
  */
  command result_t setFixedComm(bool fixed) {
    if (fixed) {
      call Leds.redOn();
    } else {
      call Leds.greenOn();
    }
    mFixedComm = fixed;
    return SUCCESS;
  }

  /* --------------------------------- Memory Callbacks ---------------------------------*/

  event result_t MemAlloc.allocComplete(Handle *handle, result_t complete) {
    bool prev;

    dbg(DBG_USR1,"in alloc complete\n");//fflush(stdout);
    if (mAllocState == STATE_NOT_ALLOCING) return SUCCESS; //not our allocation

    switch (mAllocState) {
    case STATE_ALLOC_PARSED_QUERY:
      mAllocState = STATE_NOT_ALLOCING; //not allocating any more
      if (complete) {

	QueryListHandle qlh = (QueryListHandle)*handle;
	dbg(DBG_USR1,"alloced parsed query \n");//fflush(stdout);
	(**qlh).next = NULL;
	(**qlh).q.clocksPerSample = 0; //make sure this query wont be fired yet
	//modifying this data structure is dangerous -- make sure timer thread doesnt run...
	prev = call Interrupt.disable();
	if (mTail == NULL) {
	  mTail = qlh;
	  mQs = qlh;
	} else {
	  (**mTail).next = (void **)qlh;
	  mTail = qlh;
	}
	if (prev) call Interrupt.enable();

	(*mAllocCallback)((Handle *)&mTail); //allow the application to continue
      } else
	call signalError(err_OutOfMemory);
      break;
    case STATE_ALLOC_IN_FLIGHT_QUERY:
      mAllocState = STATE_NOT_ALLOCING; //not allocating any more    
      if (complete) {

	dbg(DBG_USR1,"Alloced query.\n"); //fflush(stdout);

	(*mAllocCallback)(handle);
      } else
	call signalError(err_OutOfMemory);
      break;
    default:
      call signalError(err_UnknownAllocationState);
      break;
    }
    return SUCCESS;
  }

  event result_t MemAlloc.reallocComplete(Handle handle, result_t complete) {
    dbg(DBG_USR1,"in realloc complete, state = %d, resize = %d, not_alloc = %d\n",
	    mAllocState, STATE_RESIZE_QUERY, STATE_NOT_ALLOCING); //fflush(stdout);
    if (mAllocState == STATE_NOT_ALLOCING) return SUCCESS; //not our allocation
    if (mAllocState == STATE_RESIZE_QUERY) {
      mAllocState = STATE_NOT_ALLOCING; //not allocating any more
      if (complete)
	(*mAllocCallback)(&handle);
      else
	call signalError(err_OutOfMemory);
    }
    else
      call signalError(err_UnknownAllocationState);
    return SUCCESS;
  }

  event result_t MemAlloc.compactComplete() {
    return SUCCESS;
  }


  /* --------------------------------- Message Queuing ---------------------------------*/
  /** Copy the specified bytes into the message queue.  Messages are always data
      (tuple) messages.  Messages of more than DATA_LENGTH - sizeof(DbMsgHdr) bytes
      will be truncated.

      @param msg The data payload of the message to enqueue
      @param len The length (in bytes) of the data
      @return err_MessageSendFailed if the queue is full
  */
  command TinyDBError RadioQueue.enqueue(const char *msg, uint16_t len) {
    short slot;

    if (mMsgq.size == MSG_Q_LEN) return err_MessageBufferFull;
    slot = mMsgq.end++;
    if (mMsgq.end >= MSG_Q_LEN)
      mMsgq.end = 0;
    mMsgq.size++;

    if (len > DATA_LENGTH-sizeof(DbMsgHdr)) len = DATA_LENGTH-sizeof(DbMsgHdr);
    memcpy((char *)(mMsgq.msgs[slot].data) + sizeof(DbMsgHdr) ,(const char *)msg,len);

    //schedule result delivery if needed

    if (mOutputCount <= 0) {
      short newCount;
      bool prev;
      short root;
      ParsedQuery *pq;
      //schedule the next result to deliver

      

      //HACK -- assume data at 0 is the query id
      if (!getQuery((uint8_t)msg[0], &pq))
	root = 0;
      else
	root = pq->queryRoot;

      //NOTE -- this is weird if we're the root for some queries and not
      //others, since this schedule is a global schedule for all queries --
      //not sure what to do about this!
      if (TOS_LOCAL_ADDRESS == root) {
	newCount = 4;
      } else {
	if (mFixedComm) {
	  newCount = TOS_LOCAL_ADDRESS * 2;
	}	else {
	  newCount = max(4,(((call Random.rand() & 0x7FFF) % 
			   ((mNumSenders >> 1)+1)) << 1)); 
	}
      }
      
      prev = call Interrupt.disable(); //output count shared with time thread      
      mOutputCount = newCount;
      if (prev) call Interrupt.enable();
    }

    return err_NoError;

  }

  /* Copy the message at the top of the queue into the specified buffer
   returns err_NoMoreResults if the queue is empty
  */
  TinyDBError dequeueMessage(TOS_Msg *msg) {
    short slot = mMsgq.start;

    if (mMsgq.size == 0) return err_NoMoreResults;
    if (++mMsgq.start == MSG_Q_LEN)
      mMsgq.start = 0;
    mMsgq.size--;

    memcpy((char *)(msg->data) + sizeof(DbMsgHdr), mMsgq.msgs[slot].data + sizeof(DbMsgHdr),  sizeof(msg->data) - sizeof(DbMsgHdr));
    return err_NoError;

  }

  /* --------------------------------- Error Handling  ---------------------------------*/
  #if defined(PLATFORM_PC) //itoa not on pc
  void itoa(int err, char *errNo, int radix) {
    errNo[0] = 0;
  }
  #endif

  command void signalError(TinyDBError err) {
    char errStr[sizeof(TOS_Msg)];
    char errNo[10];
    
    //    int i, j, k, l;

    errStr[0] = 0;
#ifdef PLATFORM_PC
    errNo[0] = 0;
#else
    itoa(err, errNo, 10);
#endif

/*      call Interrupt.disable(); */
/*      for (j = 0; j < 5; j++) { */
/*        call Leds.redOff(); */
/*        call Leds.greenOff(); */
/*        call Leds.yellowOff(); */
      
/*  	l = err/10; */
/*  	while (l--) { */
/*  	  call Leds.redToggle(); */
/*  	  for (i = 0; i < 20000; i++) { */
/*  	    i++;i--; */
/*  	  } */
/*  	} */

/*  	l = err % 10; */
/*  	while (l--) { */
/*  	  call	  Leds.greenToggle(); */
/*  	  for (i = 0; i < 20000; i++) { */
/*  	    i++;i--; */
/*  	  } */
/*  	} */

/*        for (i = 0; i < 20000; i++) { */
/*  	i++;i--; */
/*        } */
/*      } */
/*      call Interrupt.enable(); */
    strcat(errStr, "Error: ");
    strcat(errStr, errNo);
    strcat(errStr, "\n");
    
    //call statusMessage(errStr);  
  }
  

  command void statusMessage(CharPtr m) {
    //if (TOS_LOCAL_ADDRESS != 0)
    //    call Network.sendUart(m,1 /* debugging msg id */);
  }

  
  /* --------------------------------- Event Handlers ---------------------------------*/

  event result_t DBBuffer.resultReady(uint8_t bufferId) {
    return SUCCESS;
  }

  event result_t DBBuffer.getNext(uint8_t bufferId) {
    return SUCCESS;
  }

  event result_t DBBuffer.allocComplete(uint8_t bufferId, TinyDBError result) {
    finishedBufferSetup();
    return SUCCESS;
  }

  event result_t CommandUse.commandDone(char *commandName, char *resultBuf, SchemaErrorNo err) {
    return SUCCESS;
  }

  /* Signalled when a get is complete */
  event result_t DBBuffer.getComplete(uint8_t bufferId, QueryResult *buf) {
    return SUCCESS;
  }
  
  /* Signalled when a put is complete */
  event result_t DBBuffer.putComplete(uint8_t bufferId, QueryResult *buf, TinyDBError err) {
    //keep enqueueing results
    post deliverTuplesTask(); 
    return SUCCESS;
  }
  

}
