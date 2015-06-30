#include "AGG_OPERATOR.h"
#include "alloc.h"
#include <string.h>

typedef struct {
  int numGroups; //how many groups are there
  int groupSize; //how many bytes per group
  char groupData[1];  //data for groups -- depends on type of aggregate -- of size groupSize * numGroups
} GroupData, *GroupDataPtr, **GroupDataHandle;

typedef struct {
  short value;
  short id;
} AlgebraicData;

typedef struct {
  short sum;
  short count;
} AverageData;

typedef struct {
  short ids[3];
  short mins[3];
} Min3Data;

typedef struct {
  short groupNo;
  union {
    bool empty;
    char exprIdx; //idx of operator that owns us
  } u;

  union{
    AlgebraicData algd;
    AverageData avgd;
    Min3Data min3d;
  } d;
} GroupRecord;

typedef void (*GroupDataCallback)(GroupRecord *d);

#define TOS_FRAME_TYPE AGG_OPERATOR_frame
TOS_FRAME_BEGIN(AGG_OPERATOR_frame) {
  GroupDataCallback callback;
  ParsedQuery *curQuery;
  Expr *curExpr;
  QueryResult *curResult;
  Tuple *curTuple;
  short curGroup;
  Handle alloced;
  GroupRecord *groupRecord;
}
TOS_FRAME_END(AGG_OPERATOR_frame);

#define kMAX_SHORT 0x7FFF
#define kMIN_SHORT 0x8000

/* -------------------------------- Local prototypes -------------------------------- */
void getGroupData(ParsedQuery *pq, short groupNo , Expr *e, GroupDataCallback callback);
void updateGroupForTuple(GroupRecord *d);
short groupSize(Expr *e);
void mergeAggregateValues(GroupRecord *dest, GroupRecord *merge, Expr *e);
void updateAggregateValue(GroupRecord *d, Expr *e, short fieldValue);
void initAggregateValue(GroupRecord *d, Expr *);
void updateGroupForPartialResult(GroupRecord *d);
GroupRecord *findGroup(GroupDataHandle dh, short groupNum);
GroupRecord *addGroup(GroupDataHandle dh, short groupNum);
bool removeEmptyGroup(GroupDataHandle dh);
short getGroupNo(Tuple *t, ParsedQuery *q, Expr *e);

TOS_TASK(fireCallback);

/* -------------------------------- Macros for getting / setting group records  -------------------------------- */

#define GET_GROUP_DATA(dHan,n)((GroupRecord *)&((**dHan).groupData[(n) * (**dHan).groupSize]))
#define SET_GROUP_DATA(dHan,n,dataptr) (memcpy(GET_GROUP_DATA(dHan,n), (const char *)(dataptr), (**dHan).groupSize))
#define COPY_GROUP_DATA(dHan,n,dest)(memcpy((char *)(dest),(const char *)GET_GROUP_DATA(dHan,n), (**dHan).groupSize))

/* -------------------------------- Functions -------------------------------- */

//Given a query-result from a different node, add the result into 
//the locally computed value for the query.  The locally computed
//value is stored with the expression.
TinyDBError TOS_COMMAND(AGG_OPERATOR_PROCESS_PARTIAL_RESULT)(QueryResult *qr, ParsedQuery *qs, Expr *e) {
  GroupRecord *gr = (GroupRecord *)qr->d.data;

  if (gr->u.exprIdx != e->idx) 
    return err_InvalidAggregateRecord; //not for us
  VAR(curExpr) = e;
  VAR(curQuery) = qs;
  VAR(curResult) = qr;

  getGroupData(qs,gr->groupNo, e, &updateGroupForPartialResult);
  return err_NoError;
}

void updateGroupForPartialResult(GroupRecord *d) {
  GroupRecord *gr = (GroupRecord *)((QueryResult *)VAR(curResult))->d.data;


  mergeAggregateValues(d,gr,VAR(curExpr));

  TOS_SIGNAL_EVENT(AGG_OPERATOR_PROCESSED_RESULT)(VAR(curResult), VAR(curQuery), VAR(curExpr));
}

