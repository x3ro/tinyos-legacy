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

includes Bombilla;
includes BombillaMsgs;

module OPsendM {

  provides {
    interface BombillaBytecode;
    interface StdControl;
    event result_t sendDone();
  }

  uses {
    interface BombillaQueue as Queue;
    interface BombillaContextSynch as Synch;
    interface BombillaError as Error;
    interface BombillaTypes as Types;
    interface BombillaStacks as Stacks;

    interface SendData as SendAdHoc;
    interface StdControl as SubControl;
    command result_t isAdHocActive();
    command result_t executeContext(BombillaContext* context);
    
  }
}

implementation {
  BombillaQueue sendWaitQueue;
  BombillaContext* sendingContext = NULL;
    
  command result_t StdControl.init() {
    call Queue.init(&sendWaitQueue);
    call SubControl.init();
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t BombillaBytecode.execute(uint8_t instr,
                                            BombillaContext* context,
                                            BombillaState* state) {
    BombillaStackVariable* arg = call Stacks.popOperand(context);
    dbg(DBG_USR1, "VM (%i): Sending packet with built-in ad-hoc routing.\n", (int)context->which);
    if (!call Types.checkTypes(context, arg, BOMB_VAR_B)) {return FAIL;}
    else if (!call isAdHocActive()) {
      dbg(DBG_ERROR, "VM (%i): Cannot send: ad-hoc layer not active.\n", (int)context->which);
      return FAIL;
    }
    else {
      BombillaDataBuffer* buffer = arg->buffer.var;
      uint8_t len = buffer->size * sizeof(buffer->entries[0]);
      len += sizeof(buffer->type) + sizeof(buffer->size);
      //      if (state->sendingContext == NULL) {
      if (call SendAdHoc.send((uint8_t*)buffer, len))  {
        context->state = BOMB_STATE_SENDING;
        context->vmData = state;
        state->sendingContext = context;
        sendingContext = context;
      }
      // }
      else {
        // Back up context so on being resumed it will try to send again
        context->pc--;
        call Stacks.pushOperand(context, arg);
        call Queue.enqueue(context, &sendWaitQueue, context);
        context->state = BOMB_STATE_SEND_WAIT;
      }
      call Synch.releaseLocks(context, context, state->locks);
      call Synch.yieldContext(context, &(state->readyQueue), state->locks);
      return SUCCESS;
    }
  }
  
  event result_t SendAdHoc.sendDone(uint8_t* buffer, result_t success) {
    BombillaContext* sender = sendingContext;
    BombillaState* state = sender->vmData;
 
    dbg(DBG_USR1, "VM: Ad hoc send completed with code %i\n", (int)success);
    if (sender == NULL || state->sendingContext == NULL ||
        sender != state->sendingContext)  {
      dbg(DBG_ERROR, "Error in sendDone event of ad hoc sending component");
      return FAIL;
    }
    
    if (sender->state != BOMB_STATE_SENDING) {
      call Error.error(sender, BOMB_ERROR_QUEUE_INVALID);
      return FAIL;
    }

    sendingContext = NULL;
    state->sendingContext = NULL;

    call Synch.resumeContext(sender, sender, &(state->readyQueue), state->locks);

    return SUCCESS;
  }

  event result_t sendDone() { // Generic sendDone
    BombillaContext* sender;
    dbg(DBG_USR1, "VM: Send done event fired in send.\n");
    if (call Queue.empty(&sendWaitQueue)) {return FAIL;}
    sender = call Queue.dequeue(sendingContext, &sendWaitQueue);
    if (sender->state != BOMB_STATE_SEND_WAIT) {
      call Error.error(sender, BOMB_ERROR_QUEUE_INVALID);
    }
    sender->state = BOMB_STATE_RUN;
    call executeContext(sender);
    return SUCCESS;
  }

  event result_t Synch.makeRunnable(BombillaContext* context) {
    return SUCCESS;
  }
  
}
