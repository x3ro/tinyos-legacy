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

module OPsendrM {

  provides {
    interface BombillaBytecode;
    event result_t sendDone();
  }

  uses {
    interface BombillaQueue as Queue;
    interface BombillaContextSynch as Synch;
    interface BombillaError as Error;
    interface BombillaTypes as Types;
    interface BombillaStacks as Stacks;

    interface SendMsg as SendPacket;
    interface ReceiveMsg as ReceivePacket;

    interface BombillaContextComm as Comm;
    interface BombillaVirus as Virus;
    interface BombillaAnalysis as Analysis;
    command result_t executeContext(BombillaContext* context);
  }
}

implementation {
  BombillaQueue sendWaitQueue;
  BombillaContext* sendingContext = NULL;
  BombillaContext sendContext;

  event result_t Comm.registerCapsule(BombillaState* state) {
    int pc = 0;

    call Queue.init(&sendWaitQueue);
    sendContext.which = BOMB_CAPSULE_SEND;
    sendContext.vmData = state;

    sendContext.rootCapsule = &(state->capsules[BOMB_CAPSULE_SEND_INDEX]);
    sendContext.state = BOMB_STATE_HALT;
    state->capsules[BOMB_CAPSULE_SEND_INDEX].capsule.type = sendContext.which;
    state->capsules[BOMB_CAPSULE_SEND_INDEX].capsule.type |= BOMB_OPTION_FORWARD;
        
    call Virus.registerCapsule(state->capsules[BOMB_CAPSULE_SEND_INDEX].capsule.type,
                               &(state->capsules[BOMB_CAPSULE_SEND_INDEX].capsule));

    state->capsules[BOMB_CAPSULE_SEND_INDEX].capsule.code[pc++] = OPpushc;
    state->capsules[BOMB_CAPSULE_SEND_INDEX].capsule.code[pc++] = OPlnot;
    state->capsules[BOMB_CAPSULE_SEND_INDEX].capsule.code[pc++] = OPsendr;
    state->capsules[BOMB_CAPSULE_SEND_INDEX].capsule.code[pc++] = OPhalt;
    state->capsules[BOMB_CAPSULE_SEND_INDEX].capsule.options = 0;
    state->capsules[BOMB_CAPSULE_SEND_INDEX].capsule.version = 0;
    
    call Analysis.analyzeCapsuleVars(state, BOMB_CAPSULE_SEND_INDEX);
    
    return SUCCESS;
  }

  event result_t Comm.analyzeLockSets(BombillaState* state) {
    return SUCCESS;
  }
  
  void alertSendContext(BombillaContext* caller,
                            BombillaStackVariable* arg,
                            BombillaState* state) {
    if (sendContext.state == BOMB_STATE_HALT) {
      nmemcpy(&(state->sendrBuffer), arg->buffer.var, sizeof(BombillaDataBuffer));
      call Synch.initializeContext(&sendContext, state);
      call Stacks.pushBuffer(&sendContext, &(state->sendrBuffer));
      call Synch.resumeContext(&sendContext, &sendContext, &(state->readyQueue), state->locks);
      // This yield/resume allows locks to be yielded to the send context,
      // and if none are shared, then it will just continue executing
      if (caller->releaseSet) {
        call Synch.releaseLocks(caller, caller, state->locks);
        call Synch.yieldContext(caller, &(state->readyQueue), state->locks);
        call Synch.resumeContext(caller, caller, &(state->readyQueue), state->locks);
      }
    }
    else {
      // Don't send, fail silently -- send context busy
    }
  }

  void executeSendr(BombillaContext* context, BombillaStackVariable* arg, 
                    BombillaState* state) {
    if ((context->which != BOMB_CAPSULE_SEND) || 
        (!call Types.checkTypes(context, arg, BOMB_VAR_V))) {
      context->state = BOMB_STATE_HALT;
      return;
    }
    else {
      uint16_t addr = arg->value.var;
      uint8_t size;
      arg = call Stacks.popOperand(context);
      if (!call Types.checkTypes(context, arg, BOMB_VAR_B)) {return;}
      size = arg->buffer.var->size * sizeof(arg->buffer.var->entries[0]);
      size += sizeof(arg->buffer.var->type);
      size += sizeof(arg->buffer.var->size);
      nmemcpy(context->msg.data +  BOMB_HEADERSIZE , arg->buffer.var, size);
      nmemcpy(context->msg.data, context->header, BOMB_HEADERSIZE);
      //if (state->sendingContext == NULL) { // do we assume Generic Comm will take care of this?
      if (call SendPacket.send(addr, size + BOMB_HEADERSIZE, &context->msg)) {
        context->state = BOMB_STATE_SENDING;
        state->sendingContext = context;
        sendingContext = context;
      }
      //}
      else {
        // Back up context so on being resumed it will try to send again
        context->pc--;
        call Stacks.pushOperand(context, arg);
        call Stacks.pushValue(context, addr);
        call Queue.enqueue(context, &sendWaitQueue, context);
        context->state = BOMB_STATE_SEND_WAIT;
      }
    }
    call Synch.releaseLocks(context, context, state->locks);
    call Synch.yieldContext(context, &(state->readyQueue), state->locks);
    return;
  }

  command result_t BombillaBytecode.execute(uint8_t instr,
					    BombillaContext* context,
					    BombillaState* state) {
    BombillaStackVariable* arg = call Stacks.popOperand(context);
    dbg(DBG_USR1, "VM (%i): Executing sendr.\n", (int)context->which);

    if (context->which == BOMB_CAPSULE_SEND)
      executeSendr(context, arg, state);

    else if (!call Types.checkTypes(context, arg, BOMB_VAR_B)) {return FAIL;}

    else alertSendContext(context, arg, state);

    return SUCCESS;
  }

  event result_t SendPacket.sendDone(TOS_MsgPtr msg, result_t success) {
    BombillaContext* sender = sendingContext;
    BombillaState* state;

    if (sender == NULL) {
      dbg(DBG_USR1, "VM: SendPacket.sendDone event not for sendr. \n");
      return SUCCESS;
    }
    state = sender->vmData;
    dbg(DBG_USR1, "VM: SendPacket.sendDone event fired in sendr op.\n");
    if (state->sendingContext == NULL ||
        sender != state->sendingContext)  {
      dbg(DBG_ERROR, "Error in SendPacket.sendDone event of sendr. \n");
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
    dbg(DBG_USR1, "VM: Send done event fired in sendr.\n");
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
  
  event TOS_MsgPtr ReceivePacket.receive(TOS_MsgPtr msg) {
    return msg;
  }

  event result_t Virus.capsuleInstalled(BombillaCapsule* capsule) {
    //capsuleAnalysis(capsule->type & BOMB_OPTION_MASK);
    return SUCCESS;
  }

  event result_t Virus.enableExecution() {
    return SUCCESS;
  }

  event result_t Virus.disableExecution() {
    return SUCCESS;
  }

  event result_t Virus.capsuleHeard(uint8_t type) {
    return SUCCESS;
  }

  event void Virus.capsuleForce(uint8_t type) {
    return;
  }
  
}