/*
Return the next result to this query.

If there are no more results, return err_NoMoreResults

qr->result_idx should be set to kFIRST_RESULT if the first result is desired,
or to the previous value of qr->result_idx returned by the last invocation
of AGG_OPERATOR_NEXT_RESULT

*/
TinyDBError TOS_COMMAND(AGG_OPERATOR_NEXT_RESULT)(QueryResult *qr, ParsedQuery *qs, Expr *e) {
  GroupDataHandle gdh = (GroupDataHandle)e->opState;
  bool empty = TRUE;
  GroupRecord *gr;

  if (gdh != NULL) {
    short idx = qr->result_idx;
    
    do {  //loop til we find the next non-empty group
      GroupRecord *gr;

      if (idx == kFIRST_RESULT) idx = 0;
      else idx++;
      
      if (idx >= (**gdh).numGroups) return err_NoMoreResults;
      qr->result_idx = idx;
      qr->qid = qs->qid;
      //copy the data into the buffer
      gr = GET_GROUP_DATA(gdh,idx);
      if (!gr->u.empty) empty = FALSE; //don't output empty results
    } while (empty);

    COPY_GROUP_DATA(gdh,idx,qr->d.data);
	gr = (GroupRecord *)qr->d.data;
    gr->u.exprIdx = e->idx;

  } else
    return err_InvalidAggregateRecord;

  return err_NoError;
}

//Given a tuple built locally, add the result into the locally computed
//value for the query
TinyDBError TOS_COMMAND(AGG_OPERATOR_PROCESS_TUPLE)(ParsedQuery *qs, Tuple *t, Expr *e) {
 
  VAR(curExpr) = e;
  VAR(curQuery) = qs;
  VAR(curTuple) = t;
  printf ("in PROCESS_TUPLE, expr = %x\n", (unsigned int)VAR(curExpr));//fflush(stdout);
  getGroupData(qs, getGroupNo(t,qs,e) , e, &updateGroupForTuple);
  return err_NoError;
}


//reset the value of the aggregates stored in a particular
//expression
void TOS_COMMAND(AGG_RESET_EXPR_STATE)(ParsedQuery *q, Expr *e) {
  GroupDataHandle gdh = (GroupDataHandle)e->opState;
  GroupRecord *gr;

  if (e->isAgg && gdh != NULL) {
    short i;
    for (i = 0; i < (**gdh).numGroups; i++) {
      gr = GET_GROUP_DATA(gdh,i);
      initAggregateValue(gr, e);
    }
    
  }
}

// finished a query
void TOS_EVENT(AGG_FINISHED_QUERY)(ParsedQuery *q) {
  short i;
  
  for (i = 0; i < q->numExprs; i++) {
    Expr *e = &PQ_GET_EXPR(q, i);
    if (e->isAgg && (e->opState !=  NULL)) {
      TOS_CALL_COMMAND(AGG_FREE)((char **)e->opState);
    }
  } 
}


//callback from getGroupData for PROCESS_TUPLE
//given the location of the aggregate record
//for the new tuple, update it
void updateGroupForTuple(GroupRecord *d) {
  Tuple *t = VAR(curTuple);
  Expr *e = VAR(curExpr);
  ParsedQuery *q = VAR(curQuery);
  char *fieldBytes = TOS_CALL_COMMAND(AGG_OP_GET_FIELD_PTR)(q, t, (char)e->ex.agg.field);
  short size = TOS_CALL_COMMAND(AGG_OP_GET_FIELD_SIZE)(q, (char)e->ex.agg.field);
  short fieldVal = 0;
  short i;

  for (i = 0; i < size; i++) {
    unsigned char b = (*fieldBytes++);
    fieldVal += ((unsigned short)b)<<(i*8);    
  }
  
  updateAggregateValue(d,e,fieldVal);
  TOS_SIGNAL_EVENT(AGG_OPERATOR_PROCESSED_TUPLE)(t, q, VAR(curExpr));
}


