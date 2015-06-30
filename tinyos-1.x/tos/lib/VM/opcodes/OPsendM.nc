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

module OPsendM {

  provides {
    interface MateBytecode;
    interface StdControl;
    event result_t sendDone();
  }

  uses {
    interface MateQueue as Queue;
    interface MateContextSynch as Synch;
    interface MateError as Error;
    interface MateTypes as TypeCheck;
    interface MateStacks as Stacks;
    interface MateEngineStatus as EngineStatus;
    interface MateType as Type[uint8_t id];
    interface Send as SendAdHoc;
    
  }
}

implementation {
  MateQueue sendWaitQueue;
  MateContext* sendingContext;
  bool busy;
  TOS_Msg msg;
    
  command result_t StdControl.init() {
    call Queue.init(&sendWaitQueue);
    sendingContext = NULL;
    busy = FALSE;
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  result_t trySend(MateContext* context) {
    MateStackVariable* arg = call Stacks.popOperand(context);
    if (!call Type.supported[arg->type]()) {
      call Error.error(context, MATE_ERROR_TYPE_CHECK);
      dbg(DBG_USR1|DBG_ERROR, "VM (%i): send tried t send data type %i, doesn't have a network representation.\n", (int)context->which, (int)arg->type);
      return FAIL;
    }
    else {
      uint16_t maxLen;
      uint8_t len = call Type.length[arg->type]((void*)arg->buffer.var);
      MateStructMsg* destMsg;
      len += offsetof(MateNetworkStruct, data);
      len += offsetof(MateStructMsg, data);
      
      destMsg = (MateStructMsg*) call SendAdHoc.getBuffer(&msg, &maxLen);

      // This is >= because we need to consider the one byte type
      // ID in the MateStructMsg on top of the size of the
      // MateNetworkStruct
      if (len >= maxLen) {
	call Error.error(context, MATE_ERROR_BUFFER_OVERFLOW);
	return FAIL;
      }
      
      destMsg->type = arg->type;
      call Type.encode[arg->type](&(destMsg->data), arg->buffer.var);

      if (call SendAdHoc.send(&msg, len) == SUCCESS)  {
        dbg(DBG_USR1, "VM (%i): OPsendM sending buffer in ad-hoc routing.\n", (int)context->which);
	busy = TRUE;
	sendingContext = context;
	context->state = MATE_STATE_BLOCKED;
	call Synch.yieldContext(context);
      }
      else {
	call Stacks.pushOperand(context, arg);
	context->state = MATE_STATE_WAITING;
	call Queue.enqueue(context, &sendWaitQueue, context);
      }
    }
    return SUCCESS;
  }
  
  command result_t MateBytecode.execute(uint8_t instr,
					MateContext* context) {
    if (busy) {
      context->state = MATE_STATE_WAITING;
      call Queue.enqueue(context, &sendWaitQueue, context);
      return SUCCESS;
    }
    else {
      return trySend(context);
    }
  }
  command uint8_t MateBytecode.byteLength() {return 1;}
  
  event result_t SendAdHoc.sendDone(TOS_MsgPtr mesg, result_t success) {
    if (mesg != &msg) {return SUCCESS;}
    
    if (sendingContext != NULL) {
      call Synch.resumeContext(sendingContext, sendingContext);
      sendingContext = NULL;
    }
    busy = FALSE;
    
    if (!call Queue.empty(&sendWaitQueue)) {
      MateContext* context = call Queue.dequeue(NULL, &sendWaitQueue);
      trySend(context);
    }
    dbg(DBG_USR1, "VM: Ad hoc send completed with code %i\n", (int)success);
    return SUCCESS;
  }
  
  event result_t sendDone() {
    if (!busy &&
	sendingContext == NULL &&
	!call Queue.empty(&sendWaitQueue)) {
      MateContext* context = call Queue.dequeue(NULL, &sendWaitQueue);
      trySend(context);
    }
    return SUCCESS;
  }
  
  event void EngineStatus.rebooted() {
    sendingContext = NULL;
    call Queue.init(&sendWaitQueue);
  }

}
