/*
 * Query Processor 
 * Basically a error checking wrapper for the time being
 * Because another operation may be in process, the same task is posted to check it later
 * The paradigm is, fo
 * a query processor operation:
 *    copy query into the queue
 *    post the corresponding query operation task
 * query operation task:
 * if pending
 *      if(num_retries > 0) {
 *        post the corresponding query operation task
 *        num_retries --
 *      }
 * else 
 *      .... (what really should be done in the task)
 * 
 * all interface calls returns true as they only post a task
 * all errors are signaled later
 */

includes SensorDB;
includes cqueue;

module QueryProcessorC 
{
  provides
	{
	  interface QueryProcessor;
	}
  uses 
	{
	  interface Leds;
	  interface QueryIndex;
#ifdef PC_DEBUG_QP
	  interface Debug;
#endif
	}
}

#ifdef PC_DEBUG_QP
#ifndef PC
#define DEBUG(x)  \
   do {\
      call Debug.dbg8(0xb1);\
      call Debug.dbg8(x); \
   } while(0)
#define DEBUG2(x)  \
   do {\
      call Debug.dbg8(0xb2);\
      call Debug.dbg16(x); \
   } while(0)
#else
#define DEBUG(x) SDEBUG(x)
#define DEBUG2(x) SDEBUG(x)
#endif
#else
#define DEBUG(x)
#define DEBUG2(x)
#endif