//allocate is used to create the operator state (which stores all the group
//records) the first time a value is stored
void TOS_EVENT(AGG_ALLOC_DONE)(char ***h, char success) {
  GroupDataHandle dh = (GroupDataHandle)*h;
  GroupRecord *newGroup;

  if (h != (char ***)VAR(alloced)) return; //not for us
  if (!success) {
    printf ("Error! Couldn't allocate aggregate data!");
    signalError(err_OutOfMemory);
  }
  printf ("in AGG_ALLOC_DONE, expr = %x\n", (unsigned int)VAR(curExpr));//fflush(stdout);
  (**dh).groupSize = groupSize(VAR(curExpr));
  (**dh).numGroups = 0;
  newGroup = addGroup(dh, VAR(curGroup));
  initAggregateValue(newGroup, VAR(curExpr));
  (*VAR(callback))(newGroup);
}


//reallocate is used when a new group is allocated in the existing operator
//state
void TOS_EVENT(AGG_REALLOC_DONE)(char **h, char success) {
  GroupRecord *newGroup;

  
  if (h != (char **)VAR(alloced)) return; //not for us
  if (!success) {
    if (!removeEmptyGroup((GroupDataHandle)h)) { //check for empty groups -- if there are any, reuse them      
      //maybe try to evict -- may be not possible
      printf ("Error! Couldn't reallocate aggregate data!");
      signalError(err_OutOfMemory);
    }
  }

  //  TOS_CALL_COMMAND(AGG_DEBUG_MEMORY)();
      
  newGroup = addGroup((GroupDataHandle)h, VAR(curGroup));
  initAggregateValue(newGroup, VAR(curExpr));
  (*VAR(callback))(newGroup);
}

//binary search to locate the group record for the specified
//group num
GroupRecord *findGroup(GroupDataHandle dh, short groupNum) {
  short min = 0, max = (**dh).numGroups;
  GroupRecord *gr;

  if (max == 0) return NULL; // no groups
  while (TRUE) {
    gr = GET_GROUP_DATA(dh, min);
    if (gr->groupNo == groupNum) return gr;

    if (max == (min + 1)) break;  

    if (gr->groupNo > groupNum) 
      max = max - ((max - min)  >> 1);
    else
      min = min + ((max - min) >> 1);
  }
  return NULL;
}

//scan the list of groups and remove one that is empty
//return true if successful, false if there are no
//emtpy groups
bool removeEmptyGroup(GroupDataHandle dh) {
  short i, lastEmpty;
  bool found = FALSE;
  GroupRecord *gr;

  //scan backwards, looking for an empty group
  for (lastEmpty = (**dh).numGroups - 1; lastEmpty >= 0; lastEmpty--) {
    gr = GET_GROUP_DATA(dh,lastEmpty);
    if (gr->u.empty) {
      found = TRUE;
      break;
    }
  }

  if (!found) return FALSE;
  printf ("found empty = %d\n", lastEmpty);
  //now shift everything after that group up one
  for (i = lastEmpty + 1; i < (**dh).numGroups; i++) {
    gr = GET_GROUP_DATA(dh,i);
    SET_GROUP_DATA(dh,i-1,&gr);
  }

  (**dh).numGroups--;

  return TRUE;
}

//add a group to a group data handle that has been realloced to be big enough to hold
//the group record (we assume the new space is at the end of the data block)
GroupRecord *addGroup(GroupDataHandle dh, short groupNum) {
  short i;
  bool shift = FALSE, first = FALSE;
  GroupRecord *gr,lastgr,newgr,tempgr,*ret=NULL;
  
  newgr.groupNo = groupNum;

  //do a simple insertion sort
  (**dh).numGroups++;
  
  for (i = 0; i < (**dh).numGroups; i++) {

    gr = GET_GROUP_DATA(dh,i);

    //did we find the place to insert?
    if ((!shift && gr->groupNo > groupNum) || (i+1 == (**dh).numGroups)) {
      lastgr = newgr; //yup
      shift = TRUE;
      first=TRUE;
    }
    
    if (shift) {  //have we already inserted?
      tempgr = *gr;  //move up the current record
      SET_GROUP_DATA(dh,i,&lastgr);
      lastgr = tempgr;
      if (first) {
	first=FALSE;
	ret = GET_GROUP_DATA(dh,i);
      }
    }
      
  }
  if (ret == NULL) {
    printf("ERROR: Retval is NULL on addGroup!\n");//fflush(stdout);
  }
  return ret;
}

