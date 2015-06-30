/*									tab:4
 *
 *
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 *  Copyright (c) 2004 Intel Corporation 
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
 * Authors:   Philip Levis
 * History:   July 19, 2004 Inception
 *	      Jan 5, 2004   Implemented scalable (unique()) locks.
  *	      April 9, 2004 Handler/capsule shift.
 *
 */

/**
 * @author Philip Levis
 */


includes Mate;

module MContextSynch {
  provides {
    interface MateContextSynch as Synch;
    interface MateContextLocks as ContextLocks;
    interface MateAnalysis as Analysis;
    interface MateContextStatus as ContextStatus[uint8_t contextID];
    interface StdControl;
  }
  uses {
    interface MateError;
    interface MateLocks as Locks;
    interface MateQueue as Queue; 
    interface MateStacks as Stacks;
    interface Leds as Leds;
    interface MateBytecode as Bytecodes[uint8_t opcode];
    interface MateBytecodeLock as CodeLocks[uint8_t param];
    interface MateHandlerStore as HandlerStore[uint8_t id];
    interface MateScheduler as Scheduler;
  }
}


implementation {

  typedef struct {
    uint8_t hasSeen:1;
  } HandlerState;

  typedef struct {
    uint8_t hasHalted:1;
  } ContextState;
  
  bool haltTaskRunning;
  HandlerState handlerState[MATE_HANDLER_NUM];
  ContextState contextState[MATE_CONTEXT_NUM];
  
  uint8_t usedVars[MATE_HANDLER_NUM][(MATE_LOCK_COUNT + 7) / 8];
  MateQueue readyQueue;
  
  command result_t StdControl.init() {
    call Queue.init(&readyQueue);
    nmemset(&handlerState, 0, sizeof(HandlerState) * MATE_HANDLER_NUM);
    nmemset(&contextState, 0, sizeof(ContextState) * MATE_CONTEXT_NUM);
    haltTaskRunning = FALSE;
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command void Synch.reset() {
    call Queue.init(&readyQueue);
    call Locks.reset();
  }
	
  command bool ContextLocks.isRunnable(MateContext* context) { 
    int8_t i;
    uint8_t* neededLocks = (context->acquireSet);
    dbg(DBG_USR2, "VM: Checking whether context %i runnable: ", (int)context->which);
    
    for (i = 0; i < MATE_LOCK_COUNT; i++) {
      dbg_clear(DBG_USR2, "%i,", (int)i); 
      if ((neededLocks[i / 8]) & (1 << (i % 8))) {
	if (call Locks.isLocked(i)) {
	  dbg_clear(DBG_USR2, " - no\n");
	  return FALSE;
	}
      }
    }
    dbg_clear(DBG_USR2, " - yes\n");
    return TRUE;
  }

  command result_t ContextLocks.obtainLocks(MateContext* caller, 
					    MateContext* obtainer) { 
    int i;
    uint8_t* neededLocks = (obtainer->acquireSet);
    dbg(DBG_USR2, "VM: Attempting to obtain necessary locks for context %i: ", obtainer->which);
    for (i = 0; i < MATE_LOCK_COUNT; i++) {
      dbg_clear(DBG_USR2, "%i", (int)i);
      if ((neededLocks[i / 8]) & (1 << (i % 8))) {
	  dbg_clear(DBG_USR2, "+"); 
	call Locks.lock(obtainer, i);
      }
      dbg_clear(DBG_USR2, ","); 
    }
    for (i = 0; i < (MATE_LOCK_COUNT + 7) / 8; i++) {
      obtainer->acquireSet[i] = 0;
    }
    dbg_clear(DBG_USR2, "\n");
    return SUCCESS;		
  }

  command result_t ContextLocks.releaseLocks(MateContext* caller, 
					     MateContext* releaser) {
    int i;
    uint8_t* lockSet = (releaser->releaseSet);
    dbg(DBG_USR2, "VM: Attempting to release specified locks for context %i.\n", releaser->which);
    for (i = 0; i < MATE_LOCK_COUNT; i++) {
      if ((lockSet[i / 8]) & (1 << (i % 8))) {
	call Locks.unlock(releaser, i);
      }
    }
    for (i = 0; i < (MATE_LOCK_COUNT + 7) / 8; i++) {
      releaser->releaseSet[i] = 0;
    }
    return SUCCESS;		
  }

  command result_t ContextLocks.releaseAllLocks(MateContext* caller,
						MateContext* releaser) {
    int i;
    uint8_t* lockSet = (releaser->heldSet);
    dbg(DBG_USR2, "VM: Attempting to release all locks for context %i.\n", releaser->which);
    for (i = 0; i < MATE_LOCK_COUNT; i++) {
      if ((lockSet[i / 8]) & (1 << (i % 8))) {
	call Locks.unlock(releaser, i);
      }
    }
    for (i = 0; i < (MATE_LOCK_COUNT + 7) / 8; i++) {
      releaser->releaseSet[i] = 0;
    }
    return SUCCESS;
  }

  command void Analysis.analyzeVars(MateHandlerID id) {
    uint16_t i;
    uint16_t handlerLen;
    MateOpcode instr;
    dbg(DBG_USR2, "VM: Analyzing capsule vars for handler %i: ", (int)(id));
    for (i = 0; i < ((MATE_LOCK_COUNT + 7) / 8); i++) {
      usedVars[id][i] = 0;
    }
    
    handlerLen = call HandlerStore.getCodeLength[id]();
    for (i = 0; i < handlerLen; i+= call Bytecodes.byteLength[instr]()) {
      int16_t lock;
      instr = call HandlerStore.getOpcode[id](i);
      lock = call CodeLocks.lockNum[instr](instr, id, i);
      if (lock >= 0) {
	dbg_clear(DBG_USR2, "%i,", (int)lock);
	usedVars[id][lock / 8] |= (1 << (lock % 8)); 
      }
    }
    dbg_clear(DBG_USR2, "\n");
    handlerState[id].hasSeen = TRUE;
  }
  
  void capsuleCallsDeep(MateHandlerID id) {
    return;
  }

  command void Analysis.analyzeCalls(MateHandlerID id) {
   capsuleCallsDeep(id);
 }
 
  command void Analysis.clearAnalysis(MateHandlerID id) {
    memset(usedVars, MATE_HANDLER_NUM * ((MATE_LOCK_COUNT + 7)/8), 0);
    handlerState[id].hasSeen = FALSE;
  }

  task void haltTask() {
    int i;
    for (i = 0; i < MATE_HANDLER_NUM; i++) {
      if (contextState[i].hasHalted) {
	contextState[i].hasHalted = FALSE;
	signal ContextStatus.halted[i]();
      }
    }
    haltTaskRunning = FALSE;
  }
  
  command void Synch.initializeContext(MateContext* context) {
    int i;
    for (i = 0; i < (MATE_LOCK_COUNT + 7) / 8; i++) {
      context->heldSet[i] = 0;
      context->releaseSet[i] = 0;
    }
    context->currentHandler = context->rootHandler;
    nmemcpy(context->acquireSet, usedVars[context->currentHandler], (MATE_LOCK_COUNT + 7) / 8);
    context->pc = 0;
    call Stacks.resetStacks(context);
    if (context->queue) {
      call Queue.remove(context, context->queue, context);
    }
    context->state = MATE_STATE_HALT;
  }
  
 command void Synch.yieldContext(MateContext* context) {
   MateContext* start = NULL;
   MateContext* current = NULL;
   dbg(DBG_USR2, "VM (%i): Yielding.\n", (int)context->which);
   call ContextLocks.releaseLocks(context, context);
   if (!call Queue.empty(&readyQueue)) {
     do {
       current = call Queue.dequeue(context, &readyQueue);
       if (!call Synch.resumeContext(context, current)) {
         dbg(DBG_USR2, "VM (%i): Context %i not runnable.\n", (int)context->which, (int)current->which);
         if (start == NULL) {
           start = current;
         }
         else if (start == current) {
           dbg(DBG_USR2, "VM (%i): Looped on ready queue. End checks.\n", (int)context->which);
           break;
         }
       }
     }
     while (!call Queue.empty(&readyQueue));
   }
   else {
     dbg(DBG_USR2, "VM (%i): Ready queue empty.\n", (int)context->which);
   }
 }
 
 command bool Synch.resumeContext(MateContext* caller,
                                  MateContext* context) {
   context->state = MATE_STATE_WAITING;
   if (call ContextLocks.isRunnable(context)) {
     call ContextLocks.obtainLocks(caller, context);
     if (call Scheduler.submit(context) == SUCCESS) {
       dbg(DBG_USR2, "VM (%i): Resumption of %i successful.\n", (int)caller->which, (int)context->which);
       return TRUE;
     }
     else {
       dbg(DBG_USR2|DBG_ERROR, "VM (%i): Resumption of %i FAILED.\n", (int)caller->which, (int)context->which);
       return FAIL;
     }
   }
   else {
     dbg(DBG_USR2, "VM (%i): Resumption of %i unsuccessful, putting on the queue.\n", (int)caller->which, (int)context->which);
      call Queue.enqueue(caller, &readyQueue, context);
      return FALSE;
    }	
 }

 command void Synch.haltContext(MateContext* context) {
   call ContextLocks.releaseAllLocks(context, context);
   call Synch.yieldContext(context);
   if (context->queue && context->state != MATE_STATE_HALT) {
     call Queue.remove(context, context->queue, context);
   }
   if (context->state != MATE_STATE_HALT) {
     context->state = MATE_STATE_HALT;
     contextState[context->which].hasHalted = TRUE;
     if (!haltTaskRunning) {
       if (post haltTask() == SUCCESS) {
	 haltTaskRunning = TRUE;
       }
     }
   }
 }

 default event void ContextStatus.halted[uint8_t contextID]() {}
 
 default command int16_t CodeLocks.lockNum[uint8_t ival](uint8_t instr, uint8_t id, uint8_t pc) {
   return -1;
 }

 event void HandlerStore.handlerChanged[uint8_t id]() {
   // do nothing.
 }
 
}    
  
  

  
  