implementation {

  // The role this node has.  Currently defaults to "MEMBER"
  Role role = MEMBER;

  uint8_t mPendingMask = 0; //various masks

  // ------------------- 
  //  Bits used in mPendingMask to determine current state 
  // ----------------- 
  enum 
	{ 
	  QUERY_BIT = 0x0002, // a query operation is posted
	  DATA_BIT = 0x0001 // a tuple search operation is posted
	};

  // Functions for setting the mask
  void SET_QUERY_PROCESS() {(mPendingMask |= QUERY_BIT); }
  void UNSET_QUERY_PROCESS() { (mPendingMask &= (QUERY_BIT ^ 0xFF)); }
  bool IS_QUERY_PROCESS() { return (mPendingMask & QUERY_BIT) != 0; }
  void SET_DATA_PROCESS() {(mPendingMask |= DATA_BIT); }
  void UNSET_DATA_PROCESS() { (mPendingMask &= (DATA_BIT ^ 0xFF)); }
  bool IS_DATA_PROCESS() { return (mPendingMask & DATA_BIT) != 0; }

  uint8_t mQueryMatched[MAX_QUERY]; //MEMBER
  uint8_t mNumQueryMatched;
  uint8_t mQueryCount;//Query Count
    
  uint8_t mMonitorState;
  uint8_t mMonitorCounter;

  //FOR COOR
  typedef struct NodeAndData 
  {
	uint16_t node;
	int16_t data;
  } NodeAndData;

  struct QueryResult {
	ParsedQueryPtr query;
	NodeAndData result[CLUSTER_SIZE];
	uint8_t counter; //how many nodes have contributed data to the coor for this query	
  } mQueryResult[MAX_QUERY];

  ParsedQueryPtr mQuery;
  ParsedQuery2Ptr mQuery2;

  QueryResponsePtr mRsp;
  QueryResponse2Ptr mRsp2;

  TuplePtr mTuple;

  result_t mResult;

  QueryResponse *mQueryRspArray;
  uint8_t mNumQRsp;
  ParsedQuery2 mTrigger;

  result_t addQuery(ParsedQueryPtr query);
  result_t deleteQuery(uint8_t qid);
  result_t updateEpoch(uint8_t qid, uint8_t new_epoch);
  result_t searchTuple(TuplePtr tuple, uint8_t epoch, uint8_t *queryMatched);
  //  result_t estimateQueryOverlap(ParsedQueryPtr query);
    
  result_t do_query2_process();
  uint8_t mQuery2Qid;

  uint8_t getQuery2Id() {
	return mQuery2Qid++;
  }

#ifdef PC
  void SDEBUG(uint8_t x) {
	dbg_clear(DBG_USR1, "%d\n", x);
  }
  void SDEBUG2(uint16_t x) {
	dbg_clear(DBG_USR1, "%d\n", x);
  }
#define DBG_USR1 DBG_SDB
#endif

  //
  // TASKS
  // 

  
  task void query2_process_task () 
	{
	  DEBUG(0x07);
	  DEBUG(0x07);
	  DEBUG(0x07);
	//if there is no data search
	  if(!IS_DATA_PROCESS()) 
		{
		  DEBUG(0x08);
		  SET_DATA_PROCESS();
		  mResult = do_query2_process();
		}
	  else 
		{
		  DEBUG(0x68);
		  dbg(DBG_USR1, "data search in process, retry a bit later\n");
		  post query2_process_task();
		}
	}
    
  task void query_process_task() 
	{
	  uint8_t ii;

	  DEBUG(0x03);
	  if(role != MEMBER) 
		{
		  ii = 0;
		  while(ii < MAX_QUERY) 
			{
			  if(mQueryResult[ii].query == 0)
				break;
			  ii ++;
			}
		  if( ii >= MAX_QUERY) 
			{
			  dbg(DBG_USR1, "query result buffer full\n");
			  return;
			}
		
		  // saveQuery saves the query in a buffer, waiting for an "add" query
		  if(call QueryIndex.saveQuery(mQuery, &(mQueryResult[ii].query)) != SUCCESS) 
			{
			  signal QueryProcessor.processQueryComplete(mQuery, FAIL);
			}
		  else 
			{
			  ASSERT(mQueryResult[ii].query->qid == mQuery->qid);
			  UNSET_QUERY_PROCESS();
			  signal QueryProcessor.processQueryComplete(mQuery, SUCCESS);
			}
		}
	  else
		{
		  DEBUG(0x04);
		  UNSET_QUERY_PROCESS();
		  signal QueryProcessor.processQueryComplete(mQuery, SUCCESS);
		}
	}

  task void post_query_process_task() {
	uint8_t ii = 0;
	uint8_t jj = 0;
	uint8_t kk = 0;
	uint8_t counter = 0;
	int16_t sum = 0;
	uint8_t count = 0;
	int16_t average = 0;
	ParsedQueryPtr query = 0;

	DEBUG(4);
	DEBUG(mNumQRsp);

	//for response from every node
	for(ii = 0; ii < mNumQRsp; ii ++) 
	  {
		//for each query matched
		for(jj = 0; jj < mQueryRspArray[ii].numMatch; jj ++) 
		  {
			kk = 0;
			//find the query
			while(kk < MAX_QUERY) 
			  {
				if(mQueryResult[kk].query->qid == mQueryRspArray[ii].qid[jj]) 
				  {
					counter = mQueryResult[kk].counter;
					mQueryResult[kk].result[counter].node = mQueryRspArray[ii].node;
					mQueryResult[kk].result[counter].data = mQueryRspArray[ii].data;
					mQueryResult[kk].counter ++;
					break;
				  }
				kk++;
			  }
		  }		
	  }

	for(kk = 0; kk < MAX_QUERY; kk ++) 
	  {
		if(mQueryResult[kk].counter <= 0)
		  {
			continue;
		  }
		query = mQueryResult[kk].query;
		if(query->aggOp == AVG) 
		  {
			sum = 0;
			count = 0;
			for(ii = 0; ii < mQueryResult[kk].counter; ii ++) 
			  {
				sum += mQueryResult[kk].result[ii].data;
				count ++;
			  }
			average = (sum/count);
 			DEBUG(114);
 			DEBUG2(sum);
 			DEBUG(count);
 			DEBUG2(average);
 			DEBUG(114);
 			//should be given by a query
 			DEBUG(mMonitorState);
 			DEBUG(114);
 			DEBUG(mQueryResult[kk].query->qid);
 			DEBUG(mQueryResult[kk].query->qor);
			if(mMonitorState == NORMAL) 
			  {
				if(mQueryResult[kk].query->qor == TRIGGER) 
				  {
 					DEBUG(115);
 					DEBUG(115);
					mTrigger.qtype = Q_QUERY;
					mTrigger.qid = getQuery2Id();
					mTrigger.qop = QOP2_UPDATE_EPOCH;
					mTrigger.qqid = mQueryResult[kk].query->qid;
					if(mQueryResult[kk].query->epoch > 0)
					  {
						mTrigger.new_epoch = mQueryResult[kk].query->epoch - 1;
					  }
					mMonitorState = AGILE;
 					DEBUG(mMonitorState);
 					DEBUG(115);
					signal QueryProcessor.postProcessQueryComplete(&mTrigger);
				  }
				else
				  {
					signal QueryProcessor.postProcessQueryComplete(0);
				  }
			  }
			else 
			  {
				//if already in AGILE state
				//post a query of trend to all member nodes
 				DEBUG(116);
 				DEBUG(116);
				mTrigger.qtype = Q_QUERY;
				mTrigger.qid = getQuery2Id();
				mTrigger.qop = QOP2_ADD_TREND_QUERY;
 				DEBUG(mMonitorState);
 				DEBUG(115);
				mMonitorState = DETECTING;
				signal QueryProcessor.postProcessQueryComplete(&mTrigger);
			  }
		  }
		mQueryResult[kk].counter = 0; //reset it
	  }
  }

  result_t do_query2_process() 
	{
	//should check if this query has been processed before
	//omit it now
	//for add and estimate
	//the query being operated should be the one we just received

	  DEBUG(0x09);
	if(mQuery2->qop == QOP2_ESTIMATE_OVERLAP && mQuery2->qqid == mQuery->qid) 
	  {
// 		if(estimateQueryOverlap(mQuery) != SUCCESS) 
// 		  {
// 			UNSET_DATA_PROCESS();
// 			UNSET_QUERY_PROCESS();
// 			signal QueryProcessor.processQuery2Complete(mQuery2, 0, FAIL);
// 		  }
	  }
	else 
		if(mQuery2->qop == QOP2_ADD_QUERY && mQuery2->qqid == mQuery->qid) 
		  {
			if(addQuery(mQuery) != SUCCESS) 
			  {
				DEBUG(0x0a);
				UNSET_DATA_PROCESS();
				UNSET_QUERY_PROCESS();
				signal QueryProcessor.processQuery2Complete(mQuery2, 0, FAIL);
			  }
		  }
		else 
		  if(mQuery2->qop == QOP2_DELETE_QUERY) 
			{
			  if(deleteQuery(mQuery2->qqid) != SUCCESS) 
				{
				  UNSET_DATA_PROCESS();
				  UNSET_QUERY_PROCESS();
				  signal QueryProcessor.processQuery2Complete(mQuery2, 0, FAIL);
				}
			}
		  else 
			if(mQuery2->qop == QOP2_UPDATE_EPOCH) 
			  {
				if(updateEpoch(mQuery2->qqid, mQuery2->new_epoch) != SUCCESS) 
				  {
					UNSET_DATA_PROCESS();
					UNSET_QUERY_PROCESS();
					signal QueryProcessor.processQuery2Complete(mQuery2, 0, FAIL);
				  }
			  }
	//	else if(mQuery2->qop == QOP2_UPDATE_QUERY)
			else 
			  {
				DEBUG(0x6a);
				UNSET_DATA_PROCESS();
				UNSET_QUERY_PROCESS();
				return FAIL;
			  }

	return SUCCESS;
  }

  // 
  // COMMANDS
  // 


  //
  // init()
  //
  command result_t QueryProcessor.init(Role r) {
	uint8_t ii;
	role = r;

	call QueryIndex.init();
	mPendingMask = 0;
	mNumQueryMatched  = 0;
#ifdef PC_DEBUG_QP
	call Debug.init();
	call Debug.setAddr(TOS_UART_ADDR);
#endif

	//	DEBUG(0);
	//	DEBUG(1);
	//	DEBUG(2);
	for(ii = 0; ii < MAX_QUERY; ii++) {
	  mQueryResult[ii].query = 0;
	  mQueryResult[ii].counter = 0;
	}

	mMonitorState = NORMAL;

	UNSET_QUERY_PROCESS();
	UNSET_DATA_PROCESS();
	return SUCCESS;
  }
    

  //
  // getQ2ID()
  // 
  command uint8_t QueryProcessor.getQ2ID() {
	return getQuery2Id();
  }

  //
  //process type-1 query: estimate overlap 
  //
  command result_t QueryProcessor.processQuery(ParsedQueryPtr query) 
	{
	  DEBUG(0x01);
	  if(!IS_QUERY_PROCESS()) 
		{
		  DEBUG(0x02);
		  SET_QUERY_PROCESS();
		  mQuery = query;
		  post query_process_task();
		  return SUCCESS;
		}
	  else 
		{
		  DEBUG(0x62);
		  dbg(DBG_USR1, "another query in process, this operation %d failed\n", query->qop);
		  return FAIL;
		}
	}

  //process type-2 query
  //add, delete
  //ask for estimate
  command result_t QueryProcessor.processQuery2(ParsedQuery2Ptr query2, 
												QueryResponse2Ptr rsp2) 
	{
	  DEBUG(0x05);
	//no other query operation pending
	if(!IS_QUERY_PROCESS()) 
	  {
		DEBUG(0x06);
		SET_QUERY_PROCESS();
		mQuery2 = query2;
		mRsp2 = rsp2;
		post query2_process_task();

		return SUCCESS;
	}
	else 
	  {
		DEBUG(0x66);
		dbg(DBG_USR1, "another query in process, this operation %d failed\n", query2->qop);
		return FAIL;
	  }
  }

  //
  // processTuple()
  //
  command result_t QueryProcessor.processTuple(TuplePtr tuple, uint8_t epoch, QueryResponsePtr rsp) 
	{
	  DEBUG(8);
	  DEBUG(mPendingMask);
	  if(!IS_DATA_PROCESS() && !IS_QUERY_PROCESS()) 
		{
		  SET_DATA_PROCESS();
		  mTuple = tuple;
		  mRsp = rsp;
		  if(searchTuple(tuple, epoch, &mQueryMatched[0]) != SUCCESS) 
			{
			  UNSET_DATA_PROCESS();
			  dbg(DBG_USR2, "point search failed.\n");
			}
		  return SUCCESS;
		}
	  else
		return FAIL;
  }

  //
  // processProcessQuery()
  //
  command result_t QueryProcessor.postProcessQuery(QueryResponse *rsp, uint8_t num_rsp) {

	DEBUG(1);
	DEBUG(1);
	DEBUG(num_rsp);
	DEBUG(1);
	DEBUG(1);

	mQueryRspArray = rsp;
	mNumQRsp = num_rsp;

	post post_query_process_task();

	
	return SUCCESS;
  }

  //
  // restoreEpoch()
  //
  command result_t QueryProcessor.restoreEpoch(uint8_t qid) {
	ParsedQueryPtr query = call QueryIndex.getQuery(qid);
	DEBUG(116);
	DEBUG(116);
	DEBUG(mMonitorState);
	if(mMonitorState == AGILE) {
	  DEBUG(117);
	  DEBUG(117);
	  mTrigger.qtype = Q_QUERY;
	  mTrigger.qid = getQuery2Id();
	  mTrigger.qop = QOP2_UPDATE_EPOCH;
	  mTrigger.qqid = qid;
	  mTrigger.new_epoch = query->epoch;

	  mMonitorState = NORMAL;
	  signal QueryProcessor.postProcessQueryComplete(&mTrigger);
	}
	return SUCCESS;
  }

  //
  // stopTrendQuery()
  //
  command result_t QueryProcessor.stopTrendQuery() {
	if(mMonitorState == DETECTING) {
	  mTrigger.qtype = Q_QUERY;
	  mTrigger.qid = getQuery2Id();
	  mTrigger.qop = QOP2_STOP_TREND_QUERY;
	  mMonitorState = AGILE;
	  signal QueryProcessor.postProcessQueryComplete(&mTrigger);
	}
	return SUCCESS;
  }

  // This is where the query in the buffer is added to the local index

  result_t addQuery(ParsedQueryPtr query) 
	{
	  if(call QueryIndex.addQuery(query) != SUCCESS) 
		{
		  dbg(DBG_USR1, "add query failed\n");
		  return FAIL;
		}
	  return SUCCESS;
	}


  result_t deleteQuery(uint8_t qid) {
	if(call QueryIndex.deleteQuery(qid) != SUCCESS) {
	  dbg(DBG_USR1, "delete query failed\n");
	  return FAIL;
	}
	return SUCCESS;
  }

  
  result_t searchTuple(TuplePtr tuple, uint8_t epoch, uint8_t *queryMatched) 
	{
	  if(call QueryIndex.searchTuple(tuple, epoch, queryMatched) != SUCCESS) 
		{
		  dbg(DBG_USR1, "search tuple failed\n");
		  return FAIL;
		}
	  return SUCCESS;
  }


//   result_t estimateQueryOverlap(ParsedQueryPtr query) {
// 	if(call QueryIndex.estimateQueryOverlap(query) != SUCCESS) {
// 	  dbg(DBG_USR1, "estimate query failed\n");
// 	  return FAIL;
// 	}
// 	return SUCCESS;
//   }

  result_t updateEpoch(uint8_t qid, uint8_t new_epoch) {
	if(call QueryIndex.updateEpoch(qid, new_epoch) != SUCCESS) {
	  dbg(DBG_USR1, "update query epoch failed\n");
	  return FAIL;
	}
	else 
	  return SUCCESS;
  }

  //Query Index events

  // 
  // addQueryComplete()
  //
  event ErrorCode QueryIndex.addQueryComplete(ParsedQueryPtr query, 
											  ErrorCode result) 
	{
	  DEBUG(0x0b);
	  UNSET_DATA_PROCESS();
	  UNSET_QUERY_PROCESS();
	  if(result == SUCCESS) 
		{
		  DEBUG(0x0c);
		  dbg(DBG_USR2, "query added successful\n");
		  UNSET_QUERY_PROCESS();	    
		  signal QueryProcessor.processQuery2Complete(mQuery2, 0, SUCCESS);
		}
	  else 
		{
		  DEBUG(0x6c);
		  dbg(DBG_USR2, "query add failed.\n");
		  UNSET_QUERY_PROCESS();	           
		  signal QueryProcessor.processQuery2Complete(mQuery2, 0, FAIL);
		}
	
	  return SUCCESS;
  }

  //
  // deleteQueryComplete()
  //
  event ErrorCode QueryIndex.deleteQueryComplete(uint8_t qid, ErrorCode result) {
	UNSET_DATA_PROCESS();
	UNSET_QUERY_PROCESS();
	if(result == SUCCESS) {
	  dbg(DBG_USR2, "query deleted successfully\n");
	  UNSET_QUERY_PROCESS();
	  signal QueryProcessor.processQuery2Complete(mQuery2, 0, SUCCESS);
	}
	else {
	  dbg(DBG_USR2, "query delete failed.\n");
	  UNSET_QUERY_PROCESS();
	  signal QueryProcessor.processQuery2Complete(mQuery2, 0, FAIL);	    
	}
	return SUCCESS;
  }

  //
  // updateEpochComplete()
  //
  event ErrorCode QueryIndex.updateEpochComplete(uint8_t qid, ErrorCode result)
	{
	  UNSET_DATA_PROCESS();
	  UNSET_QUERY_PROCESS();
	  if(result == SUCCESS) {
		dbg(DBG_USR2, "query epoch updated successfully\n");
		UNSET_QUERY_PROCESS();
		signal QueryProcessor.processQuery2Complete(mQuery2, 0, SUCCESS);
	  }
	  else {
		dbg(DBG_USR2, "query epoch update failed.\n");
		UNSET_QUERY_PROCESS();
		signal QueryProcessor.processQuery2Complete(mQuery2, 0, FAIL);	    
	  }
	  return SUCCESS;
	}

  //
  // estimateQueryOverlapComplete()
  //
//   event ErrorCode QueryIndex.estimateQueryOverlapComplete(ParsedQueryPtr query, 
// 														  uint16_t totalMatch,
// 														  uint16_t overlap,
// 														  uint16_t nonoverlap,
// 														  ErrorCode result) 
// 	{
// 	  UNSET_DATA_PROCESS();
// 	  UNSET_QUERY_PROCESS();
// 	  if(result == SUCCESS) {
// 		dbg(DBG_USR2, "query estimated successfully\n");
// 		mRsp2->node = TOS_LOCAL_ADDRESS;
// 		//seqno is reserved for big response which cannot be put wthin a message
// 		//assume a message is enough
// 		mRsp2->total_match = totalMatch;
// 		mRsp2->overlap = overlap;
// 		mRsp2->nonoverlap = nonoverlap;
// 		UNSET_QUERY_PROCESS();
// 		signal QueryProcessor.processQuery2Complete(mQuery2, mRsp2, SUCCESS);
// 	  }
// 	  else {
// 		dbg(DBG_USR2, "query estimate failed.\n");
// 		signal QueryProcessor.processQuery2Complete(mQuery2, 0, FAIL);
// 	  }	    
// 	  return SUCCESS;
// 	}
    
  //
  // searchTupleComplete()
  //
  event ErrorCode QueryIndex.searchTupleComplete(TuplePtr tuple, 
												 uint8_t *queryMatched, 
												 uint8_t numQueryMatched, 
												 ErrorCode result) 
	{
	  int i;	
	  UNSET_DATA_PROCESS();
	  if(result == SUCCESS) 
		{
		  dbg(DBG_USR2, "data # %d matches the queries: \n", tuple->temp);
		  mRsp->node = TOS_LOCAL_ADDRESS;
		  mRsp->data = tuple->temp;
		  mRsp->numMatch = numQueryMatched;
		  //seqno is reserved for big response which cannot be put wthin a message
		  for(i = 0; i < numQueryMatched; i++) 
			{
			  mRsp->qid[i]= queryMatched[i];
			  dbg_clear(DBG_USR2, "#%d ", queryMatched[i]);
			}
		  dbg_clear(DBG_USR2, "\n\n");
		  signal QueryProcessor.processTupleComplete(tuple, mRsp, SUCCESS);
		}
	  else
		{
		  dbg(DBG_USR2, "point search failed.\n");
		  signal QueryProcessor.processTupleComplete(tuple, 0, FAIL);
		}
	  return SUCCESS;
	}

}
