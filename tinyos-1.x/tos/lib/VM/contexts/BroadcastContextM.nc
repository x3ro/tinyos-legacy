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
 *
 * History:   Jun 9, 2004         Inception.
 *
 */

/**
 * @author Philip Levis <pal@cs.berkeley.edu>
 */


includes Mate;

module BroadcastContextM {

  provides {
    interface MateBytecode as BCast;
    interface MateBytecode as BCastBuf;
    interface StdControl;
  }

  uses {
    interface MateQueue as Queue;
    interface MateContextSynch as Synch;
    interface MateError as Error;
    interface MateTypes as TypeCheck;
    interface MateType as Type[uint8_t id];
    interface MateStacks as Stacks;
    interface SendMsg as SendBCast;
    interface ReceiveMsg as ReceiveBCast;
    interface MateHandlerStore as HandlerStore;
    interface MateEngineStatus as EngineStatus;
  }
}

implementation {
  MateQueue sendWaitQueue;
  MateContext* sendingContext;
  bool sending;
  MateContext receiveContext;
  MateDataBuffer recvBuffer;
  TOS_Msg msg;

  command result_t StdControl.init() {
    result_t rval;
    receiveContext.which = MATE_CONTEXT_BROADCAST;
    receiveContext.rootHandler = MATE_HANDLER_BROADCAST;
    
    rval = call HandlerStore.initializeHandler();
    call Synch.initializeContext(&receiveContext);
    call Queue.init(&sendWaitQueue);
    sending = FALSE;
    return rval;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }


  command uint8_t BCast.byteLength() {return 1;}
  command uint8_t BCastBuf.byteLength() {return 1;}

  result_t executeSend(MateContext* context) {
    MateStackVariable* arg = call Stacks.popOperand(context);
    dbg(DBG_USR1, "VM (%i): Executing bcast.\n", (int)context->which);
    if (!call Type.supported[arg->type]()) {
      call Error.error(context, MATE_ERROR_TYPE_CHECK);
      dbg(DBG_USR1|DBG_ERROR, "VM (%i): bcast tried to send data type %i, doesn't have a network representation.\n", (int)context->which, (int)arg->type);
      return FAIL;
    }
    else {
      uint16_t maxLen = TOSH_DATA_LENGTH;
      uint8_t len = call Type.length[arg->type]((void*)arg->buffer.var);
      MateStructMsg* destMsg = (MateStructMsg*)msg.data;

      len += offsetof(MateNetworkStruct, data);
      len += offsetof(MateStructMsg, data);
      if (len >= maxLen) {
	call Error.error(context, MATE_ERROR_BUFFER_OVERFLOW);
	return FAIL;
      }
      
      destMsg->type = arg->type;
      call Type.encode[arg->type](&(destMsg->data), arg->buffer.var);

      if (call SendBCast.send(TOS_BCAST_ADDR, len, &msg) == SUCCESS) {
	call Synch.yieldContext(context);
	sendingContext = context;
	context->state = MATE_STATE_BLOCKED;
	sending = TRUE;
	dbg(DBG_USR1, "VM (%i): Broadcast of length %i succeeded.\n", (int)context->which, (int)len);
      }
      else {
	call Stacks.pushOperand(context, arg);
	context->state = MATE_STATE_WAITING;
	call Queue.enqueue(context, &sendWaitQueue, context);
	dbg(DBG_USR1, "VM (%i): Broadcast of length %i failed, continuing execution.\n", (int)context->which, (int)len);
	if (context->state == MATE_STATE_WAITING) {
	  call Synch.resumeContext(context, context);
	}
      }
    }
    return SUCCESS;
  }
  
  command result_t BCast.execute(uint8_t instr, MateContext* context) {
    if (sending == TRUE) {
      call Queue.enqueue(context, &sendWaitQueue, context);
      context->state = MATE_STATE_WAITING;
      call Synch.yieldContext(context);
      return SUCCESS;
    }
    else {
      return executeSend(context);
    }
  }

  command result_t BCastBuf.execute(uint8_t instr, MateContext* context) {
    if (context->which != MATE_CONTEXT_BROADCAST) {
      call Error.error(context, MATE_ERROR_INVALID_INSTRUCTION);
      return FAIL;
    }
    else {
      call Stacks.pushBuffer(context, &recvBuffer);
      return SUCCESS;
    }
    return SUCCESS;
  }
    
  event result_t SendBCast.sendDone(TOS_MsgPtr msgPtr, result_t success) {
    if (msgPtr != &msg) {
      dbg(DBG_USR1, "VM: BCast.sendDone fired, but not for our packet... multiple protocols using the same AM type?\n");      
      return SUCCESS;
    } // Not ours...

    sending = FALSE;
    if (sendingContext == NULL) {
      dbg(DBG_USR1, "VM: BCast.sendDone fired, but no sending context: VM rebooted?\n");
      return SUCCESS;
    }
    else {
      call Synch.resumeContext(sendingContext, sendingContext);
      sendingContext = NULL;
    }
    
    if (!call Queue.empty(&sendWaitQueue)) {
      MateContext* nextSender = call Queue.dequeue(&receiveContext, &sendWaitQueue);
      return executeSend(nextSender);
    }
    return SUCCESS;
  }


  event TOS_MsgPtr ReceiveBCast.receive(TOS_MsgPtr message) {
    if (receiveContext.state != MATE_STATE_HALT) {
      dbg(DBG_USR1, "BroadcastContext: Already running, dropped packet.\n");
    }
    else {
      MateStructMsg* payload = (MateStructMsg*)message->data;
      MateNetworkStruct* nets = &(payload->data);
      if (!call Type.supported[payload->type]() ||
	  payload->type != MATE_TYPE_BUFFER) {
	dbg(DBG_USR1, "BroadcastContext: Unknown/non-buffer type, dropped packet.\n");
      }
      else if (call Type.decode[payload->type](&recvBuffer, nets, sizeof(MateDataBuffer)) == SUCCESS) {
	call Synch.initializeContext(&receiveContext);
	call Synch.resumeContext(&receiveContext, &receiveContext);	  
      }
      else {
	dbg(DBG_USR1, "BroadcastContext: Failure decoding buffer, dropped packet.\n");
      }
    }
    return message;
  }
  
  event void HandlerStore.handlerChanged() {
    dbg(DBG_USR3, "BroadcastContext: Handler changed.\n");
    if (receiveContext.state != MATE_STATE_HALT) {
      call Synch.haltContext(&receiveContext);
    }
  }

  event void EngineStatus.rebooted() {
    dbg(DBG_USR1, "BroadcastContext: VM rebooted. Clear queues.\n");
    if (receiveContext.state != MATE_STATE_HALT) {
      call Synch.haltContext(&receiveContext);
    }
    call Queue.init(&sendWaitQueue);
    sendingContext = NULL;
  }
  
}
