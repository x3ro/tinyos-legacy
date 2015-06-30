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
 * History:   Jul 19, 2002         Created
 *	      Aug 20, 2002         Instruction set (sans EEPROM)
 *            Aug 23, 2002         Capsule forwarding
 *            Sep 12, 2002         Race prevention (capsule forcing)
 *            Apr 11, 2003         Re-organization, viral component
 *
 */

includes AM;
includes Bombilla;
includes BombillaMsgs;

module BombillaCore {
  provides {
    interface StdControl;
    interface BombillaError;
    command result_t computeInstruction(BombillaContext* context);
    command result_t executeContext(BombillaContext* context);
    event result_t sendDone();
  }
  
  uses {
    interface StdControl as StdControlTimer;
    interface StdControl as StdControlPhoto;
    interface StdControl as StdControlTemp;
    interface StdControl as StdControlNetwork;
    
    interface Timer as ClockTimer;
    interface Timer as TimeoutTimer;
      
    interface Leds;
    interface Random;
    interface Pot;

    interface ADC as PhotoADC;
    interface ADC as TempADC;

    interface SendMsg as SendPacket;
    interface SendData as SendAdHoc;
    interface SendMsg as SendError;

    interface ReceiveMsg as ReceivePacket;
    
    command result_t isAdHocActive();
    command uint16_t networkActivity();
    
    interface BombillaStacks as Stacks;
    interface BombillaBuffer as Buffer;
    interface BombillaLocks as Locks;
    interface BombillaSynch as Synch;
    interface BombillaInstruction as Instruction;
    interface BombillaQueue as Queue;
    interface BombillaVirus as Virus;
  }
}


