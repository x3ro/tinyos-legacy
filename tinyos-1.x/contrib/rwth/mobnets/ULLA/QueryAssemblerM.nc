/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */

/**
 *
 * Query Assembler implementation
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/

includes UQLCmdMsg;
includes UllaQuery;
includes MemAlloc;
includes hardware;
includes msg_type;

module QueryAssemblerM {

    provides 	{
      interface StdControl;
      interface ProcessCmd as ProcessQuery[uint8_t id];
    }
    uses {
		
			interface MemAlloc as UllaAlloc;
      interface Leds;
      interface Query;
			interface UqpIf; // parameterized at UQP
    }
}

/*
 *  Module Implementation
 */

implementation
{

  enum {
  ALLOC_ULLA_QUERY_STATUS,
  ALLOC_QUERY_STATUS,
  RESIZE_QUERY_STATUS,
  NOT_ALLOCING_STATUS,
  ALLOC_QUERY_RESULT_STATUS,
};

  typedef struct {
    void **next;
    struct Query uq;
  } QueryList, *QueryListPtr, **QueryListHandle;
  
  
  QueryListHandle qListHead;
  QueryListHandle qListTail;

  TOS_MsgPtr msg;
  //TOS_Msg buf;
  TOS_MsgPtr rmsg;
  TOS_Msg rbuf;
  short nsamples;         // number of samples
  uint8_t packetReadingNumber;
  uint16_t readingNumber;
	uint8_t queryType;

  QueryMsgPtr qmsg;
	QueryMsg qmsg_buf;
  struct Query qbuf;
  /* we need a query handle for dynamic allocation (later on) */
  QueryPtr pquery;
  struct Query **gCurQuery;   /* gCurQuery is a query handle */
  UllaQueryPtr uq;
  Handle gCurHandle;
  Handle first;

  /* global varibles */
  char gCurCond;
  ResultTuple *gCurTuple;

  typedef void (*MemCallback)(Handle *memory);
  MemCallback memCallback;
  uint8_t mStatus;
  uint8_t seen;

  /* task declaration */

  task void deleteQuery();
  task void modifyQuery();

  /* function declaration */
  void addQuery(HandlePtr memory);
  bool allocateQuery();
  bool allocateUllaQuery(QueryPtr q);

	bool is_processing_query;

	uint8_t checkQueryComplete();

  command result_t StdControl.init() {
    atomic {
      rmsg = &rbuf;
      pquery = &qbuf;
			qmsg = &qmsg_buf;

      qListHead = NULL;
      qListTail = NULL;

      pquery->seenConds = 0;
      gCurCond = -1;
			is_processing_query = 0;
    }
	
    return (SUCCESS);
  }

  command result_t StdControl.start(){

    return (SUCCESS);
  }

  command result_t StdControl.stop(){

    return (SUCCESS);
  }
#if 1
  command result_t ProcessQuery.execute[uint8_t id](TOS_MsgPtr pmsg) {
    uint8_t i;

    atomic {
      //qmsg = (struct QueryMsg *) pmsg->data;
			memcpy(qmsg, &(pmsg->data), sizeof(QueryMsg));
			msg = pmsg;
			queryType = id; // RN or query
    }
    dbg(DBG_USR1,"UQP: ProcessQuery %d\n",qmsg->numFields);
		//call Leds.yellowToggle();

		dbg(DBG_USR1,"ProcessQuery execute\n");
		
		//check message data type: add, modify, delete
		if (qmsg->msgType == DEL_MSG) { // delete a query

			if (is_processing_query) return FAIL;
			is_processing_query = 1;

			post deleteQuery();
			is_processing_query = 0;

		// modify a previous query (given a query ID)
		} else if (qmsg->msgType == MOD_MSG) {

			dbg(DBG_USR1,"ProcessQuery MOD_MSG\n");
			if (is_processing_query) return FAIL;
			is_processing_query = 1;
			post modifyQuery();
			is_processing_query = 0;
		// add a query
		} 
		else if (qmsg->msgType == ADD_MSG) 
		{

				dbg(DBG_USR1,"ProcessQuery ADD_MSG\n");
				if (!is_processing_query) {
					is_processing_query = 1;
				  allocateQuery();	
					//call Leds.yellowToggle();
					
				}
				else 
				{
					if (qmsg->ruId != (**gCurQuery).qid) 
					{
						dbg(DBG_USR1,"QAU: different query -> delete old one\n");
				  
						call UllaAlloc.unlock((Handle)gCurQuery);
						call UllaAlloc.free((Handle)gCurQuery);
				
					} else // same query id
					{
					  dbg(DBG_USR1, "QAU: ruId = qid\n");
						call Query.addQuery(qmsg, *gCurQuery);
						if (checkQueryComplete()) 
						{
						  dbg(DBG_USR1, "QAU: adding query complete\n");
							//call Leds.greenToggle();
						
						}
					}
				}
				
				
				
		}

    return SUCCESS;
  }
#endif
  task void deleteQuery() {


  }

  task void modifyQuery() {

  }
	
	uint8_t checkQueryComplete() {
	
	  uint8_t i;
		uint8_t complete = 0;
		RnDescr_t rnDescr;
	  
		call Query.addQuery(qmsg, *gCurQuery);
		//if (call Query.addQuery(qmsg, *gCurQuery) == FALSE)
		if (call Query.gotCompleteQuery(*gCurQuery) == TRUE) {

			dbg(DBG_USR1,"ProcessQuery gotCompleteQuery %p\n",*gCurQuery);

			switch (qmsg->queryType) {
				case 1: // notification
				{
					struct RnDescr_t rndescr;
					uint8_t rnId;

					memcpy(&(rnDescr.query), *gCurQuery, sizeof(struct Query));
					rnDescr.count = qmsg->nsamples;
					rnDescr.period = qmsg->interval;
					//if (rnDescr.query.fields[0] != 0) call Leds.redToggle(); else call Leds.yellowToggle();
					call UqpIf.requestNotification(&rnDescr, &i, 10);
					//RnDescr_t *rndescr, RnId_t* rnId,	uint16_t validity
					call UllaAlloc.unlock((Handle)gCurQuery);
					call UllaAlloc.free((Handle)gCurQuery);
				
				}
				break;
				
				case 2: // query
				
					call UqpIf.requestInfo(*gCurQuery, &i);
					call UllaAlloc.unlock((Handle)gCurQuery);
					call UllaAlloc.free((Handle)gCurQuery);
				break;
				
				default:
				
				break;
				
			
			}
	
			complete = 1;
		}
	
	  return complete;
	}

/*----------------------------------- UQP ----------------------------------------*/

  //event result_t UqpIf.requestInfoDone(ullaResult_t *result, uint8_t numBytes) {
	event result_t UqpIf.requestInfoDone(ResultTuple *result, uint8_t numBytes) {
    // need to reset ulla_result after getting value
    call UqpIf.clearResult();
    // send results back to the remote user
    // send one message per one attribute or?
    ///call Send.send[AM_QUERY_MESSAGE](&rbuf, sizeof(struct QueryMsg));
    
    return SUCCESS;
  }

/*---------------------------------- Ulla Core ----------------------------------*/
/*
  event result_t Send.sendDone[uint8_t id](TOS_MsgPtr pMsg, result_t success) {

    return SUCCESS;
  }*/
  
   /*--------------------------- Memory Allocation (RAM) ------------------------*/
  // FIXME: handler is wrongly used here (see ULLAStorageM)
  //
  void addQuery(HandlePtr memory) {
    
		uint8_t i;

    gCurQuery = (struct Query **)*memory;
    dbg(DBG_USR1, "addQuery %p %p\n",*memory, *gCurQuery);

    (**gCurQuery).qid       = qmsg->ruId;
    (**gCurQuery).numFields = qmsg->numFields;
    (**gCurQuery).numConds  = qmsg->numConds;
		(**gCurQuery).className = qmsg->className;
    //(**gCurQuery).interval  = qmsg->interval;
    //(**gCurQuery).nsamples  = qmsg->nsamples;
    (**gCurQuery).seenConds = 0;
		
    call Query.addQuery(qmsg, *gCurQuery);
    dbg(DBG_USR1, "++++++Query %d %d\n",(**gCurQuery).numFields, (**gCurQuery).numConds);

    for (i=qmsg->numConds; i<8; i++)
      (**gCurQuery).seenConds |= (1 << i);
		
		call UllaAlloc.unlock((Handle)gCurQuery);
		checkQueryComplete();
  }

  bool allocateQuery() {

    dbg(DBG_USR1, "allocateQuery \n");
    mStatus = ALLOC_QUERY_STATUS;
    call UllaAlloc.lock((Handle) gCurHandle);
		if (call UllaAlloc.allocate(&gCurHandle, sizeof(struct Query)) == SUCCESS)
      return TRUE;
			
    return FALSE;
  }

  /*--------------------------- MemAlloc Events -------------------------------*/

  event result_t UllaAlloc.allocComplete(Handle *handle, result_t complete) {
	
    QueryListHandle qlh = (QueryListHandle)*handle;
    dbg(DBG_USR1,"UllaAlloc.alloc complete %p\n", qlh);
    if (mStatus == NOT_ALLOCING_STATUS) return SUCCESS; //not our allocation

    if (complete) {
      dbg(DBG_USR1,"Allocated query\n"); //fflush(stdout);
      //(*memCallback)(handle);
      // callback function
      switch (mStatus) {

        case ALLOC_QUERY_STATUS:
          // put a new query to the list
	        (**qlh).next = NULL;
        	atomic {
        	  if (qListTail == NULL) {
              dbg(DBG_USR1,"--** start qListTail **--\n");
	            qListTail = qlh;
	            qListHead = qlh;
	          } else {
              dbg(DBG_USR1,"--** next qListTail **--\n");
	            (**qListTail).next = (void **)qlh;
	            qListTail = qlh;
	          }
        	}
        	// then add the information
          //call Query.addQuery(qmsg, *gCurQuery);
          addQuery((HandlePtr)&qListTail);
        break;      //*/
      }

    } else {
      dbg(DBG_USR1,"Error: Out of Memory!\n");
    }
    mStatus = NOT_ALLOCING_STATUS; //not allocating any more

    return SUCCESS;
  }

  //event result_t UllaAlloc.reallocComplete[uint8_t id](Handle handle, result_t complete) {
	event result_t UllaAlloc.reallocComplete(Handle handle, result_t complete) {
    dbg(DBG_USR1,"UllaAlloc.realloc complete\n");
    return SUCCESS;
  }

  //event result_t UllaAlloc.compactComplete[uint8_t id]() {
	event result_t UllaAlloc.compactComplete() {
    dbg(DBG_USR1,"UllaAlloc.compact complete\n");
    return SUCCESS;
  }

}
