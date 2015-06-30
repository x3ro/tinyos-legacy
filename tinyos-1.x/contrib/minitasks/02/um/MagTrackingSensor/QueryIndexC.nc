/*
 * Author: Zhigang Chen
 * Date:   March 11, 2003
 */

/* implementation of query index trees
 */

includes SensorDB;

module QueryIndexC {
  provides interface QueryIndex;
  uses {
	interface IntervalTree;
	interface Leds;
#ifdef PC_DEBUG_QI
	interface Debug;
#endif
  }
}

#ifdef PC_DEBUG_QI
#ifndef PC
#define DEBUG(x)  \
   do {\
      call Debug.dbg8(0xc1);\
      call Debug.dbg8(x); \
   } while(0)
#define DEBUG2(x)  \
   do {\
      call Debug.dbg8(0xc2);\
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

  uint32_t mPendingMask; //various masks

  /* ------------------- Bits used in mPendingMask to determine
	 current state ----------------- */ 
  enum { INDEX_WRITE_BIT = 0x0001,  // write query index: add query, delete query,
		 INDEX_READ_BIT = 0x0002, // read query index: estimate query, search a tuple
  };

  void SET_READ_INDEX() {(mPendingMask |= INDEX_READ_BIT); }
  void UNSET_READ_INDEX() { (mPendingMask &= (INDEX_READ_BIT ^ 0xFFFF)); }
  bool IS_READ_INDEX() { return (mPendingMask & INDEX_READ_BIT) != 0; }
  void SET_WRITE_INDEX() {(mPendingMask |= INDEX_WRITE_BIT); }
  void UNSET_WRITE_INDEX() { (mPendingMask &= (INDEX_WRITE_BIT ^ 0xFFFF)); }
  bool IS_WRITE_INDEX() { return (mPendingMask & INDEX_WRITE_BIT) != 0; }
  void SET_UPDATE_INDEX() {(mPendingMask |= (INDEX_WRITE_BIT|INDEX_READ_BIT)); }
  void UNSET_UPDATE_INDEX() { (mPendingMask &= ((INDEX_WRITE_BIT|INDEX_READ_BIT) ^ 0xFFFF)); }
  bool IS_UPDATE_INDEX() { return (mPendingMask & (INDEX_WRITE_BIT|INDEX_READ_BIT)) != 0; }

  struct AllQueryInfo {
	bool free; //this buffer is available?
	ParsedQuery query; //query saved here, do we need it?
	uint8_t qid;
  } mQueryInfo[MAX_QUERY];

  struct {
	bool free;
	uint8_t qid;
  } mNoCondQuery[MAX_QUERY]; 
  uint8_t mNumNoCondQuery; //how many queries without conds

    
  ParsedQuery mQueryBuf; //query in process for estimate overlap
  ParsedQueryPtr mQuery; //pointer to query in process

  uint8_t mQueryInfoIndex; //the index of query in process if it is already indexed

  uint16_t mQueryCount; //how mnay queries buffered? (including no conds)

  TuplePtr mTuple; //pointer to tuple
  uint8_t mEpoch; //epoch of current query
  uint8_t mQid;
  uint8_t mNewEpoch;
    
  uint8_t *mQueryMatched; //store which queries match the data sample
  uint8_t mNumQueryMatched; //how many queries match

  //no condition queries
  void add2NoCondList();
  void checkNoCondList();

  void addInt2IndexTree();
    
  ErrorCode save_query(ParsedQueryPtr query, ParsedQueryPtr* query_saved);
  uint8_t get_query(uint8_t qid);

  task void addQueryTask();
  task void deleteQueryTask();
  task void updateEpochTask();
//  task void estimateQueryTask();
  task void searchTask();

#ifdef PC
  void SDEBUG(uint8_t x) {
	dbg_clear(DBG_USR1, "%d\n", x);
  }
  void SDEBUG2(uint16_t x) {
	dbg_clear(DBG_USR1, "%d\n", x);
  }
#endif

#define RESET_QUERY(x) do \
{ \
    mQueryInfo[x].free = TRUE; \
    mQueryInfo[x].qid = 0xff; \
} while (0)

  //init data structure
  command ErrorCode QueryIndex.init() {
	uint8_t i;
	for(i = 0; i < MAX_QUERY; i ++) {
	  mNoCondQuery[i].free = TRUE; //not set yet
	  RESET_QUERY(i);
	}

	mQueryCount = 0;
	mNumNoCondQuery = 0;

	mPendingMask = 0;

#ifdef PC_DEBUG_QI
	call Debug.init();
	call Debug.setAddr(TOS_UART_ADDR);
#endif
	call IntervalTree.init();

	return SUCCESS;
  }

  //this function add a query into the index tree
  command ErrorCode QueryIndex.addQuery(ParsedQueryPtr query) 
	{
	  ErrorCode ret;
	  ParsedQueryPtr q;

	  DEBUG(0x01);
	  ret = save_query(query, &q);
	  if(ret != SUCCESS)
		{
		  DEBUG(0x61);
		  return ret;
		}
	  mQuery = query;
	  DEBUG(0x02);
	  post addQueryTask();

	  return SUCCESS;
	}

  task void addQueryTask() 
	{
	  uint8_t condIndex;
	  uint8_t numConds;
	  ConditionPtr conds;

	  DEBUG(0x03);
	  condIndex = 0;
	  numConds = mQueryInfo[mQueryInfoIndex].query.numConds;
	  conds = &mQueryInfo[mQueryInfoIndex].query.conds[0];

	  if(numConds == 0)
		{
		  DEBUG(0x04);
		  add2NoCondList();
		}
	  else 
		{
		  DEBUG(0x05);
		  addInt2IndexTree();
		}
	  DEBUG(0x06);
	}

  //add a query without condition into the no cond query list
  void add2NoCondList() {
	uint8_t i = 0;

	while(i < MAX_QUERY && !mNoCondQuery[i].free) {
	  i ++;
	}
	if(i >= MAX_QUERY) {
	  dbg(DBG_USR1, "what has happended? no cond list is full while query info buffer is not\n");
	  return;
	}

	mNoCondQuery[i].qid = mQueryInfo[mQueryInfoIndex].qid;
	mNoCondQuery[i].free = FALSE;
	mNumNoCondQuery ++;
	UNSET_UPDATE_INDEX();
	dbg(DBG_TEMP, "--- add query # %d done\n", mNoCondQuery[i].qid);
	signal QueryIndex.addQueryComplete(mQuery, SUCCESS);
  }


  //
  //add an interval of a query into the interval tree
  //Parameter: Query stores in mQueryInfo[mQueryInfoIndex]
  //
  void addInt2IndexTree() {
	ErrorCode ret;
	uint8_t i;
	int16_t lb = NEGINF, rb = INF;
	uint8_t qid = mQueryInfo[mQueryInfoIndex].qid;
	uint8_t epoch = mQueryInfo[mQueryInfoIndex].query.epoch;
	uint8_t numConds = mQueryInfo[mQueryInfoIndex].query.numConds;
	ConditionPtr conds = &mQueryInfo[mQueryInfoIndex].query.conds[0];
	Attrib attr = conds[0].attr;

	DEBUG(0x07);

	//add the conds of the query to interval tree

	for(i = 0; i < numConds; i++) {
	  switch(conds[i].op) {
		//not a interval
	  case EQ:
	  case NEQ:
		break;
	  case GT:
	  case GE:
		if(lb < conds[i].val)
		  lb = conds[i].val;
		break;
	  case LT:
	  case LE:
		if(rb > conds[i].val)
		  rb = conds[i].val;
		break;
		//default:
		//return ;
	  }
	}

	ret = call IntervalTree.insertInt(lb, rb, qid, attr, epoch, mQueryInfoIndex);
	DEBUG(0x08);
	if(ret == SUCCESS) 
	  {
		DEBUG(0x09);
		UNSET_UPDATE_INDEX();
		dbg(DBG_USR1, "--- add query # %d done\n", qid);
		signal QueryIndex.addQueryComplete(mQuery, SUCCESS);
	  }
	else
	  {
		DEBUG(0x68);
		UNSET_UPDATE_INDEX();
		dbg(DBG_USR1, "--- insert interval for query # %d failed\n", qid);
		signal QueryIndex.addQueryComplete(mQuery, ret);
	  }

	return;
  }


  //delete a query from the relevant index trees
  command ErrorCode QueryIndex.deleteQuery(uint8_t qid) {
	int16_t i;

	if(IS_UPDATE_INDEX()) {
	  dbg(DBG_USR1, "delete query # %d failed. Another query update/read in process\n", qid);
	  return Err_QueryIndex_Pending;
	}

	SET_UPDATE_INDEX();

	//find if this query exists
	mQueryInfoIndex = 0xff;
	
	//check if it is in index
	if(mQueryCount > MAX_QUERY/2) {
	  i = MAX_QUERY - 1;
	  while(i >= 0) {
		if(!mQueryInfo[i].free && mQueryInfo[i].qid == qid) {
		  mQueryInfoIndex = i;
		  break;
		}
		i--;
	  }
	}
	else {
	  i = 0;
	  while(i < MAX_QUERY) {
		if(!mQueryInfo[i].free && mQueryInfo[i].qid == qid) {
		  mQueryInfoIndex = i;
		  break;
		}
		i++;
		
	  }	    
	}

	if(mQueryInfoIndex == 0xff) {
	  UNSET_UPDATE_INDEX();
	  dbg(DBG_USR1, "no such a query # %d\n", qid);
	  return Err_QueryIndex_QueryNotFound;
	}

	mQid = qid;

	post deleteQueryTask();
	return SUCCESS;
  }
    
  //output mQueryMatched
  //probe index trees by a Tuple and find which queries match
  command ErrorCode QueryIndex.searchTuple(TuplePtr tuple, 
										   uint8_t epoch_level, 
										   uint8_t *queryMatched) 
	{
	  if(IS_READ_INDEX()) 
		{
		  dbg(DBG_USR1, "search tuple fails, another update access is in process\n");
		  return Err_QueryIndex_Pending;
		}
	  SET_READ_INDEX();
	  mTuple = tuple;
	  mEpoch = epoch_level;
	  mQueryMatched = queryMatched;
	  mNumQueryMatched = 0;
	  
	  post searchTask();
	  return SUCCESS;
  }

  //estimate overlap of the query with indexed queries
//   command ErrorCode QueryIndex.estimateQueryOverlap(ParsedQueryPtr query) {
// 	ErrorCode ret;
// 	ret = get_query(query->qid);
// 	if(ret != 0xff)
// 	  return Err_QueryIndex_QueryExist;

// 	nmemcpy(&mQueryBuf, query, sizeof(ParsedQuery));
// 	mQuery = query;

// 	dbg(DBG_USR1, "estimate overlap of query # %d\n", query->qid);
// 	post estimateQueryTask();

// 	return SUCCESS;

//   }

  command ErrorCode QueryIndex.updateEpoch(uint8_t qid, uint8_t new_epoch) {
	int16_t i;

	if(IS_UPDATE_INDEX()) {
	  dbg(DBG_USR1, "update query epoch # %d failed. Another query update/read in process\n", qid);
	  return Err_QueryIndex_Pending;
	}

	SET_UPDATE_INDEX();

	//find if this query exists
	mQueryInfoIndex = 0xff;
	
	//check if it is in index
	if(mQueryCount > MAX_QUERY/2) {
	  i = MAX_QUERY - 1;
	  while(i >= 0) {
		if(!mQueryInfo[i].free && mQueryInfo[i].qid == qid) {
		  mQueryInfoIndex = i;
		  break;
		}
		i--;
	  }
	}
	else {
	  i = 0;
	  while(i < MAX_QUERY) {
		if(!mQueryInfo[i].free && mQueryInfo[i].qid == qid) {
		  mQueryInfoIndex = i;
		  break;
		}
		i++;
		
	  }	    
	}

	if(mQueryInfoIndex == 0xff) {
	  UNSET_UPDATE_INDEX();
	  dbg(DBG_USR1, "no such a query # %d\n", qid);
	  return Err_QueryIndex_QueryNotFound;
	}

	mQid = qid;
	mNewEpoch = new_epoch;

	post updateEpochTask();
	return SUCCESS;	
  }


  command ErrorCode QueryIndex.saveQuery(ParsedQueryPtr query, ParsedQueryPtr* query_saved) {
	return save_query(query, query_saved);
  }

  command ParsedQueryPtr QueryIndex.getQuery(uint8_t qid) {
	uint8_t ret;
	ret = get_query(qid);
	if(ret == 0xff)
	  return 0;
	else 
	  return &(mQueryInfo[ret].query);
  }


  event ErrorCode IntervalTree.deleteIntComplete(uint8_t qid, uint8_t queryInfoIndex, ErrorCode result) {
	ASSERT(result == SUCCESS);
	mQueryCount --;
	RESET_QUERY(mQueryInfoIndex);
	UNSET_UPDATE_INDEX();
	dbg(DBG_USR1, "delete query # %d done\n", mQid);
	signal QueryIndex.deleteQueryComplete(mQid, SUCCESS);
	return SUCCESS;
  }

  event ErrorCode IntervalTree.updateIntEpochComplete(uint8_t qid, uint8_t queryInfoIndex, ErrorCode result) {
	mQueryInfo[queryInfoIndex].query.epoch = mNewEpoch;
	UNSET_UPDATE_INDEX();
	dbg(DBG_USR1, "--- update query # %d done\n", qid);
	signal QueryIndex.updateEpochComplete(qid, SUCCESS);	
	return SUCCESS;
  }

  event ErrorCode IntervalTree.searchPointComplete(uint8_t *queryMatched, 
												   uint8_t numQueryMatched, 
												   ErrorCode result) 
	{
	  ASSERT(result == SUCCESS);
	  mNumQueryMatched += numQueryMatched;
	  //check if there is any no condition query
	  checkNoCondList();
	  return SUCCESS;
	}

//   event ErrorCode IntervalTree.estimateOverlapProbComplete(uint16_t totalMatch, uint16_t totalOverlap, 
// 														   uint16_t totalNonoverlap, ErrorCode result) {
// 	ASSERT(result == SUCCESS);
// 	UNSET_READ_INDEX();
// 	dbg(DBG_USR1, "estimates prob: total match = %d, total overlap = %d, total nonoverlap = %d\n", totalMatch, totalOverlap,
// 		totalNonoverlap);
// 	signal QueryIndex.estimateQueryOverlapComplete(mQuery, totalMatch, totalOverlap, totalNonoverlap, SUCCESS);

// 	return SUCCESS;
//   }


  void checkNoCondList() 
	{
	  uint8_t i;

	  if(mNumNoCondQuery > 0) 
		{
		  i = 0;
		  while(i < MAX_QUERY) 
			{
			  if(!mNoCondQuery[i].free) 
				{
				  mQueryMatched[mNumQueryMatched] = mNoCondQuery[i].qid;
				  mNumQueryMatched ++;
				}
		
			}
		}

	  UNSET_READ_INDEX();
	  dbg(DBG_USR1, "data %d matches %d queries \n", mTuple->temp, mNumQueryMatched);
	  signal QueryIndex.searchTupleComplete(mTuple, mQueryMatched, mNumQueryMatched, SUCCESS);
	}

  // Buffer the query for later processing by an "add" type2 query.
  ErrorCode save_query(ParsedQueryPtr query, ParsedQueryPtr* query_saved) {
	int16_t i;

	if(IS_UPDATE_INDEX()) {
	  dbg(DBG_USR1, "add query # %d failed. Another query update/read in process\n", query->qid);
	  return Err_QueryIndex_Pending;
	}

	SET_UPDATE_INDEX();

	//check if there is duplicate query
	i = 0;
	while(i < MAX_QUERY) {
	  if(!mQueryInfo[i].free && mQueryInfo[i].qid == query->qid) {
		UNSET_UPDATE_INDEX();
		dbg(DBG_USR1, "Query # %d already indexed\n", query->qid);
		return Err_QueryIndex_QueryExist;
	  }
	  i++;
	}
    

	//find a free slot
	mQueryInfoIndex = 0xff;
	if(mQueryCount > MAX_QUERY/2) {
	  i = MAX_QUERY - 1;
	  while(i >= 0) {
		if(mQueryInfo[i].free) {
		  mQueryInfoIndex = i;
		  break;
		}
		i--;
	  }
	}
	else {
	  i = 0;
	  while(i < MAX_QUERY) {
		if(mQueryInfo[i].free) {
		  mQueryInfoIndex = i;
		  break;
		}
		i++;
	  }	    
	}

	if(mQueryInfoIndex == 0xff) {
	  UNSET_UPDATE_INDEX();
	  dbg(DBG_USR1, "Query index: no free slot\n");
	  return Err_QueryIndex_BufferFull;
	}

	nmemcpy(&mQueryInfo[mQueryInfoIndex].query, query, sizeof(ParsedQuery));
	*query_saved = &(mQueryInfo[mQueryInfoIndex].query);
	mQueryInfo[mQueryInfoIndex].qid = query->qid;
	mQueryInfo[mQueryInfoIndex].free = FALSE;
	mQueryCount ++;
	dbg(DBG_USR1, "save query #%d\n", query->qid);
	UNSET_UPDATE_INDEX();
	return SUCCESS;
  }

  uint8_t get_query(uint8_t qid) {
	uint8_t i;
	if(IS_READ_INDEX()) {
	  dbg(DBG_USR1, "read query # %d failed. Another query update/access in process\n", qid);
	  return Err_QueryIndex_Pending;
	}

	SET_READ_INDEX();

	i = 0;
	while(i < MAX_QUERY) {
	  if(!mQueryInfo[i].free && mQueryInfo[i].qid == qid) {
		dbg(DBG_USR1, "Query # %d found\n", qid);
		UNSET_READ_INDEX();
		return i;
	  }
	  i++;
	}
	return 0xff;
  }



  task void deleteQueryTask() {
	ErrorCode ret;
	uint8_t i;
	//check if it is in NoCond list
	i = 0;
	if(mNumNoCondQuery > 0) {
	  while(i < MAX_QUERY) {
		if(!mNoCondQuery[i].free && mNoCondQuery[i].qid == mQid) {
		  mNoCondQuery[i].free = TRUE;
		  mNumNoCondQuery --;
		  UNSET_UPDATE_INDEX();
		  signal QueryIndex.deleteQueryComplete(mQid, SUCCESS);
		  return;
		}
		i++;
	  }
	}

	//check interval tree
	ret = call IntervalTree.deleteInt(mQid, mQueryInfoIndex);
	if(ret != SUCCESS) {
	  UNSET_UPDATE_INDEX();
	  dbg(DBG_USR1, "delete interval for query # %d failed\n", mQid);
	  signal QueryIndex.deleteQueryComplete(mQid, ret);
	}
  }

  task void updateEpochTask() {
	ErrorCode ret;
	ret = call IntervalTree.updateIntEpoch(mQid, mQueryInfoIndex, mQueryInfo[mQueryInfoIndex].query.epoch, mNewEpoch);
	if(ret != SUCCESS) {
	  UNSET_UPDATE_INDEX();
	  dbg(DBG_USR1, "update interval tree index for new epoch");
	  signal QueryIndex.updateEpochComplete(mQid, ret);
	}
  }

  task void searchTask() 
	{
	  ErrorCode ret;
	  //only temperature is handled now
	  //	  DEBUG(141);
	  //	  DEBUG(mEpoch);
	  //	  DEBUG(142);
	  ret = call IntervalTree.searchPoint(mEpoch, 
 //										  TEMP, 
										  MAG,
										  mTuple->temp, 
										  mQueryMatched);
	  if(ret != SUCCESS) 
		{
		  //		  DEBUG(142);
		  UNSET_READ_INDEX();
		  dbg(DBG_USR1, "data %d search failed \n", mTuple->temp);
		  signal QueryIndex.searchTupleComplete(mTuple, mQueryMatched, mNumQueryMatched, ret);
		}
	}

  //parameter: mQueryBuf
//   task void estimateQueryTask() {
// 	//add the interval to the index tree
// 	ErrorCode ret;
// 	uint8_t i;
// 	int16_t lb = NEGINF, rb = INF;
// 	uint8_t numConds = mQueryBuf.numConds;
// 	ConditionPtr conds = mQueryBuf.conds;

// 	//check non-cond list
// 	if(mNumNoCondQuery > 0) {
// 	  UNSET_READ_INDEX();
// 	  dbg(DBG_USR1, "there is an unconditioned query\n");
// 	  signal QueryIndex.estimateQueryOverlapComplete(mQuery, 100, 100, 0, SUCCESS);
// 	  return;
// 	}

// 	if(numConds == 0) {
// 	  lb = 0;
// 	  rb = 100;
// 	}

// 	for(i = 0; i < numConds; i++) {
// 	  switch(conds[i].op) {
// 		//not a interval
// 	  case EQ:
// 	  case NEQ:
// 		break;
// 	  case GT:
// 	  case GE:
// 		if(lb < conds[i].val)
// 		  lb = conds[i].val;
// 		break;
// 	  case LT:
// 	  case LE:
// 		if(rb > conds[i].val)
// 		  rb = conds[i].val;
// 		break;
// 	  }
// 	}
// 	ret = call IntervalTree.estimateOverlapProb(lb, rb, conds[0].attr, mQueryBuf.epoch);
// 	if(ret != SUCCESS) {
// 	  UNSET_READ_INDEX();
// 	  dbg(DBG_USR1, "estimates prob: failed\n");
// 	  signal QueryIndex.estimateQueryOverlapComplete(mQuery, 0xffff, 0, 0, ret);
// 	}
//   }

}
