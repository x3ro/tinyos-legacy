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
 * History:   Apr 14, 2003         Inception.
 *
 */

includes Bombilla;
includes BombillaMsgs;

module OPsenseM {
  
  provides {
    interface StdControl;
    interface BombillaBytecode;
  }
  
  uses {
    interface BombillaStacks as Stacks;
    interface BombillaTypes as Types;
    interface BombillaQueue as Queue;
    interface BombillaError as Error;
    interface BombillaContextSynch as Synch;
    interface StdControl as PhotoControl;

    interface ADC as Sensors[uint8_t types];
  }
}

implementation {
#define NO_SUCH_SENSOR 34
  BombillaQueue senseWaitQueue;
  BombillaContext* sensingContext;
  uint8_t waitingSensor;
  
  // A pointer to the readyQueue of the VM which the context
  // mid-sensing belongs to.
  BombillaQueue* readyQueue;
  
  
  command result_t StdControl.init() {
    call PhotoControl.init();
    call Queue.init(&senseWaitQueue);
    sensingContext = NULL;
    waitingSensor = 255;
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  
  inline result_t execSense(BombillaContext* context,
			BombillaState* state,
			uint8_t which) {
    BombillaQueue* queue = &senseWaitQueue;
    cli();
    if (sensingContext != NULL) {
      call Stacks.pushValue(context, which);
      context->state = BOMB_STATE_SENSE_WAIT;
      context->vmData = state;
      call Queue.enqueue(context, queue, context);
      sei();
      return SUCCESS;
    }
    else {
      result_t rval;
      sei();
      dbg(DBG_USR1, "VM (%i): Sensing %i.\n", (int)context->which, (int)which);
      rval = call Sensors.getData[which]();
      if (rval == SUCCESS) {
        waitingSensor = which;
        sensingContext = context;
        context->state = BOMB_STATE_SENSE;
        context -> vmData = state;
        return SUCCESS;
      }
      else if (rval == NO_SUCH_SENSOR) {
	dbg(DBG_ERROR, "VM (%i): Sensor type %i not supported yet.\n", (int)context->which, (int)which);
	call Error.error(context, BOMB_ERROR_INVALID_SENSOR);
	return FAIL;
      }
      else { // re-issue the instruction
	dbg(DBG_ERROR, "VM (%i): Sensor busy, reissue.\n", (int)context->which);
	call Stacks.pushValue(context, which);
	context->pc--;
	return FAIL;
      }
    }
  }

  
  command result_t BombillaBytecode.execute(uint8_t instr,
					    BombillaContext* context,
					    BombillaState* state) {
    BombillaStackVariable* arg = call Stacks.popOperand(context);
    dbg(DBG_USR1, "VM (%i): Sensing.\n", (int)context->which);
    if (!call Types.checkTypes(context, arg, BOMB_VAR_V)) {return FAIL;}

    // select a sensor here
    if (execSense(context, state, arg->value.var) == SUCCESS) {
      call Synch.releaseLocks(context, context, state->locks);
      call Synch.yieldContext(context, &(state->readyQueue), state->locks);
    }
    return SUCCESS;
  }

  event result_t Sensors.dataReady[uint8_t id](uint16_t datum) {
    BombillaContext* senser = sensingContext;
    BombillaQueue* queue = &senseWaitQueue;
    dbg(DBG_USR1, "VM: Sensor reading: %i\n", (int)datum);
    if (id != waitingSensor) {
      dbg(DBG_USR1, "VM: Not the sensor we're waiting on. Do nothing.\n");
      return SUCCESS;
    }
    
    if (sensingContext != NULL) {
      // Resume the sensing context
      BombillaState* state = (BombillaState*)sensingContext->vmData;
      sensingContext->state = BOMB_STATE_RUN;
      call Synch.resumeContext(sensingContext, sensingContext, &(state->readyQueue), state->locks);
      call Stacks.pushReading(sensingContext, id, datum);
      sensingContext = NULL;
    }
    if (!call Queue.empty(queue)) {
      BombillaState* state;
      senser = call Queue.dequeue(senser, queue);
      if (senser != NULL &&
          senser->state != BOMB_STATE_SENSE_WAIT) {
        call Error.error(senser, BOMB_ERROR_QUEUE_INVALID);
        return SUCCESS;
      }
      senser->state = BOMB_STATE_RUN;
      state = (BombillaState*)senser->vmData;
      call Synch.resumeContext(senser, senser, &(state->readyQueue), state->locks);
    }
    return SUCCESS;
  }
  
  default command result_t Sensors.getData[uint8_t which]() {
    return NO_SUCH_SENSOR;
  }

  event result_t Synch.makeRunnable(BombillaContext* context) {
    return SUCCESS;
  }

}
