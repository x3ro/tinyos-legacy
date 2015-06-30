/*

  The TupleRouter is the core of the TinyDB system -- it receives
  queries from the network, creates local state for them (converts them
  from Queries to ParsedQueries), and then collects results from local
  sensors and neighboring nodes and feeds them through local queries.

  Queries consist of selections and aggregates.  Results from queries
  without aggregates are simply forwarded to the root of the tree to be
  handled by the query processor.

  Queries with aggregates are processed according to the TAG approach:
  each node collects partial aggregates from its children, combines
  those aggregates with its own sensor readings, and forwards a partial
  aggregate on to its parents.

  There are three main execution paths within TUPLE_ROUTER; one for
  accepting new queries, one for accepting results from neighboring
  nodes, and one for generating local results and deliver data to parent
  nodes.

  QUERY ARRIVAL
  ------------

  1) New queries arrive in a TUPLE_ROUTER_QUERY_MESSAGE.  Each query
  is assumed to be identified by a globally unique ID.  Query messages
  contain a part of a query: either a single field (attribute) to
  retrieve, a single selection predicate to apply, or a single
  aggregation predicate to apply.  All the QUERY_MESSAGEs describing a
  single query must arrive before the router will begin routing tuples
  for that query.

  2) Once all the QUERY_MESSAGESs have arrived, the router calls
  parseQuery() to generate a compact representation of the query in
  which field names have been replaced with field ids that can be used
  as offsets into the sensors local catalog (SCHEMA).
  
  3) Given a parsedQuery, the tuple router allocates space at the end
  of the query to hold a single, "in-flight" tuple for that query --
  this tuple will be filled in with the appropriate data fields as the
  query executes.
  
  4) TupleRouter then calls setSampleRate() to start (or restart) the
  mote's 32khz clock to fire at the appropriate data-delivery rate for
  all of the queries currently in the system.  If there is only one
  query, it will fire once per "epoch" -- if there are multiple queries,
  it will fire at the GCD of the delivery intervals of all the queries.

  TUPLE DELIVERY
  --------------

  1) Whenever a clock event occurs (TUPLE_ROUTER_TIMER_EVENT), the
  router must perform four actions:

  a) Deliver tuples which were completed on the previous clock event
  (deliverTuplesTask).  If the query contains an aggregate, deliver the
  aggregate data from the aggregate operator;  if not, deliver the
  tuple filled out during the last iteration. Reset the counters that 
  indicate when these queries should be fired again.
  
  b) Decrement the counters for all queries.  Any queries who's
  counters reach 0 need to have data delivered.  Reset the
  expression specific state for these queries (this is specific
  to the expressions in the queries -- MAX aggregates, for instances,
  will want to reset the current maximum aggregate to some large
  negative number.)

  c) Fetch data fields for each query firing this epoch.  Loop
  through all fields of all queries, fetch them (using the SCHEMA
  interface), and fill in the appropriate values in the tuples
  on the appropriate queries.  
  
  d) Route filled in tuples to query operators.  First route to
  selections, then the aggregate (if it exists).  If any selection
  rejects a tuple, stop routing it.

  NEIGHBOR RESULT ARRIVAL
  -----------------------

  When a result arrives from a neighbor (TUPLE_ROUTER_RESULT_MESSAGE),
  it needs to be integrated into the aggregate values being computed
  locally.  If the result corresponds to an aggregate query, that result
  is forwarded into the AGG_OPERATOR component, otherwise it is 
  simply forwarded up the routing tree towards the root.

*/

#include "TUPLE_ROUTER.h"
#include "alloc.h"
#include "SchemaAPI.h"
#include <string.h>
#include <stdlib.h>

// #define kDEBUG //debug flag puts mote into tossim debugging mode 
              //where it generates a query and processes it locally

#define MIN_SAMPLE_RATE 1 //one sample per ms

#define NUM_TICKS_PER_INTERVAL 128 //number of clocks events that dictate size of interval -- every 3 seconds

/* ------------------- Bits used in pendingMask to determine current state ----------------- */
#define READING_BIT 0x01 //reading fields for Query from network
#define PARSING_BIT 0x02 //parsing the query
#define ALLOCED_BIT 0x04 //reading fields, space is alloced
#define FETCHING_BIT 0x08 //fetching the value of an attribute via the schema api
#define ROUTING_BIT 0x10 //routing tuples to queries
#define DELIVERING_BIT 0x20 //deliver tuples to parents
#define SENDING_BIT 0x40 //are sending a message buffer
#define AGGREGATING_BIT 0x80 //are computing an aggregate result
#define SENDING_QUERY_BIT 0x100 //are we sending a query
#define IN_QUERY_MSG_BIT 0x200 //are we in the query message handler?

#define SET_READING_QUERY() (VAR(pendingMask) |= READING_BIT)
#define UNSET_READING_QUERY() (VAR(pendingMask) &= (READING_BIT ^ 0xFFFF))
#define IS_READING_QUERY() (VAR(pendingMask) & READING_BIT)

#define SET_PARSING_QUERY() (VAR(pendingMask) |= PARSING_BIT)
#define UNSET_PARSING_QUERY() (VAR(pendingMask) &= (PARSING_BIT ^ 0xFFFF))
#define IS_PARSING_QUERY() (VAR(pendingMask) & PARSING_BIT)

#define IS_SPACE_ALLOCED() (VAR(pendingMask) & ALLOCED_BIT)
#define UNSET_SPACE_ALLOCED() (VAR(pendingMask) &= (ALLOCED_BIT ^ 0xFFFF))
#define SET_SPACE_ALLOCED() (VAR(pendingMask) |= ALLOCED_BIT)

#define IS_FETCHING_ATTRIBUTE() (VAR(pendingMask) & FETCHING_BIT)
#define UNSET_FETCHING_ATTRIBUTE() (VAR(pendingMask) &= (FETCHING_BIT ^ 0xFFFF))
#define SET_FETCHING_ATTRIBUTE() (VAR(pendingMask) |= FETCHING_BIT)
#define UDF_WAIT_LOOP 100 //number of times we pass through main timer loop before giving up on a fetch...


#define IS_ROUTING_TUPLES() (VAR(pendingMask) & ROUTING_BIT)
#define UNSET_ROUTING_TUPLES() (VAR(pendingMask) &= (ROUTING_BIT ^ 0xFFFF))
#define SET_ROUTING_TUPLES() (VAR(pendingMask) |= ROUTING_BIT)

#define IS_DELIVERING_TUPLES() (VAR(pendingMask) & DELIVERING_BIT)
#define UNSET_DELIVERING_TUPLES() (VAR(pendingMask) &= (DELIVERING_BIT ^ 0xFFFF))
#define SET_DELIVERING_TUPLES() (VAR(pendingMask) |= DELIVERING_BIT)

#define IS_SENDING_MESSAGE() (VAR(pendingMask) & SENDING_BIT)
#define UNSET_SENDING_MESSAGE() (VAR(pendingMask) &= (SENDING_BIT ^ 0xFFFF))
#define SET_SENDING_MESSAGE() (VAR(pendingMask) |= SENDING_BIT)

#define IS_AGGREGATING_RESULT() (VAR(pendingMask) & AGGREGATING_BIT)
#define UNSET_AGGREGATING_RESULT() (VAR(pendingMask) &= ( AGGREGATING_BIT ^ 0xFFFF))
#define SET_AGGREGATING_RESULT() (VAR(pendingMask) |= AGGREGATING_BIT)

#define IS_SENDING_QUERY() (VAR(pendingMask) & SENDING_QUERY_BIT)
#define UNSET_SENDING_QUERY() (VAR(pendingMask) &= ( SENDING_QUERY_BIT ^ 0xFFFF))
#define SET_SENDING_QUERY() (VAR(pendingMask) |= SENDING_QUERY_BIT)

#define IS_IN_QUERY_MSG() (VAR(pendingMask) & IN_QUERY_MSG_BIT)
#define UNSET_IS_IN_QUERY_MSG() (VAR(pendingMask) &= ( IN_QUERY_MSG_BIT ^ 0xFFFF))
#define SET_IS_IN_QUERY_MSG() (VAR(pendingMask) |= IN_QUERY_MSG_BIT)


#define  kFIELD 0
#define  kEXPR 1

//queries have to be decomposed into multiple messages
//these are sent one by one to fill in a query data structure,
//which is then converted to a parsed query

//these aren't an enum since gcc wants to make them bigger
//than a byte if they are
#define ADD_MSG 0
#define DEL_MSG 1
#define MODIFY_MSG 2

