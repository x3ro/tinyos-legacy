/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*									tab:4
 *									
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
 *  By downloading, copying, installing or using the software you
 *  agree to this license.  If you do not agree to this license, do
 *  not download, install, copy or use the software.
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
 * Authors:   Philip Levis <pal@cs.berkeley.edu>
 *            Neil Patel
 * History:   Apr 14, 2003         Inception.
 *
 */

/**
 * @author Philip Levis <pal@cs.berkeley.edu>
 * @author Neil Patel
 */


includes Mate;
includes Reduce;

module OneHopRegionM {

  provides {
    interface MateBytecode as Create;
    interface MateBytecode as GetNum;
    interface MateBytecode as GetElements;
    interface MateBytecode as GetVar;
    interface MateBytecode as PutVar;
    interface MateBytecode as ReduceAdd;
    interface MateBytecode as ReduceProduct;
    interface MateBytecode as ReduceMin;
    interface MateBytecode as ReduceMax;
    interface MateBytecode as ReduceMinID;
    interface MateBytecode as ReduceMaxID;
    interface StdControl;
  }

  uses {
    interface MateQueue as Queue;
    interface MateContextSynch as Synch;
    interface MateError as Error;
    interface MateTypes as Types;
    interface MateStacks as Stacks;
    interface MateEngineStatus as EngineStatus;
    interface Region as RadioRegion;
    interface TupleSpace as RadioTupleSpace;
    interface Reduce as RadioReduce;
    interface StdControl as SubControl;
  }
}

