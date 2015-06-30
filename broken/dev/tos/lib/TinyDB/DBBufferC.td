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
module DBBufferC {
  uses {
    interface RadioQueue; //writes results out to a radio queue
    interface MemAlloc;
    interface QueryProcessor;
    interface Leds;
    interface CommandUse;
    interface QueryResultIntf;
    interface ParsedQueryIntf;
    interface TupleIntf;
    interface Interrupt;
    command void allocDebug();
  } 
  provides {
    interface DBBuffer;
    interface StdControl;
  }
}


/**

   DBBuffer is a output buffer abstraction for TinyDB.  
   Buffers can be one of several types:

   Radio:  Results are written directly out to the radio
   Command:  Each result causes a command to be invoked
   RAM:  Results are written to a RAM buffer
   EEPROM:  Results are written to EEPROM
   

   RAM and EEPROM buffers use a cicrular buffer, with nextFree and
   nextFull slots if nextFull slot is after nextFree slot, then used
   slots are from nextFull to the end of the buffer plus.  Otherwise,
   used slots are from nextFull to nextFree.

   To the outside world, buffer appears to have a number of used
   slots, with the first slot (0) beginning at nextFull.
	 		
       nextFull > nextFree       	       	   nextFull < nextFree
       +--------------------------+ top	           +--------------------------+ top
       |..........................|                |                          |	   
       |.....used slots...........|                |      free slots          |	   
       |..........................|                |                          |	   
       |..........................|                |                          |	   
       +--------------------------+ nextFree       +--------------------------+	nextFull
       |                          |                |..........................|		
       |                          |                |..........................|                        	
       |                          |                |..........................|		
       |      free slots          |                |.......used slots.........|		
       |                          |                |..........................|		
       |                          |                |..........................|		
       |                          |                |..........................|		
       +--------------------------+ nextFull       +--------------------------+ nextFree
       |..........................|                |                          |	       	
       |.....used slots...........|                |                          |
       |..........................|                |       free slots         |
       |..........................|                |                          |
       +--------------------------+                +--------------------------+

*/

