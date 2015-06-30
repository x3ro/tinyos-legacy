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
 * Authors:   Phil Levis
 * History:   Nov 29, 2003         Inception.
 *
 */

/**
 * @author Phil Levis
 */


includes AM;
includes Mate;

module MergeContextM {
  provides {
    interface StdControl;
    interface MateBytecode;
    command result_t triggerMerge(MateDataBuffer* buf);
  }
  
  uses {
    interface StdControl as SubControlTimer;
    interface MateContextSynch as Synch;
    interface MateHandlerStore as HandlerStore;
    interface MateStacks as Stacks;
    interface MateError as Error;
    interface MateEngineStatus as EngineStatus;
  }
}


implementation {
  MateContext mergeContext;
  MateDataBuffer mergeBuffer;
	
  command result_t StdControl.init() {
    result_t rval;
    rval = call SubControlTimer.init();
    mergeContext.which = MATE_CONTEXT_MERGE;
    mergeContext.rootHandler = MATE_HANDLER_MERGE;
    
    rval &= call HandlerStore.initializeHandler();
    call Synch.initializeContext(&mergeContext);
    return rval;
  }

  command result_t StdControl.start() {
    call SubControlTimer.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call SubControlTimer.stop();
    return SUCCESS;
  }

  task void MergeExecTask() {
    if (mergeContext.state == MATE_STATE_HALT) {
      call Synch.initializeContext(&mergeContext);
      call Synch.resumeContext(&mergeContext, &mergeContext);
    }
    else {
      dbg(DBG_USR1, "VM: Merge context not halted. Currently in state %i.\n", mergeContext.state);
      // Can log a merge miss error here, but probably
      // not a good idea
    }
  }

  command result_t MateBytecode.execute(uint8_t instr,
					    MateContext* context) {
    if (context->which != MATE_CONTEXT_MERGE) {
      dbg(DBG_USR1, "VM: Context other than merge tried to execute MERGEBUF, context: %i.\n", (int)mergeContext.which);
      call Error.error(context, MATE_ERROR_INVALID_INSTRUCTION);
      return FAIL;
    }
    else {
      return call Stacks.pushBuffer(context, &mergeBuffer);
    }
  }

  command uint8_t MateBytecode.byteLength() {
    return 1;
  }
  
  command result_t triggerMerge(MateDataBuffer* buf) {
    dbg(DBG_USR1, "VM: Trigger merge context, posting MergeExecTask.\n");
    if (mergeContext.state == MATE_STATE_HALT) {
      memcpy(&mergeBuffer, buf, sizeof(MateDataBuffer));
      post MergeExecTask();
    }
    else {
      dbg(DBG_USR1, "VM: Trigger of merge failed: it is not halted, currently in state %i.\n", (int)mergeContext.state);
    }
    return SUCCESS;
  }

  event void HandlerStore.handlerChanged() {
    dbg(DBG_USR3, "MergeContext: Handler changed.\n");
    if (mergeContext.state != MATE_STATE_HALT) {
      call Synch.haltContext(&mergeContext);
    }
  }

  event void EngineStatus.rebooted() {
    dbg(DBG_USR1, "MergeContext: VM rebooted.\n");
    if (mergeContext.state != MATE_STATE_HALT) {
      call Synch.haltContext(&mergeContext);
    }
  }

}
