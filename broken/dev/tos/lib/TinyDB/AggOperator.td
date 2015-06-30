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
/*
 * Authors:	Sam Madden
 *              Design by Sam Madden, Wei Hong, and Joe Hellerstein
 * Date last modified:  6/26/02
 *
 *
 */

module AggOperator {
  provides {
    interface Operator;
    command TinyDBError addResults(QueryResult *qr, ParsedQuery *q, Expr *e);
    command TinyDBError finalizeAggExpr(QueryResult *qr, ParsedQueryPtr q, Expr *e, char *result_buf);
    command short getGroupNoFromQr(QueryResult *qr);
  }

  uses {
    interface MemAlloc;
    interface QueryProcessor;
    interface TupleIntf;
    interface ParsedQueryIntf;
    interface ExprEval;
    interface Leds;
    interface QueryResultIntf;
    
    command void signalError(TinyDBError err);    
  }
}




implementation {

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

  GroupDataCallback mCallback;
  ParsedQuery *mCurQuery;
  Expr *mCurExpr;
  QueryResult *mCurResult;
  Tuple *mCurTuple;
  short mCurGroup;
  Handle mAlloced;
  GroupRecord *mGroupRecord;

  enum {
    kMAX_SHORT = 0x7FFF,
    kMIN_SHORT = 0x8000
  };


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
  bool aggEqual(GroupRecord *r1, GroupRecord *r2, Expr *e);
  bool aggHasData(QueryResult *qr, ParsedQueryPtr q, Expr *e);

  task void fireCallback();

/* -------------------------------- Local Routines for getting / setting group records  -------------------------------- */

  GroupRecord *GET_GROUP_DATA(GroupDataHandle dHan,uint8_t n) {
    return (GroupRecord *)&((**dHan).groupData[(n) * (**dHan).groupSize]);
  }

  void SET_GROUP_DATA(GroupDataHandle dHan,uint8_t n,char *dataptr) {
    memcpy(GET_GROUP_DATA(dHan,n), (const char *)(dataptr), (**dHan).groupSize);
  }
  
  void COPY_GROUP_DATA(GroupDataHandle dHan,uint8_t n,char *dest) {
    memcpy((char *)(dest),(const char *)GET_GROUP_DATA(dHan,n), (**dHan).groupSize);
  }


  /* -------------------------------- Functions -------------------------------- */



    /* Reset the state that this operator stores for the specified expression 
       (Called every epoch)
       Operator state is appended to the expression (ick!) , in the opState handle --
         each expression is owned by exactly one operator, which may store state there.
    */ 



    //Given a query-result from a different node, add the result into 
    //the locally computed value for the query.  The locally computed
    //value is stored with the expression.
    command TinyDBError Operator.processPartialResult(QueryResultPtr qr, ParsedQueryPtr qs, ExprPtr e) {
      GroupRecord *gr = (GroupRecord *)qr->d.data;
      
      if (qr->qrType != kAGG_SINGLE_FIELD) return err_InvalidAggregateRecord;

      if (gr->u.exprIdx != e->idx) 
	return err_InvalidAggregateRecord; //not for us

      mCurExpr = e;
      mCurQuery = qs;
      mCurResult = qr;
      
      getGroupData(qs,gr->groupNo, e, &updateGroupForPartialResult);
      return err_NoError;
    }

    //check and see if this result represents the evaluation of this expression
    command bool Operator.resultIsForExpr(QueryResultPtr qr, ExprPtr e) {
      GroupRecord *gr = (GroupRecord *)qr->d.data;
      if (qr->qrType != kAGG_SINGLE_FIELD) return FALSE;
      if (gr->u.exprIdx != e->idx) return FALSE;
      return TRUE;
    }

    
  void updateGroupForPartialResult(GroupRecord *d) {
    GroupRecord *gr = (GroupRecord *)((QueryResult *)mCurResult)->d.data;

    mergeAggregateValues(d,gr,mCurExpr);
    signal Operator.processedResult(mCurResult, mCurQuery, mCurExpr);
  }

  
  
  /* Return the next result to this query.
    
    If there are no more results, return err_NoMoreResults
    
    qr->result_idx should be set to kFIRST_RESULT if the first result is desired,
    or to the previous value of qr->result_idx returned by the last invocation
    of AGG_OPERATOR_NEXT_RESULT
    
  */
  command TinyDBError Operator.nextResult(QueryResultPtr qr, ParsedQueryPtr qs, ExprPtr e) {
    GroupDataHandle gdh = (GroupDataHandle)e->opState;
    bool empty = TRUE;
    GroupRecord *gr;

    if (!aggHasData(qr,qs,e)) return err_NoMoreResults;

    if (gdh != NULL) {
      short idx = qr->result_idx;
    
      do {  //loop til we find the next non-empty group

	if (idx == kFIRST_RESULT) idx = 0;
	else idx++;
      
	if (idx >= (**gdh).numGroups) return err_NoMoreResults;
	qr->result_idx = idx;
	qr->qid = qs->qid;
	//just a single field result
	qr->qrType = kAGG_SINGLE_FIELD;
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

  /** Install all of the results for the last epoch of  expression e from pq into qr.
   */
  command TinyDBError addResults(QueryResult *qr, ParsedQuery *pq, ExprPtr e) {
    int i = 0;
    GroupRecord *gr;
    GroupDataHandle gdh = (GroupDataHandle)e->opState;
    TinyDBError err;

    if (gdh == NULL) return err_NoError;
    if (!aggHasData(qr,pq,e)) return err_NoError;


    for (i = 0; i < (**gdh).numGroups; i++) {

      gr = GET_GROUP_DATA(gdh, i);
      if (!gr->u.empty) {
	err = call QueryResultIntf.addAggResult(qr, gr->groupNo, (char *)gr, (**gdh).groupSize, pq, e->idx); 

	if (err != err_NoError) {
	  return err;
	}
	gr->u.exprIdx = e->idx;
      }

    }

    return err_NoError;

  }

  //Given a tuple built locally, add the result into the locally computed
  //value for the query
  command TinyDBError Operator.processTuple(ParsedQueryPtr qs, TuplePtr t, ExprPtr e) {
    mCurExpr = e;
    mCurQuery = qs;
    mCurTuple = t;
    dbg(DBG_USR1,"in PROCESS_TUPLE, expr = %x\n", (unsigned int)mCurExpr);//fflush(stdout);
    getGroupData(qs, getGroupNo(t,qs,e) , e, &updateGroupForTuple);
    return err_NoError;
  }


  //epoch ended -- give aggregates a chance to reset themselves,
  //if needed (some aggregates, like windowed and exponentially
  //decaying averages won't reset on every epoch.)
  command result_t Operator.endOfEpoch(ParsedQueryPtr q, ExprPtr e) {
    GroupDataHandle gdh = (GroupDataHandle)e->opState;
    GroupRecord *gr;

    if (e->opType != kSEL && gdh != NULL) {
      short i;
      for (i = 0; i < (**gdh).numGroups; i++) {
	gr = GET_GROUP_DATA(gdh,i);
	initAggregateValue(gr, e);
      }
    
    }

    return SUCCESS;
  }

  // finished a query
  event result_t QueryProcessor.queryComplete(ParsedQuery *q) {
    short i;
  
    for (i = 0; i < q->numExprs; i++) {
      Expr e = (call ParsedQueryIntf.getExpr(q, i));
      if (e.opType != kSEL && (e.opState !=  NULL)) {
	call MemAlloc.free((Handle)e.opState);
      }
    } 
    return SUCCESS;
  }


  //callback from getGroupData for PROCESS_TUPLE
  //given the location of the aggregate record
  //for the new tuple, update it
  void updateGroupForTuple(GroupRecord *d) {
    Tuple *t = mCurTuple;
    Expr *e = mCurExpr;
    ParsedQuery *q = mCurQuery;
    char *fieldBytes = call TupleIntf.getFieldPtr(q, t, (char)e->ex.agg.field);
    short size = call TupleIntf.fieldSize(q, (char)e->ex.agg.field);
    short fieldVal = 0;
    short i;

    for (i = 0; i < size; i++) {
      unsigned char b = (*fieldBytes++);
      fieldVal += ((unsigned short)b)<<(i*8);    
    }
  
    updateAggregateValue(d,e,fieldVal);

    signal Operator.processedTuple(t, q, mCurExpr,TRUE);    
  }


  //allocate is used to create the operator state (which stores all the group
  //records) the first time a value is stored
  event result_t MemAlloc.allocComplete(HandlePtr h, uint8_t success) {
    GroupDataHandle dh = (GroupDataHandle)*h;
    GroupRecord *newGroup;

    if (h != (Handle *)mAlloced) return SUCCESS; //not for us
    if (!success) {
      dbg(DBG_USR1,"Error! Couldn't allocate aggregate data!");
      call signalError(err_OutOfMemory);
    }
    dbg(DBG_USR1,"in AGG_ALLOC_DONE, expr = %x\n", (unsigned int)mCurExpr);//fflush(stdout);
    (**dh).groupSize = groupSize(mCurExpr);
    (**dh).numGroups = 0;
    newGroup = addGroup(dh, mCurGroup);
    initAggregateValue(newGroup, mCurExpr);
    (*mCallback)(newGroup);
    return SUCCESS;
  }


  //reallocate is used when a new group is allocated in the existing operator
  //state
  event result_t MemAlloc.reallocComplete(Handle h, uint8_t success) {
    GroupRecord *newGroup;

  
    if (h != (Handle)mAlloced) return SUCCESS; //not for us
    if (!success) {
      if (!removeEmptyGroup((GroupDataHandle)h)) { //check for empty groups -- if there are any, reuse them      
	//maybe try to evict -- may be not possible
	dbg(DBG_USR1,"Error! Couldn't reallocate aggregate data!");
	call signalError(err_OutOfMemory);
      }
    }


    newGroup = addGroup((GroupDataHandle)h, mCurGroup);
    initAggregateValue(newGroup, mCurExpr);
    (*mCallback)(newGroup);
    return SUCCESS;
  }

  event result_t MemAlloc.compactComplete() {
    return SUCCESS;
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
    dbg(DBG_USR1,"found empty = %d\n", lastEmpty);
    //now shift everything after that group up one
    for (i = lastEmpty + 1; i < (**dh).numGroups; i++) {
      gr = GET_GROUP_DATA(dh,i);
      SET_GROUP_DATA(dh,i-1,(char *)&gr);
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
	SET_GROUP_DATA(dh,i,(char *)&lastgr);
	lastgr = tempgr;
	if (first) {
	  first=FALSE;
	  ret = GET_GROUP_DATA(dh,i);
	}
      }
      
    }
    if (ret == NULL) {
      dbg(DBG_USR1,"ERROR: Retval is NULL on addGroup!\n");//fflush(stdout);
    }
    return ret;
  }

  //locate or allocate the group data for the group that t should update,
  //and invoke the callback with that data.
  void getGroupData(ParsedQuery *pq, short groupNo , Expr *e, GroupDataCallback callback) {
    GroupDataHandle dh = (GroupDataHandle)e->opState;

    mCallback = callback;
  
    mCurExpr = e;
    mCurQuery = pq;
    mCurGroup = groupNo;
  
    if (dh == NULL) {
      //we've got to allocate this baby
      mAlloced = (Handle) &e->opState; //ick
      call MemAlloc.allocate((HandlePtr)&e->opState, groupSize(e) + sizeof(GroupData));
    } else {
      GroupRecord *gr;

      //scan through it, looking to see if the needed group is there
      gr = findGroup(dh, groupNo);
      mGroupRecord = gr;
      //decouple so that we don't immediately return (yuck yuck!)
      if (gr != NULL) (*(callback))(gr);
      else {
	//group doesn't exist -- must realloc and continue
	mAlloced = (Handle) e->opState;
	
	if (call MemAlloc.reallocate((Handle)e->opState, groupSize(e) * ((**dh).numGroups + 1) + sizeof(GroupData)) == FAIL) //failure
	  {
	    signal MemAlloc.reallocComplete((Handle)e->opState, FALSE);
	  }
      
      }
    }

  }

    task void fireCallback() {
      (*mCallback)(mGroupRecord);
    }

  short getGroupNo(Tuple *t, ParsedQuery *q, Expr *e) {
    char *fieldBytes;
    short size;
    short fieldVal = 0;
    short i;
    if (e->ex.agg.groupingField == (short)kNO_GROUPING_FIELD) return 0; //we're not using a group!

    
    fieldBytes = call TupleIntf.getFieldPtr(q, t, (char)e->ex.agg.groupingField);
    size = call TupleIntf.fieldSize(q, (char)e->ex.agg.groupingField);


    for (i = 0; i < size; i++) {
      unsigned char b = (*fieldBytes++);
      fieldVal += ((unsigned short)b)<<(i*8);    
    }

    return (call ExprEval.evaluateGroupBy(e->ex.agg, fieldVal));
    //(fieldVal) >> e->ex.agg.attenuation); //group number is attenuated by some number of bits
  }

  //compare two aggregate records, determine if they are equal
  bool aggEqual(GroupRecord *r1, GroupRecord *r2, Expr *e) {
    short size = groupSize(e);
    char *b1 = (char *)&r1->d;
    char *b2 = (char *)&r2->d;

    while (size--) 
      if (*b1++ != *b2++) return FALSE;

    return TRUE;
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
    case EXP_AVG:
    case WIN_MIN:
    case WIN_MAX:
    case WIN_SUM:
    case WIN_CNT:
      return base + sizeof(AlgebraicData);
      break;
    case WIN_AVG:
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
    case WIN_SUM:
      dest->d.algd.value += merge->d.algd.value;
      break;
    case MIN:
    case WIN_MIN:
      if (dest->d.algd.value > merge->d.algd.value) {
	dest->d.algd.value = merge->d.algd.value;
	dest->d.algd.id = merge->d.algd.id;
      }
      break;
    case MAX:
    case WIN_MAX:
      if (dest->d.algd.value < merge->d.algd.value) {
	dest->d.algd.value = merge->d.algd.value;
	dest->d.algd.id = merge->d.algd.id;
      }
      break;
    case COUNT:
    case WIN_CNT:
      dest->d.algd.value += merge->d.algd.value;
      break;
    case WIN_AVG:
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
    case EXP_AVG: 
      {
	uint8_t newBits = 16 - e->ex.tagg.u.newBitsPerSample;
	dest->d.algd.value = (dest->d.algd.value - (dest->d.algd.value >> newBits)) + (merge->d.algd.value >> newBits);
	break;
      }
    }
  }

  /* Given an aggregate value and a group, merge the value into the group */

  void updateAggregateValue(GroupRecord *d, Expr *e, short fieldValue) {
    short i, j;
    
    fieldValue = call ExprEval.evaluate(e, fieldValue);
    //fieldValue /= 10;

    d->u.empty = FALSE;
    switch (e->ex.agg.op) {
    case SUM:
    case WIN_SUM:
      d->d.algd.value += fieldValue;
      break;
    case MIN:
    case WIN_MIN:
      if (d->d.algd.value > fieldValue) {
	d->d.algd.value = fieldValue;
	d->d.algd.id = TOS_LOCAL_ADDRESS;
      }
      break;
    case MAX:
    case WIN_MAX:
      if (d->d.algd.value < fieldValue) {
	d->d.algd.value = fieldValue;
	d->d.algd.id = TOS_LOCAL_ADDRESS;
      }
      break;
    case COUNT:
    case WIN_CNT:
      d->d.algd.value++;
      break;
    case AVERAGE:
    case WIN_AVG:
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
    case EXP_AVG: 
      {
	uint8_t newBits = 16 - e->ex.tagg.u.newBitsPerSample;
	d->d.algd.value = (d->d.algd.value - (d->d.algd.value >> newBits)) + (fieldValue >> newBits);
	break;
      }
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
	d->d.min3d.ids[i] =  -1;
	d->d.min3d.mins[i] = kMAX_SHORT;
      }
      break;
    case EXP_AVG:
      //don't do anything (never reset value!)
      break;
    case WIN_MIN:
      if (e->ex.tagg.epochsLeft == 0) {
	d->d.algd.value = kMAX_SHORT;
	e->ex.tagg.epochsLeft = e->ex.tagg.u.epochsPerWindow;
      } else
	e->ex.tagg.epochsLeft--;
      break;

      break;

    case WIN_MAX:
      if (e->ex.tagg.epochsLeft == 0) {
	d->d.algd.value = kMIN_SHORT;
	e->ex.tagg.epochsLeft = e->ex.tagg.u.epochsPerWindow;
      } else
	e->ex.tagg.epochsLeft--;

      break;
    case WIN_SUM:
    case WIN_CNT:

      if (e->ex.tagg.epochsLeft == 0) {
	d->d.algd.value = 0;
	e->ex.tagg.epochsLeft = e->ex.tagg.u.epochsPerWindow;
      } else
	e->ex.tagg.epochsLeft--;
      break;

    case WIN_AVG:
      if (e->ex.tagg.epochsLeft == 0) {
	d->d.avgd.sum = 0;
	d->d.avgd.count = 0;
	e->ex.tagg.epochsLeft = e->ex.tagg.u.epochsPerWindow;
      } else
	e->ex.tagg.epochsLeft--;
      break;
    }
    
  }
  

  /* Return true if this aggregate has data ready right now
     -- some aggregates, such as windowed averages, only
     produce data at the end of several epochs.
  */
  bool aggHasData(QueryResult *qr, ParsedQueryPtr q, Expr *e) {
    switch (e->ex.agg.op) {
    case WIN_MIN: case WIN_MAX: case WIN_SUM: case WIN_CNT: case WIN_AVG:
      if (e->ex.tagg.epochsLeft == 0 || TOS_LOCAL_ADDRESS == 0)
	return TRUE;
      else 
	return FALSE;
      break;
    default:
      return TRUE;
    }
  }

  /** @return The group number from this query result */
  command short getGroupNoFromQr(QueryResult *qr) {
    GroupRecord *gr = (GroupRecord *)qr->d.data;
    
    return gr->groupNo;
  }

  command TinyDBError finalizeAggExpr(QueryResult *qr, ParsedQueryPtr q, Expr *e, char *result_buf) {
    GroupRecord *gr = (GroupRecord *)qr->d.data;

    switch (e->ex.agg.op) {

    case SUM:
    case MIN:
    case MAX:
    case COUNT:
    case EXP_AVG:
    case WIN_MIN: case WIN_MAX: case WIN_SUM: case WIN_CNT:
      *(short *)result_buf = gr->d.algd.value;
      break;
    case AVERAGE:
    case WIN_AVG:
      if (gr->d.avgd.count == 0)
	*(short *)result_buf = 0;
      else
	*(short *)result_buf = gr->d.avgd.sum / gr->d.avgd.count;
      break;
    case MIN3:
      break;
    }
    return err_NoError;
  }



}

    
