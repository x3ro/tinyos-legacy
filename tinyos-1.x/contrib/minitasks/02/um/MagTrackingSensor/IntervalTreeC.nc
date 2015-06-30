/*
 * Author: Zhigang Chen
 * Date:   March 11, 2003
 */

/* implementation of interval tree
 * interval statistics only deal with temp and light.
 * location and time do not need to be here,
 * and should be processed elsewhere
 */

/* implement histogram
   leave it here for conveniently estimating extra cost
   March 26, 2003
 */

includes SensorDB;
#define KEY(i) mIntBuf[i].lb
#define RKEY(i) mIntBuf[i].rb
#define LEFT(i) mIntBuf[i].left
#define RIGHT(i) mIntBuf[i].right
#define COLOR(i) mIntBuf[i].color
#define PARENT(i) mIntBuf[i].parent
#define MAX(i) mIntBuf[i].max
#define QID(i) (mIntBuf[i].qid)
#define isInside(i, x) ((mIntBuf[i].lb <= x) && (x < mIntBuf[i].rb))
#define isFree(i) (mIntBuf[i].qid == 0xff)
#define isOverlap(i, lb1, rb1) ((mIntBuf[i].lb < rb1) && (lb1 < mIntBuf[i].rb))

#define HITS(i) (mAllQueries[mIntBuf[i].query_info_index].qstat.num_match)

#define MaxOf(x, y) (x>=y)?x:y
#define MinOf(x, y) (x<=y)?x:y

//#define HIST_CNT(x) mHistBuf[x].hits
#define CNT2PROB(x) (((100*(x))/SUBBAND_SIZE_TEMP)/mTotalSampleCount)

#define UPDATE_MAX(x) do \
{ \
    if(LEFT(x) == NIL && RIGHT(x) == NIL) \
        MAX(x) = RKEY(x); \
    else if(RIGHT(x) == NIL && LEFT(x) != NIL) \
	MAX(x) = MaxOf(MAX(LEFT(x)), RKEY(x)); \
    else if(RIGHT(x) != NIL && LEFT(x) == NIL) \
        MAX(x) = MaxOf(MAX(RIGHT(x)), RKEY(x)); \
    else \
        MAX(x) = MaxOf((MaxOf(MAX(LEFT(x)), MAX(RIGHT(x)))), RKEY(x)); \
} while (0)

#define COPY_NODE(to, from) do \
{ \
    mAllQueries[mIntBuf[from].query_info_index].intptrs[mEpoch] = mAllQueries[mIntBuf[to].query_info_index].intptrs[mEpoch]; \
    mIntBuf[to].lb = mIntBuf[from].lb; \
    mIntBuf[to].rb = mIntBuf[from].rb; \
    mIntBuf[to].max = mIntBuf[from].max; \
    mIntBuf[to].qid = mIntBuf[from].qid; \
    mIntBuf[to].query_info_index = mIntBuf[from].query_info_index; \
    mIntBuf[to].color = mIntBuf[from].color; \
} while (0)

#define RESET_INT_NODE(x) do \
{ \
    LEFT(x) = NIL; \
    RIGHT(x) = NIL; \
    PARENT(x) = NIL; \
    COLOR(x) = BLACK; \
    QID(x) = 0xff; \
} while (0)

#define RESET_ALLQUERIES_NODE(x) do \
{ \
    mAllQueries[x].qstat.num_match = 0; \
    mAllQueries[x].qstat.num_exclusive_match = 0; \
    for(j = 0; j < NUM_EPOCH_LEVEL; j ++) { \
	mAllQueries[x].intptrs[j] = NIL; \
    } \
} while (0)

#define STACK_SIZE 32

module IntervalTreeC {
    provides interface IntervalTree;
    uses {
#ifdef PC_DEBUG_INT
	interface Debug;
#endif
	;
    }
}

#ifdef PC_DEBUG_INT
#ifndef PC
#define DEBUG(x)  \
   do {\
      call Debug.dbg8(0xd1);\
      call Debug.dbg8(x); \
   } while(0)