//locate or allocate the group data for the group that t should update,
//and invoke the callback with that data.
void getGroupData(ParsedQuery *pq, short groupNo , Expr *e, GroupDataCallback callback) {
  GroupDataHandle dh = (GroupDataHandle)e->opState;

  VAR(callback) = callback;
  
  VAR(curExpr) = e;
  VAR(curQuery) = pq;
  VAR(curGroup) = groupNo;
  
  if (dh == NULL) {
    //we've got to allocate this baby
    VAR(alloced) = (Handle) &e->opState; //ick
    TOS_CALL_COMMAND(AGG_ALLOC)(&e->opState, groupSize(e) + sizeof(GroupData));
  } else {
    GroupRecord *gr;

    //scan through it, looking to see if the needed group is there
    gr = findGroup(dh, groupNo);
    VAR(groupRecord) = gr;
    //decouple so that we don't immediately return (yuck yuck!)
    if (gr != NULL) (*(callback))(gr); //TOS_POST_TASK(fireCallback); 
    else {
      //group doesn't exist -- must realloc and continue
      VAR(alloced) = e->opState;
      //TOS_CALL_COMMAND(AGG_DEBUG_MEMORY)();
      if (TOS_CALL_COMMAND(AGG_REALLOC)(e->opState, groupSize(e) * ((**dh).numGroups + 1) + sizeof(GroupData)) == 0) //failure
	{
	  TOS_SIGNAL_EVENT(AGG_REALLOC_DONE)(e->opState, FALSE);
	}
      
    }
  }

}

TOS_TASK(fireCallback) {
  (*VAR(callback))(VAR(groupRecord));
}

short getGroupNo(Tuple *t, ParsedQuery *q, Expr *e) {
  char *fieldBytes;
  short size;
  short fieldVal = 0;
  short i;
  if (e->ex.agg.groupingField == (short)kNO_GROUPING_FIELD) return 0; //we're not using a group!

  fieldBytes = TOS_CALL_COMMAND(AGG_OP_GET_FIELD_PTR)(q, t, (char)e->ex.agg.groupingField);
  size = TOS_CALL_COMMAND(AGG_OP_GET_FIELD_SIZE)(q, (char)e->ex.agg.groupingField);


  for (i = 0; i < size; i++) {
    unsigned char b = (*fieldBytes++);
    fieldVal += ((unsigned short)b)<<(i*8);    
  }

  return ((fieldVal) >> e->ex.agg.attenuation); //group number is attenuated by some number of bits
}



/* ------------------------------------- Aggregation Operator Specific Commands ------------------------------------------- */

/* Return the amount of storage required for an aggregate of the specified group
   Note that this will not generalize to support variable size (e.g. holistic aggregates)
*/
short groupSize(Expr *e) {
  GroupRecord g;
  short base = sizeof(g) - sizeof(g.d);
  switch (e->ex.agg.op) {
  case SUM:
  case MIN:
  case MAX:
  case COUNT:
    return base + sizeof(AlgebraicData);
    break;
  case AVERAGE:
    return base + sizeof(AverageData);
    break;
  case MIN3:
    return base + sizeof(Min3Data);
  }
  return 0;
}

