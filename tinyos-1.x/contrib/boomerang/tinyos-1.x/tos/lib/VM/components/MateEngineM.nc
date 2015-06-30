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
 *            Neil Patel
 * History:   Apr 11, 2003         Inception.
 *
 */

/**
 * @author Philip Levis <pal@cs.berkeley.edu>
 * @author Neil Patel
 */


includes AM;
includes Mate;

module MateEngineM {
  provides {
    interface StdControl;
    interface MateError as Error;
    interface MateEngineStatus as EngineStatus;
    interface MateScheduler as Scheduler;
    
    interface MateBytecode as Functions[uint8_t fnID];
    interface MateBytecode as Bytecodes[uint8_t fnID];
  }
  
  uses {
    interface Leds;
    interface MateContextSynch as Synch;
    interface MateQueue as Queue;
    interface StdControl as SubControl;
    interface MateAnalysis as Analysis;
    interface MateHandlerStore as HandlerStore[uint8_t id];
    interface MateEngineControl as EngineControl;
    interface Timer as ErrorTimer;
    interface SendMsg as SendError;

    interface MateBytecode as BytecodeImpls[uint8_t bytecode] ;
    interface MateBytecode as FunctionImpls[uint8_t fnID];
  }
}


implementation {
  MateQueue runQueue;
  MateContext* runningContext;
  MateContext* errorContext;
  MateErrorMsg errorMsg;
  TOS_Msg msg;
  uint8_t iCount;
  
  struct {
    uint8_t inErrorState  : 1;
    uint8_t errorFlipFlop : 1;
    uint8_t taskRunning   : 1;
    uint8_t halted        : 1;
  } flags;


  command result_t StdControl.init() {
    dbg(DBG_BOOT, "VM: Mate initializing.\n");
    call Leds.init();
    call Queue.init(&runQueue);
    call SubControl.init();
    flags.inErrorState = FALSE;
    flags.halted = FALSE;
    flags.taskRunning = FALSE;
    iCount = 0;
    return SUCCESS;
  }

  task void bootTask();
  
  command result_t StdControl.start() {
    dbg(DBG_BOOT, "VM: Starting.\n");
    call SubControl.start();
    post bootTask();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    dbg(DBG_BOOT, "VM: Stopping.\n");
    call SubControl.stop();
    return SUCCESS;
  }

  static inline result_t computeInstruction(MateContext* context) {
    MateOpcode instr = call HandlerStore.getOpcode[context->currentHandler](context->pc);
    if (context->state != MATE_STATE_RUN) {
      dbg(DBG_ERROR, "VM: (%hhi) Tried to execute instruction in non-run state: %hhi\n", context->which, context->state);
      return FAIL;
    }
    context->pc += call BytecodeImpls.byteLength[instr]();
    call BytecodeImpls.execute[instr](instr, context);
    return SUCCESS;  
  }
  
  task void RunTask() {
    int i;

    dbg(DBG_USR1, "VM: Run task running.\n");
    if (flags.halted == TRUE) {
      dbg(DBG_USR1, "VM: Halted, don't run.\n");
      flags.taskRunning = FALSE;
      return;
    }
    
    if (iCount >= MATE_CPU_SLICE &&
	runningContext != NULL) { // Slice has expired
      dbg(DBG_USR1, "VM: Slice for context %i expired, re-enqueue.\n", (int)runningContext->which);
      runningContext->state = MATE_STATE_READY;
      call Queue.enqueue(runningContext, &runQueue, runningContext);
      runningContext = NULL;
      iCount = 0; 
    }
    if (runningContext == NULL &&
	!flags.inErrorState &&
	!call Queue.empty(&runQueue)) { // Get a new context to run
            dbg(DBG_USR1, "VM: Need a new context.\n");
      runningContext = call Queue.dequeue(NULL, &runQueue);
      runningContext->state = MATE_STATE_RUN;
    }

    if (runningContext != NULL) {
      for (i = 0; i < MATE_CPU_QUANTUM; i++) {
	computeInstruction(runningContext);
	if (runningContext->state != MATE_STATE_RUN) {
	  runningContext = NULL;
	  break;
	}
      }
      if (post RunTask() == FAIL) {
	flags.taskRunning = FALSE;
      }
      iCount++;
    }
    else {
      flags.taskRunning = FALSE;
    }
  }
  
  result_t executeContext(MateContext* context) {
    if (context->state != MATE_STATE_READY) {
      dbg(DBG_USR2|DBG_ERROR, "VM: Failed to submit context %i: not in READY state.\n", (int)context->which);
      return FAIL;
    }
    call Queue.enqueue(context, &runQueue, context);
    if (!flags.taskRunning) {
      flags.taskRunning = TRUE;
      dbg(DBG_USR1, "VM: Posting run task.\n");
      post RunTask(); 
    }
    return SUCCESS;
  }
  
  default command result_t BytecodeImpls.execute[uint8_t opcode](uint8_t instr, MateContext* context) {
    dbg(DBG_ERROR|DBG_USR1, "VM: Executing default instruction: halt!\n");
    context->state = MATE_STATE_HALT;
    context->pc = 0;
    return FAIL;
  }
  
  default command uint8_t BytecodeImpls.byteLength[uint8_t opcode]() {
    return 1;
  }

  task void rebootTask() {
    signal EngineStatus.rebooted();
  }

  event void EngineControl.reboot() {
    MateHandlerID id;
    dbg(DBG_USR1, "VM: Mate rebooting.\n");
    runningContext = NULL;
    call Queue.init(&runQueue);
    call Synch.reset();
    
    for (id = 0; id < MATE_HANDLER_NUM; id++) {
      call Analysis.clearAnalysis(id);
    }
    dbg(DBG_USR1, "VM: Analyzing lock sets.\n");
    for (id = 0; id < MATE_HANDLER_NUM; id++) {
      call Analysis.analyzeVars(id);
    }
    for (id = 0; id < MATE_HANDLER_NUM; id++) {
      call Analysis.analyzeCalls(id);
    }

    flags.inErrorState = FALSE;
    flags.halted = FALSE;
    iCount = 0;
    errorContext = NULL;
    dbg(DBG_USR1, "VM: Signaling reboot.\n");    
    call Leds.set(0);
    post rebootTask();
  }

  task void bootTask() {
    signal EngineControl.reboot();
  }
  
  event void EngineControl.halt() {
    dbg(DBG_TEMP, "MateEngineM halted.\n");
    flags.halted = TRUE;
  }

  event void EngineControl.resume() {
    flags.halted = FALSE;
    if (!flags.taskRunning) {
      flags.taskRunning = TRUE;
      post RunTask();
    }
  }
  
  command result_t Scheduler.submit(MateContext* context) {
    dbg(DBG_USR1, "VM: Context %i submitted to run.\n", (int)context->which);
    context->state = MATE_STATE_READY;
    return executeContext(context);
  }

  command result_t Error.error(MateContext* context, uint8_t cause) {
    flags.inErrorState = TRUE;
    dbg(DBG_ERROR|DBG_USR1, "VM: Entering ERROR state. Context: %i, cause %i\n", (int)context->which, (int)cause);
    call Leds.redOn();
    call Leds.greenOn();
    call Leds.yellowOn();
    call ErrorTimer.start(TIMER_REPEAT, 1000);
    errorContext = context;
    if (context != NULL) {
      errorContext = context;
      errorMsg.context = context->which;
      errorMsg.reason = cause;
      errorMsg.capsule = context->currentHandler;
      errorMsg.instruction = context->pc - 1;
      errorMsg.me = TOS_LOCAL_ADDRESS;
      context->state = MATE_STATE_HALT;
    }
    else {
      errorMsg.context = MATE_CAPSULE_INVALID;
      errorMsg.reason = cause;
      errorMsg.capsule = MATE_CAPSULE_INVALID;
      errorMsg.instruction = 255;
    }
    return SUCCESS;
  }

  event result_t ErrorTimer.fired() {
    dbg(DBG_USR1|DBG_ERROR, "VM: ERROR\n");
    if (!flags.inErrorState) {
      call ErrorTimer.stop();
      return FAIL;
    }
    call Leds.redToggle();
    call Leds.greenToggle();
    call Leds.yellowToggle();
    nmemcpy(msg.data,
            &errorMsg,
            sizeof(MateErrorMsg));

    if (flags.errorFlipFlop) {
      call SendError.send(TOS_UART_ADDR,
                          sizeof(MateErrorMsg),
                          (TOS_MsgPtr)&(msg));
    }
    else {
      call SendError.send(TOS_BCAST_ADDR,
                          sizeof(MateErrorMsg),
                          (TOS_MsgPtr)&(msg));
    }
    flags.errorFlipFlop = !flags.errorFlipFlop;
    return SUCCESS;
  }

  event result_t SendError.sendDone(TOS_MsgPtr mesg, result_t success) {
    return SUCCESS;
  }

  event void HandlerStore.handlerChanged[uint8_t id]() {
    // Do nothing
  }

  
  
  command result_t Bytecodes.execute[uint8_t fnID](uint8_t functionID, MateContext* context) {
    return call BytecodeImpls.execute[fnID](functionID, context);
  }
 
  command uint8_t Bytecodes.byteLength[uint8_t fnID]() {
    return call BytecodeImpls.byteLength[fnID]();
  }
  
  command result_t Functions.execute[uint8_t fnID](uint8_t functionID, MateContext* context) {
    return call FunctionImpls.execute[fnID](functionID, context);
  }
 
  command uint8_t Functions.byteLength[uint8_t fnID]() {
    return call FunctionImpls.byteLength[fnID]();
  }

   default event void EngineStatus.rebooted() {}

  default command result_t FunctionImpls.execute[uint8_t fnID](uint8_t functionID, MateContext* context) {
    dbg(DBG_USR1, "MateEngineM: Executed default function. Chances are there's a function miswiring.\n");
    return SUCCESS;
  }

  default command uint8_t FunctionImpls.byteLength[uint8_t fnID]() {
    return 0;
  }
  
}