#define DEBUG2(x)  \
   do {\
      call Debug.dbg8(0xd2);\
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

  uint16_t epoch_factor[NUM_EPOCH_LEVEL];

  struct QueryStatAndRoots {
	QueryStatistics qstat;
	IntervalNodePtr intptrs[NUM_EPOCH_LEVEL];
  } mAllQueries[MAX_QUERY]; //each of this cooresponding a query in query info buffer. The same index is used here.

  uint8_t mQueryInfoIndex; //the query info buffer index cooresponding to the query

  IntNode mIntBuf[MAX_INTERVAL_BUF]; //may be more than enough. Memory usage needs to be optimzied.

  IntNode mDummyNil; //for convenience in delete_fixup
  struct roots_ {
	IntervalNodePtr roots[NUM_EPOCH_LEVEL];
  } mIndexRoots[1];

  uint16_t mTotalSampleCount;
  uint16_t mTotalMatchCount;
  uint16_t mIntervalCount;

  /* save parameters for insert interval*/
  uint8_t mQid;
  int16_t mLb;
  int16_t mRb;
  uint8_t mEpoch;

  uint8_t mOldEpoch;
  uint8_t mNewEpoch;

  /* parameters for search point */
  int16_t mDataSample;
  uint8_t *mQueryMatched; //which queries match the sample
  uint8_t mNumQueryMatched; //the number of queries match for a given data sample


  IntervalNodePtr* rootT; // the root of the tree that is currently accessed
  //functions of red-black interval tree
  IntervalNodePtr tree_successor(IntervalNodePtr x);
  void tree_insert(IntervalNodePtr *root, IntervalNodePtr intptr);
  void left_rotate(IntervalNodePtr *root, IntervalNodePtr intptr);
  void right_rotate(IntervalNodePtr *root, IntervalNodePtr x);
  //  task void insertTask();
  task void deleteTask();
  task void searchTask();
  //  task void estimatetask();

  //record the qid of a matched query
  bool recordMatch(IntervalNodePtr p, uint8_t *queryMatched);
  //estimate the count of samples within the interval
  //  uint32_t estimateCount(int16_t lb, int16_t rb);

  //the binary tree does not change once built.
  //histogram is updated with the most higher query evaluation freq.
  //so the sampling rate may vary from time to time.
  //however, it still gives the statistics of the samples, therefore it can be shared by 
  //queries of different freqs

  //histogram
//   HistNode mHistBuf[HIST_SIZE];
//   uint8_t mHistRoot;

//   void buildHistTree();
//   uint8_t searchHistTree(int16_t key, Attrib att);

  uint8_t stack[STACK_SIZE];
  uint8_t stack_ptr;
  bool push_stack(uint8_t data);
  bool top_stack(uint8_t *data);
  bool pop_stack();
  bool is_stack_empty();
  void ret_stack();

#ifdef PC
  void SDEBUG(uint8_t x) {
	dbg_clear(DBG_USR1, "%d\n", x);
  }
  void SDEBUG2(uint16_t x) {
	dbg_clear(DBG_USR1, "%d\n", x);
  }
#endif
    
  bool push_stack(uint8_t data) {
	if(stack_ptr >= STACK_SIZE)
	  return FALSE;
	stack[stack_ptr] = data;
	stack_ptr ++;
	return TRUE;
  }

  bool top_stack(uint8_t *data) {
	if(stack_ptr <= 0)
	  return FALSE;
	*data = stack[stack_ptr -1];
	return TRUE;
  }

  bool pop_stack() {
	if(stack_ptr <= 0)
	  return FALSE;
	stack_ptr --;
	return TRUE;
  }

  bool is_stack_empty() {
	return (stack_ptr <= 0);
  }

  void reset_stack() {
	stack_ptr = 0;
  }


  //histogram functions
  //the binary tree does not change once built.
  /* --------------------------------------------------------------------------*/
//   void buildHistTree() {
// 	uint8_t i,j,a;
// 	uint16_t subband, min;
// 	uint8_t attr;

// 	attr = TEMP;
// 	min = MIN_TEMP;
// 	subband = (MAX_TEMP - MIN_TEMP)/HIST_SIZE;
// 	mHistBuf[0].key = min;
// 	mHistBuf[0].hits = 100;
// 	for(i = 1; i < HIST_SIZE; i++) {
// 	  mHistBuf[i].key = min + i * subband;
// 	  if(i % 2 == 1) {
// 		mHistBuf[i].left = NIL;
// 		mHistBuf[i].right = NIL;
// 	  }
// 	  else {
// 		j = 0;
// 		a = i;
// 		while((a % 2) == 0) {
// 		  a = a/2;
// 		  j++;
// 		}
// 		a = 1;
// 		while(j>1) {
// 		  a = a*2;
// 		  j --;
// 		}
			       
// 		mHistBuf[i].left = i - a ;
// 		mHistBuf[i].right = i + a;
// 	  }
// 	  //for test
// 	  mHistBuf[i].hits = 100;
// 	}
// 	mHistRoot = HIST_SIZE/2;

//   }

//   uint8_t searchHistTree(int16_t key, Attrib att) {
// 	uint8_t x,y;
// 	if(att == TEMP) {// support TEMP now. add code for LIGHT later
// 	  x = mHistRoot;
// 	  while(TRUE) {
// 		if(key >= mHistBuf[x].key) {
// 		  y = x;
// 		  x = mHistBuf[x].right;
// 		  if(x == NIL)
// 			return y;
// 		}
// 		else {
// 		  y = x;
// 		  x = mHistBuf[x].left;
// 		  if(x == NIL)
// 			return y -1;
// 		}
// 	  }
// 	}
// 	else
// 	  return 0;
//   }

//   void updateHist(int16_t key, Attrib att) {
// 	uint8_t x;
// 	if(att == TEMP) {
// 	  x = searchHistTree(key, att);
// 	  HIST_CNT(x) ++;
// 	}
//   }

//   uint32_t estimateCount(int16_t lb, int16_t rb){
// 	uint8_t i;
// 	uint32_t sum = 0;
// 	uint8_t li, ri;
// 	uint32_t ret;
	
// 	if(lb >= rb)
// 	  return 0;
// 	li = searchHistTree(lb, TEMP);
// 	ri = searchHistTree(rb, TEMP);

// 	//to reduce truncation error, we will divide by SUBBAND_SIZE_TEMP later
// 	if(li == ri) {
// 	  ret = (uint16_t)((uint8_t)(rb - lb)) * HIST_CNT(ri);
// 	}
// 	else {
// 	  sum += (mHistBuf[li+1].key - lb) * HIST_CNT(li);
// 	  for(i = li+1; i <ri; i++)
// 		sum += HIST_CNT(li) * SUBBAND_SIZE_TEMP;
// 	  sum += (rb - mHistBuf[ri].key) * HIST_CNT(ri);
// 	  ret = sum;
// 	}

// 	//dbg_clear(DBG_TEMP, "count of [%d, %d) = %d\n", lb, rb, ret);
// 	return ret;
//   }

  //interval tree
  //it is bsaically a black-red interval tree
  /*--------------------------------------------------------------------------------------------*/
  IntervalNodePtr tree_successor(IntervalNodePtr x);
  void left_rotate(IntervalNodePtr *root, IntervalNodePtr x);
  void right_rotate(IntervalNodePtr *root, IntervalNodePtr x);
  void tree_insert(IntervalNodePtr *root, IntervalNodePtr newNode);
  void tree_delete(IntervalNodePtr *root, IntervalNodePtr z);
  void delete_fixup(IntervalNodePtr *root, IntervalNodePtr x);
  void adjustColor(IntervalNodePtr *root, IntervalNodePtr new_node);
  void dump_tree(IntervalNodePtr y);

  IntervalNodePtr tree_successor(IntervalNodePtr x) {
	IntervalNodePtr y, z;
	if(RIGHT(x) != NIL) {
	  x = RIGHT(x);
	  while(LEFT(x) != NIL)
		x = LEFT(x);
	  return x;
	}
	z = x;
	y = PARENT(z);
	while(y != NIL && z == RIGHT(y)) {
	  z = y;
	  y = PARENT(y);
	}
	return y;
  }
	    
	    
  void tree_insert(IntervalNodePtr *root, IntervalNodePtr newNode) {
	IntervalNodePtr y = NIL;
	IntervalNodePtr x = *root;
	while(x != NIL) {
	  y = x;
	  if(KEY(newNode) < KEY(x))
		x = LEFT(x);
	  else
		x = RIGHT(x);
	}
	PARENT(newNode) = y;
	if(y == NIL)
	  *root = newNode;
	else {
	  if(KEY(newNode) < KEY(y))
		LEFT(y) = newNode;
	  else
		RIGHT(y) = newNode;
	}

	//update augmented fields
	//from the new node up to the root
	MAX(newNode) = mIntBuf[newNode].rb;

	if(*root == newNode)
	  return;
	y = PARENT(newNode);
	do {
	  UPDATE_MAX(y);
	  y = PARENT(y);
	} while(y != NIL);

	return;
  }

  void tree_delete(IntervalNodePtr *root, IntervalNodePtr z) {
	IntervalNodePtr x, y, w;
	if(LEFT(z) == NIL || RIGHT(z) == NIL)
	  y = z;
	else
	  y = tree_successor(z);
	if(LEFT(y) != NIL)
	  x = LEFT(y);
	else
	  x = RIGHT(y);
	
	if(x != NIL)
	  PARENT(x) = PARENT(y);
	else
	  mDummyNil.parent = PARENT(y); //just record where should go up. 

	if(PARENT(y) == NIL) {
	  *rootT = x;
	}
	else {
	  if(y == LEFT(PARENT(y)))
		LEFT(PARENT(y)) = x ;
	  else
		RIGHT(PARENT(y)) = x;
	  //update max
	  UPDATE_MAX(PARENT(y));
	}
	if(y != z) {
	  COPY_NODE(z, y);
	  UPDATE_MAX(z);
	}

	//update max
	w = PARENT(z);
	while(w != NIL) {
	  UPDATE_MAX(w);
	  w = PARENT(w);
	}

	//dump_tree(*rootT);

	if(COLOR(y) == BLACK)
	  delete_fixup(rootT, x);

	RESET_INT_NODE(y); //y is actually kicked out
  }

  void left_rotate(IntervalNodePtr *root, IntervalNodePtr x) {
	IntervalNodePtr y = RIGHT(x);
	RIGHT(x) = LEFT(y);

	//update augmented fields
	UPDATE_MAX(x);

	if(LEFT(y) != NIL)
	  PARENT(LEFT(y)) = x;
	PARENT(y) = PARENT(x);
	if(PARENT(x) == NIL)
	  *root = y;
	else {
	  if(x == LEFT(PARENT(x)))
		LEFT(PARENT(x)) = y;
	  else
		RIGHT(PARENT(x)) = y;
	  //update augmented fields
	  UPDATE_MAX(PARENT(x));
	}
	LEFT(y) = x;
	//update augmented fields
	UPDATE_MAX(y);

	PARENT(x) = y;
	return;
  }

  void right_rotate(IntervalNodePtr *root, IntervalNodePtr x) {
	IntervalNodePtr y = LEFT(x);
	LEFT(x) = RIGHT(y);

	//update augmented fields
	UPDATE_MAX(x);
	
	if(RIGHT(y) != NIL)
	  PARENT(RIGHT(y)) = x;
	PARENT(y) = PARENT(x);
	if(PARENT(x) == NIL)
	  *root = y;
	else {
	  if(x == LEFT(PARENT(x)))
		LEFT(PARENT(x)) = y;
	  else
		RIGHT(PARENT(x)) = y;
	  //update augmented fields
	  UPDATE_MAX(PARENT(x));
	}

	RIGHT(y) = x;
	//update augmented fields
	UPDATE_MAX(y);

	PARENT(x) = y;
	return;
  }

  void delete_fixup(IntervalNodePtr *root, IntervalNodePtr x) {
	IntervalNodePtr w;
	//take care if x == NIL
	//use mDummyNil
	if(x == NIL && x != *root) {
	  if(LEFT(mDummyNil.parent) == NIL) {
		w = RIGHT(mDummyNil.parent);
		if(COLOR(w) == RED) {
		  COLOR(w) = BLACK;
		  COLOR(mDummyNil.parent) = RED;
		  left_rotate(root, mDummyNil.parent);
		  w = RIGHT(mDummyNil.parent);
		}
		if(COLOR(LEFT(w)) == BLACK && COLOR(RIGHT(w)) == BLACK) {
		  COLOR(w) = RED;
		  x = mDummyNil.parent;
		}
		else {
		  if(COLOR(RIGHT(w)) == BLACK) {
			COLOR(w) = RED;
			right_rotate(root, w);
			w = RIGHT(mDummyNil.parent);
		  }
		  COLOR(w) = COLOR(mDummyNil.parent);
		  COLOR(mDummyNil.parent) = BLACK;
		  COLOR(RIGHT(w)) = BLACK;
		  left_rotate(root, mDummyNil.parent);
		  x = *root;
		}
	  }
	  else {
		w = LEFT(mDummyNil.parent);
		if(COLOR(w) == RED) {
		  COLOR(w) = BLACK;
		  COLOR(mDummyNil.parent) = RED;
		  right_rotate(root, mDummyNil.parent);
		  w = LEFT(mDummyNil.parent);
		}
		if(COLOR(RIGHT(w)) == BLACK && COLOR(LEFT(w)) == BLACK) {
		  COLOR(w) = RED;
		  x = mDummyNil.parent;
		}
		else {
		  if(COLOR(LEFT(w)) == BLACK) {
			COLOR(w) = RED;
			left_rotate(root, w);
			w = LEFT(mDummyNil.parent);
		  }
		  COLOR(w) = COLOR(mDummyNil.parent);
		  COLOR(mDummyNil.parent) = BLACK;
		  COLOR(LEFT(w)) = BLACK;
		  right_rotate(root, mDummyNil.parent);
		  x = *root;
		}
	  }

	}

	while(x != *root && COLOR(x) == BLACK) {
	  if(x == LEFT(PARENT(x))) {
		w = RIGHT(PARENT(x));
		if(COLOR(w) == RED) {
		  COLOR(w) = BLACK;
		  COLOR(PARENT(x)) = RED;
		  left_rotate(root, PARENT(x));
		  w = RIGHT(PARENT(x));
		}
		if(COLOR(LEFT(w)) == BLACK && COLOR(RIGHT(w)) == BLACK) {
		  COLOR(w) = RED;
		  x = PARENT(x);
		}
		else {
		  if(COLOR(RIGHT(w)) == BLACK) {
			COLOR(w) = RED;
			right_rotate(root, w);
			w = RIGHT(PARENT(x));
		  }
		  COLOR(w) = COLOR(PARENT(x));
		  COLOR(PARENT(x)) = BLACK;
		  COLOR(RIGHT(w)) = BLACK;
		  left_rotate(root, PARENT(x));
		  x = *root;
		}
	  }
	  else {
		w = LEFT(PARENT(x));
		if(COLOR(w) == RED) {
		  COLOR(w) = BLACK;
		  COLOR(PARENT(x)) = RED;
		  right_rotate(root, PARENT(x));
		  w = LEFT(PARENT(x));
		}
		if(COLOR(RIGHT(w)) == BLACK && COLOR(LEFT(w)) == BLACK) {
		  COLOR(w) = RED;
		  x = PARENT(x);
		}
		else {
		  if(COLOR(LEFT(w)) == BLACK) {
			COLOR(w) = RED;
			left_rotate(root, w);
			w = LEFT(PARENT(x));
		  }
		  COLOR(w) = COLOR(PARENT(x));
		  COLOR(PARENT(x)) = BLACK;
		  COLOR(LEFT(w)) = BLACK;
		  right_rotate(root, PARENT(x));
		  x = *root;
		}
	  }
	}
	COLOR(x) = BLACK;
  }

  void adjustColor(IntervalNodePtr *root, IntervalNodePtr new_node) {
	IntervalNodePtr x, y;
	x = new_node;

	COLOR(x) = RED;
	while(x != *root && COLOR(PARENT(x)) == RED) {
	  if(PARENT(x) == LEFT(PARENT(PARENT(x)))) {
		y = RIGHT(PARENT(PARENT(x)));
		if(COLOR(y) == RED) {
		  COLOR(PARENT(x)) = BLACK;
		  COLOR(y) = BLACK;
		  COLOR(PARENT(PARENT(x))) = RED;
		  x = PARENT(PARENT(x));
		}
		else {
		  if(x == RIGHT(PARENT(x))) {
			x = PARENT(x);
			left_rotate(root, x);
		  }
		  COLOR(PARENT(x)) = BLACK;
		  COLOR(PARENT(PARENT(x))) = RED;
		  right_rotate(root, PARENT(PARENT(x)));
		}
	  }
	  else if(PARENT(x) == RIGHT(PARENT(PARENT(x)))){ 
		y = LEFT(PARENT(PARENT(x)));
		if(COLOR(y) == RED) {
		  COLOR(PARENT(x)) = BLACK;
		  COLOR(y) = BLACK;
		  COLOR(PARENT(PARENT(x))) = RED;
		  x = PARENT(PARENT(x));
		}
		else {
		  if(x == LEFT(PARENT(x))) {
			x = PARENT(x);
			right_rotate(root, x);
		  }
		  COLOR(PARENT(x)) = BLACK;
		  COLOR(PARENT(PARENT(x))) = RED;
		  left_rotate(root, PARENT(PARENT(x)));		
		}
	  }	    
	}

	COLOR(*root) = BLACK;
  }

  bool recordMatch(IntervalNodePtr p, uint8_t *queryMatched) {
	uint8_t qid = QID(p);
	if(qid >= MAX_QUERY)
	  return FALSE;


	//remember the qid since we need to count sigle(exclusive) matches
	mQueryInfoIndex = mIntBuf[p].query_info_index;
	mQid = qid; 

	queryMatched[mNumQueryMatched] = qid;
	mNumQueryMatched ++;
	mTotalMatchCount ++;
	mAllQueries[mIntBuf[p].query_info_index].qstat.num_match ++; //increase the match counter of that query for statistics record
	return TRUE;
  }

  void searchTreeByPoint(IntervalNodePtr *root, int16_t data, uint8_t *queryMatched) {
	IntervalNodePtr x = *root;
	DEBUG(222);
	DEBUG(222);
	while(x != NIL || !is_stack_empty()) {
	  if(x == NIL) {
		top_stack(&x);
		pop_stack();
	  }
	  DEBUG2(KEY(x));
	  DEBUG(222);
	  DEBUG2(RKEY(x));
	  DEBUG(222);
	  DEBUG2(data);
	  DEBUG(222);
	  if(isInside(x, data)) {
		dbg_clear(DBG_USR1, "data %d matches query %d\n", data, QID(x));		
		recordMatch(x, queryMatched);
		DEBUG(220);
	  }

	  if(LEFT(x) != NIL && MAX(LEFT(x)) > data) {
		if(RIGHT(x) != NIL) //remember right subtree
		  push_stack(RIGHT(x));
		x = LEFT(x);
	  }
	  else
		x = RIGHT(x);	    
	}
	DEBUG(222);
	DEBUG(222);
  }

  void dump_tree(IntervalNodePtr y) {
	IntervalNodePtr x = y;
	if(x != NIL) {
	  dbg_clear(DBG_USR1, "node #= %d (%d,%d) %d, l = %d, r = %d, parent = %d, \n color = %d, qid = %d, query_info_index = %d\n",
				x, KEY(x), RKEY(x), MAX(x), LEFT(x), RIGHT(x), PARENT(x), COLOR(x), QID(x), mIntBuf[x].query_info_index);
	  dbg_clear(DBG_USR1," l-- ");
	  DEBUG(111);
	  DEBUG(111);
	  DEBUG(111);
	  DEBUG(x);
	  DEBUG(111);
	  DEBUG2(KEY(x));
	  DEBUG(111);
	  DEBUG2(RKEY(x));
	  DEBUG(111);
	  DEBUG(111);
	  dump_tree(LEFT(x));
	  dbg_clear(DBG_USR1, " r-- ");
	  dump_tree(RIGHT(x));
	}
	else {
	  dbg_clear(DBG_USR1, "NIL\n");
	  return;
	}
  }


  task void deleteTask() {
	uint8_t epoch = 0, j;
	IntervalNodePtr z;
	
	for(epoch = 0; epoch < NUM_EPOCH_LEVEL; epoch ++) {
	  z = mAllQueries[mQueryInfoIndex].intptrs[epoch];
	  if(z == NIL)
		continue;
	  mEpoch = epoch; //for update intptrs in mAllQueries
	  rootT = &mIndexRoots[0].roots[epoch];
	  tree_delete(rootT, z);
	  mAllQueries[mQueryInfoIndex].intptrs[epoch] = NIL;
	  mIntervalCount --;

	  //dump_tree(*rootT);

	}
	RESET_ALLQUERIES_NODE(mQueryInfoIndex);
	signal IntervalTree.deleteIntComplete(mQid, mQueryInfoIndex, SUCCESS);
  }

  task void updateIntEpochTask() {
	uint8_t epoch = 0, i;
	IntervalNodePtr z;

	IntervalNodePtr start = 0;
	IntervalNodePtr new_node = 0xff;

	if(mOldEpoch == mNewEpoch) {
	  signal IntervalTree.updateIntEpochComplete(mQid, mQueryInfoIndex, SUCCESS);
	}
	else if(mOldEpoch < mNewEpoch) {
	  for(epoch = mOldEpoch; epoch < mNewEpoch; epoch ++) {
		z = mAllQueries[mQueryInfoIndex].intptrs[epoch];
		if(z == NIL)
		  continue;
		mEpoch = epoch; //for update intptrs in mAllQueries
		rootT = &mIndexRoots[0].roots[epoch];
		tree_delete(rootT, z);
		mAllQueries[mQueryInfoIndex].intptrs[epoch] = NIL;;
		mIntervalCount --;
	  }
	  signal IntervalTree.updateIntEpochComplete(mQid, mQueryInfoIndex, SUCCESS);	    
	}
	else if(mOldEpoch > mNewEpoch) {
	  for(epoch = mNewEpoch; epoch < mOldEpoch; epoch ++) {
		//find a free slot
		i = start;
		new_node = 0xff;
		z = mAllQueries[mQueryInfoIndex].intptrs[mOldEpoch];

		while(i < MAX_INTERVAL_BUF) {
		  if(isFree(i)) {
			start = i + 1;
			new_node = i;
			break;
		  }
		  i++;
		}	

		if(new_node == 0xff) {
		  dbg(DBG_USR1, "what has happened? interval count does not reach the limit, but no free slot\n");
		  return;
		}
	    
		mIntervalCount ++;

		mIntBuf[new_node].lb = KEY(z);
		mIntBuf[new_node].rb = RKEY(z);
		mIntBuf[new_node].qid = mQid;
		mIntBuf[new_node].query_info_index = mQueryInfoIndex;
	    
		//record the IntervalNodePtr of the interval
		mAllQueries[mQueryInfoIndex].intptrs[epoch] = new_node;

		HITS(new_node) = 0;
		rootT = &mIndexRoots[0].roots[epoch];
		dbg(DBG_USR1, "root of tree epoch %d  is %d\n", epoch, *rootT);
		tree_insert(rootT, new_node); //insert the interval into the tree by its left bound
		dbg(DBG_USR1, "after insert root of tree epoch %d  is %d\n", epoch, *rootT);
		adjustColor(rootT, new_node);
		dbg(DBG_USR1, "after adjust root of tree epoch %d  is %d\n", epoch, *rootT);
		//		dump_tree(*rootT);
	  }
	  signal IntervalTree.updateIntEpochComplete(mQid, mQueryInfoIndex, SUCCESS);
	}
  }


  task void searchTask() 
	{
	  //search the interval tree
	  //get the queries that match the data sample
	  DEBUG(152);
	  searchTreeByPoint(rootT, mDataSample, mQueryMatched);
	
	  //this data sample match at least a query
	  //so a result must be sent back
	  //mTotalSample
	  if(mNumQueryMatched > 0)
		mTotalMatchCount ++;

	  if(mNumQueryMatched == 1) 
		{
		  dbg(DBG_USR1, "sample %d matches query %d exclusively\n", mDataSample, mQid);
		  mAllQueries[mQueryInfoIndex].qstat.num_exclusive_match ++;
		}

	  signal IntervalTree.searchPointComplete(mQueryMatched, mNumQueryMatched, SUCCESS);
	  return;
	}


  /* 
	 for each epoch tree
	 find the overlaps and non-overlaps the interval of the new query has with the index queries.
	 Calculate the probability based on the statistics of the histogram
	 Input: 
	 mLb, mRb: left and right bound of the interval
	 mEpoch: the epoch of the query
	 Output: 
	 mOverlapCount: probability of overlap
	 mNonoverlapCount: probability of non-overlap
  */

//   task void estimateTask() {
// 	IntervalNodePtr x, y;
// 	int16_t overlap_lb, overlap_rb;
// 	uint16_t overlap_prob = 0;
// 	uint16_t nonoverlap_prob = 0;
// 	uint8_t epoch;
// 	uint32_t overlap_count;
// 	uint32_t total_overlap_count;
// 	uint32_t total_nonoverlap_count;
// 	uint32_t A, B;
// 	uint32_t adjust;

// 	uint16_t total_match_prob;

// 	int16_t max_rb; //the max right bound seen
// 	//this node has not been used for while: mTotalSampleCount == 0
// 	//so no information for estimate

// 	if(mTotalSampleCount == 0) {
// 	  signal IntervalTree.estimateOverlapProbComplete(0xff, 0, 0, SUCCESS); //no info
// 	  return;
// 	}
	
// 	total_overlap_count = 0;
// 	total_nonoverlap_count = 0;
// 	adjust = 0;
// 	//check from mEpoch 
// 	for(epoch = mEpoch; epoch < NUM_EPOCH_LEVEL; epoch ++) {
// 	  x = mIndexRoots[0].roots[epoch];

// 	  overlap_count = 0;
// 	  overlap_lb = mLb;
// 	  overlap_rb = mRb;

// 	  //nothing has been indexed, but there is some useful data; otherwise, mTotalSampleCount should be reset.
// 	  if(x == NIL) {
// 		overlap_count = 0;
// 		goto calcProb;
// 	  }

// 	  //find the left most interval
// 	  while(LEFT(x) != NIL)
// 		x = LEFT(x);

// 	  while(RKEY(x) <= overlap_lb && x != NIL)
// 		x = tree_successor(x);
	    
// 	  if(x == NIL) {//no overlap
// 		overlap_count = 0;
// 		goto calcProb;
// 	  }
// 	  else {
// 		if(overlap_lb < KEY(x)) {
// 		  if(overlap_rb <= KEY(x)) {
// 			overlap_count = 0;
// 			goto calcProb;
// 		  }
// 		  overlap_lb = KEY(x);
// 		}
// 	  }

// 	  if(overlap_lb >= KEY(x)) {
// 		max_rb = RKEY(x);
// 		//if mRb is beyond the max right bound we know, we need to check further
// 		while(mRb > max_rb) {
// 		  y = x;		    
// 		  x = tree_successor(x);
		    
// 		  //first need to check if the next interval overlaps x
// 		  //if not an end of the tree
// 		  if(x != NIL) {
// 			//the max right bound is less than the left bound of the new interval
// 			//so there is overlap is segmented here
// 			if(max_rb < KEY(x)) {//not overlap, update probabilites
// 			  overlap_rb = max_rb;
// 			  overlap_count += estimateCount(overlap_lb, overlap_rb);
// 			  //update the left bound and max right bound
// 			  overlap_lb = KEY(x);
// 			  max_rb = RKEY(x);
// 			}
// 			else {
// 			  if(max_rb < RKEY(x)) //update max_rb, seen a larger one.
// 				max_rb = RKEY(x);
// 			}			    
// 		  }
// 		  else
// 			break;
// 		}
// 		if(x == NIL) { //reach the right most 
// 		  overlap_rb = max_rb;
// 		  overlap_count += estimateCount(overlap_lb, overlap_rb);
// 		}
// 		else {
// 		  overlap_rb = mRb;
// 		  overlap_count += estimateCount(overlap_lb, overlap_rb);
// 		}
// 	  }

// 	calcProb:
// 	  //if query 1 and 2 overlap at epoch i, it must also overlap at epoch i+1, i+2, etc.
// 	  //so we should substract it at 
// 	  total_overlap_count += (overlap_count/epoch_factor[epoch]);
// 	  if(epoch < NUM_EPOCH_LEVEL - 1)
// 		adjust += total_overlap_count/epoch_factor[epoch+1];
	    
// 	  dbg(DBG_USR1, "total_overlap_count in %d is %d\n", epoch, total_overlap_count);
// 	}

// 	total_overlap_count -= adjust; 
// 	dbg(DBG_USR1, "final total_overlap_count is %d\n", total_overlap_count);
// 	total_nonoverlap_count = estimateCount(mLb, mRb) - total_overlap_count;
// 	//to avoid floating point computation (very expensive for motes)
// 	//we use percentage so times by 1000
// 	dbg(DBG_USR1, "%d\n", mTotalSampleCount);
// 	A = 1000 * total_overlap_count;		
// 	B = mTotalSampleCount;		
// 	B = SUBBAND_SIZE_TEMP * B;
// 	dbg(DBG_USR1, "A and B for overlap = %d and %d\n", A, B);
// 	overlap_prob = (uint16_t)(A/B);

// 	A = 1000 * total_nonoverlap_count;
// 	B = (uint32_t)mTotalSampleCount;
// 	B = SUBBAND_SIZE_TEMP * B;

// 	dbg(DBG_USR1, "A and B for nonoverlap = %d and %d\n", A, B);
// 	nonoverlap_prob = (uint16_t)(A/B);

// 	A = mTotalMatchCount;
// 	A *= 100;
// 	B = mTotalSampleCount;
// 	total_match_prob = (uint16_t)(A/B);
// 	dbg(DBG_USR1, "estimate query task completes here\n");
// 	DEBUG(overlap_prob);
// 	DEBUG(nonoverlap_prob);
// 	DEBUG(total_match_prob);
// 	signal IntervalTree.estimateOverlapProbComplete(total_match_prob, overlap_prob, nonoverlap_prob, SUCCESS);
// 	return;
//   }


  // 
  // Init() command
  //
  command ErrorCode IntervalTree.init() {
	uint8_t i, j;

#ifdef PC_DEBUG_INT
	call Debug.init();
	call Debug.setAddr(TOS_UART_ADDR);
#endif
	DEBUG(101);
	//constants
	epoch_factor[0] = 1;
	epoch_factor[1] = 4;
	epoch_factor[2] = 16;
	epoch_factor[3] = 64;

	//init the interval buffer
	for(i = 0; i < MAX_INTERVAL_BUF; i ++) {
	  RESET_INT_NODE(i);
	}

	//init mAllQueries
	for(i = 0; i < MAX_QUERY; i++) {
	  RESET_ALLQUERIES_NODE(i);
	}

	mTotalSampleCount = 3200;
	mTotalMatchCount = 0;
	mIntervalCount = 0;

	for(i = 0; i < NUM_EPOCH_LEVEL; i ++) {
	  mIndexRoots[0].roots[i] = NIL;
	}

	//init stack
	reset_stack();

	//build histogram tree
//	buildHistTree();

	return SUCCESS;
  }

  /* 
   * Find a free node from buffer and set the subscript of the node to mNewIndex
   * return Err_Interval_Pending is there is another interval operation pending
   * return Err_Interval_Too_Many_Interval if there is not more free node
   */
  command ErrorCode IntervalTree.insertInt(int16_t lb, 
										   int16_t rb, 
										   uint8_t qid, 
										   Attrib att, 
										   EpochLevel epoch, 
										   uint8_t queryInfoIndex) 
	{
	  uint8_t epoch_, i;

	  IntervalNodePtr start = 0;
	  IntervalNodePtr new_node = 0xff;

	  DEBUG(0x01);
	  if(mIntervalCount >= MAX_INTERVAL_BUF) 
		{
		  DEBUG(0x61);
		  dbg(DBG_USR1, "interval buffer full\n");
		  return Err_IntervalTree_Full;
		}

	
	  DEBUG(0x02);
	  //start from mEpoch, we need to insert it to all the 
	  for(epoch_ = mEpoch; epoch_ < NUM_EPOCH_LEVEL; epoch_++) 
		{
		  //find a free slot
		  i = start;
		  new_node = 0xff;
		  while(i < MAX_INTERVAL_BUF) 
			{
			  if(isFree(i)) 
				{
				  start = i + 1;
				  new_node = i;
				  break;
				}
			  i++;
			}	

		  if(new_node == 0xff) 
			{
			  DEBUG(0x62);
			  dbg(DBG_USR1, "what has happened? interval count does not reach the limit, but no free slot\n");
			  return FAIL;
			}
	    
		  mIntervalCount ++;

		  mIntBuf[new_node].lb = lb;
		  mIntBuf[new_node].rb = rb;
		  mIntBuf[new_node].qid = qid;
		  mIntBuf[new_node].query_info_index = queryInfoIndex;
	    
		  //record the IntervalNodePtr of the interval
		  mAllQueries[queryInfoIndex].intptrs[epoch_] = new_node;

		  HITS(new_node) = 0;
		  rootT = &mIndexRoots[0].roots[epoch_];
		  //insert the interval into the tree by its left bound
		  tree_insert(rootT, new_node); 
		  adjustColor(rootT, new_node);
		}
	  DEBUG(0x03);
	  //	  signal IntervalTree.insertIntComplete(mQid, mQueryInfoIndex, SUCCESS);
	  return SUCCESS;
	}





  /* delete the interval of a query given by the subscript of the node
   * return 
   */
  command ErrorCode IntervalTree.deleteInt(uint8_t qid, uint8_t queryInfoIndex) {
	uint8_t epoch;
	IntervalNodePtr p;
	bool queryFound = FALSE;

	//find if this query is actually here	
	for (epoch = 0; epoch < NUM_EPOCH_LEVEL; epoch ++) {
	  p = mAllQueries[queryInfoIndex].intptrs[epoch];
	  if(p == NIL) 
		continue;
	  if(mIntBuf[p].qid == qid) {
		queryFound = TRUE;
		break;
	  }
	}

	if(!queryFound) {
	  dbg(DBG_USR1, "query id does not match what interval tree has when deleting query # %d\n", qid);
	  return Err_IntervalTree_NotFound;
	}

	mQueryInfoIndex = queryInfoIndex;
	mQid = qid;

	post deleteTask();

	return SUCCESS;
  }


  command ErrorCode IntervalTree.updateIntEpoch(uint8_t qid, uint8_t queryInfoIndex, uint8_t old_epoch, uint8_t new_epoch) {
	uint8_t epoch;
	IntervalNodePtr p;

	//find if this query is actually here	
	for (epoch = old_epoch; epoch < NUM_EPOCH_LEVEL; epoch ++) {
	  p = mAllQueries[queryInfoIndex].intptrs[epoch];
	  if(p == NIL || mIntBuf[p].qid != qid) {
		dbg(DBG_USR1, "query %d seems not to have epoch %d\n", qid, old_epoch);
		return Err_IntervalTree_IntNotFound;
	  }
	}

	mQueryInfoIndex = queryInfoIndex;
	mQid = qid;
	mOldEpoch = old_epoch;
	mNewEpoch = new_epoch;

	post updateIntEpochTask();

	return SUCCESS;
  }
    
  command ErrorCode IntervalTree.searchPoint(EpochLevel qlevel, 
											 Attrib att, 
											 int16_t point, 
											 uint8_t *queryMatched) 
	{
	  rootT = &mIndexRoots[0].roots[qlevel];
	  DEBUG(*rootT);
	  DEBUG(143);
	  //	dump_tree(*rootT);
	  mEpoch = qlevel;
	  mDataSample = point;
	  mQueryMatched = queryMatched;
	  mNumQueryMatched = 0;
	  DEBUG(151);
//	  updateHist(point, att);

	  post searchTask();
	  return SUCCESS;
	}

//   command ErrorCode IntervalTree.estimateOverlapProb(int16_t lb, int16_t rb, Attrib att, EpochLevel qlevel) {
// 	mLb = lb; mRb = rb;
// 	mEpoch = qlevel;

// 	DEBUG(lb);
// 	DEBUG(rb);

// 	post estimateTask();
// 	return SUCCESS;
//   }
    
}
	