typedef struct {
  DbMsgHdr hdr;
  char msgType;  //type of message (e.g. add, modify, delete q)
  char qid; //query id
  char numFields;
  char numExprs;
  short epochDuration; //in millisecs
  char type;  //is this a field or an expression?
  char idx;
  union {
    Field field;
    Expr expr;
  } u;
} QueryMessage;

typedef enum {
  STATE_ALLOC_PARSED_QUERY = 0,
  STATE_ALLOC_IN_FLIGHT_QUERY,
  STATE_RESIZE_QUERY,
  STATE_NOT_ALLOCING
} AllocState;

typedef struct {
  void **next;
  ParsedQuery q;
} *QueryListPtr, **QueryListHandle, QueryListEl;

typedef void (*MemoryCallback)(Handle *memory);


typedef struct {
  bool request; //request or response?
  short sid; //sender id
  char numQueries;
  char qids[10];
  
} StatusMessage;


typedef struct {
  DbMsgHdr hdr;
  char qid;
} QueryRequestMessage;

#define MSG_Q_LEN 8
typedef struct {
  short start;
  short end;
  short size;
  TOS_Msg msgs[MSG_Q_LEN];
} MsgQ;

#define TOS_FRAME_TYPE TINY_DB_frame
TOS_FRAME_BEGIN(TINY_DB_frame) {
  TOS_Msg msg;
  MsgQ msgq;
  short pendingMask;
  byte cycleToSend; //cycle number on which we send
  QueryListHandle qs;
  QueryListHandle tail;
  Query **curQuery; //dynamically allocated query handle

  Handle tmpHandle;


  MemoryCallback allocCallback; //function to call after allocation

  short fetchingFieldId; //the field we are currently fetching
  char curExpr;  //the last operator in curRouteQuery we routed to
  Tuple *curTuple; /* The tuple currently being routed (not the same as the tuple in the
		     query, since operators may allocated new tuples!) 
		  */ 
  QueryListHandle curRouteQuery; //the query we are currently routing tuples for


  QueryResult result; //result we are currently delivering
  ParamVals params; //the parameters to the command
  short outputCount;
  short fetchTries;
  AllocState allocState;

  short oldRate; //previous clock rate

  QueryListHandle curSendingQuery;
  char curSendingField;
  char curSendingExpr;
  TOS_Msg qmsg;

  bool triedAllocWaiting; //tried to create a new query, but allocation flag was true
  bool triedQueryRequest;  //received a request for query from a neighbor, but was buys

  unsigned char xmitSlots;
  unsigned char numSenders;

  short ticksThisInterval;
  short msgsThisInterval;

  bool fixedComm;
#ifdef kDEBUG
  char dbgState;
  char dbgWait;
#endif
}
TOS_FRAME_END(TINY_DB_frame);


/* --------------------------------- Local Prototypes ---------------------------------*/

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
AttrDescPtr getNextQueryField();
QueryListHandle nextQueryToRoute(QueryListHandle curQuery);
bool routeToQuery(ParsedQuery *q, Tuple *t);
Expr *nextExpr(ParsedQuery *q);
bool getQuery(byte qid, ParsedQuery **q);
void startFetchingTuples();
//void statusMessage(char *m);
void resetTupleState(ParsedQuery *q);
void fillInAttrVal(char *resultBuf, SchemaErrorNo errorNo);
void aggregateResult(ParsedQuery *q, QueryResult *qr, char exprId);
void computeOutputRate();
TinyDBError enqueueMessage(const char *msg, short len);
TinyDBError dequeueMessage(TOS_Msg *msg);


TOS_TASK(deliverTuplesTask);
TOS_TASK(routeTask);
TOS_TASK(sendQuery);

//NOTIFY can be used to send a message over the UART when 
//actually running one  a mote
#define VERBOSE_ERRORS
#ifdef VERBOSE_ERRORS
#define NOTIFY(s) statusMessage(s)
#else
#define NOTIFY(s) 
#endif

/* -----------------------------------------------------------------------------*/
/* --------------------------------- Functions ---------------------------------*/
/* -----------------------------------------------------------------------------*/

/* Intialize the tuple router */
char TOS_COMMAND(TUPLE_ROUTER_INIT)(void) {
  
  VAR(pendingMask) = 0;
  VAR(cycleToSend) = 0;
  VAR(qs) = NULL;
  VAR(tail) = NULL;
  VAR(curQuery) = NULL;

  VAR(msgq).start = 0;
  VAR(msgq).end = 0;
  VAR(msgq).size = 0;

  VAR(oldRate) = 0;
  VAR(outputCount) = 0;
  VAR(fetchTries) = 0; //hangs in fetch sometimes -- retry count

  VAR(triedAllocWaiting) = FALSE;
  VAR(triedQueryRequest) = FALSE;
  VAR(fixedComm) = FALSE;
  VAR(numSenders) = 16; //something fairly long

  VAR(ticksThisInterval) = NUM_TICKS_PER_INTERVAL;
  VAR(msgsThisInterval) = 0;

#ifdef kDEBUG
  VAR(dbgState) = 0;
  VAR(dbgWait) = 0;
#endif
  NOTIFY("IN INIT!"); //fflush(stdout);
  VAR(allocState) = STATE_NOT_ALLOCING;

  //init clock
  TOS_CALL_COMMAND(TUPLE_ROUTER_CHILD_INIT)();

  return TOS_Success;
}


//Debugging Stuff

/* Start a simple query running and see what happens... */


#ifdef kDEBUG
TOS_TASK(testTask);

Field queryFields[2] = {{"voltage"}, {"temp"}};
QueryMessage qmsg;
Expr e;
char didOne = 0;
char cntr = 10;

#endif


/* Start the tuple router routing */
char TOS_COMMAND(TUPLE_ROUTER_START)(void) {
#ifdef kDEBUG
  if (TOS_LOCAL_ADDRESS == 0) {
    //  e.isAgg = 0;
    //  e.ex.opval.field = 0; //light
    //  e.ex.opval.op = LE;
    //  e.ex.opval.value = 0x300;
    
    e.isAgg = 1;
    e.ex.agg.field = 0; //light
    e.ex.agg.groupingField = -1;
    e.ex.agg.op = MAX;
    
    qmsg.msgType = ADD_MSG;
    qmsg.qid = 1;
    qmsg.numFields = 2;
    qmsg.numExprs = 0;
    qmsg.epochDuration = 1000; //1 s per epoch
    
    didOne = 0;



    //    TOS_SIGNAL_EVENT(TUPLE_ROUTER_QUERY_MESSAGE)((TOS_MsgPtr)&VAR(msg));
    TOS_POST_TASK(testTask);
    

  }
#endif
  return TOS_Success;
}

#ifdef kDEBUG
//send out a query in three parts to neighboring motes
TOS_TASK(testTask) {

  if (!IS_SENDING_MESSAGE()) {
    switch (VAR(dbgState)) {
    case 0:
    case 1:
      qmsg.type = kFIELD;
      qmsg.u.field = queryFields[0];
      qmsg.idx = 0;
      memcpy((char *)(VAR(msg).data),(const char *)&qmsg,DATA_LENGTH);
      if (TOS_CALL_COMMAND(OUTPUT_QUERY)(&VAR(msg)) == err_NoError) {
	SET_SENDING_MESSAGE();
	VAR(dbgState) = 2;
	VAR(dbgWait) = 1;
      }
      break;
    case 2:
      
      qmsg.u.field = queryFields[1];
      qmsg.idx = 1;
      memcpy((char *)(VAR(msg).data),(const char *)&qmsg,DATA_LENGTH);
      if (TOS_CALL_COMMAND(OUTPUT_QUERY)(&VAR(msg)) == err_NoError) {
	SET_SENDING_MESSAGE();
	VAR(dbgState) = 0;
	VAR(dbgWait) = 1;
      }
      break;
    case 3:
      qmsg.type = kEXPR;
      qmsg.u.expr = e;
      qmsg.idx = 0;
      memcpy((char *)(VAR(msg).data),(const char *)&qmsg,DATA_LENGTH);
      if (TOS_CALL_COMMAND(OUTPUT_QUERY)(&VAR(msg)) == err_NoError) {
	SET_SENDING_MESSAGE();
	if (cntr-- > 0)
	  VAR(dbgState) = 0;
	else
	  VAR(dbgState) = 4;
	VAR(dbgWait) = 1;
      }
      break;
    }
  } 
}
#endif


/* --------------------------------- Query Handling ---------------------------------*/

