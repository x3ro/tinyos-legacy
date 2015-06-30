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
 * Authors:   Philip Levis <pal@cs.berkeley.edu>

 * History:   Jun 11, 2004         Inception.
 *
 */

/**
 * @author Philip Levis <pal@cs.berkeley.edu>
 *
 */


includes Mate;

module TriggerContextM {

  provides {
    interface MateBytecode as Trigger;
    interface MateBytecode as TriggerBuf;
    interface StdControl;
  }

  uses {
    interface MateQueue as Queue;
    interface MateContextSynch as Synch;
    interface MateError as Error;
    interface MateTypes as Types;
    interface MateStacks as Stacks;
    interface MateHandlerStore as HandlerStore;
    interface MateEngineStatus as EngineStatus;
    interface MateContextStatus as ContextStatus;
  }
}

implementation {
  MateQueue triggerWaitQueue;
  MateContext* triggeringContext;
  MateContext triggerContext;
  MateDataBuffer triggerBuffer;

  command result_t StdControl.init() {
    result_t rval;
    triggeringContext = NULL;
    triggerContext.which = MATE_CONTEXT_TRIGGER;
    triggerContext.rootHandler = MATE_HANDLER_TRIGGER;
    
    rval = call HandlerStore.initializeHandler();
    call Synch.initializeContext(&triggerContext);
    call Queue.init(&triggerWaitQueue);
    return rval;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  void alertTriggerContext(MateContext* caller) {
    MateStackVariable* arg = call Stacks.popOperand(caller);
    if (triggerContext.state == MATE_STATE_HALT) {
      if (!call Types.checkTypes(caller, arg, MATE_TYPE_BUFFER)) {return;}
      else {
	nmemcpy(&triggerBuffer, arg->buffer.var, sizeof(MateDataBuffer));
	call Synch.initializeContext(&triggerContext);
	call Synch.resumeContext(&triggerContext, &triggerContext);
	// This yield/resume allows locks to be yielded to the trigger context,
	// and if none are shared, then it will just continue executing
	if (caller->releaseSet) {
	  call Synch.yieldContext(caller);
	  call Synch.resumeContext(caller, caller);
	}
      }
    }
    else {
      dbg(DBG_USR1, "VM: Trigger context not halted. Failing silently. \n");
      // Don't trigger, fail silently -- trigger context busy
    }
  }

  void executeTrigger(MateContext* context, MateStackVariable* arg) { 
    arg = call Stacks.popOperand(context);
    if (!call Types.checkTypes(context, arg, MATE_TYPE_BUFFER)) {return;}
    memcpy(&triggerBuffer, arg->buffer.var, sizeof(MateDataBuffer));
    call Synch.yieldContext(context);
    call Synch.initializeContext(&triggerContext);
    // Resuming the triggerContext first means that the triggerer
    // can yield resources which will be acquired by the triggerContext.
    // This allows a context to pass resources.
    call Synch.resumeContext(context, &triggerContext); 
    call Synch.resumeContext(context, context);         
    return;
  }

  command uint8_t Trigger.byteLength() {return 1;}
  command uint8_t TriggerBuf.byteLength() {return 1;}
  
  command result_t Trigger.execute(uint8_t instr, MateContext* context) {
    dbg(DBG_USR1, "VM (%i): Executing trigger.\n", (int)context->which);
    
    if (context->which == MATE_CONTEXT_TRIGGER) {
      call Error.error(context, MATE_ERROR_INVALID_INSTRUCTION);
      return FAIL;
    }
    else if (triggeringContext != NULL) {
      // We need a "trigger done" event...
      call Queue.enqueue(context, &triggerWaitQueue, context);
    }
    else {
      alertTriggerContext(context);
    }
    return SUCCESS;
  }

  command result_t TriggerBuf.execute(uint8_t instr, MateContext* context) {
    dbg(DBG_USR1, "VM (%i): Executing triggerbuf.\n", (int)context->which);

    if (context->which == MATE_CONTEXT_TRIGGER) {
      return call Stacks.pushBuffer(context, &triggerBuffer);
    }
    else {
      call Error.error(context, MATE_ERROR_INVALID_INSTRUCTION);
      return FAIL;
    }
  }

  event void ContextStatus.halted() {

  }
  
  event void HandlerStore.handlerChanged() {
    dbg(DBG_USR3, "SendContext: Handler changed.\n");
    if (triggerContext.state != MATE_STATE_HALT) {
      call Synch.haltContext(&triggerContext);
    }
  }
  
  event void EngineStatus.rebooted() {
    dbg(DBG_USR1, "SendContext: VM rebooted.\n");
    if (triggerContext.state != MATE_STATE_HALT) {
      call Synch.haltContext(&triggerContext);
    }
    triggeringContext = NULL;
    call Queue.init(&triggerWaitQueue);
  }
}