implementation {
  enum {
    kNUM_BUFS = 8
  };

  typedef enum {
    kIDLE,
    kALLOC_SCHEMA,
    kALLOC_BUFFER,
    kALLOC_ROW,
    kREAD_ROW
 } AllocState;

  typedef struct {
    BufferType type;
    BufferPolicy policy;
    ParsedQuery **qh; //schema of buffer (rest of query fields ignored)
    uint16_t numRows; //number of rows in buffer
    uint16_t nextFree; //next free row
    uint16_t nextFull; //next full row (top of queue)

    uint16_t len; //length, in bytes, of buffers
    uint16_t rowSize; //length, in bytes, of one row

    long data;

    union {
      char **bufdata; //data handle for RAM buffers
      uint16_t offset; //offset into EEPROM for start of buffer
    } u;
  } Buffer;

  Buffer mBuffers[kNUM_BUFS];
  long mUsedBufs;
  uint8_t mCurBuffer;
  uint16_t mCurRow;
  Handle mCurRowHandle;
  QueryResultPtr mCurResult;
  ParsedQuery *mAllocSchema;
  AllocState mState;
  
  TinyDBError calcNextFreeRow(Buffer *buf);
  TinyDBError getBuf(uint8_t bufId, Buffer **buf);
#if defined(PLATFORM_PC)
#define kDEBUG
#endif
#ifdef kDEBUG
  ParsedQueryPtr mQueryPtr;
  QueryResult mQr;
  short mInt;
  char tupleBuf[50];
  char queryBuf[100];
  char aggResult[7];
#endif

  

  
  /* ----------------------------------- StdControl Methods ------------------------------------- */

  command result_t StdControl.init() {
    mUsedBufs = 1; //clear free bitmap -- can't use first buffer -- it's for the radio!
    mState = kIDLE;
#ifdef kDEBUG
    mInt = 0;
#endif
    return SUCCESS;
  }

  command result_t StdControl.start() {
#ifdef kDEBUG
    BufInfo buf;
    bool pending;
    TinyDBError err;
    Expr e;

    mQueryPtr = (ParsedQueryPtr)queryBuf;

    dbg(DBG_USR2, "start"); fflush(stdout);

    mQueryPtr->qid = 0;
    mQueryPtr->numFields = 1;
    mQueryPtr->numExprs = 1;
    mQueryPtr->epochDuration = 1024;
    mQueryPtr->clocksPerSample = 1024/32;
    mQueryPtr->clockCount = mQueryPtr->clocksPerSample;
    mQueryPtr->currentEpoch = 0;
    mQueryPtr->fromQid = kNO_QUERY;
    mQueryPtr->bufferType = kRAM;
    mQueryPtr->queryToSchemaFieldMap[0] = 1; //some field in the schema?
    memset(aggResult, 0, 7);
    aggResult[4]=10;
    aggResult[5]=10;
    aggResult[6]=10;
    
    e.opType = kAGG;
    e.idx = 0;
    e.fieldOp = FOP_NOOP;
    e.fieldConst = 0;
    e.ex.agg.field = 0;
    e.ex.agg.groupingField = kNO_GROUPING_FIELD;
    e.ex.agg.groupFieldOp = FOP_NOOP;
    e.ex.agg.groupFieldConst = 0;
    e.ex.agg.op = MIN;

    call ParsedQueryIntf.setExpr(mQueryPtr, 0, e);
    err = call DBBuffer.nextUnusedBuffer(&mQueryPtr->bufferId);
    if (err != err_NoError)
      dbg(DBG_USR2, "err, nextUnusedBuf: %d", err);
    buf.ram.numRows = 2;
    buf.ram.policy = EvictOldestPolicy;
    
    mQueryPtr->buf = buf;

    err = call DBBuffer.alloc(mQueryPtr->bufferId, kRAM, buf.ram.numRows, buf.ram.policy,&mQueryPtr, &pending, 0);
    if (err != err_NoError)
      dbg(DBG_USR2, "err, DBBuffer.alloc: %d", err);
    
#endif
      return SUCCESS;
  }

  command result_t StdControl.stop() {
      return SUCCESS;
  }

#ifdef kDEBUG
  void enqueueResult() {
    bool pending;
    TinyDBError err;


    mInt++;

    dbg(DBG_USR2, "enqueuing"); fflush(stdout);

    err = call QueryResultIntf.initQueryResult(&mQr);
    if (err != err_NoError)
      dbg(DBG_USR2, "err, initQueryResult: %d", err);

    err = call QueryResultIntf.addAggResult(&mQr, 0, aggResult, 7, mQueryPtr, 0);
    if (err != err_NoError)
      dbg(DBG_USR2, "err, addAggResult: %d", err);

    err = call DBBuffer.enqueue(mQueryPtr->bufferId, &mQr, &pending, mQueryPtr);
    if (err != err_NoError)
      dbg(DBG_USR2, "err, enqueue: %d", err);


  }


  void readResult() {
    QueryResult qr;
    ParsedQuery *pq;
    TinyDBError err;
    short result;

    bool pending;
    Tuple *t;

    err = call DBBuffer.peek(mQueryPtr->bufferId, &qr, &pending);
    if (err != err_NoError)
      dbg(DBG_USR2, "error,peek: %d", err);
    err = call QueryResultIntf.toTuplePtr(&qr, mQueryPtr, &t);
    if (err != err_NoError)
      dbg(DBG_USR2, "error,toTuplePtr: %d", err);
    pq = *(call DBBuffer.getSchema(mQueryPtr->bufferId));

    dbg(DBG_USR2,"num fields = %d\n", pq->numFields);
    err = call ParsedQueryIntf.getResultField(pq, &qr, 0, (char *)&result);
    if (err != err_NoError)
      dbg(DBG_USR2, "error, %d", err);
    else
      dbg(DBG_USR2,"tuple.val = %d\n",result); fflush(stdout);
  }

#endif


  /* ----------------------------------- DBBuffer Methods ------------------------------------- */

  /** Enqueue a result into the specified buffer 
     Note that if pending returns true, this routine may store a reference to r (so it had better not be on the stack!)
   */
  command TinyDBError DBBuffer.enqueue(uint8_t bufferId, QueryResultPtr r, bool *pending, ParsedQuery *pq) {
    Buffer *buf;
    uint16_t row;
    TinyDBError err = err_NoError;
    Handle *bufList;

    *pending = FALSE;

    switch (bufferId) {
    case kRADIO_BUFFER: {
      int i;
      int numResults = call QueryResultIntf.numRecords(r, pq);
      QueryResult newqr;

      ResultTuple rtup;


      for (i = 0; i < numResults; i++) {
	rtup = call QueryResultIntf.getResultTuple(r, i, pq);
	if (rtup.error != err_NoError) return rtup.error;

	err = call QueryResultIntf.fromResultTuple(rtup, &newqr, pq);
	if (err != err_NoError) break;


	err = call RadioQueue.enqueue((char *)&newqr,kMSG_LEN - sizeof(DbMsgHdr));
      }

      return err;

    }
    default:
      err = getBuf(bufferId, &buf);
      if (err != err_NoError) return err;
      break;
    }

    switch (buf->type) {
    case kCOMMAND: 
      {
	//low byte of data should be command id!
	char *cmdStr = (char *)&buf->data;
	CommandDescPtr cmd = call CommandUse.getCommandById((uint8_t)(cmdStr[0]));


	if (cmd!=NULL) {
	  ParamVals params;
	  SchemaErrorNo schema_err;
	  char result[1];


	  switch (cmd->params.numParams) {
	  case 0:
	    params.numParams = 0;
	    break;
	  case 1:
	    //command buffer supports 1 integer (short) parameter
	    if (cmd->params.params[0] != INT16 &&
		cmd->params.params[0] != UINT16 &&
		cmd->params.params[0] != INT8 &&
		cmd->params.params[0] != UINT8)
	      return err_UnknownError;
	    params.numParams = 1;
	    params.paramDataPtr[0] = &cmdStr[1]; //2nd and 3rd bytes are command param
	    break;
	  default:
	    return err_InvalidIndex;
	    
	  }
	  call CommandUse.invoke(cmd->name, result, &schema_err, &params);
      }
    }
    break;
      
    case kRAM:
      //prev = call Interrupt.disable();    
      if (mState != kIDLE) {
	//if(prev) call Interrupt.enable();    
	return err_ResultBufferBusy;
      }
      mState = kALLOC_ROW;
      //if(prev) call Interrupt.enable();    


      row = buf->nextFree;
      err = calcNextFreeRow(buf);
      if (err != err_NoError) {
	mState = kIDLE;
	return err;
      }

      //need to allocate the buffer for this row
      mCurResult = r;
      mCurRow = row;
      mCurBuffer = bufferId;

      *pending = TRUE;

      bufList = (Handle *)(*buf->u.bufdata);

        if (bufList[row] != NULL) { 
	  //realloc'ing can be much more efficient than allocing all over again, 
	  //especially if the results are the same size (which should be the common case) 
	  mCurRowHandle = bufList[row];
	  if (call MemAlloc.reallocate(bufList[row], call QueryResultIntf.resultSize(r, pq)) != SUCCESS) { 
	    *pending = FALSE; 
	    mState = kIDLE; 
	    return err_OutOfMemory; 
	  } 
        } else { 
	  if (call MemAlloc.allocate(&mCurRowHandle, call QueryResultIntf.resultSize(r, pq)) != SUCCESS) {
	    *pending = FALSE;
	    mState = kIDLE;
	    return err_OutOfMemory;
	  }
	}

      break;
    default:
      return err_UnknownError;
    }

    return err_NoError;
  }

  /** 
     Remove the first element from the db buffer & deallocate it (don't return it.)
     Use peek() to retrieve the first element without deallocating, then call pop()
     when finished  (because peek returns a pointer into the buffer.)
  */
  command TinyDBError DBBuffer.pop(uint8_t bufferId) {
    Buffer *buf;
    Handle data;
    uint16_t row = buf->nextFull;
    Handle *bufList;

    getBuf(bufferId, &buf);
    bufList = (Handle *)(*buf->u.bufdata);
    data = bufList[row];
    if (data != NULL) {
      call MemAlloc.free(data);
      bufList[row] = NULL;
    }
    buf->nextFull++;
    if (buf->nextFull >= buf->numRows) buf->nextFull = 0;    
  }
    
  /** Copy the top most result in the buffer into buf
     @return err_NoMoreResults if no results are available
  */
  command TinyDBError DBBuffer.peek(uint8_t bufferId, QueryResult *qr, bool *pending) {
    Buffer *buf;
    TinyDBError err = getBuf(bufferId, &buf);
    uint16_t row;
    Handle *bufList;
    
    //bool prev = call Interrupt.disable();    
    if (mState != kIDLE) {
      //if (prev) call Interrupt.enable();
      return err_ResultBufferBusy;
    }
    mState = kREAD_ROW;
    //if (prev) call Interrupt.enable();

    *pending = FALSE;
    
    if (err != err_NoError) goto done;

    row= buf->nextFull;
    if (row == buf->nextFree && buf->numRows != 1) { //special case single row...
      err =  err_NoMoreResults;
      goto done;
    }

    switch(buf->type) {
    case kRAM:
      bufList = (Handle *)(*buf->u.bufdata);
      if (bufList[row] == NULL) {
	err =  err_NoMoreResults; 
	goto done;
      }
      call QueryResultIntf.fromBytes((char *)*bufList[row], qr, *buf->qh,0);
      //memcpy(qr, &(*buf->u.bufdata)[row*buf->rowSize],buf->rowSize);
      break;
    default:
      err = err_UnknownError;
    }

  done:
    mState = kIDLE;
    return err;
  }
  
  /** Copy the nth result in the buffer into buf
     @return err_NoMoreResults  if idx > getSize() or if buffer[idx] is empty (unset)
  */
  command TinyDBError DBBuffer.getResult(uint8_t bufferId, uint16_t idx, QueryResult *qr, bool *pending) {
    Buffer *buf;
    TinyDBError err = getBuf(bufferId, &buf);
    uint16_t size;
    uint16_t row;
    Handle *bufList;

    //bool prev = call Interrupt.disable();    
    if (mState != kIDLE) {
      //if (prev) call Interrupt.enable();
      return err_ResultBufferBusy;
    }
    mState = kREAD_ROW;
    //if (prev) call Interrupt.enable();

    *pending = FALSE;
    
    if (err != err_NoError) goto done;
    
    if (buf->nextFull == buf->nextFree && buf->numRows != 1) {
      err =  err_NoMoreResults;
      goto done;
    }
    call DBBuffer.size(bufferId, &size);
    if (idx >= size) {
      err = err_NoMoreResults;
      goto done;
    }
    
    //see comment at beginning of document for info on slot management & indexing
    if (buf->nextFull > buf->nextFree) {
      if (idx >= (buf->numRows - buf->nextFull)) {
	row = idx - (buf->numRows - buf->nextFull);
      } else
	row = buf->nextFull + idx;
    } else {
      row = buf->nextFull + idx;
    }

    bufList = (Handle *)(*buf->u.bufdata);
    call QueryResultIntf.fromBytes((char *)*bufList[row], qr, *buf->qh,0);
    //memcpy(qr, &(*buf->u.bufdata)[row*buf->rowSize], buf->rowSize);
    
  done:
    mState = kIDLE;
    return err;
  }

  /* Return the number of used rows in the buffer */
    command TinyDBError DBBuffer.size(uint8_t bufferId, uint16_t *size) {
      Buffer *buf;
      TinyDBError err = getBuf(bufferId, &buf);
      
      if (err != err_NoError) return err;
      
    //see comment at beginning of document for info on slot management & indexing
      if (buf->nextFull == buf->nextFree)
	*size = 0;
      else if (buf->nextFull > buf->nextFree) {
	*size = (buf->numRows - buf->nextFull) + buf->nextFree;
      } else {
	*size = buf->nextFree - buf->nextFull;
      }
      return err_NoError;
    }
  
    /** Allocate the buffer with the specified size 
	sizes is an array of sizes of each field, with one entry per field
	<p>
	Note that this may keep a reference to schema until after pending is complete.
	<p>
	Signals allocComplete when allocation is complete if *pending is true on return
	@param bufferId The buffer to allocate
	@param type The type of the buffer (see DBBuffer.h -- only kRAM and kRADIO are supported)
	@param size The size (in rows) of the buffer
	@param policy The eviction policy to use with the buffer (see DBBuffer.h)
	@param schema The schema (layout) of rows in this buffer (expressed as a query)
	@param pending On return, set to true if the buffer is still being allocated (expect allocComplete if
	               true).
	@param data is currently unused
	@return err_UnsupportedPolicy if the specified policy can't be applied
    */
  command TinyDBError DBBuffer.alloc(uint8_t bufferId, BufferType type, uint16_t size, BufferPolicy policy,
				     ParsedQuery *schema, bool *pending, long data) {
    
    Buffer *buf;
    

    *pending = FALSE;
    
    if (mState != kIDLE) return err_ResultBufferBusy;

    if (bufferId >= kNUM_BUFS)
      return err_InvalidIndex;
    
    if (type == kRADIO || type == kEEPROM)
      return err_UnsupportedBuffer; // can't do these right now

    if (mUsedBufs & (1 << bufferId))
      return err_ResultBufferInUse;
    
    mState = kALLOC_SCHEMA;

    buf = &mBuffers[bufferId];


    buf->type = type;
    buf->policy = policy;
    buf->numRows = size;
    buf->nextFree = 0;
    buf->nextFull = 0;
    buf->data = data;

    switch (type) {
    case kRAM:

      buf->rowSize = sizeof(Handle); //rows are handles into memory
      buf->len = buf->rowSize * buf->numRows;

      mCurBuffer = bufferId;
      mAllocSchema = schema;
      
      //now, we have to allocate buf->u.bufdata and buf->qh
      if (call MemAlloc.allocate((HandlePtr)(&buf->qh), call ParsedQueryIntf.pqSize(schema)) == SUCCESS) {
	*pending = TRUE;
	return err_NoError;
      } else {
	mState = kIDLE;
	return err_OutOfMemory;
      }
      break;
    case kCOMMAND:
      mState = kIDLE;
      mUsedBufs |= (1 << bufferId); 
      return err_NoError;
      break;
    default: 
      break;
    }


    return err_NoError;


  }
  
  /** @return the number of rows in this buffer */
  command uint16_t DBBuffer.maxSize(uint8_t bufferId) {
    Buffer *buf;
    TinyDBError err = getBuf(bufferId, &buf);
    if (err != err_NoError) return 0;
    
    return buf->numRows;
  }
  
  /** @return the schema of the result */
  command ParsedQuery **DBBuffer.getSchema(uint8_t bufferId) {
    Buffer *buf;
    TinyDBError err = getBuf(bufferId, &buf);
    if (err != err_NoError) return NULL;
    return buf->qh;
  }

  /* Return the next unused buffer id, or err_OutOfMemory, 
     if no more buffers are available */
  command TinyDBError DBBuffer.nextUnusedBuffer(uint8_t *bufferId) {
    int i;

    for (i = 0; i < kNUM_BUFS; i++) {
      if (!(mUsedBufs & (1<<i))) { 
	*bufferId = i;
	return err_NoError;
      }
    }
    
    return err_OutOfMemory;

  }
  
  /** @return the buffer id that corresponds to the specified query id
     in bufferId, or err_InvalidIndex if no such buffer exists 
  */
  command TinyDBError DBBuffer.qidToBuffer(uint8_t qid, uint8_t *bufferId) {
    int i;

    for (i = 0; i < kNUM_BUFS; i++) {
      if ((mUsedBufs & (1<<i))) {
	if ((**mBuffers[i].qh).qid == qid) {
	  *bufferId = i;
	  return err_NoError;
	}
      }
    }

    return err_InvalidIndex;
  }



  /* --------------------- Default event handlers ------------------------- */
  default event result_t DBBuffer.resultReady(uint8_t bufferId) {
    return SUCCESS;
  }

  default event result_t DBBuffer.getNext(uint8_t bufferId) {
    return SUCCESS;
  }

  default event result_t DBBuffer.allocComplete(uint8_t bufferId, TinyDBError result) {

    return SUCCESS;
  }

  default event result_t DBBuffer.putComplete(uint8_t bufferId, QueryResult *buf, TinyDBError result) {

    return SUCCESS;
  }

  /* --------------------- Event handlers ------------------------- */

  event result_t MemAlloc.allocComplete(HandlePtr handle, result_t success) {
    Handle *bufList;

	//Handle h = bufList[buf->nextFull];
      if (mState == kIDLE || mState == kREAD_ROW) //not for us
        return SUCCESS; 

      if (success) {
        switch (mState) { 
        case kALLOC_SCHEMA:
	  //need to copy schema over!
	  memcpy (**handle,(char *)mAllocSchema,call ParsedQueryIntf.pqSize(mAllocSchema));
	  //now we have to alloc the memory buffer */
	  mState = kALLOC_BUFFER; 
	  
	  if (call MemAlloc.allocate((HandlePtr)&mBuffers[mCurBuffer].u.bufdata, mBuffers[mCurBuffer].len) == FAIL) { 
	    mState = kIDLE; 
	    signal DBBuffer.allocComplete(mCurBuffer, err_UnknownError); 
	  } 
	  break; 
        case kALLOC_BUFFER: 
	  mUsedBufs |= (1 << mCurBuffer); 

	  memset(**handle, 0, mBuffers[mCurBuffer].len); //clear to 0
	  mState = kIDLE; 
#ifdef kDEBUG
	  enqueueResult();
#endif
	  signal DBBuffer.allocComplete(mCurBuffer, err_NoError); 
	  break; 
	case kALLOC_ROW: {

	  Buffer *buf = &mBuffers[mCurBuffer];
	  bufList = (Handle *)(*buf->u.bufdata);
	  bufList[mCurRow] = *handle;
	  call MemAlloc.lock(*handle);
	  call QueryResultIntf.toBytes(mCurResult, *buf->qh, (char *)**handle);
	  call MemAlloc.unlock(*handle);
	  mState = kIDLE;

#ifdef kDEBUG
	  readResult();
	  enqueueResult();
#endif
	  signal DBBuffer.putComplete(mCurBuffer, mCurResult, err_NoError);
	  break;
	}
	case kREAD_ROW:
	case kIDLE: //checked for this above -- just do this to stop compiler warnings
	  break;
        } 
      } else { 
        mState = kIDLE; 
	switch (mState) {
	case kALLOC_SCHEMA:
	case kALLOC_BUFFER:
	  signal DBBuffer.allocComplete(mCurBuffer, err_UnknownError); 
	  break;
	case kALLOC_ROW:
	  signal DBBuffer.putComplete(mCurBuffer, mCurResult, err_UnknownError);
	case kIDLE: //checked for this above -- just do this to stop compiler warnings
	case kREAD_ROW:
	  break; 
	}
      } 
    
    return SUCCESS;
  }

  event result_t MemAlloc.compactComplete() {
    return SUCCESS;
  }

  event result_t MemAlloc.reallocComplete(Handle handle, result_t success) {
    if (mState != kIDLE && handle == mCurRowHandle)
      return signal MemAlloc.allocComplete(&mCurRowHandle,success);
    else
      return SUCCESS; //not for us
    //return SUCCESS;
  }

  event result_t QueryProcessor.queryComplete(ParsedQueryPtr q) {
      uint8_t bufid; 

      if (call DBBuffer.qidToBuffer(q->qid, &bufid) == err_NoError) { 
        Buffer *buf = &mBuffers[bufid]; 

        //delete this buffer 
        call MemAlloc.free((Handle)buf->qh); 
        if (buf->type == kRAM) { 
	  call MemAlloc.free((Handle)buf->u.bufdata); 
        } 
        mUsedBufs &= (0xFF | (1 << bufid)); //mark this buffer as unused 
      } 

    return SUCCESS;
  }

  event result_t CommandUse.commandDone(char *commandName, char *resultBuf, SchemaErrorNo err) {
    return SUCCESS;
  }
  
  /* --------------------- Private Routines ------------------------- */

  /** (PRIVATE) Adjust the next free row in the buffer
     @return err_OutOfMemory if the policy indicates that no more inserts should be allowed 
  */

  TinyDBError calcNextFreeRow(Buffer *buf) {
    switch (buf->policy) {
    case EvictOldestPolicy:
      //just a circular buffer

      buf->nextFree++;
      if (buf->nextFree >= buf->numRows) 
	buf->nextFree = 0;

      //if current free reaches head of queue, advance head of queue (which is pointing at oldest element)
      //also deallocate current nextFull item
      if (buf->nextFree == buf->nextFull) {

	//we don't actually dispose of the memory anymore -- instead, we realloc, which can be a lot faster
	/* Handle *bufList = (Handle *)(*buf->u.bufdata);
	   Handle h = bufList[buf->nextFull];
	
	   if (h != NULL) call MemAlloc.free(h);
	   bufList[buf->nextFull] = NULL;
	*/

	buf->nextFull++;
	if (buf->nextFull >= buf->numRows)
	  buf->nextFull = 0;
      }


      break;
    }
    return err_NoError;

  }

  /** (PRIVATE) Return a pointer to buffer bufId in buf if bufId is a valid buf.
     Otherwise, return err_InvalidIndex
  */
  TinyDBError getBuf(uint8_t bufId, Buffer **buf) {
    if (bufId >= kNUM_BUFS)
      return err_IndexOutOfBounds; //unknown schema
    if ((mUsedBufs & (1 << bufId)) == 0)
      return err_InvalidIndex;
    *buf = &mBuffers[bufId];
    return err_NoError;
  }
  

}
