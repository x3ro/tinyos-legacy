// $Id: QueryHandlerM.nc,v 1.2 2004/07/15 22:56:32 whong Exp $

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
includes Attr;
includes MemAlloc;
includes TinyDB;



module QueryHandlerM {

  uses {
    interface Network;
    interface DBBuffer;
    interface Leds;
    interface TupleIntf;
    interface QueryIntf;
    interface ParsedQueryIntf;
    interface Debugger as UartDebugger;
    interface Table;
    interface MemAlloc;
    interface CommandUse;
    interface AttrUse;
    interface QueryResultIntf;

    command void signalError(TinyDBError err, int lineNo);
  }
  provides {
    interface StdControl ;
    interface QueryProcessor;
  }



}

implementation {

#include "Timing.h"
  #define TDB_SIG_ERR(errNo) call signalError((errNo), __LINE__)

  /** Completion routine for memory allocation complete */
  typedef void (*MemoryCallback)(Handle *memory);


  /* AllocState is used to track what we're currently allocing */
  typedef enum {
    STATE_ALLOC_PARSED_QUERY = 0,
    STATE_ALLOC_IN_FLIGHT_QUERY,
    STATE_RESIZE_QUERY,
    STATE_NOT_ALLOCING,
    STATE_ALLOC_QUERY_RESULT
  } AllocState;

  void continueQuery(Handle *memory);
  bool addQueryField(QueryMessagePtr qmsg);
  bool allocPendingQuery(MemoryCallback callback, Query *q);
  bool allocQuery(MemoryCallback callback, Query *q);
  void parsedCallback(Handle *memory);
  bool parseQuery(Query *q, ParsedQuery *pq);
  void parsedQuery(bool success);
  void continueParsing(result_t success);
  bool queryComplete(Query q);
  
  void finishedOpeningWriteBuffer(ParsedQuery *pq);
  void finishedOpeningReadBuffer(ParsedQuery *pq, uint8_t bufferId);

  bool reallocQueryForTuple(MemoryCallback callback, QueryListHandle qlh);
  void resizedCallback(Handle *memory);
  TinyDBError forwardQuery(QueryMessagePtr qmsg);
  
  void finishedBufferSetup(ParsedQuery *pq);
  bool getQuery(uint8_t qid, ParsedQuery **q);  
  void setSampleRate();
  void failedOpeningWriteBuffer(ParsedQuery *pq);

  void continueFromBufferFetch(TinyDBError err);
  result_t outputDone(TOS_MsgPtr msg);
  
  /* ----------------------------- Module Variables ------------------------------- */

  TOS_Msg mMsg;
  uint16_t mPendingMask;
  QueryListHandle mQs;
  QueryListHandle mTail;
  Query **mCurQuery; //dynamically allocated query handle
  Query *mCurQueryPtr;
  MemoryCallback mAllocCallback; //function to call after allocation
  Handle mTmpHandle;
  AllocState mAllocState;

  QueryListHandle mCurSendingQuery;
  char mCurSendingField;
  char mCurSendingExpr;
  uint32_t mCurQMsgMask;
  TOS_Msg mQmsg;
  bool mTriedAllocWaiting; //tried to create a new query, but allocation flag was true
#ifdef kQUERY_SHARING
  bool mTriedQueryRequest;  //received a request for query from a neighbor, but was buys
#endif
  bool mSendingQuery;
  uint8_t mSendQueryCnt;
  ParsedQuery *mTempPQ;
  uint8_t mCurField;
  uint8_t mQidToRemove;
  bool mForceRemove;
  uint8_t mStoppedQid;

  bool mAllQueriesSameRate;

  // ------------------------- status flags ----------------------------------- 
  uint16_t mPendingMask;

  enum {READING_BIT = 0x0001,  // reading fields for Query from network
         PARSING_BIT = 0x0002, //parsing the query
         ALLOCED_BIT = 0x0004, //reading fields, space is alloced
	SENDING_BIT = 0x0008, //sending message
	OPENING_WRITE_BUF_BIT = 0x0010,
	IN_QUERY_MSG_BIT = 0x0020,
	SENDING_QUERY_BIT = 0x040, //are we sending a query
  };

  bool IS_IN_QUERY_MSG() { return (mPendingMask & IN_QUERY_MSG_BIT) != 0; }
  void UNSET_IS_IN_QUERY_MSG() { (mPendingMask &= ( IN_QUERY_MSG_BIT ^ 0xFFFF)); }
  void SET_IS_IN_QUERY_MSG() { (mPendingMask |= IN_QUERY_MSG_BIT); }

  void SET_READING_QUERY() {(mPendingMask |= READING_BIT);  }
  void UNSET_READING_QUERY() { (mPendingMask &= (READING_BIT ^ 0xFFFF)); }
  bool IS_READING_QUERY() { return (mPendingMask & READING_BIT) != 0; }
  
  void SET_PARSING_QUERY() { (mPendingMask |= PARSING_BIT); }
  void UNSET_PARSING_QUERY() { (mPendingMask &= (PARSING_BIT ^ 0xFFFF)); }
  bool IS_PARSING_QUERY() { return (mPendingMask & PARSING_BIT) != 0; }
  
  bool IS_SPACE_ALLOCED() { return (mPendingMask & ALLOCED_BIT) != 0; }
  void UNSET_SPACE_ALLOCED() { (mPendingMask &= (ALLOCED_BIT ^ 0xFFFF)); }
  void SET_SPACE_ALLOCED() { (mPendingMask |= ALLOCED_BIT); }

  bool IS_SENDING_MESSAGE() { return (mPendingMask & SENDING_BIT) != 0; }
  void UNSET_SENDING_MESSAGE() { (mPendingMask &= (SENDING_BIT ^ 0xFFFF)); }
  void SET_SENDING_MESSAGE() { (mPendingMask |= SENDING_BIT); }

  bool IS_OPENING_WRITE_BUF() { return (mPendingMask & OPENING_WRITE_BUF_BIT) != 0; }
  void UNSET_OPENING_WRITE_BUF() { (mPendingMask &= ( OPENING_WRITE_BUF_BIT ^ 0xFFFF)); }
  void SET_OPENING_WRITE_BUF() { (mPendingMask |= OPENING_WRITE_BUF_BIT); }

  bool IS_SENDING_QUERY() { return (mPendingMask & SENDING_QUERY_BIT) != 0; }
  void UNSET_SENDING_QUERY() { (mPendingMask &= ( SENDING_QUERY_BIT ^ 0xFFFF)); }
  void SET_SENDING_QUERY() { (mPendingMask |= SENDING_QUERY_BIT); }
  


  // ------------------------- tasks  ----------------------------------- 

  task void querySubTask();
  task void sendQuery();
  task void removeQueryTask();
  task void sendQuery();
  task void queryMsgTask();

  // ------------------------- code  ----------------------------------- 


  command result_t StdControl.init() {
    atomic {
      mQs = NULL;
    }
    mTail = NULL;
    mCurQuery = NULL;

    mAllQueriesSameRate = TRUE;

    mAllocState = STATE_NOT_ALLOCING;

    mTriedAllocWaiting = FALSE;
#ifdef kQUERY_SHARING
    mTriedQueryRequest = FALSE;
#endif
    mStoppedQid = 0xFF;

    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }


  command result_t StdControl.stop() {
    return SUCCESS;
  }

  /* --------------------------------- Query Handling ---------------------------------*/




  /** Message indicating the arrival of (part of) a query */
  event result_t Network.querySub(QueryMessagePtr qmsg) {
    if (!mSendingQuery) {
      QueryMessagePtr tmpmsg = call Network.getQueryPayLoad(&mQmsg);
      *tmpmsg = *qmsg;
      post querySubTask();
    }
    return SUCCESS;
  }

  task void querySubTask() {
    ParsedQuery *q;
    QueryMessagePtr qmsg = call Network.getQueryPayLoad(&mQmsg);
    bool oldField = TRUE;

    if (qmsg->msgType == DROP_TABLE_MSG) {
      if (IS_IN_QUERY_MSG())
	return;
      SET_IS_IN_QUERY_MSG();
      //call UartDebugger.writeLine("cleaning",8);
#ifdef kMATCHBOX
      call DBBuffer.cleanupEEPROM();
#endif
      if (qmsg->u.ttl-- > 0)
	forwardQuery(qmsg);
      UNSET_IS_IN_QUERY_MSG();
      return;
    } else
    if (qmsg->msgType == RATE_MSG) {
    //is a request to change the rate of an existing query

      if (IS_IN_QUERY_MSG())
	return;

      SET_IS_IN_QUERY_MSG();


      //can't change the rate of a query we know nothing about!
      if (!getQuery(qmsg->qid, &q)) {
	goto done_rate;
      }
      if (qmsg->fwdNode == TOS_UART_ADDR) {
	forwardQuery(qmsg);
      }
      dbg(DBG_USR2, "changing rate to %d\n", qmsg->epochDuration);
      call QueryProcessor.setRate(qmsg->qid, qmsg->epochDuration);
    done_rate:
      UNSET_IS_IN_QUERY_MSG();
      return;

     } else if (qmsg->msgType == DEL_MSG) {
    //is a request to delete an existing query
      ParsedQuery *pq;
	  bool isKnown;

      call Leds.yellowToggle();

      
      if (IS_IN_QUERY_MSG() )
	return;
      
      SET_IS_IN_QUERY_MSG();
      if (getQuery(qmsg->qid, &pq))
	isKnown = TRUE;
      else
	isKnown = FALSE;

      //call Leds.redOn();
      call Leds.greenOn();
      call Leds.yellowOn();
      //can't force -- might be in flight
      mQidToRemove = qmsg->qid;
      mForceRemove = FALSE;
      post removeQueryTask();
      //only forward if we know about the query, or if we're the root

      if (isKnown) {
	forwardQuery(qmsg);
      }
      mStoppedQid = qmsg->qid;

      UNSET_IS_IN_QUERY_MSG();
      return;
    }

    //otherwise, assume its an ADD_MSG, for now
    if (!IS_IN_QUERY_MSG()) {


      if (!getQuery(qmsg->qid, &q)) { //ignore if we already know about this query
	SET_IS_IN_QUERY_MSG();
	mStoppedQid = 0xFF;  //a new query, not one we just stopped
	//go ahead and time synchronize with the sender of this message
	//XXX doTimeSync(qmsg->timeSyncData, qmsg->clockCount);

	if (IS_READING_QUERY()) {
	  if (qmsg->qid != (**mCurQuery).qid) {
	    if (IS_SPACE_ALLOCED() || mTriedAllocWaiting) {
	      //query is alloced, but heard about a new one
	      //forget old one
	      if (IS_SPACE_ALLOCED()) {
		UNSET_SPACE_ALLOCED();
		dbg(DBG_USR3, "freeing query in READING_QUERY\n");
		 call MemAlloc.free((Handle)mCurQuery);
	      //mCurQuery 
	       }

	      UNSET_READING_QUERY();
	    } else {
	      mTriedAllocWaiting = TRUE;
	      UNSET_IS_IN_QUERY_MSG();
	      return;
	    }
	  } else if (! IS_SPACE_ALLOCED()) {
	    UNSET_IS_IN_QUERY_MSG();
	    return;
	  }  else {  
	    mTriedAllocWaiting = FALSE;
	    oldField = addQueryField(qmsg);
	  }
	
	  //go ahead and forward this guy on, as long as it's new, or we're the root
	  if (!oldField || qmsg->fwdNode == TOS_UART_ADDR)
	    forwardQuery(qmsg);
	}

	//note that we can fall through from previous clause
	if (!IS_READING_QUERY() /*&& !IS_SENDING_MESSAGE()*/) {
	
	  Query pq;
	  QueryMessagePtr qmsgCopy = call Network.getQueryPayLoad(&mMsg);
	
	
	  SET_READING_QUERY();
	  UNSET_SPACE_ALLOCED();
	  mTriedAllocWaiting = FALSE;
	  pq.qid = qmsg->qid;
	  pq.numFields=qmsg->numFields;
	  pq.numExprs=qmsg->numExprs;
	
	  *qmsgCopy = *qmsg; //save a copy
	  //allocate space for query
	  if (!allocPendingQuery(&continueQuery, &pq)) {
	    UNSET_READING_QUERY(); //barf!
	  }
	}
      }  else if (qmsg->fwdNode == TOS_UART_ADDR)  //forward on if it comes from UART
		forwardQuery(qmsg);
      UNSET_IS_IN_QUERY_MSG();
    }

  }
  
  /** Forward out a query message, setting errors as appropriate if the radio is already
      busy.

      Note, this uses the mMsg module variable.
      @param msg The message to send (a copy is made into mMsg, so the application can overwrite after this call)
      @return err_MSF_ForwardKnownQuery if message send failed, err_MSG_ForwardKnownQueryBusy if radio was busy
  */
  TinyDBError forwardQuery(QueryMessagePtr qmsg) {
    TinyDBError err = err_NoError;

    if (!IS_SENDING_MESSAGE()) {
      QueryMessagePtr qmsgCopy;
      SET_SENDING_MESSAGE();
      qmsgCopy = call Network.getQueryPayLoad(&mMsg);
      *qmsgCopy = *qmsg;
      qmsgCopy->fwdNode = TOS_LOCAL_ADDRESS;
      //XXX
      //mMustTimestamp = TS_QUERY_MESSAGE;
      //mTimestampMsg = &mMsg;
      post queryMsgTask();
    } else
      err = err_MSF_ForwardKnownQueryBusy;

    if (err != err_NoError)
      TDB_SIG_ERR(err);
    return err;

  }
  /** Continuation after query is successfully alloc'ed
      @param memory The newly allocated handle (must to be non-null)
  */
  void continueQuery(Handle *memory) {
    QueryMessage *qmsg = call Network.getQueryPayLoad(&mMsg);
    short i; 

    mCurQuery = (Query **)*memory;
    (**mCurQuery).qid = qmsg->qid;
    (**mCurQuery).numFields=qmsg->numFields;
    (**mCurQuery).numExprs=qmsg->numExprs;
    (**mCurQuery).epochDuration=qmsg->epochDuration;
    (**mCurQuery).fromBuffer = qmsg->fromBuffer;
    (**mCurQuery).fromCatalogBuffer = qmsg->fromCatalogBuffer;
    (**mCurQuery).bufferType = qmsg->bufferType;
    (**mCurQuery).queryRoot = 0; // obsoleted
    (**mCurQuery).knownFields = 0;
    (**mCurQuery).knownExprs = 0;
    (**mCurQuery).needsEvent = qmsg->hasEvent;
    dbg(DBG_USR2, "needsEvent = %d, qms.hasEvent = %d", (**mCurQuery).needsEvent,qmsg->hasEvent);
    (**mCurQuery).hasForClause = qmsg->hasForClause;

    if ((**mCurQuery).bufferType != kRADIO) {
      //special buffer info
      (**mCurQuery).hasBuf = FALSE;
      (**mCurQuery).buf.cmd.hasParam = FALSE;
    }

    (**mCurQuery).hasEvent = FALSE;
  
    dbg (DBG_USR3, "num fields = %d\n", qmsg->numFields);

    for (i = qmsg->numFields; i < MAX_FIELDS; i++)
      (**mCurQuery).knownFields |= (1 << i);
    for (i = qmsg->numExprs; i < MAX_EXPRS; i++)
      (**mCurQuery).knownExprs |= (1 << i);
  
    dbg (DBG_USR3, "completeMask = %x, %x\n",(**mCurQuery).knownFields, (**mCurQuery).knownExprs);

    SET_SPACE_ALLOCED();
    addQueryField(qmsg);

    //now forward the message on
    forwardQuery(qmsg);

  }

  /** Given a query message, add the corresponding
      field or expression to a partially completed query
      @return true iff we already knew about this field
      @param msg The query message
  */
  bool addQueryField(QueryMessagePtr qmsg) {
    bool knewAbout = FALSE;

    if (qmsg->type == kFIELD) {
      call QueryIntf.setField(*mCurQuery, (short)qmsg->idx, qmsg->u.field);
      knewAbout = ((**mCurQuery).knownFields & (1 << qmsg->idx)) != 0;
      (**mCurQuery).knownFields |= (1 << qmsg->idx);
      //dbg (DBG_USR3,"Setting field idx %d\n",qmsg->idx); //fflush(stdout);
    } else if (qmsg->type == kEXPR) {
      qmsg->u.expr.opState = NULL; //make sure we clear this out
      call QueryIntf.setExpr(*mCurQuery, qmsg->idx, qmsg->u.expr);
      //call statusMessage(((char *)*mCurQuery) + 24);
      //dbg (DBG_USR3, "Setting expr idx %d\n",qmsg->idx); //fflush(stdout);
      knewAbout = ((**mCurQuery).knownExprs & (1 << qmsg->idx)) != 0;
      (**mCurQuery).knownExprs |= (1 << qmsg->idx);
    } else if (qmsg->type == kBUF_MSG) {
      knewAbout = (**mCurQuery).hasBuf;
      (**mCurQuery).hasBuf = TRUE;
      (**mCurQuery).buf = qmsg->u.buf;
    } else if (qmsg->type == kEVENT_MSG) {

      knewAbout = (**mCurQuery).hasEvent;
      (**mCurQuery).hasEvent = TRUE;
      strcpy((**mCurQuery).eventName,
	     qmsg->u.eventName);
      dbg(DBG_USR2, "GOT EVENT: %s\n", (**mCurQuery).eventName);
    } else if (qmsg->type == kN_EPOCHS_MSG)
	{
      knewAbout = (**mCurQuery).hasForClause;
      (**mCurQuery).hasForClause = TRUE;
	  (**mCurQuery).numEpochs = qmsg->u.numEpochs;
      dbg(DBG_USR2, "GOT NumEpochs: %d\n", (**mCurQuery).numEpochs);
	}

    if (queryComplete(**mCurQuery)) {
      SET_PARSING_QUERY();

      //allocate a parsed query for this query, initialize it
      dbg(DBG_USR3,"Query is complete!\n");//fflush(stdout);

      //lock this down, since we'll be using it for awhile
      call MemAlloc.lock((Handle)mCurQuery);

      allocQuery(&parsedCallback, *mCurQuery);
    }
    return knewAbout;
  }

  /** Called when the buffer has been allocated */
  void finishedBufferSetup(ParsedQuery *pq) {
    //all done
    UNSET_READING_QUERY();
    UNSET_PARSING_QUERY();
		signal startedQuery(pq);
  }

  /** Continuation after parsed query is successfully alloc'ed
      NOTE: after we setup query, need to resize for tuple at end of query...
      @param memory Newly allocated handle for the parsed query
  */
  void parsedCallback(Handle *memory) {
    QueryListHandle h = (QueryListHandle)*memory;  //this has already been allocated
    Expr e;

    //dbg(DBG_USR3,"in parsed callback \n");//fflush(stdout);

    e = call QueryIntf.getExpr(*mCurQuery, 0);
    call MemAlloc.lock((Handle)h);
    dbg(DBG_USR3,"parsing \n");//fflush(stdout);
    mTmpHandle = (Handle)h;
    if (!parseQuery(*mCurQuery, &((**h).q))) { //failure?
      (**h).q.qid = (**mCurQuery).qid;   //cleanup
      //we know it's idle, so force
	  mQidToRemove = (**h).q.qid;
	  mForceRemove = TRUE;
      post removeQueryTask();
      call MemAlloc.unlock((Handle)h);
      call MemAlloc.unlock((Handle)mCurQuery);
      call MemAlloc.free((Handle)mCurQuery);
      UNSET_READING_QUERY();
      UNSET_PARSING_QUERY();
      return;
    } 
  }

  /** Callback routine that indicates parsing is complete */
  void parsedQuery(bool success) {
    QueryListHandle h = (QueryListHandle)mTmpHandle;
    int qid = (**mCurQuery).qid; 
    TinyDBError err = err_NoError;

    //dbg(DBG_USR3,"unlocking \n");//fflush(stdout);
    call MemAlloc.unlock((Handle)h);
    //locked this earlier
    call MemAlloc.unlock((Handle)mCurQuery);
    call MemAlloc.free((Handle)mCurQuery);
    mCurQuery = NULL;
    if (success) {
      dbg(DBG_USR3,"finished, now resizing\n");//fflush(stdout);
      if (reallocQueryForTuple(&resizedCallback, (QueryListHandle)h) == FALSE) {
	err = err_OutOfMemory;
	goto fail;
      }
    } else {
      err = err_UnknownError;
      goto fail;
    }
    
    return;
    
  fail:
    if (err != err_UnknownError) TDB_SIG_ERR(err);

    (**h).q.qid = qid;   //cleanup

    //we know it's idle, so force
    mQidToRemove = qid;
    mForceRemove = TRUE;
    post removeQueryTask();

    UNSET_READING_QUERY();
    UNSET_PARSING_QUERY();
      
  }
  
  /** Continuation after the query is realloced to include space for a tuple
      @param memory Resized parsed query
  */
  void resizedCallback(Handle *memory) {
    QueryListHandle h = (QueryListHandle)*memory;  //this has already been allocated
    ParsedQuery *pq = &((**h).q);
    bool pending = FALSE;
    TinyDBError err = err_NoError;

    dbg(DBG_USR3,"finished with resizing\n");//fflush(stdout);
    

    //set up the output buffer for this query

    switch (pq->bufferType) {
    case kRADIO:
      pq->bufferId = kRADIO_BUFFER;
      break;
    case kRAM: 
    case kEEPROM:
      {
	RamBufInfo *ram = &pq->buf.ram;
	
	//look to see if we're logging to an already created (named) buffer
	if (ram->hasOutput) {
	  mTempPQ = pq;

	  if (strlen(ram->outBufName) != 0 && !ram->create ) {
    
	    //we'll get an error from this call if the buffer doesn't exist
	    err = call DBBuffer.getBufferIdFromName(ram->outBufName,&pq->bufferId);
	    if (err != err_NoError) {
	      //if it doesn't exist, look for it in the header
	      SET_OPENING_WRITE_BUF();
#ifdef kMATCHBOX
	      if (pq->bufferType == kEEPROM) err = call DBBuffer.loadEEPROMBuffer(ram->outBufName);
#else
	      err = err_NoMatchbox;
#endif
	      if (err !=  err_NoError) {
		TDB_SIG_ERR(err);
		goto fail;
	      }  else
		pending = TRUE;
	      
	    }

	    if (!pending) {
	      call DBBuffer.openBuffer(pq->bufferId, &pending);
	    }
	    
	  } else {
	    err = call DBBuffer.nextUnusedBuffer(&pq->bufferId);
	    
	    if (err == err_NoError) {
	      //call UartDebugger.writeLine("CREATE BUF", 10);
	      err = call DBBuffer.alloc(pq->bufferId, pq->bufferType, ram->numRows, ram->policy, pq , ram->outBufName, &pending, 0);
	    }
	  }
	  mTempPQ = pq;
	  //--SRM--
	  // err = call DBBuffer.openBufferForWriting(pq->bufferId, &pending);
	  //next state -- call finishedOpeningBuffer

	  if (!pending) {
	    //call UartDebugger.writeLine("nopending", 9);
	    finishedOpeningWriteBuffer(pq);
	  }
	  return;

	} else {
	  pq->bufferId = kRADIO_BUFFER;
	}
      }
      break;
    case kCOMMAND:
      {
	long cmd_param;
	uint8_t *cmd_buf = (uint8_t *)&cmd_param;
	CommandDescPtr cmd = call CommandUse.getCommand(pq->buf.cmd.name);
	
	if (cmd == NULL) {
	  TDB_SIG_ERR(err_UnknownCommand);
	  goto fail;
	}
	
	cmd_buf[0] = cmd->idx;
	*(short *)(&cmd_buf[1]) = pq->buf.cmd.param;
	
	err = call DBBuffer.nextUnusedBuffer(&pq->bufferId);
	if (err == err_NoError)
	  err = call DBBuffer.alloc(pq->bufferId, kCOMMAND, 0, 0, NULL, NULL, &pending, cmd_param);
	if (err != err_NoError) {
	  TDB_SIG_ERR(err);
	  goto fail;
	}
      }
      break;
    default:
	TDB_SIG_ERR(err_UnknownError);
	goto fail;
    }

    if (!pending) finishedBufferSetup(pq);
    return;

  fail:
    failedOpeningWriteBuffer(pq);
    return;
  }

  /* Called when the write buffer fails to open properly */
  void failedOpeningWriteBuffer(ParsedQuery *pq) {

    
    //we know it's idle, so force
	mQidToRemove = pq->qid;
	mForceRemove = TRUE;
    post removeQueryTask();
    UNSET_READING_QUERY();
    UNSET_PARSING_QUERY();    
  }

  /* Should be called after a RAM or EEPROM buffer has been successfully
     opened for writing. Typechecks the buffer and complete query allocation.
  */
  void finishedOpeningWriteBuffer(ParsedQuery *pq) {

    dbg(DBG_USR2,"TYPECHECKING\n");
    //now, we need to type check the buffer with our schema
    if (!(call ParsedQueryIntf.typeCheck(*(call DBBuffer.getSchema(pq->bufferId)), pq))) {
      //TDB_SIG_ERR(err_Typecheck);
      goto fail;
    } else {
      //call UartDebugger.writeLine("typechecked", 11);
    }
    dbg(DBG_USR2,"TYPECHECKED\n");
    
    finishedBufferSetup(pq);

    return;
  fail:
    failedOpeningWriteBuffer(pq);
    return;
  }

  /** Remove a query from the tuple router

     @param qid The query to remove
     @param success Set TRUE if the query was succesfully removed, FALSE if the query
     couldn't be found or an error occurred.
     @param force Remove this query even if it may be in flight
     @return err_RemoveRouterFailed if router is in a state such that the
     query may be use, err_NoError otherwise.
  */
  task void removeQueryTask() {
    //remove information about the specified query id
    QueryListHandle curq;
    QueryListHandle last = NULL;

    curq = mQs;
    while (curq != NULL) {
      if ((**curq).q.qid == mQidToRemove) {       //this is the one to remove
	//best not remove if we're currently sending out this query!

	if (IS_SENDING_QUERY() && (**mCurSendingQuery).q.qid == (**curq).q.qid) {
	  TDB_SIG_ERR(err_RemoveFailedRouterBusy);
	  return;
	}
	if (last != NULL) {       //not the first element
	  (**last).next = (**curq).next;
	} else {  //the first element
	  atomic {
	    mQs = (QueryListHandle)(**curq).next;
	  }
	}

	if (mTail == curq) //was the last element
	  mTail = last; //ok if this is also the first element, since this will now be NULL
	if (mQs == NULL) { //no more queries, stop the clock!
	  signal QueryProcessor.allQueriesStopped();
	} 

#ifdef kSUPPORTS_EVENTS
	//delete correspondance between the command and event
	//NOTE: we don't delete the command here -- command interface will allow us to
	// redefine this command id later, so let's not worry about it
	if ((**curq).q.hasEvent) {

	  EventDescPtr e = call EventUse.getEventById((**curq).q.eventId);
	  CommandDescPtr c = call CommandUse.getCommandById((**curq).q.eventCmdId);
	  if (e != NULL && c != NULL) {
	    dbg(DBG_USR2, "Removing correspondance between event %s and command %s\n", e->name, c->name);
	    call EventUse.deleteEventCallback(e->name, c->name);
	    
	  }
	}
#endif

	//notify children (e.g. AGG_OPERATOR) that this query is complete
	dbg(DBG_USR2,"ENDING QUERY : %d\n", (**curq).q.qid);
	signal QueryProcessor.queryComplete(&(**curq).q);
	call MemAlloc.free((Handle)curq);
	return;
      } else {
	last = curq;
	curq = (QueryListHandle)(**curq).next;
      }
    }
  }

  /** Send mCurSendingQuery to a neighbor (we assume the query is in
   mCurSendingQuery because the sending must be done in multiple phases)
  */
  task void sendQuery() {
    //this task assembles the query one field / attribute at a time,
    //send each out in a separate radio message (just like they are delivered).
    //task is resceduled after SEND_DONE_EVENT fires
    QueryListHandle curq = mCurSendingQuery;
    QueryMessage *qmsg = call Network.getQueryPayLoad(&mQmsg);

    mSendingQuery=FALSE;
    if (curq == NULL) {
      UNSET_SENDING_QUERY();
      return;
    }

    //NOTE -- we don't current share queries that aren't over the base
    //sensor data!
    if ((**curq).q.fromBuffer != kNO_QUERY) {
      UNSET_SENDING_QUERY();
      return;
    }

	// find the next requested query message
	while (mCurSendingField < (**curq).q.numFields &&
		   (mCurQMsgMask & (1 << mCurSendingField)))
		mCurSendingField++;
    if (mCurSendingField < (**curq).q.numFields) {
      char fieldId = call ParsedQueryIntf.getFieldId(&(**curq).q, (short)mCurSendingField);

      qmsg->msgType = ADD_MSG;
      qmsg->qid = (**curq).q.qid;

      qmsg->numFields = (**curq).q.numFields;
      qmsg->numExprs = (**curq).q.numExprs;
      qmsg->fromBuffer = (**curq).q.fromBuffer;
      qmsg->fromCatalogBuffer = (**curq).q.fromCatalogBuffer;
      qmsg->hasForClause = (**curq).q.hasForClause;
      qmsg->epochDuration = (**curq).q.epochDuration;
      qmsg->bufferType = (**curq).q.bufferType;
      qmsg->fwdNode = TOS_LOCAL_ADDRESS;

      mCurSendingField++;
      if (!(call ParsedQueryIntf.queryFieldIsNull(fieldId))) {
	AttrDescPtr attr = call AttrUse.getAttrById(fieldId);

	qmsg->type = kFIELD;
	qmsg->idx = mCurSendingField-1;
	strcpy(qmsg->u.field.name, attr->name);
	
	call Leds.greenToggle();

	if (!IS_SENDING_MESSAGE()) {
	  SET_SENDING_MESSAGE();
	
	  atomic {
	    //XXX
	    //mMustTimestamp = TS_QUERY_MESSAGE;
	    //mTimestampMsg = &mQmsg;
	  }
	  if (call Network.sendQueryMessage(&mQmsg) != err_NoError) {
	    UNSET_SENDING_MESSAGE();
	    //XXX
	    //atomic {
	      //mMustTimestamp = TS_NO;
	    //}
		mSendingQuery = TRUE;
	  	post sendQuery(); // try the next field
	  }
	}

      } else {
	//field is null (we don't know what it's name should be) -- do the next one
	mSendingQuery = TRUE;
	post sendQuery();


      }
    } else {
      // find the next requested query message
      while (mCurSendingExpr < (**curq).q.numExprs &&
	     (mCurQMsgMask & (1 << (**curq).q.numFields + mCurSendingExpr)))
	mCurSendingExpr++;
      if (mCurSendingExpr < (**curq).q.numExprs) {
	Expr e = call ParsedQueryIntf.getExpr(&(**curq).q, mCurSendingExpr);
	mCurSendingExpr++;
	
	qmsg->type = kEXPR;
	qmsg->idx = mCurSendingExpr-1;
	qmsg->u.expr = e; //this could be bad! (extra bytes on end of expression might overwrite memory)
	
	//call Leds.redToggle();
	
	if (!IS_SENDING_MESSAGE()) {
	  SET_SENDING_MESSAGE();
	  //XXX
	  //atomic {
	  //  mMustTimestamp = TS_QUERY_MESSAGE;	
	  //  mTimestampMsg = &mQmsg;
	  //}
	  if (call Network.sendQueryMessage(&mQmsg) != err_NoError) {
	    UNSET_SENDING_MESSAGE();
	    //XXX
	    //atomic {
	    //  mMustTimestamp = TS_NO;
	    // }
	    mSendingQuery = TRUE;
	    post sendQuery(); //try the next field;
	  }
	}
	//send the command that should be invoked in response to this query
      } else if ((**curq).q.bufferType != kRADIO && 
		 mCurSendingExpr == (**curq).q.numExprs &&
		 !(mCurQMsgMask & (1 << ((**curq).q.numFields + (**curq).q.numExprs)))) { 
	qmsg->type =  kBUF_MSG;
	qmsg->u.buf = (**curq).q.buf;
	mCurSendingExpr++;
	
	call Leds.yellowToggle();
	
	if (!IS_SENDING_MESSAGE()) {
	  SET_SENDING_MESSAGE();
	  
	  if (call Network.sendQueryMessage(&mQmsg) != err_NoError)
	    UNSET_SENDING_MESSAGE();
	  UNSET_SENDING_QUERY();
	}
	
	
      }
      else {
	UNSET_SENDING_QUERY();
      }
    }
    
    
  }

#ifdef kQUERY_SHARING
  /** Message indicating neighbor requested a query from us 
      If we know about the query, and aren't otherwise
      occupied with sending / routing, send the query back

      @param The QueryRequestMessage from the neighbor
   */
  event result_t Network.queryRequestSub(QueryRequestMessagePtr qmsg) {
    char qid = qmsg->qid;

    QueryListHandle curq;
  
    //if we're already sending this query, ignore duplicate
    //requests...
    if (IS_SENDING_QUERY() && mCurSendingQuery && mSendQueryCnt < 5) {
      if (qid == (**mCurSendingQuery).q.qid)
	return SUCCESS;
    }

	mSendQueryCnt = 0;


    //triedQueryRequest flag set to true when a neighbor requests a
    //query but we're sending another one

    //if we get another such request, we'll abort the current one (ick)
    if (!IS_SENDING_MESSAGE() && (!IS_SENDING_QUERY() || mTriedQueryRequest)) {
      mTriedQueryRequest = FALSE;
      mCurSendingQuery = NULL;
      SET_SENDING_QUERY();
    } else {
      mTriedQueryRequest = TRUE;
      return SUCCESS;
    }
  

    curq = mQs;
    while (curq != NULL) {

      if ((**curq).q.qid == qid) {
	//the query we're supposed to send
	mCurSendingField = 0;
	mCurSendingExpr = 0;
	mCurSendingQuery = curq;
	mCurQMsgMask = qmsg->qmsgMask;
			mSendingQuery = TRUE;
	post sendQuery();

	break;
      }
      curq = (QueryListHandle)(**curq).next;
    }

    if (!mCurSendingQuery) UNSET_SENDING_QUERY();
  
    return SUCCESS;
  }
#endif

  // return a bit vector representing the query messages that have already
  // be received for query sharing.  This avoids repeatedly sending all query
  // messages for sharing
  static uint32_t getQueryMsgMask()
  {
	uint32_t mask = 0;
  	if (IS_READING_QUERY()) {
		QueryPtr q = *mCurQuery;
		short i;
		mask = q->knownFields;
		mask |= (q->knownExprs << q->numFields);
		if (q->bufferType != kRADIO && q->hasBuf)
			mask |= (1 << (q->numFields + q->numExprs));
		else
			mask &= ~(1 << (q->numFields + q->numExprs));
		// clear the rest of the bits
		for (i = q->numFields + q->numExprs + 1; i < 32; i++)
			mask &= ~(1 << i);
	}
	return mask;
  }

  task void queryMsgTask() {
    if (call Network.sendQueryMessage(&mMsg) != err_NoError) {
      UNSET_SENDING_MESSAGE();
      //XXX
      //       atomic {
      // 	mMustTimestamp = TS_NO;
      //       }

    }
  }



  /** A message not directly addressed to us that we overhead
      Used for query sharing

      @param msg The message
      @param amId The amid of the message
      @param isParent If the message is from our parent
  */
  event result_t Network.snoopedSub(QueryResultPtr qrMsg, bool isParent, uint16_t senderid) {
    ParsedQuery *q;
    uint8_t qid;
    QueryRequestMessage *qreq = call Network.getQueryRequestPayLoad(&mMsg);

    //check and see if it has information about a query we haven't head before

#ifdef kQUERY_SHARING

    call Leds.greenToggle();

      qid = call QueryResultIntf.queryIdFromMsg(qrMsg);
      //is this a query we've never heard of before?

      if (!getQuery(qid, &q) && qid != mStoppedQid) {
	if (!IS_SENDING_MESSAGE()) {
	  SET_SENDING_MESSAGE();
	  qreq->qid = qid;
	  qreq->qmsgMask = getQueryMsgMask();

	  if (call Network.sendQueryRequest(&mMsg, senderid) != err_NoError)
	    UNSET_SENDING_MESSAGE();
	}
	
      } else if (qid == mStoppedQid) {
	//send a cancel message
	QueryMessage *qm = call Network.getQueryPayLoad(&mMsg);
	
	SET_SENDING_MESSAGE();
	qm->qid = qid;
	qm->msgType = DEL_MSG;	
	call Leds.yellowToggle();
	post queryMsgTask();
	
	}
	
#endif
  
    return SUCCESS;
  }


  event result_t Network.dataSub(QueryResultPtr qrMsg) {
    return SUCCESS;
  }
  
  /** Set the EPOCH DURATION of the specified query to the specifed value.
      @param qid The query that needs its sample rate adjusted
      @param epochDur The new epoch duration for qid
   */

  void command QueryProcessor.setRate(uint8_t qid, uint16_t epochDur) {
    ParsedQuery *q;
    if (getQuery(qid, &q)) {
      q->clocksPerSample = (uint16_t)((((uint32_t)epochDur * kBASE_EPOCH_RATE) / (uint32_t)kMS_PER_CLOCK_EVENT));

    }
  }
  

/* ================================== Query Processor Interface ============================== */

  command ParsedQueryPtr QueryProcessor.getQueryCmd(uint8_t qid) {
    ParsedQueryPtr pq;
    if (getQuery(qid,&pq))
      return pq;
    else
      return NULL;
  }


  command bool  QueryProcessor.getQuery(uint8_t qid, ParsedQueryPtr *pq) {
    return getQuery(qid,pq);
  }

  command short QueryProcessor.numQueries() {
    QueryListHandle curq;
    short count = 0;

    curq = mQs;
    while (curq != NULL) {
      count++;
      curq = (QueryListHandle)(**curq).next;
    }
    return count;
  }


  command ParsedQueryPtr QueryProcessor.getQueryIdx(short i) {
    QueryListHandle curq;

    curq = mQs;
    while (curq != NULL) {
      if (i-- == 0) return &(**curq).q;
      curq = (QueryListHandle)(**curq).next;
    }
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
    qid = call QueryResultIntf.queryIdFromMsg(call Network.getDataPayLoad(msg));

    pq = call QueryProcessor.getQueryCmd(qid);

    if (pq == NULL) {
      root =  -1;
    }
    else {
      root =pq->queryRoot;
    }
    return root;
  }


  command bool QueryProcessor.queryProcessorWantsData(QueryResultPtr qr) {
    uint8_t qid = qr->qid;
    ParsedQuery *pq = call QueryProcessor.getQueryCmd(qid);

    if (pq == NULL) {
      return FALSE;
    } else {
      return pq->hasAgg;
    }
    return FALSE;
  }

command QueryListHandle QueryProcessor.getQueryList() {
    return mQs;
  }

 command bool QueryProcessor.allQueriesSameRate() {
   return mAllQueriesSameRate;
 }
 
command result_t QueryProcessor.removeQuery(uint8_t qid, bool force) {
  //should really check a status flag
  mQidToRemove = qid;
  mForceRemove = force;
  post removeQueryTask();
  return SUCCESS;
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
    *q = NULL;
    return FALSE;
  }


  /** Given a query, parse it into pq
      @param q The query to convert
      @param pq The parsed query to fill in.  Assumes that
      pq has been allocated with ParsedQueryIntf.pqSize(q) bytes.
      @return TRUE if successful
  */
  bool parseQuery(Query *q, ParsedQuery *pq) {

    TinyDBError err;
    bool pending = FALSE;

    dbg(DBG_USR3, "## TupleRouterM.parseQuery called\n");
    
    
    pq->qid = q->qid;
    pq->numFields = q->numFields;
    pq->numExprs = q->numExprs;
    pq->epochDuration = q->epochDuration;
    pq->savedEpochDur = q->epochDuration;
	pq->numEpochs = q->numEpochs;
    pq->fromBuffer = q->fromBuffer;
    pq->bufferType = q->bufferType;
    pq->bufferId = q->bufferId;
    pq->markedForDeletion = 0;
    pq->currentEpoch = 0;
    pq->buf = q->buf;
    pq->queryRoot = q->queryRoot;
    pq->hasEvent = q->hasEvent;
    pq->tableInfo = NULL;
    pq->hasAgg = FALSE;

    pq->fromCatalogBuffer = q->fromCatalogBuffer;

    mCurQueryPtr  = q;
    mTempPQ = pq;

    if (q->hasEvent) {
#ifdef kSUPPORTS_EVENTS
      char queryIdStr[5];
      ParamList params;
      EventDesc *evt;

      queryIdStr[0] = 0;
  #if defined(PLATFORM_PC) //itoa not on pc
      sprintf(queryIdStr,"%d", q->qid);
  #else
      itoa(q->qid, queryIdStr, 10);
  #endif
      params.numParams = 0;

      dbg(DBG_USR2, "registering command %s for event %s\n",  queryIdStr, q->eventName);

      //make sure this is a known event
      evt = call EventUse.getEvent(q->eventName);
      if (evt == NULL) return FALSE;

      //now, register ourselves as the command handler for this event
      if (call EventFiredCommand.registerCommand(queryIdStr,VOID, 0, &params) == FAIL)
	return FALSE;
      
      pq->eventId = evt->idx;
      pq->eventCmdId = (call CommandUse.getCommand(queryIdStr))->idx;
      //request that our command be called whenever this event fires.
      if (call EventUse.registerEventCallback(q->eventName, queryIdStr) == FAIL) {
	return FALSE;
      }
      dbg(DBG_USR2, "registration successuful.\n");
      //this query is started by an event... 
#endif
      pq->running= FALSE;
    } else {
      //if query isn't triggered by an event, it's running
      if ((pq->bufferType == kRAM || pq->bufferType == kEEPROM) &&
	  pq->buf.ram.create == 1)
	pq->running = FALSE;
      else
	pq->running = TRUE;
    }

    //initial fromBuffer here if we have a named input buffer
    if (pq->bufferType == kRAM || pq->bufferType == kEEPROM) {
      RamBufInfo *ram = &pq->buf.ram;
    
      
      if (ram->hasInput) {
	uint8_t bufId;

	err = call DBBuffer.getBufferIdFromName(ram->inBufName,&bufId);
	if (err != err_NoError) {
	  //if it doesn't exist, look for it in the header
	  UNSET_OPENING_WRITE_BUF(); 
	  
	  if (pq->bufferType == kEEPROM) {
#ifdef kMATCHBOX
	    err = call DBBuffer.loadEEPROMBuffer(ram->inBufName);
#else
	    err = err_NoMatchbox;
#endif
	  }
	  if (err !=  err_NoError) {
	    TDB_SIG_ERR(err);
	    return FALSE;
	  }  else
	    pending = TRUE;
	}


	if (!pending) {
	  err = call DBBuffer.qidFromBufferId(bufId, &pq->fromBuffer);
	  if (err != err_NoError) {
	    TDB_SIG_ERR(err);
	    return FALSE;
	  }
	}
      }
    }

    if (!pending) continueFromBufferFetch(err_NoError);

    return TRUE;
  }

  //Called on return from loadEEPromBuffer or from parseQuery 
  void continueFromBufferFetch(TinyDBError err) {
    ParsedQuery *pq = mTempPQ;

    uint8_t bufferId;
    uint8_t i;

    if (err != err_NoError) {
      //      TDB_SIG_ERR(err);
      parsedQuery(FALSE);
      return;
    }

    if ((pq->bufferType == kRAM || pq->bufferType == kEEPROM) && pq->buf.ram.hasInput) {
      RamBufInfo *ram = &pq->buf.ram;
      err = call DBBuffer.getBufferIdFromName(ram->inBufName,&bufferId);
      if (err != err_NoError) {
	TDB_SIG_ERR(err);
	parsedQuery(FALSE);
	return;
      }

      err = call DBBuffer.qidFromBufferId(bufferId, &pq->fromBuffer);
      if (err != err_NoError) {
	TDB_SIG_ERR(err);
	parsedQuery(FALSE);
	return;
      }
    }


    mCurField = 0;

    if ((uint8_t)pq->fromBuffer != kNO_QUERY) {
      err = call DBBuffer.getBufferId(pq->fromBuffer, pq->fromCatalogBuffer, &bufferId);
      if (err != err_NoError) {
	TDB_SIG_ERR(err);
	parsedQuery(FALSE);
	return;
      }
      
      //call UartDebugger.writeLine("getting map", 11);

      for (i = 0; i < pq->numFields; i++) {
	Field f = call QueryIntf.getField(mCurQueryPtr,i);
	err = call DBBuffer.getFieldId(bufferId, &f, &pq->queryToSchemaFieldMap[i]);
	if (err != err_NoError)
	  TDB_SIG_ERR(err);
      }


    }


    continueParsing(SUCCESS); //continue, split phased possibly
  }

  /** Finish parsing, to allow split phase operations
      which allocate named query fields to complete
      Must be called initially from parsedQuery.
  */
  void continueParsing(result_t success) {
    int i;
    ParsedQuery *pq = mTempPQ;
    Query *q = mCurQueryPtr;
    AttrDesc *attr;
    
    if (!success) parsedQuery(FALSE);

    if (pq->fromBuffer == kNO_QUERY) { //did fromBuffer above.
      while (mCurField < q->numFields) {
	Field *f = call QueryIntf.getFieldPtr(q,mCurField);
	//dbg(DBG_USR3,"Setting field %d (%s)\n", mCurField, f->name);//fflush(stdout);
	
	if ((pq->bufferType == kRAM  || pq->bufferType == kEEPROM) && pq->buf.ram.create == 1) {
	  //add the field -- split phase op
	  pq->queryToSchemaFieldMap[mCurField] = TYPED_FIELD;
	  call Table.addNamedField(pq, mCurField++, f->name, f->type);
	  return;
	} else {
	  attr = call AttrUse.getAttr(f->name);
	  if (attr != NULL) {
	    pq->queryToSchemaFieldMap[mCurField] = attr->idx;
	  } else {
	    pq->queryToSchemaFieldMap[mCurField] = NULL_QUERY_FIELD;
	  }
	  mCurField++;
	}
      }
    }

    for (i = 0; i < q->numExprs; i++) {
      Expr e = call QueryIntf.getExpr(q,i);
      
      e.idx = i;
      //dbg(DBG_USR3," e.opType = %d, e.opVal.field = %d, e.opVal.value = %d\n",
      //	      e.opType, e.ex.opval.field, e.ex.opval.value); //fflush(stdout);
      call ParsedQueryIntf.setExpr(pq, i, e);
      e = call ParsedQueryIntf.getExpr(pq,i);
      //dbg(DBG_USR3," e.opType = %d, e.opVal.field = %d, e.opVal.value = %d\n",
      //e.opType, e.ex.opval.field, e.ex.opval.value); //fflush(stdout);
      if (e.opType != kSEL)
	pq->hasAgg = TRUE;
    }




    parsedQuery(TRUE);
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
	

    //dbg(DBG_USR3,"resizing query for tuple to :  %d \n", size);//fflush(stdout);
    mAllocState = STATE_RESIZE_QUERY;
    mAllocCallback = callback;
    //dbg(DBG_USR3,"set alloc state to %d\n", mAllocState);
    return call MemAlloc.reallocate((Handle)qlh, size);

  }

  /** Return TRUE if we've heard about all the fields for the specified query */
  bool queryComplete(Query q) {
    //dbg(DBG_USR3,"completeMask = %x, %x\n",q.knownFields, q.knownExprs);//fflush(stdout);

    
    if (q.bufferType != kRADIO && !q.hasBuf) return FALSE;
    if (!q.hasEvent && q.needsEvent) return FALSE;
    if (q.hasForClause && q.numEpochs == 0) return FALSE;
    return (call QueryIntf.fieldsComplete(q) && call QueryIntf.exprsComplete(q));
  }

  /** Callback after we add a named field to the query schema
      Continue building the parsed query
  */
  event result_t Table.addNamedFieldDone(result_t success) {
    continueParsing(success);
    return SUCCESS;
  }


  /* --------------------------------- Memory Callbacks ---------------------------------*/

  event result_t MemAlloc.allocComplete(Handle *handle, result_t complete) {

    dbg(DBG_USR3,"in alloc complete\n");//fflush(stdout);
    if (mAllocState == STATE_NOT_ALLOCING) return SUCCESS; //not our allocation

    switch (mAllocState) {
    case STATE_ALLOC_PARSED_QUERY:
      mAllocState = STATE_NOT_ALLOCING; //not allocating any more
      if (complete) {

	QueryListHandle qlh = (QueryListHandle)*handle;
	dbg(DBG_USR3,"alloced parsed query \n");//fflush(stdout);
	(**qlh).next = NULL;
	(**qlh).q.clocksPerSample = 0; //make sure this query wont be fired yet
	(**qlh).q.needsData = FALSE;
	//modifying this data structure is dangerous -- make sure timer thread doesnt run...

	atomic {
	  if (mTail == NULL) {
	    mTail = qlh;
	    mQs = qlh;
	  } else {
	    (**mTail).next = (void **)qlh;
	    mTail = qlh;
	  }
	}

#ifdef HSN_ROUTING
	signal HSNValue.adjuvantValueReset();
#endif
	mAllocCallback((Handle *)&mTail); //allow the application to continue
      } else
	TDB_SIG_ERR(err_OutOfMemory);
      break;
    case STATE_ALLOC_IN_FLIGHT_QUERY:
      mAllocState = STATE_NOT_ALLOCING; //not allocating any more
      if (complete) {

	dbg(DBG_USR3,"Alloced query.\n"); //fflush(stdout);

	(*mAllocCallback)(handle);
      } else {
	TDB_SIG_ERR(err_OutOfMemory);
	UNSET_READING_QUERY();
      }
      break;
    default:
      TDB_SIG_ERR(err_UnknownAllocationState);
      break;
    }
    return SUCCESS;
  }

  event result_t MemAlloc.reallocComplete(Handle handle, result_t complete) {
    //    dbg(DBG_USR3,"in realloc complete, state = %d, resize = %d, not_alloc = %d\n",
    //mAllocState, STATE_RESIZE_QUERY, STATE_NOT_ALLOCING); //fflush(stdout);
    if (mAllocState == STATE_NOT_ALLOCING) return SUCCESS; //not our allocation
    if (mAllocState == STATE_RESIZE_QUERY) {
      mAllocState = STATE_NOT_ALLOCING; //not allocating any more
     
      mTmpHandle = handle;
      if (complete)
	(*mAllocCallback)(&mTmpHandle);
      else
	TDB_SIG_ERR(err_OutOfMemory);
    }
    else
      TDB_SIG_ERR(err_UnknownAllocationState);
    return SUCCESS;
  }

  event result_t MemAlloc.compactComplete() {
    return SUCCESS;
  }

/* ================================= Network Stuff =========================== */

  event result_t Network.sendDataDone(TOS_MsgPtr msg, result_t success)
    {
      return SUCCESS;
    }

  event result_t Network.sendQueryRequestDone(TOS_MsgPtr msg, result_t success)
    {
      return outputDone(msg);
    }
  
  event result_t Network.sendQueryDone(TOS_MsgPtr msg, result_t success)
    {
      return outputDone(msg);
    }

  /** Event that's signalled when a send is complete */
  result_t outputDone(TOS_MsgPtr msg) {
    if (IS_SENDING_MESSAGE() ) {
      UNSET_SENDING_MESSAGE();
    }    
    if (IS_SENDING_QUERY()) {
      post sendQuery();
    }

    return SUCCESS;
  }


/* ================================= DBBuffer Stuff =========================== */

  event result_t DBBuffer.resultReady(uint8_t bufferId) {
    return SUCCESS;
  }

  event result_t DBBuffer.getNext(uint8_t bufferId) {
    return SUCCESS;
  }

  event result_t DBBuffer.allocComplete(uint8_t bufferId, TinyDBError result) {
    if (result != err_NoError) {
#ifdef kUART_DEBUGGER
      //      call UartDebugger.writeLine("fail opened", 11);
#endif
      failedOpeningWriteBuffer(mTempPQ);
    }
    else {
#ifdef kUART_DEBUGGER
      //call UartDebugger.writeLine("alloc ok", 8);
#endif
      finishedOpeningWriteBuffer(mTempPQ);
    }
    return SUCCESS;
  }

  /* Signalled when a get is complete */
  event result_t DBBuffer.getComplete(uint8_t bufferId, QueryResult *buf, TinyDBError err) {
    return SUCCESS;
  }
  
  /* Signalled when a put is complete */
  event result_t DBBuffer.putComplete(uint8_t bufferId, QueryResult *buf, TinyDBError err) {
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
    if (err == err_NoError) {
      //call UartDebugger.writeLine("open ok",7);
    } else {
      //call UartDebugger.writeLine("open fail",9);
    }

    if (err!=err_NoError) {
      TDB_SIG_ERR(err);
    }
    finishedOpeningWriteBuffer(mTempPQ);
    return SUCCESS;
  }

  event result_t CommandUse.commandDone(char *commandName, char *resultBuf, SchemaErrorNo err) {
    return SUCCESS;
  }  

  async event result_t  UartDebugger.writeDone(char * string, result_t success) {
    return SUCCESS;
  }

  event result_t AttrUse.getAttrDone(char *name, char *resultBuf, SchemaErrorNo errorNo) {
    return SUCCESS;
  }

  event result_t AttrUse.startAttrDone(uint8_t id) {
    return SUCCESS;
  }

  
}