//Message indicating the arrival of (part of) a query
TOS_MsgPtr TOS_EVENT(TUPLE_ROUTER_QUERY_MESSAGE)(TOS_MsgPtr msg) {
  QueryMessage *qmsg = (QueryMessage *)msg->data;
  ParsedQuery *q;
  short i;
  bool success;
  bool oldField = TRUE;

  CLR_YELLOW_LED_PIN();

  //is a request to delete an existing query
  if (qmsg->msgType == DEL_MSG) {
      TinyDBError err;

      err = TOS_CALL_COMMAND(TUPLE_ROUTER_REMOVE_QUERY)(qmsg->qid, &success);
      if (err != err_NoError)
	  signalError(err);

      if (success || TOS_LOCAL_ADDRESS == 0) { //only forward if we know about the query, or if we're the root
	if (!IS_SENDING_MESSAGE()) {
	  VAR(msg) = *msg;
	  if (TOS_CALL_COMMAND(OUTPUT_QUERY)(msg) == err_NoError) {
	    SET_SENDING_MESSAGE();
	  } else
	    signalError(err_MessageSendFailed);      
	}else
	  signalError(err_MessageSendFailed);
      }
      return msg;
  }

  //otherwise, assume its an ADD_MSG, for now
  if (!IS_IN_QUERY_MSG()) { 
    
    if (!getQuery(qmsg->qid, &q)) { //ignore if we already know about this query 
      SET_IS_IN_QUERY_MSG();
      
      if (READ_RED_LED_PIN())
	CLR_RED_LED_PIN();
      else
	SET_RED_LED_PIN();
      
      if (IS_READING_QUERY()) {
	if (qmsg->qid != (**VAR(curQuery)).qid) {
	  if (IS_SPACE_ALLOCED() || VAR(triedAllocWaiting)) {
	    //query is alloced, but heard about a new one
	    //forget old one
	    if (IS_SPACE_ALLOCED()) TOS_CALL_COMMAND(FREE_HANDLE)((Handle)VAR(curQuery));
	    UNSET_SPACE_ALLOCED();
	    UNSET_READING_QUERY();
	  } else {
	    VAR(triedAllocWaiting) = TRUE;
	    UNSET_IS_IN_QUERY_MSG();
	    return msg; //waiting for query to be alloced -- dont interrupt
	  }
	} else if (! IS_SPACE_ALLOCED()) {
	  UNSET_IS_IN_QUERY_MSG();
	  return msg; //failure -- space not alloced for this query yet!
	}  else {  
	  oldField = addQueryField(msg);
	}
	
	//go ahead and forward this guy on, if its new or we're the root
	if ((!oldField || TOS_LOCAL_ADDRESS == 0)  && !IS_SENDING_MESSAGE()) {
	  VAR(msg) = *msg;
	  
	  if (TOS_CALL_COMMAND(OUTPUT_QUERY)(msg) == err_NoError) {
	    
	    SET_SENDING_MESSAGE();
	  } else
	    signalError(err_MessageSendFailed);
	} else
	  signalError(err_MessageSendFailed);
      }

      //note that we can fall through from previous clause
      if (!IS_READING_QUERY() /*&& !IS_SENDING_MESSAGE()*/) {
	
	Query pq;
	
	
	
	SET_READING_QUERY();
	UNSET_SPACE_ALLOCED();
	VAR(triedAllocWaiting) = FALSE;
	pq.qid = qmsg->qid;
	pq.numFields=qmsg->numFields;
	pq.numExprs=qmsg->numExprs;    
	pq.epochDuration = qmsg->epochDuration;
	pq.knownFields = 0;
	pq.knownExprs = 0;
	
	for (i = qmsg->numFields; i < MAX_FIELDS; i++)
	  pq.knownFields |= (1 << i);
	for (i = qmsg->numExprs; i < MAX_EXPRS; i++)
	  pq.knownExprs |= (1 << i);
	
	printf("completeMask = %x, %x\n",pq.knownFields, pq.knownExprs);//fflush(stdout);
	
	VAR(msg) = *msg; //save a copy
	//allocate space for query
	allocPendingQuery(&continueQuery, &pq);
      }
    }
    UNSET_IS_IN_QUERY_MSG();
  }

  return msg;
}

//continuation after query is successfully alloc'ed
void continueQuery(Handle *memory) {
  QueryMessage *qmsg = (QueryMessage *)(VAR(msg).data);
  short i; 

  
  VAR(curQuery) = (Query **)*memory;
  (**VAR(curQuery)).qid = qmsg->qid;
  (**VAR(curQuery)).numFields=qmsg->numFields;
  (**VAR(curQuery)).numExprs=qmsg->numExprs;    
  (**VAR(curQuery)).epochDuration=qmsg->epochDuration;
  (**VAR(curQuery)).knownFields = 0;
  (**VAR(curQuery)).knownExprs = 0;
  
  printf ("num fields = %d\n", qmsg->numFields);

  for (i = qmsg->numFields; i < MAX_FIELDS; i++)
    (**VAR(curQuery)).knownFields |= (1 << i);
  for (i = qmsg->numExprs; i < MAX_EXPRS; i++)
    (**VAR(curQuery)).knownExprs |= (1 << i);
  
    printf ("completeMask = %x, %x\n",(**VAR(curQuery)).knownFields, (**VAR(curQuery)).knownExprs);//fflush(stdout);

  SET_SPACE_ALLOCED();
  addQueryField(&VAR(msg));

 
  //now forward the message on
  if (!IS_SENDING_MESSAGE() && TOS_CALL_COMMAND(OUTPUT_QUERY)(&VAR(msg)) == err_NoError) {
    SET_SENDING_MESSAGE();
  } else
    signalError(err_MessageSendFailed);

}

//Add a field or expression to a partially completed query
//return true iff we already knew about this field
bool addQueryField(TOS_MsgPtr msg) {
  QueryMessage *qmsg = (QueryMessage *)msg->data;
  bool knewAbout = FALSE;

  if (qmsg->type == kFIELD) {
    SET_FIELD(*VAR(curQuery), (short)qmsg->idx, qmsg->u.field);
    printf ("set field (%s), value is (%s)\n", qmsg->u.field.name, GET_FIELD(*VAR(curQuery), (short)qmsg->idx).name);//fflush(stdout);
    knewAbout = (**VAR(curQuery)).knownFields & (1 << qmsg->idx);
    (**VAR(curQuery)).knownFields |= (1 << qmsg->idx);
    printf ("Setting field idx %d\n",qmsg->idx); //fflush(stdout);
  } else {  //type == kEXPR
    qmsg->u.expr.opState = NULL; //make sure we clear this out
    SET_EXPR(*VAR(curQuery), qmsg->idx, qmsg->u.expr);
    printf ("Setting expr idx %d\n",qmsg->idx); //fflush(stdout);
    knewAbout = (**VAR(curQuery)).knownExprs & (1 << qmsg->idx);
    (**VAR(curQuery)).knownExprs |= (1 << qmsg->idx);
  }
  if (queryComplete(**VAR(curQuery))) {
    //allocate a parsed query for this query, initialize it
    printf("Query is complete!\n");//fflush(stdout);

    SET_PARSING_QUERY();
    allocQuery(&parsedCallback, *VAR(curQuery));
  }
  return knewAbout;
}

//continuation after parsed query is successfully alloc'ed
//NOTE: after we setup query, need to resize for tuple at end of query...
void parsedCallback(Handle *memory) {
  QueryListHandle h = (QueryListHandle)*memory;  //this has already been allocated

  printf("in parsed callback \n");//fflush(stdout);
  TOS_CALL_COMMAND(LOCK_HANDLE)((Handle)h);
  printf("parsing \n");//fflush(stdout);
  parseQuery(*VAR(curQuery), &((**h).q));
  printf("unlocking \n");//fflush(stdout);
  TOS_CALL_COMMAND(UNLOCK_HANDLE)((Handle)h);
  TOS_CALL_COMMAND(FREE_HANDLE)((Handle)VAR(curQuery));
  printf("finished, now resizing\n");//fflush(stdout);
  reallocQueryForTuple(&resizedCallback, (QueryListHandle)h);
    
}

