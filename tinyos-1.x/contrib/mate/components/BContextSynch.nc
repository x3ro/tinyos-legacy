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
 * Authors:   Philip Levis
 * History:   July 19, 2002
 *	     
 *
 */

includes Bombilla;

module BContextSynch {
  provides interface BombillaContextSynch as Synch;
  provides interface BombillaAnalysis as Analysis;
  
  uses {
    interface BombillaError;
    interface BombillaLocks as Locks;
    interface BombillaInstruction as Instruction;
    interface BombillaQueue as Queue; 
    interface BombillaStacks as Stacks;
  }
}


implementation {
	
  command bool Synch.isRunnable(BombillaContext* context, 
				BombillaLock* locks) {
    int8_t i;
    uint16_t neededLocks = (context->acquireSet);
    dbg(DBG_USR2, "VM: Checking whether context %i runnable: ", (int)context->which);

    for (i = 0; i < BOMB_HEAPSIZE; i++) {
      if (neededLocks & (1 << i)) {
	if (call Locks.isLocked(locks, i)) {
	  dbg_clear(DBG_USR2, "no\n");
	  return FALSE;
	}
      }
    }
    dbg_clear(DBG_USR2, "yes\n");
    return TRUE;
  }

  command result_t Synch.obtainLocks(BombillaContext* caller, 
				     BombillaContext* obtainer, 
				     BombillaLock* locks) {
    int8_t i;
    uint16_t neededLocks = (obtainer->acquireSet);
    dbg(DBG_USR2, "VM: Attempting to obtain necessary locks for context %i\n", obtainer->which);
    for (i = 0; i < BOMB_HEAPSIZE; i++) {
      if (neededLocks & (1 << i)) {
	call Locks.lock(obtainer, locks, i);
      }
    }
    obtainer->acquireSet = 0;
    return SUCCESS;		
  }

  command result_t Synch.releaseLocks(BombillaContext* caller, 
				      BombillaContext* releaser, 
				      BombillaLock* locks) {
    int8_t i;
    uint16_t lockSet = (releaser->releaseSet);
    dbg(DBG_USR2, "VM: Attempting to release specified locks for context %i.\n", releaser->which);
    for (i = 0; i < BOMB_HEAPSIZE; i++) {
      if (lockSet & (1 << i)) {
	call Locks.unlock(releaser, locks, i);
      }
    }
    releaser->releaseSet = 0;
    return SUCCESS;		
  }

  command result_t Synch.releaseAllLocks(BombillaContext* caller,
					 BombillaContext* releaser, 
					 BombillaLock* locks) {
    int8_t i;
    uint16_t lockSet = (releaser->heldSet);
    dbg(DBG_USR2, "VM: Attempting to release all locks for context %i.\n", releaser->which);
    for (i = 0; i < BOMB_HEAPSIZE; i++) {
      if (lockSet & (1 << i)) {
	call Locks.unlock(releaser, locks, i);
      }
    }
    releaser->releaseSet = 0;
    return SUCCESS;
  }

  command void Analysis.analyzeCapsuleVars(BombillaState* state, uint8_t which) {
    int i;
    BombillaCapsuleBuffer* buf = &(state->capsules[(int)which]);
    dbg(DBG_USR2, "VM: Analyzing capsule vars for context %i: ", (int)which);
    buf->usedVars = 0;

    for (i = 0; i < BOMB_PGMSIZE; i++) {
      if (call  Instruction.isVClass(buf->capsule.code[i])) {
	uint8_t arg = (buf->capsule.code[i]) & VARG_MASK;
	dbg_clear(DBG_USR2, "%i ", (int)arg);
	buf->usedVars |= (1 << arg);
      }
    }
    dbg_clear(DBG_USR2, "\n");
    buf->haveSeen = 0;
  }

  command void Analysis.analyzeCapsuleCalls(BombillaState* state, uint8_t which) {
    int i;
    BombillaCapsuleBuffer* buf = &(state->capsules[(int)which]);
    for (i = 0; i < BOMB_PGMSIZE; i++) {
      if ((buf->capsule.code[i] & 0xfc) == OPcall0) {
	uint8_t arg = (buf->capsule.code[i]) & 0x3;
	buf->usedVars |= state->capsules[(int)arg].usedVars;
      }
    }
  }

 uint16_t capsuleCallsDeep(BombillaState* state, uint8_t which) {
    int i;
    BombillaCapsuleBuffer* buf = &(state->capsules[(int)which]);
    if (buf->haveSeen) {
      return buf->usedVars;
    }
    buf->haveSeen = 1;
    for (i = 0; i < BOMB_PGMSIZE; i++) {
      if ((buf->capsule.code[i] & 0xfc) == OPcall0) {
        uint8_t arg = (buf->capsule.code[i]) & 0x3;
        buf->usedVars |= capsuleCallsDeep(state, arg);
      }
    }
    return buf->usedVars;
 }

  command void Analysis.analyzeCapsuleCallsDeep(BombillaState* state, uint8_t which) {
    capsuleCallsDeep(state, which);
  }

  command void Synch.initializeContext(BombillaContext* context,
				       BombillaState* state) {
    context->heldSet = 0;
    context->releaseSet = 0;
    context->capsule = context->rootCapsule;
    context->acquireSet = context->capsule->usedVars;
    context->pc = 0;
    call Stacks.resetStacks(context);
    context->queue = 0;
    context->state = BOMB_STATE_HALT;
  }

  command void Synch.yieldContext(BombillaContext* context,
				  BombillaQueue* readyQueue,
				  BombillaLock* locks) {
    BombillaContext* start = NULL;
    BombillaContext* current = NULL;
    dbg(DBG_USR2, "VM (%i): Yielding.\n", (int)context->which);
    if (!call Queue.empty(readyQueue)) {
      do {
	current = call Queue.dequeue(context, readyQueue);
	if (!call Synch.resumeContext(context, current, readyQueue, locks)) {
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
      while (!call Queue.empty(readyQueue));
    }
    else {
      dbg(DBG_USR2, "VM (%i): Ready queue empty.\n", (int)context->which);
    }
  }

  command bool Synch.resumeContext(BombillaContext* caller,
				   BombillaContext* context,
				   BombillaQueue* readyQueue,
				   BombillaLock* locks) {
    context->state = BOMB_STATE_RESUMING;
    if (call Synch.isRunnable(context, locks)) {
      call Synch.obtainLocks(caller, context, locks);
      signal Synch.makeRunnable(context);
      dbg(DBG_USR2, "VM (%i): Resumption of %i successful.\n", (int)caller->which, (int)context->which);
      return TRUE;
    }
    else {
      dbg(DBG_USR2, "VM (%i): Resumption of %i unsuccessful, putting on the queue.\n", (int)caller->which, (int)context->which);
      call Queue.enqueue(caller, readyQueue, context);
      return FALSE;
    }	
  }

  command void Synch.haltContext(BombillaContext* context,
				 BombillaState* state) {
    call Synch.releaseAllLocks(context, context, state->locks);
    call Synch.yieldContext(context, &(state->readyQueue), state->locks);
    context->state = BOMB_STATE_HALT;
    // !!! Need something better here... it should
    // dequeue a waiting context from any waiting situation
    /*
    if ((context->which == BOMB_CAPSULE_SEND_INDEX) &&
	!call Queue.empty(&state->sendrWaitQueue)) {
      BombillaContext* waiter = call Queue.dequeue(context, &state->sendrWaitQueue);
      call Synch.resumeContext(context, waiter, &(state->readyQueue), state->locks);
      }*/
  }
}    
  
  

  
  




