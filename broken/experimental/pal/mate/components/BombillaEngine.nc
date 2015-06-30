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
 * History:   Apr 11, 2003         Inception.
 *
 */

includes AM;
includes Bombilla;
includes BombillaMsgs;

module BombillaEngine {
  provides {
    interface StdControl;
    interface BombillaError;
    command result_t computeInstruction(BombillaContext* context);
    command result_t executeContext(BombillaContext* context);
  }
  
  uses {
    interface StdControl as SubControlTimer;
    interface StdControl as SubControlNetwork;
    interface StdControl as SubControl;

    interface Timer as ClockTimer;
      
    interface Leds;
    interface Random;

    interface SendMsg as SendError;
    interface ReceiveMsg as ReceivePacket;
    
    interface BombillaStacks as Stacks;
    interface BombillaBuffer as Buffer;
    interface BombillaLocks as Locks;
    interface BombillaContextSynch as Synch;
    interface BombillaInstruction as Instruction;
    interface BombillaQueue as Queue;
    interface BombillaVirus as Virus;
    interface BombillaAnalysis as Analysis;
    
    interface BombillaBytecode as Bytecode[uint8_t bytecode] ;
  }
}


implementation {

  BombillaContext clockContext;
  //  BombillaContext sendContext;
  //BombillaContext recvContext;
  //BombillaContext onceContext;
  BombillaState state;

  command result_t StdControl.init() {
    uint16_t i;

    dbg(DBG_BOOT, "VM: Bombilla initializing.\n");
    call Leds.init();
    call Random.init();

    call SubControlTimer.init();
    call SubControlNetwork.init();
    call SubControl.init();
    
    state.inErrorState = FALSE;

    clockContext.rootCapsule = &state.capsules[BOMB_CAPSULE_CLOCK_INDEX];
    clockContext.state = BOMB_STATE_HALT;
    /*    sendContext.rootCapsule = &state.capsules[BOMB_CAPSULE_SEND_INDEX];
    sendContext.state = BOMB_STATE_HALT;
    recvContext.rootCapsule = &state.capsules[BOMB_CAPSULE_RECV_INDEX];
    recvContext.state = BOMB_STATE_HALT;
    onceContext.rootCapsule = &state.capsules[BOMB_CAPSULE_ONCE_INDEX];
    onceContext.state = BOMB_STATE_HALT; */
    
    call Queue.init(&state.readyQueue);

    for (i = 0; i < BOMB_BUF_NUM; i++) {
      state.buffers[i].type = BOMB_DATA_NONE;
      state.buffers[i].size = 0;
    }

    clockContext.which = BOMB_CAPSULE_CLOCK;
    /*    sendContext.which = BOMB_CAPSULE_SEND;
    recvContext.which = BOMB_CAPSULE_RECV;
    onceContext.which = BOMB_CAPSULE_ONCE; */

    for (i = 0; i < BOMB_HEAPSIZE; i++) {
      state.heap[(int)i].type = BOMB_TYPE_VALUE;
      state.heap[(int)i].value.var = 0;
    }
    
    state.capsules[BOMB_CAPSULE_SUB0].capsule.type = BOMB_CAPSULE_SUB0;
    state.capsules[BOMB_CAPSULE_SUB1].capsule.type = BOMB_CAPSULE_SUB1;
    state.capsules[BOMB_CAPSULE_SUB2].capsule.type = BOMB_CAPSULE_SUB2;
    state.capsules[BOMB_CAPSULE_SUB3].capsule.type = BOMB_CAPSULE_SUB3;
    state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.type = BOMB_CAPSULE_CLOCK;
    state.capsules[BOMB_CAPSULE_RECV_INDEX].capsule.type = BOMB_CAPSULE_RECV;
    state.capsules[BOMB_CAPSULE_SEND_INDEX].capsule.type = BOMB_CAPSULE_SEND;
    state.capsules[BOMB_CAPSULE_ONCE_INDEX].capsule.type = BOMB_CAPSULE_ONCE;

    for (i = 0; i < BOMB_CAPSULE_NUM; i++) {
      state.capsules[i].capsule.type |= BOMB_OPTION_FORWARD;
      //      if (TOS_LOCAL_ADDRESS == 25 &&
      //	  i == BOMB_CAPSULE_CLOCK_INDEX) {
	//state.capsules[i].capsule.version = 1;
	//state.capsules[i].capsule.type |= BOMB_OPTION_FORWARD;
      //}
      //else {
	state.capsules[i].capsule.version = 0;
	//}
      call Virus.registerCapsule(state.capsules[i].capsule.type,
				 &(state.capsules[i].capsule));
    }

    {
      int pc = 0;
      state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.code[pc++] = OPpushc|1;
      state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.code[pc++] = OPgetvar|1;
      state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.code[pc++] = OPadd;
      state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.code[pc++] = OPcopy;
      state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.code[pc++] = OPpushc|7;
      state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.code[pc++] = OPland;
      state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.code[pc++] = OPputled;
      state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.code[pc++] = OPsetvar|1;
      state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.code[pc++] = OPhalt;
    }

    call Analysis.analyzeCapsuleVars(&state, BOMB_CAPSULE_CLOCK_INDEX);
    
    return SUCCESS;
  }

  task void ClockTask() {
    call computeInstruction(&clockContext);
    if (clockContext.state == BOMB_STATE_RUN) {
      post ClockTask();
    }
  }
  /*
  task void SendTask() {
        call computeInstruction(&sendContext);
    if (sendContext.state == BOMB_STATE_RUN) {
      post SendTask();
    }
  }
  
  task void RecvTask() {
    call computeInstruction(&recvContext);
    if (recvContext.state == BOMB_STATE_RUN) {
      post RecvTask();
    }
  }
  
  task void OnceTask() {
    call computeInstruction(&onceContext);
    if (onceContext.state == BOMB_STATE_RUN) {
      post OnceTask();
    }
  }
  */
  command result_t executeContext(BombillaContext* context) {
    if (context->state != BOMB_STATE_RUN) {return FAIL;}
    switch(context->which) {
    case BOMB_CAPSULE_CLOCK:
      return post ClockTask();
      /*   case BOMB_CAPSULE_SEND:
      return post SendTask();
    case BOMB_CAPSULE_RECV:
      return post RecvTask();
    case BOMB_CAPSULE_ONCE:
      return post OnceTask();
      case BOMB_CAPSULE_OUTER: */
    default:
      dbg(DBG_ERROR, "VM: Tried to run context not yet supported: %i\n", context->which);
      return FAIL;
    }
    return FAIL;
  }

  command result_t StdControl.start() {
    result_t res1, res2;
    dbg(DBG_BOOT, "VM: Starting.\n");
    res1 = call SubControlTimer.start();
    res2 = call SubControlNetwork.start();
    res2 = call SubControl.start();
    call ClockTimer.start(TIMER_REPEAT, 1024);
    return rcombine(res1, res2);
  }

  command result_t StdControl.stop() {
    result_t res1, res2;
    dbg(DBG_BOOT, "VM: Stopping.\n");
    call ClockTimer.stop();
    res1 = call SubControlTimer.stop();
    res2 = call SubControlNetwork.stop();
    res2 = call SubControl.stop();
    return rcombine(res1, res2);
  }
  
  command result_t BombillaError.error(BombillaContext* context, uint8_t cause) {
    state.inErrorState = TRUE;
    dbg(DBG_ERROR|DBG_USR1, "VM: Entering ERROR state. Context: %i, cause %i\n", (int)context->which, (int)cause);
    call Leds.redOn();
    call Leds.greenOn();
    call Leds.yellowOn();
    state.errorContext = context;
    if (context != NULL) {
      state.errorContext = context;
      state.errorMsg.context = context->which;
      state.errorMsg.reason = cause;
      state.errorMsg.capsule = context->capsule->capsule.type;
      state.errorMsg.instruction = context->pc - 1;
      context->state = BOMB_STATE_HALT;
    }
    else {
      state.errorMsg.context = BOMB_CAPSULE_INVALID;
      state.errorMsg.reason = cause;
      state.errorMsg.capsule = BOMB_CAPSULE_INVALID;
      state.errorMsg.instruction = 255;
    }
    return SUCCESS;
  }

  task void ClockErrorTask() {
    dbg(DBG_USR1|DBG_ERROR, "VM: ERROR\n");
    call Leds.redToggle();
    call Leds.greenToggle();
    call Leds.yellowToggle();
    nmemcpy(state.errorContext->msg.data,
	    &state.errorMsg,
	    sizeof(BombillaErrorMsg));

    if (state.errorFlipFlop) {
      call SendError.send(TOS_UART_ADDR,
			  sizeof(BombillaErrorMsg),
			  (TOS_MsgPtr)&(state.errorContext->msg));
    }
    else {
      call SendError.send(TOS_BCAST_ADDR,
			  sizeof(BombillaErrorMsg),
			  (TOS_MsgPtr)&(state.errorContext->msg));
    }
    state.errorFlipFlop = !state.errorFlipFlop;
  }
    
  task void ClockEventTask() {
    if (clockContext.state == BOMB_STATE_HALT) {
      call Synch.initializeContext(&clockContext, &state);
      clockContext.state = BOMB_STATE_RUN;
      //initializeContext(&clockContext);
      call Synch.resumeContext(&clockContext, &clockContext, &(state.readyQueue), state.locks);
      //resumeContext(&clockContext, &clockContext);
    }
    else {
      dbg(DBG_TEMP, "VM: Clock context not halted.\n");
      // Can log a clock miss error here, but probably
      // not a good idea
    }
  }

  event result_t ClockTimer.fired() {
    if (state.inErrorState) {post ClockErrorTask();}
    else {post ClockEventTask();}
    return SUCCESS;
  }

  event result_t SendError.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }
  
  event TOS_MsgPtr ReceivePacket.receive(TOS_MsgPtr msg) {
    return msg;
  }
  
  command result_t computeInstruction(BombillaContext* context) {
    uint8_t instr = context->capsule->capsule.code[(int)context->pc];
    //	dbg(DBG_USR1, "VM (%hhi): Issuing instruction 0x%hhx.\n", context->which, instr);
    if (context->state != BOMB_STATE_RUN) {
      dbg(DBG_ERROR, "VM: (%hhi) Tried to execute instruction in non-run state: %hhi\n", context->which, context->state);
      return FAIL;
    }
    context->pc++;
    call Bytecode.execute[instr](instr, context, &state);
    return SUCCESS;  
  }

  default command result_t Bytecode.execute[uint8_t opcode](uint8_t instr,
							    BombillaContext* context,
							    BombillaState* vmState) {
    dbg(DBG_ERROR|DBG_USR1, "VM: Executing default instruction: halt!\n");
    context->state = BOMB_STATE_HALT;
    return FAIL;
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

  event result_t Synch.makeRunnable(BombillaContext* context) {
    context->state = BOMB_STATE_RUN;
    return call executeContext(context);
  }

}