/* Given two aggregate records, merge them together into dest. */
void mergeAggregateValues(GroupRecord *dest, GroupRecord *merge, Expr *e) {
  short i,j, k;

  dest->u.empty = FALSE;
  switch (e->ex.agg.op) {
  case SUM:
    dest->d.algd.value += merge->d.algd.value;
    break;
  case MIN:
    if (dest->d.algd.value > merge->d.algd.value) {
      dest->d.algd.value = merge->d.algd.value;
      dest->d.algd.id = merge->d.algd.id;
    }
    break;
  case MAX:
    if (dest->d.algd.value < merge->d.algd.value) {
      dest->d.algd.value = merge->d.algd.value;
      dest->d.algd.id = merge->d.algd.id;
    }
    break;
  case COUNT:
    dest->d.algd.value += merge->d.algd.value;
    break;
  case AVERAGE:
    dest->d.avgd.sum += merge->d.avgd.sum;
    dest->d.avgd.count += merge->d.avgd.count;
    break;
  case MIN3:
    i = 0; j = 0;
   //loop through dest, filling in 3 slots with
    //top three values from merge or dest
    while (i < 3) {
      if (dest->d.min3d.mins[i] > merge->d.min3d.mins[j]) {
	//shift up dest
	for (k = i+1; k < 3; k++) {
	  dest->d.min3d.mins[k] = dest->d.min3d.mins[k-1];
	  dest->d.min3d.ids[k] = dest->d.min3d.ids[k-1];
	}
	//copy top el of merge into top of dest
	dest->d.min3d.mins[i] = merge->d.min3d.mins[j];
	dest->d.min3d.ids[i] = merge->d.min3d.ids[j];
	j++; //move to next el of merge
      } //otherwise, top of dest is min
      i++; //always move to next el of dest
    }
    break;
  }
}

/* Given an aggregate value and a group, merge the value into the group */

void updateAggregateValue(GroupRecord *d, Expr *e, short fieldValue) {
  short i, j;

  d->u.empty = FALSE;
  switch (e->ex.agg.op) {
  case SUM:
    d->d.algd.value += fieldValue;
    break;
  case MIN:
    if (d->d.algd.value > fieldValue) {
      d->d.algd.value = fieldValue;
      d->d.algd.id = TOS_LOCAL_ADDRESS;
    }
    break;
  case MAX:
    if (d->d.algd.value < fieldValue) {
      d->d.algd.value = fieldValue;
      d->d.algd.id = TOS_LOCAL_ADDRESS;
    }
    break;
  case COUNT:
    d->d.algd.value++;
    break;
  case AVERAGE:
    d->d.avgd.sum += fieldValue;
    d->d.avgd.count ++;
    break;
  case MIN3:
    for (i = 0; i < 3; i++) {
      if (d->d.min3d.mins[i] > fieldValue) {

	//shift up
	for (j = i+1; j < 3; j++) {
	  d->d.min3d.mins[j] = d->d.min3d.mins[j-1];
	  d->d.min3d.ids[j] = d->d.min3d.ids[j-1];
	}
	d->d.min3d.mins[i] = fieldValue;
	d->d.min3d.ids[i] = TOS_LOCAL_ADDRESS;
	break; //once it's inserted, quit!
      }
    }
    break;
  }
}


/* Initialize the value of the specified aggregate value. */

void initAggregateValue(GroupRecord *d, Expr *e) {
  short i;
  d->u.empty = TRUE;
  switch (e->ex.agg.op) {
  case SUM:
    d->d.algd.value = 0;
    break;
  case MIN:
    d->d.algd.value = kMAX_SHORT;
    d->d.algd.id = TOS_LOCAL_ADDRESS;
    break;
  case MAX:
    d->d.algd.value = kMIN_SHORT;
    d->d.algd.id = TOS_LOCAL_ADDRESS;
    break;
  case COUNT:
    d->d.algd.value = 0;
    break;
  case AVERAGE:
    d->d.avgd.sum = 0;
    d->d.avgd.count = 0;
    break;
  case MIN3:
    for (i = 0; i < 3; i++) {
      d->d.min3d.ids[i] = -1;
      d->d.min3d.mins[i] = kMAX_SHORT;
    }
    break;
  }
    
}
