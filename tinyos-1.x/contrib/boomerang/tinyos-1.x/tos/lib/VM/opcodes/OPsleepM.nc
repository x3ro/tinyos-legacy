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
 * History:   Feb 10, 2004         Inception.
 *
 */

/**
 * @author Philip Levis <pal@cs.berkeley.edu>
 */


includes Mate;

module OPsleepM {
  
  provides {
    interface StdControl;
    interface MateBytecode;
  }
  
  uses {
    interface MateStacks as Stacks;
    interface MateTypes as Types;
    interface MateQueue as Queue;
    interface MateError as Error;
    interface MateContextSynch as Synch;
    interface MateEngineStatus as EngineStatus;
    interface Timer;
  }
}

implementation {
  
  bool active;
  
  typedef struct {
    int16_t counter;
    bool active;
    MateContext* context;
  } SleepState;
  
  SleepState state[MATE_CONTEXT_NUM];
  

  inline void clearState() {
    nmemset(&state, 0, sizeof(SleepState) * MATE_CONTEXT_NUM);
  }
  
  command result_t StdControl.init() {
    active = FALSE;
    clearState();
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  

  command result_t MateBytecode.execute(uint8_t instr,
					MateContext* context) {
    MateStackVariable* var = call Stacks.popOperand(context);
    if (!call Types.checkTypes(context, var, MATE_TYPE_INTEGER)) {return FAIL;}
    
    dbg(DBG_USR1, "VM (%i): Sleeping for %i.\n", (int)context->which, (int)var->value.var);
    
    state[context->which].context = context;
    state[context->which].active = TRUE;
    state[context->which].counter = var->value.var;
    context->state = MATE_STATE_BLOCKED;
    call Synch.yieldContext(context);

    if (!active) {
      call Timer.start(TIMER_REPEAT, 102);
      active = TRUE;
    }
    return SUCCESS;
  }

  command uint8_t MateBytecode.byteLength() {return 1;}

  event result_t Timer.fired() {
    int i;
    bool hasActive = FALSE;
    for (i = 0; i < MATE_CONTEXT_NUM; i++) {
      if (state[i].active) {
	state[i].counter--;
	if (state[i].counter <= 0) {
	  call Synch.resumeContext(state[i].context, state[i].context);
	  state[i].active = FALSE;
	}
	else {
	  hasActive = TRUE;
	}
      }
    }
    if (!hasActive) {
      call Timer.stop();
      active = FALSE;
    }
    return SUCCESS;
  }

  event void EngineStatus.rebooted() {
    clearState();
    call Timer.stop();
    active = FALSE;
  }

}