implementation {

  BombillaContext clockContext;
  BombillaContext sendContext;
  BombillaContext recvContext;
  BombillaContext onceContext;
  BombillaState state;
  
  /*
    BombillaCapsuleBuffer capsules[BOMB_CAPSULE_NUM];
  BombillaDataBuffer buffer0;
  BombillaDataBuffer buffer1;
  BombillaDataBuffer sendrBuffer;
  BombillaDataBuffer recvBuffer;
  
  BombillaStackVariable heap[BOMB_HEAPSIZE];
  BombillaLock locks[BOMB_HEAPSIZE];

  BombillaQueue sendWaitQueue;
  BombillaContext* sendingContext;
  
  BombillaQueue logWaitQueue;
  BombillaContext* loggingContext;

  BombillaQueue senseWaitQueue;
  BombillaContext* sensingContext;

  BombillaContext* errorContext;
  BombillaErrorMsg errorMsg;
  
  BombillaQueue sendrWaitQueue;
  
  BombillaQueue readyQueue;
  bool inErrorState;
  bool errorFlipFlop; // Send to UART or Radio?
  
  TOS_Msg forwardingBuffer;
  bool tryingToForward;
  uint8_t forwardingCapsule; */


  void analyzeCapsuleVars(BombillaCapsuleBuffer* buffers, uint8_t which);
  void analyzeCapsuleCalls(BombillaCapsuleBuffer* buffers, uint8_t which);
  
  void initializeContext(BombillaContext* context) {
    context->heldSet = 0;
    context->releaseSet = 0;
    context->capsule = context->rootCapsule;
    context->acquireSet = context->capsule->usedVars;
    context->pc = 0;
    Stacks.resetStacks(context);
    if (state.sendingContext == context) {
      state.sendingContext = NULL;
    }
    if (state.loggingContext == context) {
      state.loggingContext = NULL;
    }
    if (state.sendingContext == context) {
      state.sensingContext = NULL;
    }
    context->state = BOMB_STATE_HALT;
  }

  bool resumeContext(BombillaContext* caller, BombillaContext* context) {
    context->state = BOMB_STATE_RESUMING;
    if (call Synch.isRunnable(context, state.locks)) {
      call Synch.obtainLocks(caller, context, state.locks);
      context->state = BOMB_STATE_RUN;
      call executeContext(context);
      dbg(DBG_USR2, "VM (%i): Resumption of %i successful.\n", (int)caller->which, (int)context->which);
      return TRUE;
    }
    else {
      call Queue.enqueue(caller, &state.readyQueue, context);
      return FALSE;
    }	
  }

  /*
   * The correctness of this code is a little tricky. Basically, what
   * we need to ensure is that we only check each context for
   * runnability once. The only way to effectively do this is to keep
   * track of the first checked context that's still on the queue (if
   * it was checked and started running, we no longer have a handle on
   * it). This is where the if (start == NULL) piece of code comes in;
   * start is set to be the first context that is not made
   * runnable. If that context is ever encountered again (start ==
   * current), control breaks out of loop. If all contexts are made
   * runnable, then Queue.empty() will return true and the loop will
   * terminate (the while clause at the end).
   *
   * I fully acknowledge that "tricky" is a bad adjective for code,
   * and means I'm probably doing this wrong. It works, though...
   */
  void yieldContext(BombillaContext* context) {
    BombillaContext* start = NULL;
    BombillaContext* current = NULL;
    dbg(DBG_USR2, "VM (%i): Yielding.\n", (int)context->which);
    if (!call Queue.empty(&state.readyQueue)) {
      do {
	current = call Queue.dequeue(context, &state.readyQueue);
	if (!resumeContext(context, current)) {
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
      while (!call Queue.empty(&state.readyQueue));
    }
    else {
      dbg(DBG_USR2, "VM (%i): Ready queue empty.\n", (int)context->which);
    }
  }

  void haltContext(BombillaContext* context) {
    call Synch.releaseAllLocks(context, context, state.locks);
    yieldContext(context);
    context->state = BOMB_STATE_HALT;
    if ((context->which == BOMB_CAPSULE_SEND_INDEX) &&
	!call Queue.empty(&state.sendrWaitQueue)) {
      BombillaContext* waiter = call Queue.dequeue(context, &state.sendrWaitQueue);
      resumeContext(context, waiter);
    }
  }

  void initializeProgram() {
    int pc = 0;
    state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.code[pc++] = OPpushc | 1;
    state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.code[pc++] = OPgetvar | 0;
    state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.code[pc++] = OPadd;
    state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.code[pc++] = OPcopy;
    state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.code[pc++] = OPsetvar | 0;
    state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.code[pc++] = OPpushc | 7;
    state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.code[pc++] = OPland;
    state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.code[pc++] = OPputled;
    state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.code[pc++] = OPhalt;  
    state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.version = 0;
    
    analyzeCapsuleVars(state.capsules, BOMB_CAPSULE_CLOCK_INDEX);
    analyzeCapsuleVars(state.capsules, BOMB_CAPSULE_SEND_INDEX);
    analyzeCapsuleVars(state.capsules, BOMB_CAPSULE_RECV_INDEX);
    
  }
  
  command result_t StdControl.init() {
    uint16_t i;

    dbg(DBG_BOOT, "VM: Bombilla initializing.\n");
    call Leds.init();
    call Random.init();

    call StdControlTimer.init();
    call StdControlPhoto.init();
    call StdControlTemp.init();
    /* EEPROM functionality is currently not implemented. */
    //    call StdControlEEPROM.init();
    call StdControlNetwork.init();
    
    state.inErrorState = FALSE;

    clockContext.rootCapsule = &state.capsules[BOMB_CAPSULE_CLOCK_INDEX];
    clockContext.state = BOMB_STATE_HALT;
    sendContext.rootCapsule = &state.capsules[BOMB_CAPSULE_SEND_INDEX];
    sendContext.state = BOMB_STATE_HALT;
    recvContext.rootCapsule = &state.capsules[BOMB_CAPSULE_RECV_INDEX];
    recvContext.state = BOMB_STATE_HALT;
    onceContext.rootCapsule = &state.capsules[BOMB_CAPSULE_ONCE_INDEX];
    onceContext.state = BOMB_STATE_HALT;
    
    call Queue.init(&state.sendWaitQueue);
    state.sendingContext = NULL;
    call Queue.init(&state.logWaitQueue);
    state.loggingContext = NULL;
    call Queue.init(&state.senseWaitQueue);
    state.sensingContext = NULL;

    call Queue.init(&state.sendrWaitQueue);
    call Queue.init(&state.readyQueue);

    state.buffer0.type = BOMB_DATA_NONE;
    state.buffer0.size = 0;
    state.buffer1.type = BOMB_DATA_NONE;
    state.buffer1.size = 0;

    clockContext.which = BOMB_CAPSULE_CLOCK;
    sendContext.which = BOMB_CAPSULE_SEND;
    recvContext.which = BOMB_CAPSULE_RECV;
    onceContext.which = BOMB_CAPSULE_ONCE;

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
      //capsules[i].capsule.version = 0;
      //capsules[i].capsule.options = 0;
      call Virus.registerCapsule(state.capsules[i].capsule.type,
				 &(state.capsules[i].capsule));
    }
    
    initializeProgram();
    
    if (TOS_LOCAL_ADDRESS == 1) {
      state.capsules[BOMB_CAPSULE_CLOCK_INDEX].capsule.version = 3;
    }

    return SUCCESS;
  }

  uint8_t checkTypes(BombillaContext* context,
		     BombillaStackVariable* var,
		     uint8_t types) {
    uint8_t rval = (uint8_t)(var->type & types);
    if (!rval) {
      dbg(DBG_USR1|DBG_ERROR, "VM: Operand failed type check: type = %i, allowed types = %i\n", (int)var->type, (int)types);
      call BombillaError.error(context, BOMB_ERROR_TYPE_CHECK);
    }
    return rval;
  }

  task void ClockTask() {
    //	dbg(DBG_USR1, "VM: Running clock context.\n");
    call computeInstruction(&clockContext);
    if (clockContext.state == BOMB_STATE_RUN) {
      post ClockTask();
    }
  }

  task void SendTask() {
    //    dbg(DBG_USR1, "VM: Running send context.\n");
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

  command result_t executeContext(BombillaContext* context) {
    if (context->state != BOMB_STATE_RUN) {return FAIL;}
    switch(context->which) {
    case BOMB_CAPSULE_CLOCK:
      return post ClockTask();
    case BOMB_CAPSULE_SEND:
      return post SendTask();
    case BOMB_CAPSULE_RECV:
      return post RecvTask();
    case BOMB_CAPSULE_ONCE:
      return post OnceTask();
    case BOMB_CAPSULE_OUTER:
    default:
      dbg(DBG_ERROR, "VM: Tried to run context not yet supported: %i\n", context->which);
      return FAIL;
    }
    return FAIL;
  }

  command result_t StdControl.start() {
    result_t res1, res2, res3, res4;
    dbg(DBG_BOOT, "VM: Bombilla starting.\n");
    
    res1 = call StdControlTimer.start();
    res2 = call StdControlPhoto.start();
    res3 = call StdControlTemp.start();
    /* EEPROM functionality is currently not implemented. */
    //    call StdControlEEPROM.start();
    res4 = call StdControlNetwork.start();

    call ClockTimer.start(TIMER_REPEAT, 1024);
   return rcombine3(res1, res2, rcombine(res3, res4));
  }

  command result_t StdControl.stop() {
    result_t res1, res2, res3, res4;

    res1 = call StdControlTimer.stop();
    res2 = call StdControlPhoto.stop();
    res3 = call StdControlTemp.stop();
    /* EEPROM functionality is currently not implemented. */
    //    call StdControlEEPROM.stop();
    res4 = call StdControlNetwork.stop();

    return rcombine3(res1, res2, rcombine(res3, res4));
  }
  
  command result_t BombillaError.error(BombillaContext* context, uint8_t cause) {
    state.inErrorState = TRUE;
    dbg(DBG_ERROR|DBG_USR1, "VM: Entering ERROR state. Context: %i, cause %i\n", (int)context->which, (int)cause);
    call Leds.redOn();
    call Leds.greenOn();
    call Leds.yellowOn();
    state.errorContext = context;
    state.errorMsg.context = context->which;
    state.errorMsg.reason = cause;
    state.errorMsg.capsule = context->capsule->capsule.type;
    state.errorMsg.instruction = context->pc - 1;
    return SUCCESS;
  }

  task void ClockErrorTask() {
    dbg(DBG_USR1|DBG_ERROR, "VM: ERROR\n");
    call Leds.redToggle();
    call Leds.greenToggle();
    call Leds.yellowToggle();
    nmemcpy(state.errorContext->msg.data, &state.errorMsg, sizeof(BombillaErrorMsg));
    if (state.errorFlipFlop) {
      call SendError.send(TOS_UART_ADDR, sizeof(BombillaErrorMsg), (TOS_MsgPtr)&(state.errorContext->msg));
    }
    else {
      call SendError.send(TOS_BCAST_ADDR, sizeof(BombillaErrorMsg), (TOS_MsgPtr)&(state.errorContext->msg));
    }
    state.errorFlipFlop = !state.errorFlipFlop;
  }
    
  task void ClockEventTask() {
    if (clockContext.state == BOMB_STATE_HALT) {
      initializeContext(&clockContext);
      resumeContext(&clockContext, &clockContext);
    }
    else {
      // Can log a clock miss error here, but probably
      // not a good idea
    }
  }

  event result_t ClockTimer.fired() {
    //dbg(DBG_USR1|DBG_TEMP, "VM: Clock event fired: %lli\n",
    //tos_state.tos_time);
    if (state.inErrorState) {
      post ClockErrorTask();
    }
    else {
      post ClockEventTask();
    }
    return SUCCESS;
  }

  void analyzeCapsuleVars(BombillaCapsuleBuffer* buffers, uint8_t which) {
    int i;
    BombillaCapsuleBuffer* buf = &(state.capsules[(int)which]);
    buf->usedVars = 0;
    for (i = 0; i < BOMB_PGMSIZE; i++) {
      if (call  Instruction.isVClass(buf->capsule.code[i])) {
	uint8_t arg = (buf->capsule.code[i]) & VARG_MASK;
	buf->usedVars |= (1 << arg);
      }
    }
  }

  void analyzeCapsuleCalls(BombillaCapsuleBuffer* buffers, uint8_t which) {
    int i;
    BombillaCapsuleBuffer* buf = &(state.capsules[(int)which]);
    for (i = 0; i < BOMB_PGMSIZE; i++) {
      if ((buf->capsule.code[i] & 0xfc) == OPcall0) {
	uint8_t arg = (buf->capsule.code[i]) & 0x3;
	buf->usedVars |= buffers[(int)arg].usedVars;
      }
    }
  }
  
  void executeSense(BombillaContext* context, uint8_t type) {
    BombillaQueue* queue = &state.senseWaitQueue;
    // cli()/sei() is safe because we are always in task context here
    cli();
    if (state.sensingContext != NULL) {
      call Stacks.pushValue(context, type);
      context->state = BOMB_STATE_SENSE_WAIT;
      call Queue.enqueue(context, queue, context);
      sei();
    }
    else {
      sei();
      switch(type) {
	// Be sure to handle sensingContext/senseQueue properly
	// so that sense done events don't traverse a null pointer.
      case BOMB_DATA_PHOTO:
	dbg(DBG_USR1, "VM (%i): Sensing photo.\n", (int)context->which);
	if (call PhotoADC.getData() == SUCCESS) {
	  state.sensingContext = context;
	  context->state = BOMB_STATE_SENSE;
	}
	else { // re-issue the instruction
	  call Stacks.pushValue(context, type);
	  context->pc--;
	}
	break;
      case BOMB_DATA_TEMP:
	dbg(DBG_USR1, "VM (%i): Sensing temperature.\n", (int)context->which);
	if (call TempADC.getData() == SUCCESS) {
	  state.sensingContext = context;
	  context->state = BOMB_STATE_SENSE;
	}
	else { // re-issue the instruction
	  call Stacks.pushValue(context, type);
	  context->pc--;
	}
	break;
      default:
	dbg(DBG_ERROR, "VM (%i): Sensor type %i not supported yet.\n", (int)context->which, (int)type);
	call BombillaError.error(context, BOMB_ERROR_INVALID_TYPE);
      }
    }
  }

  void executeAdd(BombillaContext* context, BombillaStackVariable* arg1, BombillaStackVariable* arg2) {
    if ((arg1->type == BOMB_TYPE_VALUE) && (arg2->type == BOMB_TYPE_VALUE)) {
      dbg(DBG_USR1, "VM (%i): Executing add of two values: %i + %i == %i\n", (int)context->which, (int)arg1->value.var, (int)arg2->value.var, (int)arg1->value.var + arg2->value.var);
      call Stacks.pushValue(context, arg1->value.var + arg2->value.var);
	
    }
    else if (arg1->type == BOMB_TYPE_BUFFER) {
      if (arg2->type != BOMB_TYPE_BUFFER) {
	dbg(DBG_USR1, "VM (%i): Prepend value onto buffer.\n", (int)context->which);
	call Buffer.prepend(context, arg1->buffer.var, arg2);
      }
      else {
	dbg(DBG_USR1, "VM (%i): Concatenating buffers.\n", (int)context->which);
	call Buffer.concatenate(context, arg2->buffer.var, arg1->buffer.var);			
      }
      call Stacks.pushBuffer(context, arg1->buffer.var);
    }
    else if (arg2->type == BOMB_TYPE_BUFFER) {
      call Buffer.append(context, arg2->buffer.var, arg1);
      call Stacks.pushBuffer(context, arg2 ->buffer.var);
    }
    else {
      call BombillaError.error(context, BOMB_ERROR_TYPE_CHECK);
      dbg(DBG_USR1, "VM (%i): Invalid add.\n", (int)context->which);
    }
  }

  void executeSendr(BombillaContext* context, BombillaStackVariable* arg) {
    if ((context->which != BOMB_CAPSULE_SEND) ||
	(!checkTypes(context, arg, BOMB_VAR_V))) {
      context->state = BOMB_STATE_HALT;
      return;
    }
    else {
      uint16_t addr = arg->value.var;
      uint8_t size;
      arg = call Stacks.popOperand(context);
      if (!checkTypes(context, arg, BOMB_VAR_B)) {return;}
      size = arg->buffer.var->size;
      size += sizeof(arg->buffer.var->type);
      size += sizeof(arg->buffer.var->size);
      nmemcpy(context->msg.data, arg->buffer.var, size);
      if (call SendPacket.send(addr, size, &context->msg)) {
	state.sendingContext = context;
	context->state = BOMB_STATE_SENDING;
      }
      else {
	// Back up context so on being resumed it will try to send again
	context->pc--;
	call Stacks.pushOperand(context, arg);
	call Stacks.pushValue(context, addr);
	call Queue.enqueue(context, &state.sendWaitQueue, context);
	context->state = BOMB_STATE_SEND_WAIT;
      }
    }
    call Synch.releaseLocks(context, context, state.locks);
    yieldContext(context);
    return;
  }
  
  bool areEqual(BombillaStackVariable* arg1, BombillaStackVariable* arg2) {
    if (arg1->type != arg2->type) {return FALSE;}
    if (arg1->type == BOMB_TYPE_SENSE) {
      return ((arg1->sense.type == arg2->sense.type) &&
	      (arg1->sense.var == arg2->sense.var));
    }
    else if (arg1->type == BOMB_TYPE_VALUE) {
      return (arg1->value.var == arg2->value.var);
    }
    else if (arg1->type == BOMB_TYPE_BUFFER) {
      return (arg1->buffer.var == arg2->buffer.var);
    }
    else {
      return FALSE;
    }
  }

  bool typeEqual(BombillaStackVariable* arg1, BombillaStackVariable* arg2) {
    return (arg1->type == arg2->type);
  }

  void ledOP(uint16_t arg) {
    uint8_t op = (arg >> 3) & 3;
    uint8_t led = arg & 7;
    switch (op) {
    case 0:			/* set */
      if (led & 1) call Leds.redOn();
      else call Leds.redOff();
      if (led & 2) call Leds.greenOn();
      else call Leds.greenOff();
      if (led & 4) call Leds.yellowOn();
      else call Leds.yellowOff();
      break;
    case 1:			/* OFF 0 bits */
      if (!(led & 1)) call Leds.redOff();
      if (!(led & 2)) call Leds.greenOff();
      if (!(led & 4)) call Leds.yellowOff();
      break;
    case 2:			/* on 1 bits */
      if (led & 1) call Leds.redOn();
      if (led & 2) call Leds.greenOn();
      if (led & 4) call Leds.yellowOn();
      break;
    case 3:			/* TOGGLE 1 bits */
      if (led & 1) call Leds.redToggle();
      if (led & 2) call Leds.greenToggle();
      if (led & 4) call Leds.yellowToggle();
      break;
    default:
      dbg(DBG_ERROR, ("VM: LED command had unknown operations.\n"));
    }
  }  

  event result_t TimeoutTimer.fired() {
    return SUCCESS;
  }


  inline result_t senseReady(uint16_t datum) {
    BombillaContext* senser;
    BombillaQueue* queue = &state.senseWaitQueue;
    dbg(DBG_USR1, "VM: Sensor reading: %i\n", (int)datum);
    if (state.sensingContext != NULL) {
      // Resume the sensing context
      state.sensingContext->state = BOMB_STATE_RUN;
      resumeContext(state.sensingContext, state.sensingContext);
      call Stacks.pushReading(state.sensingContext, BOMB_DATA_PHOTO, datum);
      state.sensingContext = NULL;
    }
    if (!call Queue.empty(queue)) {
      senser = call Queue.dequeue(&clockContext, queue);
      if (senser->state != BOMB_STATE_SENSE_WAIT) {
	call BombillaError.error(senser, BOMB_ERROR_QUEUE_INVALID);
      }
      senser->state = BOMB_STATE_RUN;
      resumeContext(senser, senser);
    }
    return SUCCESS;
  }
  event result_t PhotoADC.dataReady(uint16_t datum) {
    return senseReady(datum);
  }

  event result_t TempADC.dataReady(uint16_t datum) {
    return senseReady(datum);
  }

  /* Acceleration sensor not supported yet
     event result_t AccelXADC.dataReady(uint16_t data) {
     return SUCCESS;
     }

     event result_t AccelYADC.dataReady(uint16_t data) {
     return SUCCESS;
     }
  */

  event result_t SendPacket.sendDone(TOS_MsgPtr msg, result_t success) {
    BombillaContext* sender = state.sendingContext;
    dbg(DBG_USR1, "VM: SendPacket.sendDone event fired.\n");
    if (sender == NULL) {return FAIL;}

    state.sendingContext = NULL;
    if (sender->state != BOMB_STATE_SENDING) {
      call BombillaError.error(sender, BOMB_ERROR_QUEUE_INVALID);
      return FAIL;
    }
    resumeContext(sender, sender);
    return SUCCESS;
  }

  event result_t SendAdHoc.sendDone(uint8_t* buffer, result_t success) {
    BombillaContext* sender = state.sendingContext;
    dbg(DBG_USR1, "VM: Ad hoc send completed with code %i\n", (int)success);
    if (sender == NULL) {return FAIL;}

    state.sendingContext = NULL;
    if (sender->state != BOMB_STATE_SENDING) {
      call BombillaError.error(sender, BOMB_ERROR_QUEUE_INVALID);
      return FAIL;
    }
    resumeContext(sender, sender);
    return SUCCESS;
  }
  
  event result_t SendError.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }

  /** 
   * Install a new capsule and compute locks sets for all caspules
   * possibly modified by this installation.
   */

  void capsuleAnalysis(uint8_t which) {
    state.inErrorState = FALSE;
    dbg(DBG_USR1, "VM: Analyzing new capsule: %i\n", (int)which);
    if (which <= BOMB_CAPSULE_SUB3) {
      int i;
      initializeContext(&clockContext);
      initializeContext(&sendContext);
      initializeContext(&recvContext);
      initializeContext(&onceContext);
      analyzeCapsuleVars(state.capsules, which);
      for (i = 0; i < BOMB_CAPSULE_SUB3; i++) {
	analyzeCapsuleCalls(state.capsules, BOMB_CAPSULE_SUB0);
	analyzeCapsuleCalls(state.capsules, BOMB_CAPSULE_SUB1);
	analyzeCapsuleCalls(state.capsules, BOMB_CAPSULE_SUB2);
	analyzeCapsuleCalls(state.capsules, BOMB_CAPSULE_SUB3);
      }
      analyzeCapsuleCalls(state.capsules, BOMB_CAPSULE_CLOCK_INDEX);
      analyzeCapsuleCalls(state.capsules, BOMB_CAPSULE_SEND_INDEX);
      analyzeCapsuleCalls(state.capsules, BOMB_CAPSULE_RECV_INDEX);
      analyzeCapsuleCalls(state.capsules, BOMB_CAPSULE_ONCE_INDEX);
    }
    else if (which == BOMB_CAPSULE_CLOCK) {
      int capsuleIndex = BOMB_CAPSULE_CLOCK_INDEX;
      initializeContext(&clockContext);
      analyzeCapsuleVars(state.capsules, capsuleIndex);
      analyzeCapsuleCalls(state.capsules, capsuleIndex);
    }
    else if (which == BOMB_CAPSULE_SEND) {
      int capsuleIndex = BOMB_CAPSULE_SEND_INDEX;
      initializeContext(&sendContext);
      analyzeCapsuleVars(state.capsules, capsuleIndex);
      analyzeCapsuleCalls(state.capsules, capsuleIndex);
    }
    else if (which == BOMB_CAPSULE_RECV) {
      int capsuleIndex = BOMB_CAPSULE_RECV_INDEX;
      initializeContext(&recvContext);
      analyzeCapsuleVars(state.capsules, capsuleIndex);
      analyzeCapsuleCalls(state.capsules, capsuleIndex);
    }
    else if (which == BOMB_CAPSULE_ONCE) {
      int capsuleIndex = BOMB_CAPSULE_ONCE_INDEX;
      /* !!! This doesn't look right: analysis can occur
	 even when a capsule isn't installed (e.g., subroutine install). */
      dbg(DBG_USR1, "VM: Installing once capsule, resuming.\n");
      initializeContext(&onceContext);
      analyzeCapsuleVars(state.capsules, capsuleIndex);
      analyzeCapsuleCalls(state.capsules, capsuleIndex);
      //resumeContext(&onceContext, &onceContext);
    }
  }
  
  event TOS_MsgPtr ReceivePacket.receive(TOS_MsgPtr msg) {
    if (!msg->crc) {return msg;}
    if (recvContext.state != BOMB_STATE_HALT) {
      dbg(DBG_USR1, "VM: Received packet, receive context busy, drop.\n");
    }
    else {
      int i;
      BombillaPacket* packet = (BombillaPacket*)(msg->data);
      BombillaDataBuffer* buffer = (BombillaDataBuffer*)&(packet->payload);
      dbg(DBG_USR1, "VM: Received packet, enqueuing receive context to run.\n");
      dbg(DBG_USR1, "VM: Copying %i bytes of header over:\n  ", sizeof(recvContext.header));
      for (i = 0; i < sizeof(recvContext.header); i++) {
	dbg_clear(DBG_USR1, "%02hhx", packet->header[i]);
      }
      dbg_clear(DBG_USR1, "\n->");
      nmemcpy(&(recvContext.header), packet->header, sizeof(recvContext.header));
      for (i = 0; i < sizeof(recvContext.header); i++) {
	dbg_clear(DBG_USR1, "%02hhx", ((uint8_t*)recvContext.header)[i]);
      }
      dbg_clear(DBG_USR1, "\n");
      nmemcpy(&(state.recvBuffer), buffer, sizeof(BombillaDataBuffer));
      initializeContext(&recvContext);
      call Stacks.pushBuffer(&recvContext, &state.recvBuffer);
      resumeContext(&recvContext, &recvContext);
    }
    return msg;
  }

  event result_t sendDone() { // Generic sendDone
    BombillaContext* sender;
    dbg(DBG_USR1, "VM: Send done event fired.\n");
    if (call Queue.empty(&state.sendWaitQueue)) {return FAIL;}
    sender = call Queue.dequeue(&clockContext, &state.sendWaitQueue);
    if (sender->state != BOMB_STATE_SEND_WAIT) {
      call BombillaError.error(sender, BOMB_ERROR_QUEUE_INVALID);
    }
    sender->state = BOMB_STATE_RUN;
    call executeContext(sender);
    return SUCCESS;
  }

  void execute0ClassInstruction(BombillaContext* context, uint8_t instr) {
    switch(instr) {
    case OPhalt:
      dbg(DBG_USR1, "VM (%i): Halting.\n", (int)context->which);
      haltContext(context);
      break;
    case OPid:
      dbg(DBG_USR1, "VM (%i): Pushing local address: %i.\n", (int)context->which, (int)TOS_LOCAL_ADDRESS);
      call Stacks.pushValue(context, (int16_t)(TOS_LOCAL_ADDRESS & 0xffff));
      break;
    case OPrand: {
      uint16_t rval = call Random.rand();
      dbg(DBG_USR1, "VM (%i): Pushing random number: %hu.\n", (int)context->which, rval);
      call Stacks.pushValue(context, (int16_t)(rval & 0xff));
      break;
    }
    case OPctrue:
      dbg(DBG_USR1, "VM (%i): Setting condition to be true.\n", (int)context->which);
      context->condition = 1;
      break;
    case OPcfalse:
      dbg(DBG_USR1, "VM (%i): Setting condition to be false.\n", (int)context->which);
      context->condition = 0;
      break;
    case OPcpush:
      dbg(DBG_USR1, "VM (%i): Pushing condition onto the stack: %i.\n", (int)context->which, (int)context->condition);
      call Stacks.pushValue(context, (int16_t)context->condition);
      break;
    case OPlogp:
      dbg(DBG_USR1, "VM (%i): Pushing logline onto stack (NOT IMPLEMENTED): %i\n", context->which, 0);
      call Stacks.pushValue(context, 0);
      break;
    case OPbpush0:
      dbg(DBG_USR1, "VM (%i): Pushing buffer 0 onto stack\n", context->which);
      call Stacks.pushBuffer(context, &state.buffer0);
      break;
    case OPbpush1:
      dbg(DBG_USR1, "VM (%i): Pushing buffer 1 onto stack\n", context->which);
      call Stacks.pushBuffer(context, &state.buffer1);
      break;
    case OPdepth: {
      uint8_t depth = call Stacks.getOpStackDepth(context);
      dbg(DBG_USR1, "VM (%i): Pushing op stack depth onto stack: %i\n", context->which, (int)depth);
      call Stacks.pushValue(context, (int16_t)depth);
      break;
    }
    case OPerr:
      call BombillaError.error(context, BOMB_ERROR_TRIGGERED);
      break;
    case OPret:
      dbg(DBG_USR1, "VM (%i): Returning from subroutine.\n", (int)context->which);
      call Stacks.popReturnAddr(context);
      break;
    case OPcall0:
    case OPcall1:
    case OPcall2:
    case OPcall3:
      dbg(DBG_USR1, "VM (%i): Calling subroutine %hhu\n", (int)context->which, (uint8_t)(instr & 0x3));
      call Stacks.pushReturnAddr(context);
      context->capsule = &(state.capsules[instr & 0x3]);
      context->pc = 0;
      break;
    default:
      call BombillaError.error(context, BOMB_ERROR_INVALID_INSTRUCTION);
      dbg(DBG_USR1|DBG_ERROR, "VM (%i): Unrecognized class 0 instruction: %hhx\n", (int)TOS_LOCAL_ADDRESS, instr);
    }
  }

  void execute1ClassInstruction(BombillaContext* context, uint8_t instr) {
    BombillaStackVariable* arg = call Stacks.popOperand(context);
    switch(instr) {
    case OPinv:
      dbg(DBG_USR1, "VM (%i): Inverting top of stack.\n", (int)context->which);
      if (!checkTypes(context, arg, BOMB_VAR_V)) {return;}
      arg->value.var = -(arg->value.var);
      call Stacks.pushOperand(context, arg);
      break;
    case OPcpull:
      dbg(DBG_USR1, "VM (%i): Pulling top of stack to condition.\n", (int)context->which);
      if (!checkTypes(context, arg, BOMB_VAR_V)) {return;}
      context->condition = arg->value.var;
      break;
    case OPnot:
      dbg(DBG_USR1, "VM (%i): Logical not of top of stack.\n", (int)context->which);
      if (!checkTypes(context, arg, BOMB_VAR_V)) {return;}
      arg->value.var = (arg->value.var)? 0:1;
      call Stacks.pushOperand(context, arg);
      break;
    case OPlnot:
      dbg(DBG_USR1, "VM (%i): Logical not of top of stack.\n", (int)context->which);
      if (!checkTypes(context, arg, BOMB_VAR_V)) {return;}
      arg->value.var = ~(arg->value.var);
      call Stacks.pushOperand(context, arg);
      break;
    case OPsense: 
      dbg(DBG_USR1, "VM (%i): Sensing.\n", (int)context->which);
      if (!checkTypes(context, arg, BOMB_VAR_V)) {return;}
      executeSense(context, (uint8_t)arg->value.var);
      call Synch.releaseLocks(context, context, state.locks);
      yieldContext(context);
      break;
    case OPsend:
      dbg(DBG_USR1, "VM (%i): Sending packet with built-in ad-hoc routing.\n", (int)context->which);
      if (!checkTypes(context, arg, BOMB_VAR_B)) {return;}
      else if (!call isAdHocActive()) {
	dbg(DBG_ERROR, "VM (%i): Cannot send: ad-hoc layer not active.\n", (int)context->which);
	return;
      }
      else {
	BombillaDataBuffer* buffer = arg->buffer.var;
	uint8_t len = buffer->size * sizeof(buffer->entries[0]);
	len += sizeof(buffer->type) + sizeof(buffer->size);
				
	if (call SendAdHoc.send((uint8_t*)buffer, len))  {
	  state.sendingContext = context;
	  context->state = BOMB_STATE_SENDING;
	}
	else {
	  // Back up context so on being resumed it will try to send again
	  context->pc--;
	  call Stacks.pushOperand(context, arg);
	  call Queue.enqueue(context, &state.sendWaitQueue, context);
	  context->state = BOMB_STATE_SEND_WAIT;
	}
	call Synch.releaseLocks(context, context, state.locks);
	yieldContext(context);
      }
      break;
    case OPsendr:
      dbg(DBG_USR1, "VM (%i): Executing sendr.\n", (int)context->which);
      if (context->which == BOMB_CAPSULE_SEND) {
	executeSendr(context, arg);
      }
      else if (!checkTypes(context, arg, BOMB_VAR_B)) {return;}
      
      //There's a problem here -- what if send context
      // won't issue a send done?
      else if (sendContext.state == BOMB_STATE_HALT) {
        nmemcpy(&state.sendrBuffer, arg->buffer.var, sizeof(BombillaDataBuffer));
        //call Stacks.resetStacks(&sendContext);
        initializeContext(&sendContext);
        call Stacks.pushBuffer(&sendContext, &state.sendrBuffer);
        //initializeContext(&sendContext);
        resumeContext(context, &sendContext);
        // This yield/resume allows locks to be yielded to the send context,
	// and if none are shared, then it will just continue executing
        if (context->releaseSet) {
          call Synch.releaseLocks(context, context, state.locks);
          yieldContext(context);
          resumeContext(context, context);
        }
      }
      else {
        // Don't send, fail silently -- send context busy
      }
      break;
      
    case OPuart: {
      if (!checkTypes(context, arg, BOMB_VAR_B)) {return;}
      else {
        int i;
        BombillaDataBuffer* buffer = arg->buffer.var;
        uint8_t len = buffer->size * sizeof(buffer->entries[0]);
        len += sizeof(buffer->type) + sizeof(buffer->size);
	
        for (i = 0; i < len; i++) {
          context->msg.data[i] = ((uint8_t*)(buffer))[i];
	}	
	if (call SendPacket.send(TOS_UART_ADDR, len, &context->msg))  {
	  dbg(DBG_USR1, "VM (%i): Sending packet to UART.\n", (int)context->which);
	  state.sendingContext = context;
	  context->state = BOMB_STATE_SENDING;
	}
	else {
	  dbg(DBG_USR1, "VM (%i): UART send request refused. Enqueue and wait.\n", (int)context->which);

	  // Back up context so on being resumed it will try to send again
	  context->pc--;
	  call Stacks.pushOperand(context, arg);
	  call Queue.enqueue(context, &state.sendWaitQueue, context);
	  context->state = BOMB_STATE_SEND_WAIT;
	}
	call Synch.releaseLocks(context, context, state.locks);
	yieldContext(context);
      }
      break;
    }
    case OPlogw:
      dbg(DBG_ERROR, "VM (%i): logw not supported yet\n", (int)context->which);
      break;
    case OPbhead:
      dbg(DBG_USR1, "VM (%i): Yanking head of buffer.\n", (int)context->which);
      if (!checkTypes(context, arg, BOMB_VAR_B)) {return;}
      else {
	BombillaStackVariable var;
	call Buffer.yank(context, arg->buffer.var,
			 0, &var);
	call Stacks.pushOperand(context, arg);
	call Stacks.pushOperand(context, &var);
      }
      break;
    case OPbtail:
      dbg(DBG_USR1, "VM (%i): Yanking tail of buffer.\n", (int)context->which);
      if (!checkTypes(context, arg, BOMB_VAR_B)) {return;}
      else {
	BombillaStackVariable var;
	call Buffer.yank(context, arg->buffer.var,
			 arg->buffer.var->size -1, 
			 &var);
	call Stacks.pushOperand(context, arg);
	call Stacks.pushOperand(context, &var);
      }
      break;
    case OPbclear:
      dbg(DBG_USR1, "VM (%i): Clearing buffer.\n", (int)context->which);
      if (!checkTypes(context, arg, BOMB_VAR_B)) {return;}
      call Buffer.clear(context, arg->buffer.var);
      call Stacks.pushOperand(context, arg);
      break;
    case OPbsize:
      dbg(DBG_USR1, "VM (%i): Pushing size of buffer.\n", (int)context->which);
      if (!checkTypes(context, arg, BOMB_VAR_B)) {return;}
      call Stacks.pushOperand(context, arg);
      call Stacks.pushValue(context, arg->buffer.var->size);
      break;
    case OPcopy:
      dbg(DBG_USR1, "VM (%i): Copying top of stack.\n", (int)context->which);			
      call Stacks.pushOperand(context, arg);
      call Stacks.pushOperand(context, arg);
      break;
    case OPpop:
      break;
    default:
      call BombillaError.error(context, BOMB_ERROR_INVALID_INSTRUCTION);
      dbg(DBG_ERROR, "VM (%i): Unrecognized class 1 instruction: 0x%hhx.\n", (int)context->which, instr);			
    }
  }

  void execute2ClassInstruction(BombillaContext* context, uint8_t instr) {
    BombillaStackVariable* arg = call Stacks.popOperand(context);
	
    switch(instr) {
    case OPbsorta:
      dbg(DBG_USR1, "VM (%i): Sorting buffer ascending.\n", (int)context->which);			
      if (!checkTypes(context, arg, BOMB_VAR_B)) {return;}
      call Buffer.sortAscending(context, arg->buffer.var);
      call Stacks.pushOperand(context, arg);
      break;
    case OPbsortd:
      dbg(DBG_USR1, "VM (%i): Sorting buffer descending.\n", (int)context->which);			
      if (!checkTypes(context, arg, BOMB_VAR_B)) {return;}
      call Buffer.sortDescending(context, arg->buffer.var);
      call Stacks.pushOperand(context, arg);
      break;
    case OPbfull:
      dbg(DBG_USR1, "VM (%i): Checking if buffer full.\n", (int)context->which);			
      if (!checkTypes(context, arg, BOMB_VAR_B)) {return;}
      call Stacks.pushValue(context, (arg->buffer.var->size == BOMB_BUF_LEN)? 1: 0);
      call Stacks.pushOperand(context, arg);
      break;
    case OPputled:
      dbg(DBG_USR1, "VM (%i): Setting LEDs.\n", (int)context->which);			
      if (!checkTypes(context, arg, BOMB_VAR_V)) {return;}
      ledOP(arg->value.var);
      break;
    case OPcast:
      dbg(DBG_USR1, "VM (%i): Casting.\n", (int)context->which);
      if (!checkTypes(context, arg, BOMB_VAR_S)) {return;}
      call Stacks.pushValue(context, arg->sense.var);
      break;
    case OPunlock:
      dbg(DBG_USR1, "VM (%i): Yielding lock", (int)context->which);
      if (!checkTypes(context, arg, BOMB_VAR_V)) {return;}
      if (arg->value.var >= BOMB_HEAPSIZE ||
	  arg->value.var < 0) {
	call BombillaError.error(context, BOMB_ERROR_INVALID_LOCK);
	return;
      }
      dbg_clear(DBG_USR1, " %i\n", (int)arg->value.var);
      context->releaseSet |= (1 << arg->value.var);
      context->acquireSet |= (1 << arg->value.var);
      break;
    case OPunlockb: {
      dbg(DBG_USR1, "VM (%i): Yielding locks", (int)context->which);
      if (!checkTypes(context, arg, BOMB_VAR_V)) {return;}
      if ((arg->value.var & context->heldSet) != arg->value.var) {
	call BombillaError.error(context, BOMB_ERROR_UNLOCK_INVALID);
	return;
      }
      dbg_clear(DBG_USR1, " 0x%hx\n", arg->value.var);
      context->releaseSet |= arg->value.var;
      context->acquireSet |= arg->value.var;
      break;
    }
    case OPpunlock:
      dbg(DBG_USR1, "VM (%i): Releasing lock", (int)context->which);
      if (!checkTypes(context, arg, BOMB_VAR_V)) {return;}
      if (arg->value.var >= BOMB_HEAPSIZE ||
	  arg->value.var < 0) {
	call BombillaError.error(context, BOMB_ERROR_INVALID_LOCK);
	return;
      }
      dbg_clear(DBG_USR1, " %i\n", (int)arg->value.var);
      context->releaseSet |= (1 << arg->value.var);
      break;
    case OPpunlockb:
      dbg(DBG_USR1, "VM (%i): Releasing locks", (int)context->which);
      if (!checkTypes(context, arg, BOMB_VAR_V)) {return;}
      if ((arg->value.var & context->heldSet) != arg->value.var) {
	call BombillaError.error(context, BOMB_ERROR_UNLOCK_INVALID);
	return;
      }
      dbg_clear(DBG_USR1, " 0x%hx\n", arg->value.var);
      context->releaseSet |= arg->value.var;
      break;
    case OPlogwl:
    case OPlogr:
      dbg(DBG_ERROR, "VM (%i): Unimplemented class 2 instruction: 0x%hhx.\n", (int)context->which, instr);			
      break;
    case OPbget: {
      BombillaStackVariable element;
      BombillaStackVariable* arg2 = call Stacks.popOperand(context);
      dbg(DBG_USR1, "Getting element from buffer\n");
      if (!checkTypes(context, arg, BOMB_VAR_V) ||
	  !checkTypes(context, arg2, BOMB_VAR_B)) {return;}
      call Buffer.get(context, arg2->buffer.var, arg->value.var, &element);
      call Stacks.pushOperand(context, arg);
      call Stacks.pushOperand(context, &element);
      break;
    }
    case OPbyank: {
      BombillaStackVariable* arg2 = call Stacks.popOperand(context);
      BombillaStackVariable element;
      dbg(DBG_USR1, "Yanking element from buffer\n");
      if (!checkTypes(context, arg, BOMB_VAR_V) ||
	  !checkTypes(context, arg2, BOMB_VAR_B)) {return;}
      call Buffer.yank(context, arg2->buffer.var, arg->value.var, &element);
      call Stacks.pushOperand(context, arg);
      call Stacks.pushOperand(context, &element);
      break;
    }
    case OPmotectl:
      dbg(DBG_ERROR, "VM (%i): Unimplemented class 2 instruction: 0x%hhx.\n", (int)context->which, instr);			
    default:
      call BombillaError.error(context, BOMB_ERROR_INVALID_INSTRUCTION);
      dbg(DBG_ERROR, "VM (%i): Unrecognized class 2 instruction: 0x%hhx.\n", (int)context->which, instr);			
    }
  }
  void execute3ClassInstruction(BombillaContext* context, uint8_t instr) {
    BombillaStackVariable* arg1 = call Stacks.popOperand(context);
    BombillaStackVariable* arg2 = call Stacks.popOperand(context);
    BombillaStackVariable temp;
	
    switch(instr) {
    case OPswap:
      dbg(DBG_USR1, "VM (%i): Executing swap.\n", (int)context->which);
      temp = *arg2;
      call Stacks.pushOperand(context, arg1);
      call Stacks.pushOperand(context, &temp);
      break;
    case OPland:
      dbg(DBG_USR1, "VM (%i): Executing land.\n", (int)context->which);
      if (!checkTypes(context, arg1, BOMB_VAR_V) ||
	  !checkTypes(context, arg2, BOMB_VAR_V)) {return;}
      call Stacks.pushValue(context, arg1->value.var & arg2->value.var);
      break;
    case OPlor:
      dbg(DBG_USR1, "VM (%i): Executing lor.\n", (int)context->which);
      if (!checkTypes(context, arg1, BOMB_VAR_V) ||
	  !checkTypes(context, arg2, BOMB_VAR_V)) {return;}
      call Stacks.pushValue(context, arg1->value.var | arg2->value.var);
      break;
    case OPand:
      dbg(DBG_USR1, "VM (%i): Executing add.\n", (int)context->which);
      if (!checkTypes(context, arg1, BOMB_VAR_V) ||
	  !checkTypes(context, arg2, BOMB_VAR_V)) {return;}
      call Stacks.pushValue(context, arg1->value.var && arg2->value.var);
      break;
    case OPor:
      dbg(DBG_USR1, "VM (%i): Executing or.\n", (int)context->which);
      if (!checkTypes(context, arg1, BOMB_VAR_V) ||
	  !checkTypes(context, arg2, BOMB_VAR_V)) {return;}
      call Stacks.pushValue(context, arg1->value.var || arg2->value.var);
      break;
    case OPshiftr:
      dbg(DBG_USR1, "VM (%i): Executing shiftr.\n", (int)context->which);
      if (!checkTypes(context, arg1, BOMB_VAR_V) ||
	  !checkTypes(context, arg2, BOMB_VAR_V)) {return;}
      call Stacks.pushValue(context, arg2->value.var >> arg1->value.var);
      break;
    case OPshiftl:
      dbg(DBG_USR1, "VM (%i): Executing shiftl.\n", (int)context->which);
      if (!checkTypes(context, arg1, BOMB_VAR_V) ||
	  !checkTypes(context, arg2, BOMB_VAR_V)) {return;}
      call Stacks.pushValue(context, arg2->value.var << arg1->value.var);
      break;
    case OPadd:
      dbg(DBG_USR1, "VM (%i): Executing add.\n", (int)context->which);
      executeAdd(context, arg1, arg2);
      break;
    case OPmod:
      dbg(DBG_USR1, "VM (%i): Executing add.\n", (int)context->which);
      if (!checkTypes(context, arg1, BOMB_VAR_V) ||
	  !checkTypes(context, arg2, BOMB_VAR_V)) {return;}
      call Stacks.pushValue(context, arg2->value.var % arg1->value.var);
      break;
    case OPeq:
      dbg(DBG_USR1, "VM (%i): Executing eq.\n", (int)context->which);
      call Stacks.pushValue(context, areEqual(arg1, arg2));
      break;
    case OPneq:
      dbg(DBG_USR1, "VM (%i): Executing neq.\n", (int)context->which);
      call Stacks.pushValue(context, !areEqual(arg1, arg2));
      break;
    case OPlt:
      if ((arg1->type == BOMB_VAR_V) &&
	  (arg2->type == BOMB_VAR_V)) {
	call Stacks.pushValue(context, arg2->value.var < arg1->value.var);
      }
      else if ((arg1->type == BOMB_VAR_S) &&
	       (arg2->type == BOMB_VAR_S) &&
	       (arg1->sense.type == arg2->sense.type)) {
	call Stacks.pushValue(context, arg2->sense.var < arg1->sense.var);
      }
      else {
	call BombillaError.error(context, BOMB_ERROR_INVALID_TYPE);
      }
      break;
    case OPgt:
      if ((arg1->type == BOMB_VAR_V) &&
	  (arg2->type == BOMB_VAR_V)) {
	call Stacks.pushValue(context, arg2->value.var > arg1->value.var);
      }
      else if ((arg1->type == BOMB_VAR_S) &&
	       (arg2->type == BOMB_VAR_S) &&
	       (arg1->sense.type == arg2->sense.type)) {
	call Stacks.pushValue(context, arg2->sense.var > arg1->sense.var);
      }
      else {
	call BombillaError.error(context, BOMB_ERROR_INVALID_TYPE);
      }
      break;
    case OPlte:
      if ((arg1->type == BOMB_VAR_V) &&
	  (arg2->type == BOMB_VAR_V)) {
	call Stacks.pushValue(context, arg2->value.var <= arg1->value.var);
      }
      else if ((arg1->type == BOMB_VAR_S) &&
	       (arg2->type == BOMB_VAR_S) &&
	       (arg1->sense.type == arg2->sense.type)) {
	call Stacks.pushValue(context, arg2->sense.var <= arg1->sense.var);
      }
      else {
	call BombillaError.error(context, BOMB_ERROR_INVALID_TYPE);
      }
      break;
    case OPgte:
      if ((arg1->type == BOMB_VAR_V) &&
	  (arg2->type == BOMB_VAR_V)) {
	call Stacks.pushValue(context, arg2->value.var > arg1->value.var);
      }
      else if ((arg1->type == BOMB_VAR_S) &&
	       (arg2->type == BOMB_VAR_S) &&
	       (arg1->sense.type == arg2->sense.type)) {
	call Stacks.pushValue(context, arg2->sense.var > arg1->sense.var);
      }
      else {
	call BombillaError.error(context, BOMB_ERROR_INVALID_TYPE);
      }
      break;
    case OPeqtype:
      call Stacks.pushValue(context, typeEqual(arg1, arg2));
      break;
    default:
      call BombillaError.error(context, BOMB_ERROR_INVALID_INSTRUCTION);
      dbg(DBG_ERROR, "VM (%i): Unrecognized class 3 instruction: 0x%hhx.\n", (int)context->which, instr);
    }
  }
  
  void executeMClassInstruction(BombillaContext* context, uint8_t instr) {
    uint8_t arg = instr & MARG_MASK;
    uint8_t* ptr = (uint8_t*)context->header;
    switch(instr & MINSTR_MASK) {
    case OPgetms:
      dbg(DBG_USR1, "VM (%i): Pushing message header short %i onto operand stack.\n", (int)context->which, (int)arg);
      if (arg >= BOMB_HEADERSIZES) {
	dbg(DBG_USR1|DBG_ERROR, "VM (%i): getms: index %i out of range .\n", (int)context->which, (int)arg);
	call BombillaError.error(context, BOMB_ERROR_INDEX_OUT_OF_BOUNDS);
	return;
      }
      call Stacks.pushValue(context, context->header[(int)arg]);	
      break;
    case OPgetmb: 
      dbg(DBG_USR1, "VM (%i): Pushing message header byte %i onto operand stack.\n", (int)context->which, (int)arg);
      if (arg >= BOMB_HEADERSIZE) {
	dbg(DBG_USR1|DBG_ERROR, "VM (%i): getmb: index %i out of range .\n", (int)context->which, (int)arg);
	call BombillaError.error(context, BOMB_ERROR_INDEX_OUT_OF_BOUNDS);
	return;
      }
      call Stacks.pushValue(context, (int16_t)ptr[(int)arg]);
      break;
    case OPsetms: {
      BombillaStackVariable* val = call Stacks.popOperand(context);
      dbg(DBG_USR1, "VM (%i): Setting message header short %i.\n", (int)context->which, (int)arg);
      if (!checkTypes(context, val, BOMB_VAR_V)) {return;}
      if (arg >= BOMB_HEADERSIZES) {
	dbg(DBG_USR1|DBG_ERROR, "VM (%i): setms: index %i out of range .\n", (int)context->which, (int)arg);
	call BombillaError.error(context, BOMB_ERROR_INDEX_OUT_OF_BOUNDS);
	return;
      }

      context->header[arg] = val->value.var;
      break;
    }
    case OPsetmb: {
      BombillaStackVariable* val = call Stacks.popOperand(context);
      dbg(DBG_USR1, "VM (%i): Setting message header byte %i.\n", (int)context->which, (int)arg);
      if (!checkTypes(context, val, BOMB_VAR_V)) {return;}
      if (arg >= BOMB_HEADERSIZE) {
	dbg(DBG_USR1|DBG_ERROR, "VM (%i): setmb: index %i out of range .\n", (int)context->which, (int)arg);
	call BombillaError.error(context, BOMB_ERROR_INDEX_OUT_OF_BOUNDS);
	return;
      }
      ptr[arg] = (uint8_t)(val->value.var & 0xff);
      break;
    }
    default:
      call BombillaError.error(context, BOMB_ERROR_INVALID_INSTRUCTION);
    }	
  }
  
  void executeJClassInstruction(BombillaContext* context, uint8_t instr) {
    uint8_t arg = instr & JARG_MASK;
    switch(instr & JINSTR_MASK) {
    case OPjumpc:
      if (context->condition > 0) {
	dbg(DBG_USR1, "VM (%i): Condition true, jump to %i.\n", (int)context->which, (int)arg);
	context->condition--;
	if (arg < BOMB_PGMSIZE) {
	  context->pc = arg;
	}
	else {
	  call BombillaError.error(context, BOMB_ERROR_INDEX_OUT_OF_BOUNDS);
	}
      }
      else {
	dbg(DBG_USR1, "VM (%i): Condition false, do not jump.\n", (int)context->which, (int)arg);
      }
      break;
    case OPjumps: {
      BombillaStackVariable* cond = call Stacks.popOperand(context);
      if (!checkTypes(context, cond, BOMB_VAR_V)) {return;}
      if (cond->value.var > 0) {
	dbg(DBG_USR1, "VM (%i): Stack variable (%i) true, jump to %i.\n", (int)context->which, (int)cond->value.var, (int)arg);
	if (arg < BOMB_PGMSIZE) {
	  context->pc = arg;
	}
	else {
	  call BombillaError.error(context, BOMB_ERROR_INDEX_OUT_OF_BOUNDS);
	}
      }
      else {
	dbg(DBG_USR1, "VM (%i): Stack variable false, do not jump.\n", (int)context->which, (int)arg);
      }
      break;
    }
    default:
      call BombillaError.error(context, BOMB_ERROR_INVALID_INSTRUCTION);
    }	
  }

  void executeVClassInstruction(BombillaContext* context, uint8_t instr) {
    uint8_t arg = instr & VARG_MASK; 

    // Check we have access to the variable
    if ((context->heldSet & (1 << arg)) == 0) {
      dbg(DBG_USR1|DBG_ERROR, "VM (%i): Invalid variable access: %i\n", (int)context->which, (int)arg);
      call BombillaError.error(context, BOMB_ERROR_INVALID_ACCESS);
      return;
    }

    // Access it
    switch (instr & VINSTR_MASK) {
    case OPgetvar: 
      dbg(DBG_USR1, "VM (%i): Getting variable %i\n", (int)context->which, (int)arg);
      call Stacks.pushOperand(context, &(state.heap[arg]));
      break;
    case OPsetvar: {
      BombillaStackVariable* var = call Stacks.popOperand(context);
      if (!checkTypes(context, var, (BOMB_VAR_V | BOMB_VAR_S))) {break;}
      dbg(DBG_USR1, "VM (%i): Setting variable %i\n", (int)context->which, (int)arg);
      state.heap[arg] = *var;
      break;
    }
    default:
      call BombillaError.error(context, BOMB_ERROR_INVALID_INSTRUCTION);
      dbg(DBG_ERROR, "VM (%i): Unrecognized v-class instruction: %hhx\n", (int)context->which, instr);
    }
    return;
  }

  void executeXClassInstruction(BombillaContext* context, uint8_t instr) {
    int16_t arg = (int16_t)(instr & XARG_MASK);
    dbg(DBG_USR1, "VM (%i): Executing pushc :%i\n", (int)context->which, (int)arg);
    call Stacks.pushValue(context, arg);
    return;
  }

  
  command result_t computeInstruction(BombillaContext* context) {
    uint8_t instr = context->capsule->capsule.code[(int)context->pc];
    //	dbg(DBG_USR1, "VM (%hhi): Issuing instruction 0x%hhx.\n", context->which, instr);
    if (context->state != BOMB_STATE_RUN) {
      dbg(DBG_ERROR, "VM: (%hhi) Tried to execute instruction in non-run state: %hhi\n", context->which, context->state);
      return FAIL;
    }
    context->pc++;
	
    if (call Instruction.isMClass(instr)) {
      executeMClassInstruction(context, instr);
    }
    else if (call Instruction.isVClass(instr)) {
      executeVClassInstruction(context, instr);
    }
    else if (call Instruction.isJClass(instr)) {
      executeJClassInstruction(context, instr);
    }
    else if (call Instruction.isXClass(instr)) {
      executeXClassInstruction(context, instr);
    }
    else {   // Basic class
      uint8_t instrSet = instr >> 4;
      switch(instrSet) {
      case 0:
	execute0ClassInstruction(context, instr);
	break;
      case 1:
	execute1ClassInstruction(context, instr);
	break;
      case 2:
	execute2ClassInstruction(context, instr);
	break;
      case 3:
	execute3ClassInstruction(context, instr);
	break;
      default:
	call BombillaError.error(context, BOMB_ERROR_INVALID_INSTRUCTION);
	dbg(DBG_ERROR, "VM: Unidentified instruction class. Instruction: %hhx\n", instr);
      }
    }
    return SUCCESS;  
  }

  event result_t Virus.capsuleInstalled(BombillaCapsule* capsule) {
    capsuleAnalysis(capsule->type & BOMB_OPTION_MASK);
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