//continuation after the query is realloced to include space for a tuple
void resizedCallback(Handle *memory) {
  printf("finished with resizing\n");//fflush(stdout);
  setSampleRate(); //adjust clock rate to be gcd of rate of all queries
  UNSET_READING_QUERY();
  UNSET_PARSING_QUERY();
  
}

	
/* Remove a query from the tuple router 
 Set *success to TRUE if the query was succesfully removed
*/
TinyDBError TOS_COMMAND(TUPLE_ROUTER_REMOVE_QUERY)(char qid, bool *success) {
  //remove information about the specified query id
  QueryListHandle curq;
  QueryListHandle last = NULL;

  if (IS_FETCHING_ATTRIBUTE() || IS_ROUTING_TUPLES() || 
      IS_DELIVERING_TUPLES() || IS_SENDING_MESSAGE()) return err_RemoveFailedRouterBusy;

  *success = FALSE;
  curq = VAR(qs);
  while (curq != NULL) {
    if ((**curq).q.qid == qid) {       //this is the one to remove
      *success = TRUE;
      if (last != NULL) {       //not the first element
	(**last).next = (**curq).next;
      } else {  //the first element
	VAR(qs) = (QueryListHandle)(**curq).next;
      }

      if (VAR(tail) == curq) //was the last element
	VAR(tail) = last; //ok if this is also the first element, since this will now be NULL
      if (VAR(qs) == NULL) { //no more queries, stop the clock!
	TOS_CALL_COMMAND(TUPLE_ROUTER_TIMER_STOP)(0); 
	VAR(oldRate) = 0; //clear rate info...
	SET_RED_LED_PIN();
	SET_YELLOW_LED_PIN();
	SET_GREEN_LED_PIN();
      } else 
	  computeOutputRate(); //adjust number of comm slots

      //notify children (e.g. AGG_OPERATOR) that this query is complete
      TOS_SIGNAL_EVENT(QUERY_COMPLETE)(&(**curq).q);
      TOS_CALL_COMMAND(FREE_HANDLE)((Handle)curq);


      return err_NoError;
    } else {
      last = curq;
      curq = (QueryListHandle)(**curq).next;
    }
  }
  return err_NoError; //not an error if query doesn't exist

}



/* Send a query to a neighbor */
TOS_TASK(sendQuery) {
  //this task assembles the query one field / attribute at a time,
  //send each out in a separate radio message (just like they are delivered).
  //task is resceduled after SEND_DONE_EVENT fires
  QueryListHandle curq = VAR(curSendingQuery);
  QueryMessage *qmsg = (QueryMessage *)VAR(qmsg).data;


  if (VAR(curSendingField) < (**curq).q.numFields) {
    char fieldId = PQ_GET_FIELD_ID(&(**curq).q, (short)VAR(curSendingField));

    VAR(curSendingField)++;
    if (!QUERY_FIELD_IS_NULL(fieldId)) {
      AttrDescPtr attr = TOS_CALL_COMMAND(TR_GET_SCHEMA_FIELD_BY_ID)(fieldId);

      qmsg->msgType = ADD_MSG;
      qmsg->qid = (**curq).q.qid;
      qmsg->numFields = (**curq).q.numFields;
      qmsg->numExprs = (**curq).q.numExprs;
      qmsg->epochDuration = (**curq).q.epochDuration;
      qmsg->type = kFIELD;
      qmsg->idx = VAR(curSendingField)-1;
      strcpy(qmsg->u.field.name, attr->name);

      if (READ_GREEN_LED_PIN())
	CLR_GREEN_LED_PIN();
      else
	SET_GREEN_LED_PIN();



      if (!IS_SENDING_MESSAGE()) {
	SET_SENDING_MESSAGE();
	
	if (TOS_CALL_COMMAND(OUTPUT_QUERY)(&VAR(qmsg)) != err_NoError)
	  UNSET_SENDING_MESSAGE();
      }

    } else {
      //field is null (we don't know what it's name should be) -- do the next one
      TOS_POST_TASK(sendQuery); //try the next one...
    }
  } else if (VAR(curSendingExpr) < (**curq).q.numExprs) {
    Expr e = PQ_GET_EXPR(&(**curq).q, VAR(curSendingExpr));
    VAR(curSendingExpr)++;
    
    qmsg->msgType = ADD_MSG;
    qmsg->qid = (**curq).q.qid;
    qmsg->numFields = (**curq).q.numFields;
    qmsg->numExprs = (**curq).q.numExprs;
    qmsg->epochDuration = (**curq).q.epochDuration;
    qmsg->type = kEXPR;
    qmsg->idx = VAR(curSendingExpr)-1;
    qmsg->u.expr = e;

      if (READ_RED_LED_PIN())
	CLR_RED_LED_PIN();
      else
	SET_RED_LED_PIN();

      if (!IS_SENDING_MESSAGE()) {
	SET_SENDING_MESSAGE();
	
	if (TOS_CALL_COMMAND(OUTPUT_QUERY)(&VAR(qmsg)) != err_NoError)
	  UNSET_SENDING_MESSAGE();
      }

  } else {
    UNSET_SENDING_QUERY();
  }
    
  
}


/* A neighbor requested a query from us */
TOS_MsgPtr TOS_EVENT(TUPLE_ROUTER_QUERY_REQUEST)(TOS_MsgPtr msg) {
  QueryRequestMessage *qmsg = (QueryRequestMessage *)(msg->data);
  char qid = qmsg->qid;

  QueryListHandle curq;
  
  //triedQueryRequest flag set to true when a neighbor requests a 
  //query but we're sending another one

  //if we get another such request, we'll abort the current one (ick)
  if (!IS_SENDING_MESSAGE() && (!IS_SENDING_QUERY() || VAR(triedQueryRequest))) {
    VAR(triedQueryRequest) = FALSE;
    SET_SENDING_QUERY();
  } else {
    VAR(triedQueryRequest) = TRUE;
    return msg;
  }
  

  curq = VAR(qs);
  while (curq != NULL) {

    if ((**curq).q.qid == qid) {
      //the query we're supposed to send
      VAR(curSendingField) = 0;
      VAR(curSendingExpr) = 0;
      VAR(curSendingQuery) = curq;
      TOS_POST_TASK(sendQuery);

      break;
    }
    curq = (QueryListHandle)(**curq).next;
  }
  
  return msg;
}