implementation {
  MateQueue createWaitQueue;
  MateContext* creatingContext;

  MateQueue getWaitQueue;
  MateContext* gettingContext;
  uint16_t bufs[MATE_CONTEXT_NUM];
  bool getResponseReceived;

  MateQueue reduceWaitQueue;
  MateContext* reducingContext;

  enum {
    REDUCE_KEY = TUPLESPACE_MAX_KEY - 1,
  };
  
  command result_t StdControl.init() {
    call Queue.init(&createWaitQueue);
    creatingContext = NULL;

    call Queue.init(&getWaitQueue);
    gettingContext = NULL;

    call Queue.init(&reduceWaitQueue);
    reducingContext = NULL;
    
    getResponseReceived = FALSE;
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command uint8_t Create.byteLength() {return 1;}
  command uint8_t GetNum.byteLength() {return 1;}
  command uint8_t GetElements.byteLength() {return 1;}
  command uint8_t GetVar.byteLength() {return 1;}
  command uint8_t PutVar.byteLength() {return 1;}
  command uint8_t ReduceAdd.byteLength() {return 1;}
  command uint8_t ReduceProduct.byteLength() {return 1;}
  command uint8_t ReduceMax.byteLength() {return 1;}
  command uint8_t ReduceMin.byteLength() {return 1;}
  command uint8_t ReduceMaxID.byteLength() {return 1;}
  command uint8_t ReduceMinID.byteLength() {return 1;}
 
  command result_t Create.execute(uint8_t instr,
				  MateContext* context) {
    
    if (creatingContext == NULL &&
	call RadioRegion.getRegion() == SUCCESS) {
      dbg(DBG_USR1, "VM (%i): Creating neighborhood.\n", (int)context->which);
      context->state = MATE_STATE_SENDING;
      creatingContext = context;
    }
    else {
      dbg(DBG_USR1, "VM (%i): Neighborhood create request refused.\n", (int)context->which);
      context->pc--;
      call Queue.enqueue(context, &createWaitQueue, context);
      context->state = MATE_STATE_SEND_WAIT;
    }
    call Synch.releaseLocks(context, context);
    call Synch.yieldContext(context);
    
    return SUCCESS;
  }

  event void RadioRegion.getDone(result_t success) {
    if (creatingContext != NULL) {
      // It would be nice to check for failure here,
      // but what would you do?
      call Synch.resumeContext(creatingContext, creatingContext);
      dbg(DBG_USR1, "VM (%i): Neighborhood created.\n", (int)creatingContext->which);
      creatingContext = NULL;
    }

    if (!call Queue.empty(&createWaitQueue)) {
      MateContext* newCreator = call Queue.dequeue(creatingContext, &createWaitQueue);
      if (newCreator->state != MATE_STATE_SEND_WAIT) {
	call Error.error(newCreator, MATE_ERROR_QUEUE_INVALID);
      }
      call Synch.resumeContext(newCreator, newCreator);
    }
  }

  command result_t GetNum.execute(uint8_t instr,
				  MateContext* context) {
    uint16_t val = (uint16_t) call RadioRegion.numNodes();
    dbg(DBG_USR1, "VM (%i): Getting neighborhood count.\n", (int)context->which);
    call Stacks.pushValue(context, val);
    return SUCCESS;
  }

  command result_t GetElements.execute(uint8_t instr,
				       MateContext* context) {
     MateStackVariable* arg = call Stacks.popOperand(context);
     if (!call Types.checkTypes(context, arg, MATE_VAR_B)) {return FAIL;}
     else {
       MateDataBuffer* buffer = arg->buffer.var;
       uint16_t* ptr;
       dbg(DBG_USR1, "VM (%i): Getting neighborhood elements.\n", (int)context->which);
       call RadioRegion.getNodes(&ptr);
       nmemcpy((uint16_t*)buffer->entries, ptr, MATE_BUF_LEN);
       buffer->size = call RadioRegion.numNodes();
       buffer->type = MATE_DATA_VALUE;
     }
     return SUCCESS;
  }

  result_t executeGet(MateContext* context,
		      uint16_t addr,
		      ts_key_t key) {
    getResponseReceived = FALSE;
    if (gettingContext == NULL) {
      getResponseReceived = FALSE;
      // This will only fail if tuple IDs are wrong, etc.
      // Trust the programmer here. A bad idea for now, but
      // language side should take care of this side of things.
      call RadioTupleSpace.get(key, addr, &bufs[context->which]);
      if (!getResponseReceived) {
	context->state = MATE_STATE_SENDING;
	gettingContext = context;
	call Synch.releaseLocks(context, context);
	call Synch.yieldContext(context);
      }
      else {
	// already received a response, so just push the value
	call Stacks.pushValue(context, bufs[context->which]);
      }
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t GetVar.execute(uint8_t instr,
				  MateContext* context) {
    MateStackVariable* mote = call Stacks.popOperand(context);
    MateStackVariable* which = call Stacks.popOperand(context);
    if (!call Types.checkTypes(context, mote, MATE_VAR_V)) {return FAIL;}
    if (!call Types.checkTypes(context, which, MATE_VAR_V)) {return FAIL;}
    else {
      uint16_t addr = mote->value.var;
      ts_key_t var = (ts_key_t)which->value.var;
      if (executeGet(context, addr, var) != SUCCESS) {
	dbg(DBG_USR1, "VM (%i): Neighborhood getvar request refused.\n", (int)context->which);
	context->pc--;
	call Stacks.pushOperand(context, which);
	call Stacks.pushOperand(context, mote);
	call Queue.enqueue(context, &createWaitQueue, context);
	context->state = MATE_STATE_SEND_WAIT;
	call Synch.releaseLocks(context, context);
	call Synch.yieldContext(context);
      }
      return SUCCESS;
    }
  }

  event void RadioTupleSpace.getDone(ts_key_t key, 
				uint16_t nodeaddr,
				void *buf,
				int buflen,
				result_t success) {
    getResponseReceived = TRUE;
    if (gettingContext != NULL) {
      dbg(DBG_USR1, "VM (%i): Radio tuple space getvar done event handled.\n", (int)gettingContext->which);
      call Stacks.pushValue(gettingContext, bufs[gettingContext->which]);
      call Synch.resumeContext(gettingContext, gettingContext);
      gettingContext = NULL;
    }
    else {
      // It's null if this happened to be a local get;
      // haven't put anyone on the queue due to event signalling
      // in command handler (ew).
      // Alternatively, a repsonse to a request after the VM has rebooted.
    }
    if (!call Queue.empty(&getWaitQueue)) {
      MateContext* newGetter = call Queue.dequeue(gettingContext, &getWaitQueue);
      if (newGetter->state != MATE_STATE_SEND_WAIT) {
	call Error.error(newGetter, MATE_ERROR_QUEUE_INVALID);
      }
      call Synch.resumeContext(newGetter, newGetter);
    }
  }
  
  command result_t PutVar.execute(uint8_t instr,
				  MateContext* context) {
    MateStackVariable* val = call Stacks.popOperand(context);
    MateStackVariable* which = call Stacks.popOperand(context);
    if (!call Types.checkTypes(context, val, MATE_VAR_V)) {return FAIL;}
    if (!call Types.checkTypes(context, which, MATE_VAR_V)) {return FAIL;}
    call RadioTupleSpace.put((ts_key_t)which->value.var, &(val->value.var), sizeof(uint16_t));
    return SUCCESS;
  }

  result_t startReduce(MateContext* context, operator_t op) {
    if (reducingContext != NULL) {
      context->pc--;
      call Queue.enqueue(context, &reduceWaitQueue, context);
      context->state = MATE_STATE_SEND_WAIT;
    }
    else {
      MateStackVariable* srcKey = call Stacks.popOperand(context);
      if (!call Types.checkTypes(context, srcKey, MATE_VAR_V)) {return FAIL;}
      if (call RadioReduce.reduceToOne(op, (ts_key_t)srcKey->value.var, (ts_key_t)REDUCE_KEY) == SUCCESS) {
	reducingContext = context;
	context->state = MATE_STATE_SENDING;
      }
      else {
	context->pc--;
	call Stacks.pushOperand(context, srcKey);
	call Queue.enqueue(context, &reduceWaitQueue, context);
	context->state = MATE_STATE_SEND_WAIT;
      }
      call Synch.releaseLocks(context, context);
      call Synch.yieldContext(context);
    }
    return SUCCESS;
  }
  
  command result_t ReduceAdd.execute(uint8_t instr,
				     MateContext* context) {
    return startReduce(context, REDUCE_OP_ADD);
  }

  command result_t ReduceProduct.execute(uint8_t instr,
					 MateContext* context) {
    return startReduce(context, REDUCE_OP_PROD);
  }
  
  command result_t ReduceMin.execute(uint8_t instr,
				     MateContext* context) {
     return startReduce(context, REDUCE_OP_MIN);
  }

  command result_t ReduceMax.execute(uint8_t instr,
				     MateContext* context) {
     return startReduce(context, REDUCE_OP_MAX);
  }

  command result_t ReduceMinID.execute(uint8_t instr,
				       MateContext* context) {
    return startReduce(context, REDUCE_OP_MINID);
  }

  command result_t ReduceMaxID.execute(uint8_t instr,
				       MateContext* context) {
    return startReduce(context, REDUCE_OP_MAXID);
  }

  event void RadioReduce.reduceDone(ts_key_t result_key,
				    result_t success, float quality) {
    if (result_key == REDUCE_KEY &&
	reducingContext != NULL) {
      // This call to executeGet is not quite right;
      // the request can fail, requiring the context to block
      // however, resuming from being blocked is a bit tricky, as
      // you can't restart (you're in the midst of a three-phase
      // operation). This is where the regions pseudocode breaks
      // down from what the actual code does. Why can't
      // reductions just return values?
      executeGet(reducingContext, TOS_LOCAL_ADDRESS, result_key);
      call Synch.resumeContext(reducingContext, reducingContext);
      dbg(DBG_USR1, "VM (%i): Reduction complete.\n", (int)reducingContext->which);
      reducingContext = NULL;
    }
    if (!call Queue.empty(&reduceWaitQueue)) {
      MateContext* newReducer = call Queue.dequeue(reducingContext, &reduceWaitQueue);
      if (newReducer->state != MATE_STATE_SEND_WAIT) {
	call Error.error(newReducer, MATE_ERROR_QUEUE_INVALID);
      }
      call Synch.resumeContext(newReducer, newReducer);
    }
  }

  
  
  event result_t Synch.makeRunnable(MateContext* context) {
    return SUCCESS;
  }
  
  event void EngineStatus.rebooted() {
    call Queue.init(&createWaitQueue);
    creatingContext = NULL;
    
    call Queue.init(&getWaitQueue);
    gettingContext = NULL;
    getResponseReceived = FALSE;

    call SubControl.stop();
    call SubControl.start();
    
  }
}