// A message not directly addressed to us that we overhead
TOS_MsgPtr TOS_EVENT(TUPLE_ROUTER_SNOOPED_MESSAGE)(TOS_MsgPtr msg, char amId, bool isParent) {
    ParsedQuery *q;
    char qid;
    DbMsgHdr *hdr = (DbMsgHdr *)msg->data;
    QueryRequestMessage *qreq;

  //check and see if it has information about a query we haven't head before
    //don't snoop on queries from the root (it wont reply)!

    VAR(msgsThisInterval)++;
  if (amId == AM_MSG(TINYDB_NETWORK_DATA_MESSAGE) && hdr->senderid != 0) {

    qid = TOS_CALL_COMMAND(GET_QID_FROM_RESULT)(msg->data);
    qreq = (QueryRequestMessage *)VAR(msg.data);
    
    //is this a query we've never heard of before?

    if (!getQuery(qid, &q)) {
      qreq->qid = qid;
      if (!IS_SENDING_MESSAGE() && TOS_CALL_COMMAND(REQUEST_QUERY)(&VAR(msg), hdr->senderid) == err_NoError)
	SET_SENDING_MESSAGE();
    }
  }

  //did this message come from our parent?

  if (isParent) {
      QueryResult qr;

      //epoch sync with parent
      qid = TOS_CALL_COMMAND(GET_QID_FROM_RESULT)(msg->data);


      if (getQuery(qid, &q)) {
	  TOS_CALL_COMMAND(RESULT_FROM_BYTES)(msg->data, &qr, q);
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

      // Each node now estimates its local neighborhood size
      //      VAR(numSenders) = hdr->xmitSlots;
  }

  
  return msg;
}

/* --------------------------------- Tuple / Data Arrival ---------------------------------*/

/* Continue processing a tuple  after a selection operator
   t is the tuple that after is has been processed by the operator,
   which is stored in q.  

   Passed indicates whether the tuple passed the operator --
   if not, the tuple should not be output.
*/

TinyDBError TOS_EVENT(TUPLE_ROUTER_FILTERED_TUPLE_EVENT)(Tuple *t,
							 ParsedQuery *q,
							 Expr *e, 
							 bool passed) 
{
  if (!passed) {
    e->success = FALSE;
    VAR(curRouteQuery) = nextQueryToRoute(VAR(curRouteQuery));
  }
  TOS_POST_TASK(routeTask); //keep routing tuples during this epoch
  return err_NoError;
}

/* Continue processing a tuple after an aggregation operator has been applied
   T is the tuple passed into the operator 
*/
TinyDBError TOS_EVENT(TUPLE_ROUTER_AGGREGATED_TUPLE_EVENT)(Tuple *t, ParsedQuery *q,
							   Expr *e)
{
    TOS_POST_TASK(routeTask);
    return err_NoError;
}

/* Called every time we route a tuple through an aggregate operator.
   Need to route to the next aggregation operator.
*/
TinyDBError TOS_EVENT(TUPLE_ROUTER_AGGREGATED_RESULT_EVENT)(QueryResult *qr, ParsedQuery *q, Expr *e) {
  //maybe unset a status variable?

  aggregateResult(q, qr, e->idx+1);
  return err_NoError;
}


//received a result from a neighbor
TOS_MsgPtr TOS_EVENT(TUPLE_ROUTER_RESULT_MESSAGE)(TOS_MsgPtr msg) {
  QueryResult qr;
  ParsedQuery *q;
  short i;
  bool gotAgg = FALSE;

  if (READ_GREEN_LED_PIN())
    CLR_GREEN_LED_PIN();
  else
    SET_GREEN_LED_PIN();

  VAR(msgsThisInterval)++;

  if (getQuery(TOS_CALL_COMMAND(GET_QID_FROM_RESULT)(msg->data), &q)) {
    TOS_CALL_COMMAND(RESULT_FROM_BYTES)(msg->data, &qr, q);
    //now determine where to route this result to -- either an
    //aggregation operator or to our parent

    for (i = 0; i < q->numExprs; i++) {
      Expr e = PQ_GET_EXPR(q, i);
      if (e.isAgg) {
	gotAgg = TRUE;
	break;
      }
    }
    if (!gotAgg) { //didn't give to an aggregate, so just pass it on...
      TinyDBError err = enqueueMessage((char *)(msg->data + sizeof(DbMsgHdr)), DATA_LENGTH-sizeof(DbMsgHdr));
      if (err != err_NoError) signalError(err);
    } else { //got an agg -- do all the aggregation expressions
      VAR(result) = qr;
      if (!IS_AGGREGATING_RESULT()) //don't double aggregate!
	aggregateResult(q, &VAR(result), 0);
    }
  } else {
    TOS_SIGNAL_EVENT(TUPLE_ROUTER_SNOOPED_MESSAGE)(msg, AM_MSG(TINYDB_NETWORK_DATA_MESSAGE), FALSE);
    //    NOTIFY("unknown neighbor q!");
  }

  return msg;
}

/** Apply all aggregate operators to this result.
    Apply them one after another, starting with exprId.
    This is called from TUPLE_ROUTER_RESULT_MESSAGE and from 
    AGGREGATED_RESULT_EVENT
*/
void aggregateResult(ParsedQuery *q, QueryResult *qr, char exprId) {
  Expr *e;

  if (exprId >= q->numExprs) { //no more aggregation expressions
    UNSET_AGGREGATING_RESULT();
    return;
  }

  e = &PQ_GET_EXPR(q,exprId);
  if (e->isAgg) {
    SET_AGGREGATING_RESULT();
    if (TOS_CALL_COMMAND(AGGREGATE_PARTIAL_RESULT)(qr, q, e) != err_NoError) {
      UNSET_AGGREGATING_RESULT(); //error, just do the next one 
                                  //(errors may just mean the result doesn't apply to the agg)
      aggregateResult(q,qr,exprId+1);
    }
  } else
    aggregateResult(q,qr,exprId+1); //move on to the next one
}



/* --------------------------------- Timer Events ---------------------------------*/

void setSampleRate() {
  QueryListHandle qlh;
  short rate = -1;
  char prev = inp(SREG) & 0x80;

#ifdef nodef
  //walk through queries, choose lowest sample rate
  qlh = VAR(qs);
  while (qlh != NULL) {
    if (rate == -1) 
      rate = (**qlh).q.epochDuration;
    else 
      rate = gcd((**qlh).q.epochDuration,rate);
    qlh = (QueryListHandle)(**qlh).next;
  }
  
  //throttle rate to maximum
  if (rate <= MIN_SAMPLE_RATE) {
      //    rate = gcd(MIN_SAMPLE_RATE,rate);
      rate = MIN_SAMPLE_RATE;
  }
  printf("rate = %d\n", rate); //fflush(stdout);
#endif

  
  //HACK
  rate = 32; //hardcode!
  //now set the rate at which we have to deliver tuples to each query
  //as a multiple of this rate
  qlh = VAR(qs);

  while (qlh != NULL) {
    (**qlh).q.clocksPerSample = (**qlh).q.epochDuration / rate;

    cli(); //this shared with clock thread...
    (**qlh).q.clockCount = (**qlh).q.clocksPerSample; //reset counter
    if (prev) sei();

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

  if (rate != VAR(oldRate)) { //restart the clock if rate changed
      VAR(oldRate) = rate;
      TOS_CALL_COMMAND(TR_TIMER_INIT)();
      //stop timer 0
      cli(); //make this a critical section too -- if a timer event goes off while this is happening, who knows what that means?
      TOS_CALL_COMMAND(TUPLE_ROUTER_TIMER_STOP)(0); 
      if (prev) sei();

      //restart it at the new rate
      //TOS_CALL_COMMAND(TUPLE_ROUTER_TIMER_START)(0,0,32); //timer for outputting results
      //TOS_CALL_COMMAND(TUPLE_ROUTER_TIMER_START)(1,0,rate); //timer for outputting results
      TOS_CALL_COMMAND(TUPLE_ROUTER_TIMER_START)(0, 0 /* repeat */, rate);
  }
  computeOutputRate();
}

/* Determine how many communication slots there are in the
   shortest duration query -- this will determine how long we can 
   afford to maximally wait before sending a result.
*/
void computeOutputRate() {
    QueryListHandle qlh = VAR(qs);
    short minSlots = 0x7FFF;

    
    while (qlh != NULL) {
	if (minSlots > (**qlh).q.clocksPerSample)
	    minSlots = (**qlh).q.clocksPerSample;

	qlh = (QueryListHandle)(**qlh).next;
    }
    
    VAR(xmitSlots) = minSlots;
    
}


//find the GCD of two integers
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

/* Clock fired --
   Works as follows:
   1) Output tuples from previous epochs
   2) Deterimine what queries fire in this epoch
   3) Collect samples from those queries
   4) Fill in the tuples in those queries
   5) Apply operators to those tuples

   While this is happening, results may arrive from other sensors
   nodes representing results from the last epoch.  Those results need
   to be forwarded (if we're just selection), or stored (if we're aggregating)
   
   Question:  What to do if next time event goes off before this one is
   complete?
*/
void TOS_EVENT(TUPLE_ROUTER_TIMER_EVENT)() {
  printf("IN CLOCK \n"); //fflush(stdout);
  //test to see if we're already sampling, in which case we better
  //not reinvoke sampling!


  VAR(ticksThisInterval)--;
  if (VAR(ticksThisInterval) <= 0) {
    //numSenders is used to determine the backoff period between message sends
    //xmitSlots tracks the epoch duration of the shortest query in clock ticks
    //msgsThisInterval is the number of messages heard during the last NUM_TICKS_PER_INTERVAL clock ticks
    //idea here is that we want to backoff more if :
    // 1) there is more network traffic
    // 2) there is more time between epochs
    VAR(numSenders) = ((((VAR(msgsThisInterval) + 1) * 2) * VAR(xmitSlots)) >> 7); //(2^7 == 128 == NUM_TICKS_THIS_INTERVAL)
    VAR(msgsThisInterval) = 0;
    VAR(ticksThisInterval) = NUM_TICKS_PER_INTERVAL;
  }

  TOS_SIGNAL_EVENT(DELIVER_TUPLE)();

  if (IS_FETCHING_ATTRIBUTE()) {
    NOTIFY("fetching");
    VAR(fetchTries)++;
    //so we can escape a blocked fetch
    if (VAR(fetchTries) < UDF_WAIT_LOOP)
      return;
    else
      UNSET_FETCHING_ATTRIBUTE();
  } else if (IS_ROUTING_TUPLES()) {
    NOTIFY("routing");
    return;
  } else if ( IS_DELIVERING_TUPLES()) { 
    NOTIFY("delivering");
    return;
  }  else if (IS_AGGREGATING_RESULT()) {
    NOTIFY("aggregating");
    return;
  }



  //Since all transmission now happens through the message queue, I think
  //its ok to proceed even if we are currently sending a message...
  //else if(IS_SENDING_MESSAGE())  {
  //    NOTIFY("sending");
  //    return;
  //  }

  VAR(fetchTries) = 0;


  //  TOS_SIGNAL_EVENT(TUPLE_ROUTER_NEW_EPOCH)();
  VAR(curRouteQuery) = NULL; //find the first query we need to deliver results for
  VAR(curExpr) = -1;
  printf("POSTING TASK.");//fflush(stdout);
  TOS_POST_TASK(deliverTuplesTask);
}

/* --------------------------------- Tuple Output Routines ---------------------------------*/


TOS_TASK(deliverTuplesTask) {
  bool success = TOS_LOCAL_ADDRESS == 0 ? FALSE : TRUE; //don't deliver tuples for root
  bool didAgg = FALSE;
  
  // if (IS_SENDING_MESSAGE()) return; //wait til networking send is done...
  printf("IN DELIVER TUPLES TASK.\n");//fflush(stdout);
  SET_DELIVERING_TUPLES();
  
  VAR(curRouteQuery) = nextQueryToRoute(VAR(curRouteQuery)); 
  if (VAR(curRouteQuery) != NULL) {

    ParsedQuery *pq = &(**VAR(curRouteQuery)).q;
    Expr *e = nextExpr(pq);

    //scan the query, looking for an aggregate operator --
    //if we find it, output all the tuples it knows about --
    //otherwise, just output the tuple associated with the query
    while (e != NULL) {
      if (e->isAgg) {
	VAR(result).result_idx = kFIRST_RESULT;
	while (TOS_CALL_COMMAND(AGG_GET_NEXT_RESULT)(&VAR(result), pq, e) == err_NoError) {
	  TinyDBError err;
	  // stamp current epoch number
	  VAR(result).epoch = pq->currentEpoch;
	  //enqueue all the results from this aggregate
	  err = enqueueMessage((const char *)&VAR(result), DATA_LENGTH-sizeof(DbMsgHdr));
	  if (err != err_NoError) 
	    signalError(err);
	  didAgg = TRUE;
	}
	//break;
      } else {
	if (!e->success) success = FALSE;
      }
      e = nextExpr(pq);
    }
    pq->clockCount = pq->clocksPerSample; //reschedule this query

    //just a selection query -- enqueue appropriate results
    if (success && !didAgg) {
      TinyDBError err;

      VAR(result).epoch = pq->currentEpoch;
      TOS_CALL_COMMAND(TUPLE_TO_QR)( &VAR(result), pq , PQ_GET_TUPLE_PTR(pq));
      err =  enqueueMessage((const char *)&VAR(result), DATA_LENGTH-sizeof(DbMsgHdr));
      if (err != err_NoError) {
	signalError(err);
      }
    }

    //send tuples for next query
    TOS_POST_TASK(deliverTuplesTask);
    VAR(curExpr) = -1; //reset for next query

  } else {
    UNSET_DELIVERING_TUPLES(); //now that tuples from last epoch are delivered, start fetching
                                //new tuples
    printf ("FETCTHING TUPLES\n"); //fflush(stdout);
    startFetchingTuples();
  }
}

//called in response to timer 1 firing
void TOS_EVENT(DELIVER_TUPLE)(void) {
    if (VAR(outputCount) > 0) {
	VAR(outputCount)--;
    }

        
    if (VAR(outputCount) <= 0) {

      
	  TinyDBError err = dequeueMessage(&VAR(msg));
	  DbMsgHdr *hdr;
	  ParsedQuery *q;

	  if (err == err_NoError) {
	      getQuery(TOS_CALL_COMMAND(GET_QID_FROM_RESULT)(VAR(msg).data), &q);
	      if (READ_RED_LED_PIN())
		  CLR_RED_LED_PIN();
	      else
		  SET_RED_LED_PIN();
	      
	      hdr = (DbMsgHdr *)VAR(msg).data;
	      hdr->xmitSlots = VAR(numSenders);
	      if (q != NULL)
		  hdr->timeRemaining = (unsigned char)(q->clockCount & 0x00FF);
	      else
		  hdr->timeRemaining = 0xFF;
	      
	      if (!IS_SENDING_MESSAGE() && TOS_CALL_COMMAND(OUTPUT_RESULT)(&VAR(msg)) == err_NoError) {
		  SET_SENDING_MESSAGE();
	      } else {
		  //	      if (!IS_SENDING_MESSAGE) TOS_POST_TASK(deliverTuplesTask);
		  signalError(err_MessageSendFailed);
	      }
	      //schedule the next result to deliver
	      if (TOS_LOCAL_ADDRESS == 0) {
		VAR(outputCount) = 1;
	      } else {
		if (VAR(fixedComm)) {
		  VAR(outputCount) = TOS_LOCAL_ADDRESS * 2;
		}	else {
		  VAR(outputCount) = (((TOS_CALL_COMMAND(NEXT_RAND)() & 0x7FFF) % 
				       ((VAR(numSenders) >> 1)+1)) << 1); 
		}
	      }
	  } else if (err != err_NoMoreResults)
	      signalError(err);
    }
}

void TOS_EVENT(TUPLE_ROUTER_SEND_DONE_EVENT)(TOS_MsgPtr msg, char amId) {

  if (IS_SENDING_MESSAGE() ) {
    UNSET_SENDING_MESSAGE();

    if (msg == &VAR(qmsg) && IS_SENDING_QUERY())
      TOS_POST_TASK(sendQuery);

#ifdef kDEBUG
    if (VAR(dbgWait) == 1) {
      VAR(dbgWait) = 0;
      printf ("%d: SCHEDULING testTask\n", TOS_LOCAL_ADDRESS);
      TOS_POST_TASK(testTask);
      
    }
#endif
  } else
    return; //not for us!

}


void startFetchingTuples() {
  QueryListHandle qlh = VAR(qs);
  bool mustSample = FALSE;


  //update queries, determine if any needs to sample data this epoch
  while (qlh != NULL) {
    //reset queries that just restarted
    if ((**qlh).q.clocksPerSample > 0 && (**qlh).q.clockCount == (**qlh).q.clocksPerSample) 
      resetTupleState(&(**qlh).q); //clear it out
    if ((**qlh).q.clocksPerSample > 0 && --(**qlh).q.clockCount <= 0) {
      if (READ_YELLOW_LED_PIN()) //end of epoch
	CLR_YELLOW_LED_PIN();
      else
	SET_YELLOW_LED_PIN();

      mustSample = TRUE;
      (**qlh).q.currentEpoch++;
      break;
    }
    qlh = (QueryListHandle)(**qlh).next;
  }
  //only actually process local tuples if we're not the root.
  if (TOS_LOCAL_ADDRESS != 0 && mustSample) {
    fetchNextAttr();
  }
  

}

void resetTupleState(ParsedQuery *q) {
  short i;
  Expr *e;

  //clear out this tuple
  TOS_CALL_COMMAND(INIT_TUPLE)(q, PQ_GET_TUPLE_PTR(q));
  for (i = 0; i < q->numExprs; i++) {
    e = &PQ_GET_EXPR(q, i);
    TOS_CALL_COMMAND(TUPLE_READER_RESET_EXPR_STATE)(q, e);
  }
}

/* --------------------------------- Tuple Building Routines ---------------------------------*/

//fetch the next needed attribute, and 
//return true if an attribute was found and the
//request to fetch it was successful
bool fetchNextAttr() {
  AttrDescPtr queryField;
  SchemaErrorNo errorNo;
  char *resultBuf;
  ParsedQuery *q;
  short i, fieldId = -1;

  printf("in fetchNextAttr\n"); //fflush(stdout);
  //at least one query needs samples -- but which ones?
  queryField = getNextQueryField(&q); 

  if (queryField != NULL)
    printf("got query field, field = %s\n", queryField->name);//fflush(stdout);
  if (queryField != NULL) {
    CommandDesc *command = TOS_CALL_COMMAND(GET_COMMAND_ID)(queryField->getCommand);

    if (command == NULL) {
      printf("COMMAND IS NULL\n");
      return FALSE;
    }
    printf("Invoking commnad %s\n", command->name); //fflush(stdout);
    //invoke the get data command on this field
    if (command->params.numParams != 0) {
      printf("Get command has arguments!\n");//fflush(stdout);
      signalError(err_InvalidGetDataCommand);
    }
    VAR(params).numParams = 0;
    VAR(fetchingFieldId) = queryField->idx;
    //figure out this fields local query index
    for (i = 0; i < q->numFields;i++) {
      if (q->queryToSchemaFieldMap[i] == queryField->idx)
	fieldId = i;
    }
    if (fieldId != -1) {
      //CAREFUL:  Invoke command can return very quickly, such that
      //we best have set this value before we call it, since if we do it
      //afterwards, it may completion before we have a chance to set the flag
      //So, we have to make sure to unset the flag below, when needed.
      SET_FETCHING_ATTRIBUTE();

	  // use pre-allocated tuple space
	  resultBuf = TOS_CALL_COMMAND(TUPLE_GET_FIELD_PTR)(q, PQ_GET_TUPLE_PTR(q), fieldId);
      if (TOS_CALL_COMMAND(INVOKE_COMMAND)(command, resultBuf, 
					   &errorNo) == TOS_Success) {
	if (errorNo != SCHEMA_RESULT_PENDING)
	  fillInAttrVal(resultBuf, errorNo);
	if (errorNo != SCHEMA_ERROR)
	  return TRUE;
      }
    }
  }
  return FALSE;
}

//scan queries, looking for fields that haven't been defined yet
AttrDescPtr getNextQueryField(ParsedQuery **q) {
  QueryListHandle qlh = VAR(qs);
  AttrDescPtr attr = NULL; 

  while (qlh != NULL) {
    if ((**qlh).q.clocksPerSample > 0 &&  (**qlh).q.clockCount <= 0) { //is this query's time up?
      Tuple *t = PQ_GET_TUPLE_PTR(&(**qlh).q);
      ParsedQuery *q = &(**qlh).q;
      printf ("q->qid = %d, t->qid = %d, t->numFields = %d\n", q->qid, t->qid, t->numFields);
      printf("calling GET_NEXT_QUERY_FIELD\n"); //fflush(stdout); 

      attr = TOS_CALL_COMMAND(GET_NEXT_QUERY_FIELD)(q,t);
      if (attr != NULL) break;
      
    }
    qlh = (QueryListHandle)(**qlh).next;
  }
  if (qlh == NULL)
	  *q = NULL;
  else
	  *q = &(**qlh).q;
  return attr;
}

void fillInAttrVal(char *resultBuf, SchemaErrorNo errorNo)
{
  short id = VAR(fetchingFieldId); //the mote-specific field this command has data for
  short i;
  QueryListHandle qlh = VAR(qs);

  printf ("GOT DATA, COMMAND data = %d, errorNo = %d\n", *(short *)resultBuf, errorNo);


  while (qlh != NULL) {
    if ((**qlh).q.clocksPerSample > 0 &&  (**qlh).q.clockCount <= 0) { //this query needs data
      ParsedQuery *q = &(**qlh).q;
      Tuple *t = PQ_GET_TUPLE_PTR(&(**qlh).q);
      for (i = 0; i < q->numFields; i++) {
	if (q->queryToSchemaFieldMap[i] == id) { //the correct field in this query
	  TOS_CALL_COMMAND(SET_TUPLE_FIELD)(q, t, i, resultBuf);
	  printf ("SET QUERY FIELD : %d\n", i);
	}
      }
    }
    qlh = (QueryListHandle)(**qlh).next;
  }



  if (! fetchNextAttr()) {
    UNSET_FETCHING_ATTRIBUTE(); //clear, and try again
    SET_ROUTING_TUPLES();
    //no more attributes to fetch, start processing tuples....
    VAR(curRouteQuery) = nextQueryToRoute(NULL);
    VAR(curExpr) = -1;
    TOS_POST_TASK(routeTask);

  }
}

//completion event after some data was fetched
//params should be filled out with the result of the command
void TOS_EVENT(DATA_COMMAND_COMPLETE)(CommandDescPtr commandDesc, char *resultBuf, SchemaErrorNo errorNo) 
{
	fillInAttrVal(resultBuf, errorNo);
}

/* --------------------------------- Tuple Routing Routines ---------------------------------*/


/* Route task does the heavy lifting of routing tuples to queries.
   It assumes the tuples stored in each query that needs to be routed
   during this epoch have been initialized.  It then iterates through the
   operators in each query, routing tuples to them in succession.
   
   Tuples are routed through a query at a time, and always in a fixed order.
*/
TOS_TASK(routeTask) {
  if (VAR(curRouteQuery) != NULL) {
    ParsedQuery *q = &(**VAR(curRouteQuery)).q;
    if (!routeToQuery(q,  VAR(curTuple))) {
      //false here means move on to the next query
      VAR(curRouteQuery) = nextQueryToRoute(VAR(curRouteQuery)); 
      TOS_POST_TASK(routeTask); //reschedule ourselves
    }
  } else { 
    UNSET_ROUTING_TUPLES(); //all done routing
  }
}

//Return the next query in the query list that needs to be output
//assumes that all attributes have already been filled out (e.g. fetchNextAttr() returns fals)
//curTuple is changed to point at the tuple corresponding to the returned
//query
QueryListHandle nextQueryToRoute(QueryListHandle curQuery) {
  VAR(curTuple) = NULL;
  if (curQuery == NULL) {
    curQuery = VAR(qs);
  } else 
    curQuery = (QueryListHandle)(**curQuery).next;

  while (curQuery != NULL) {
    if ((**curQuery).q.clocksPerSample > 0 && (**curQuery).q.clockCount <= 0) { //this query is ready to go
      VAR(curTuple) = PQ_GET_TUPLE_PTR(&(**curQuery).q);
      break;
    } else {
      curQuery = (QueryListHandle)(**curQuery).next;
    }
  }
  return curQuery;
}

//route the specified tuple to the first operator of the
//specified query.  This will send the tuple to an operator,
//which will return the tuple when it is done.
//returns true if the tuple was routed, false otherwise
bool routeToQuery(ParsedQuery *q, Tuple *t) {
  Expr *e = nextExpr(q);

  if (e != NULL) {   //assume expressions are listed in the order
    e->success = TRUE;
    if (e->isAgg) {  //they should be executed! (e.g. selections before aggs)
      TOS_CALL_COMMAND(AGGREGATE_TUPLE)(q,t,e);
    } else {
      TOS_CALL_COMMAND(FILTER_TUPLE)(q,t,e);
    }
    return TRUE; //more routing to be done
  } else {
    //don't do this here -- wait til beginning of next epoch
    //    TOS_CALL_COMMAND(DELIVER_TUPLE)(q, t, FALSE);
    return FALSE; //routing all done
  }
}


Expr *nextExpr(ParsedQuery *q) {
  if (++VAR(curExpr) >= q->numExprs) {
    VAR(curExpr) = -1;
    return NULL;
  } else {
    Expr *e = &PQ_GET_EXPR(q,VAR(curExpr));
    return e;
  }
    
}

/* --------------------------------- Query Utility Routines ---------------------------------*/
//return true if the query exists
//if it does, q will point to the parsed query
bool getQuery(byte qid, ParsedQuery **q) {
  QueryListHandle curq;

  curq = VAR(qs);
  while (curq != NULL) {
    if ((**curq).q.qid == qid) {
      *q = &(**curq).q;
      return TRUE;
    } else
      curq = (QueryListHandle)(**curq).next;
  }
  return FALSE;
}



//Given a query, parse it into pq
//return true if successful
bool parseQuery(Query *q, ParsedQuery *pq) {
  AttrDesc *attr;
  int i;

  pq->qid = q->qid;
  pq->numFields = q->numFields;
  pq->numExprs = q->numExprs;
  pq->epochDuration = q->epochDuration;
  pq->currentEpoch = 0;
  for (i = 0; i < q->numFields; i++) {
    printf("Setting field %d (%s)\n", i, GET_FIELD(q,i).name);//fflush(stdout);
    attr = TOS_CALL_COMMAND(GET_ATTR)(GET_FIELD(q,i).name);

    if (attr != NULL) {
      pq->queryToSchemaFieldMap[i] = attr->idx;
    } else {
      pq->queryToSchemaFieldMap[i] = NULL_QUERY_FIELD;
    }
  }
  for (i = 0; i < q->numExprs; i++) {
    Expr e = GET_EXPR(q,i);
    e.idx = i;
    printf (" e.isAgg = %d, e.opVal.field = %d, e.opVal.value = %d\n",
	    e.isAgg, e.ex.opval.field, e.ex.opval.value); //fflush(stdout);
    PQ_SET_EXPR(pq, i, e);
    e = PQ_GET_EXPR(pq,i);
    printf (" e.isAgg = %d, e.opVal.field = %d, e.opVal.value = %d\n",
	    e.isAgg, e.ex.opval.field, e.ex.opval.value); //fflush(stdout);
  }
  return TRUE;
}


//Allocates space for a pending query
bool allocPendingQuery(MemoryCallback callback, Query *q) {
  VAR(allocState) = STATE_ALLOC_IN_FLIGHT_QUERY;
  VAR(allocCallback) = callback;
  return TOS_CALL_COMMAND(DO_ALLOC)(&VAR(tmpHandle), QUERY_SIZE(q));
}

//allocate space for a parsed query
//return true if request succesfully made
//after request compltes, add the result to qs linked list
//and invoke callback with the new memory
bool allocQuery(MemoryCallback callback, Query *q) {
  short size = (sizeof(QueryListEl) - sizeof(ParsedQuery)) + BASE_PQ_SIZE(q);

  VAR(allocState) = STATE_ALLOC_PARSED_QUERY;
  VAR(allocCallback) = callback;

  return TOS_CALL_COMMAND(DO_ALLOC)((Handle *)&VAR(tmpHandle), size);
  
}

//resize q to have space for tuple
bool reallocQueryForTuple(MemoryCallback callback, QueryListHandle qlh) {
  ParsedQuery *q = &(**qlh).q;
  short size = TOS_CALL_COMMAND(HANDLE_SIZE)((Handle)(qlh)) + TOS_CALL_COMMAND(TUPLE_SIZE)(q);

  printf("resizing query for tuple to :  %d \n", size);//fflush(stdout);
  VAR(allocState) = STATE_RESIZE_QUERY;
  VAR(allocCallback) = callback;
  printf("set alloc state to %d\n", VAR(allocState));
  return TOS_CALL_COMMAND(REALLOC_HANDLE)((Handle)qlh, size);

}

/* Return true if we've heard about all the fields for the specified query */
bool queryComplete(Query q) {
  printf ("completeMask = %x, %x\n",q.knownFields, q.knownExprs);//fflush(stdout);
  return (FIELDS_COMPLETE(q) && EXPRS_COMPLETE(q));
}

/* "fixed communication" means that we transmit during a time slot
   proportional to our mote id, rather than learning about the neighborhood
   size from the root and choosing a random time slot based on that size
*/
void TOS_COMMAND(TR_SET_FIXED_COMM)(bool fixed) {
  if (fixed) {
    CLR_RED_LED_PIN();
  } else {
    CLR_GREEN_LED_PIN();
  }
  VAR(fixedComm) = fixed;
}

/* --------------------------------- Memory Callbacks ---------------------------------*/

void TOS_EVENT(ALLOC_COMPLETE)(Handle *handle, char complete) {
  char prev = inp(SREG) & 0x80;

  printf("in alloc complete\n");//fflush(stdout);
  if (VAR(allocState) == STATE_NOT_ALLOCING) return; //not our allocation

  switch (VAR(allocState)) {
  case STATE_ALLOC_PARSED_QUERY:
    VAR(allocState) = STATE_NOT_ALLOCING; //not allocating any more
    if (complete) {

      QueryListHandle qlh = (QueryListHandle)*handle;
      printf("alloced parsed query \n");//fflush(stdout);
      (**qlh).next = NULL;
      (**qlh).q.clocksPerSample = 0; //make sure this query wont be fired yet
      cli(); //modifying this data structure is dangerous -- make sure timer thread doesnt run...
      if (VAR(tail) == NULL) {
	VAR(tail) = qlh;
	VAR(qs) = qlh;
      } else {
	(**VAR(tail)).next = (void **)qlh;
	VAR(tail) = qlh;
      }
      if (prev) sei();

      (*VAR(allocCallback))((Handle *)&VAR(tail)); //allow the application to continue
    } else
      signalError(err_OutOfMemory);
    break;
  case STATE_ALLOC_IN_FLIGHT_QUERY:
    VAR(allocState) = STATE_NOT_ALLOCING; //not allocating any more    
    if (complete) {
      printf("Alloced query.\n"); //fflush(stdout);

      (*VAR(allocCallback))(handle);
    } else
      signalError(err_OutOfMemory);
    break;
  default:
    signalError(err_UnknownAllocationState);
    break;
  }

}

void TOS_EVENT(REALLOC_COMPLETE)(Handle handle, char complete) {
  printf ("in realloc complete, state = %d, resize = %d, not_alloc = %d\n",
	  VAR(allocState), STATE_RESIZE_QUERY, STATE_NOT_ALLOCING); //fflush(stdout);
  if (VAR(allocState) == STATE_NOT_ALLOCING) return; //not our allocation
  if (VAR(allocState) == STATE_RESIZE_QUERY) {
    VAR(allocState) = STATE_NOT_ALLOCING; //not allocating any more
    if (complete)
      (*VAR(allocCallback))(&handle);
    else
      signalError(err_OutOfMemory);
  }
  else
    signalError(err_UnknownAllocationState);

}

void TOS_EVENT(COMPACT_COMPLETE)() {
}

/* --------------------------------- Status Stuff ---------------------------------*/
//Status messages can be used to learn which queries a sensor knows about
//currently there is no java-side interface to support his
TOS_MsgPtr TOS_EVENT(TUPLE_ROUTER_STATUS_MESSAGE)(TOS_MsgPtr msg) {
  StatusMessage *in = (StatusMessage *)msg;

  //status request has no params, for now
  //just fill out status message, send it

  if (!IS_SENDING_MESSAGE() && in->request) {
    StatusMessage *sm = (StatusMessage *)&VAR(msg);
    QueryListHandle curq;

    sm->numQueries = 0;
    sm->request = FALSE;
    sm->sid = TOS_LOCAL_ADDRESS;

    curq = VAR(qs);
    while (curq != NULL && sm->numQueries < sizeof(sm->qids)) {
      sm->qids[(unsigned char)sm->numQueries++] = (**curq).q.qid;
      curq = (QueryListHandle)(**curq).next;
    }
    
    TOS_CALL_COMMAND(TUPLE_ROUTER_SEND_MSG)(in->sid, AM_MSG(TUPLE_ROUTER_STATUS_MESSAGE), &VAR(msg));
    
  }
  return msg;

}

/* --------------------------------- Message Queuing ---------------------------------*/
/* Copy the specified bytes into the message queue
   Return err_MessageSendFailed if the queue is full
*/
TinyDBError enqueueMessage(const char *msg, short len) {
  short slot;

  if (VAR(msgq).size == MSG_Q_LEN) return err_MessageBufferFull;
  slot = VAR(msgq).end++;
  if (VAR(msgq).end >= MSG_Q_LEN)
    VAR(msgq).end = 0;
  VAR(msgq).size++;

  if (len > DATA_LENGTH-sizeof(DbMsgHdr)) len = DATA_LENGTH-sizeof(DbMsgHdr);
  memcpy((char *)(VAR(msgq.msgs[slot]).data) + sizeof(DbMsgHdr) ,(const char *)msg,len);

  //schedule result delivery if needed

  if (VAR(outputCount) <= 0) {
    cli(); //output count shared with time thread
    //schedule the next result to deliver
    if (TOS_LOCAL_ADDRESS == 0) {
      VAR(outputCount) = 1;
    } else {
      if (VAR(fixedComm)) {
	VAR(outputCount) = TOS_LOCAL_ADDRESS * 2;
      }	else {
	VAR(outputCount) = (((TOS_CALL_COMMAND(NEXT_RAND)() & 0x7FFF) % 
			     ((VAR(numSenders) >> 1)+1)) << 1); 
      }
    }
    //    VAR(outputCount) = TOS_LOCAL_ADDRESS * 2;
    sei();
  }

  return err_NoError;

}

/* Copy the message at the top of the queue into the specified buffer
   returns err_NoMoreResults if the queue is empty
*/
TinyDBError dequeueMessage(TOS_Msg *msg) {
  short slot = VAR(msgq).start;

  if (VAR(msgq).size == 0) return err_NoMoreResults;
  if (++VAR(msgq).start == MSG_Q_LEN)
    VAR(msgq).start = 0;
  VAR(msgq).size--;

  memcpy((char *)(msg->data) + sizeof(DbMsgHdr), VAR(msgq).msgs[slot].data + sizeof(DbMsgHdr),  sizeof(msg->data) - sizeof(DbMsgHdr));
  return err_NoError;

}

/* --------------------------------- Error Handling  ---------------------------------*/

void signalError(TinyDBError err) {
  char errStr[20];


  /*
  if (err & 1) 
    CLR_RED_LED_PIN();
  else
    SET_RED_LED_PIN();
  if (err & 2) 
    CLR_GREEN_LED_PIN();
  else
    SET_GREEN_LED_PIN();
  if (err & 4) 
    CLR_YELLOW_LED_PIN();
  else
    SET_YELLOW_LED_PIN();
  */
#ifndef TOSSIM
  char errNo[10];
  errStr[0] = 0;
  itoa(err, errNo, 10);

  strcat(errStr, "Error: ");
  strcat(errStr, errNo);
  strcat(errStr, "\n");
#else
  sprintf(errStr, "Error: %d \n", err);
#endif

  NOTIFY(errStr);
  
}


void statusMessage(char *m) {
#ifdef FULLPC
  printf(m); fflush(stdout);
#else
  if (TOS_LOCAL_ADDRESS != 0)
    TOS_CALL_COMMAND(SEND_UART)(m,1 /* debugging msg id */);
#endif
}
