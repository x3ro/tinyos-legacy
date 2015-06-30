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
 * History:   Jun 21, 2004         Inception.
 *
 * This component exports the magnetometer sensor as provided by the
 * mica sensor board (micasb). If there is contention for the sensor,
 * it maintains two FIFO request queues (X and Y) and alternates between
 * them.
 */

/**
 * @author Philip Levis <pal@cs.berkeley.edu>
 */


includes Mate;

module MateHamamatsuM {
  
  provides {
    interface StdControl;
    interface MateBytecode as PhotoActive;
    interface MateBytecode as TotalSolar; 
  }
  
  uses {
    interface MateStacks as Stacks;
    interface MateTypes as Types;
    interface MateQueue as Queue;
    interface MateError as Error;
    interface MateContextSynch as Synch;
    interface StdControl as HamControl;
    interface MateEngineStatus as EngineStatus;
    
    interface ADC as PAR;
    interface ADC as TSR;
  }
}

implementation {

  enum {
    SENSING_NONE = 0,
    SENSING_TSR = 1,
    SENSING_PAR = 2
  } SenseType;
  
  MateQueue sensePARWaitQueue;
  MateQueue senseTSRWaitQueue;
  MateContext* sensingContext;
  uint8_t sensing;
  uint16_t reading;
  
  command result_t StdControl.init() {
    call Queue.init(&sensePARWaitQueue);
    call Queue.init(&senseTSRWaitQueue);
    atomic {
      sensingContext = NULL;
      sensing = SENSING_NONE;
    }
    return call HamControl.init();
  }
  
  command result_t StdControl.start() {
    return call HamControl.start();
  }
  
  command result_t StdControl.stop() {
    return call HamControl.stop();
  }
  
  
  inline result_t execSensePAR(MateContext* context) {
    bool yield = FALSE;
    dbg(DBG_USR1, "VM (%i): Sensing photo active radiation (PAR).\n", (int)context->which);

    atomic {
      if (call PAR.getData() == SUCCESS) {
	sensingContext = context;
	context->state = MATE_STATE_BLOCKED;
	sensing = SENSING_PAR;
	yield = TRUE;
      }
    }
    if (yield) {
      call Synch.yieldContext(context);
      return SUCCESS;
    }
    else { // re-issue the instruction
      call Error.error(context, MATE_ERROR_INVALID_SENSOR);
      dbg(DBG_ERROR, "VM (%i): Sensor busy, reissue.\n", (int)context->which);
      context->pc--;
      return FAIL;
    }
  }
  
  inline result_t execSenseTSR(MateContext* context) {
    dbg(DBG_USR1, "VM (%i): Sensing total solar radiation (TSR).\n", (int)context->which);

    if (call TSR.getData() == SUCCESS) {
      atomic {
	sensingContext = context;
	context->state = MATE_STATE_BLOCKED;
	sensing = SENSING_TSR;
      }
      call Synch.yieldContext(context);
      return SUCCESS;
    }
    else { // re-issue the instruction
      call Error.error(context, MATE_ERROR_INVALID_SENSOR);
      dbg(DBG_ERROR, "VM (%i): Sensor busy, reissue.\n", (int)context->which);
      context->pc--;
      return FAIL;
    }
  }
  
  task void sensePARDoneTask();
  task void senseTSRDoneTask();
  
  command result_t PhotoActive.execute(uint8_t instr,
				       MateContext* context) {
    if (sensing != SENSING_NONE) {
      call Queue.enqueue(context, &sensePARWaitQueue, context);
      context->state = MATE_STATE_WAITING;
      call Synch.yieldContext(context);
      return SUCCESS;
    }
    else {
      return execSensePAR(context);
    }
  }
  
  command result_t TotalSolar.execute(uint8_t instr,
				      MateContext* context) {
    if (sensing != SENSING_NONE) {
      call Queue.enqueue(context, &senseTSRWaitQueue, context);
      context->state = MATE_STATE_WAITING;
      call Synch.yieldContext(context);
      return SUCCESS;
    }
    else {
      return execSenseTSR(context);
    }
  }

  command uint8_t PhotoActive.byteLength() {return 1;}
  command uint8_t TotalSolar.byteLength() {return 1;}

  async event result_t PAR.dataReady(uint16_t datum) {
    bool isMine;
    atomic {
      isMine = (sensing == SENSING_PAR);
    }
    if (isMine) {
      atomic {
	reading = datum;
      }
      post sensePARDoneTask();
    }
    return SUCCESS;
  }

  async event result_t TSR.dataReady(uint16_t datum) {
    bool isMine;
    atomic {
      isMine = (sensing == SENSING_TSR);
    }
    if (isMine) {
      atomic {
	reading = datum;
      }
      post senseTSRDoneTask();
    }
    return SUCCESS;
  }

  task void sensePARDoneTask() {
    uint16_t datum;

    if (sensing != SENSING_PAR) {
      return;
    }
    atomic {
      datum = reading;
      sensing = SENSING_NONE;
    }

    dbg(DBG_USR1, "VM: PAR reading: %i\n", (int)datum);

    if (sensingContext == NULL) {
      dbg(DBG_USR1, "VM: MateHamamatsuM: received sensor reading, but no sending context: VM rebooted?\n");
      return;
    }
    else {
      // Resume the sensing context
      call Synch.resumeContext(sensingContext, sensingContext);
      call Stacks.pushReading(sensingContext, MATE_TYPE_TPAR, datum);
      sensingContext = NULL;
    }
    // Here is the queue alternation: after an PAR reading, schedule
    // a TSR reading first
    if (!call Queue.empty(&senseTSRWaitQueue)) {
      MateContext* senser = call Queue.dequeue(NULL, &senseTSRWaitQueue);
      execSenseTSR(senser);
    }
    else if (!call Queue.empty(&sensePARWaitQueue)) {
      MateContext* senser = call Queue.dequeue(NULL, &sensePARWaitQueue);
      execSensePAR(senser);
    }
    return;
  }
  
  task void senseTSRDoneTask() {
    uint16_t datum;
    if (sensing != SENSING_TSR) {
      return;
    }
    atomic {
      datum = reading;
      sensing = SENSING_NONE;
    }

    dbg(DBG_USR1, "VM: TSR reading: %i\n", (int)datum);

    if (sensingContext == NULL) {
      dbg(DBG_USR1, "VM: MateTSRM: received sensor reading, but no sending context: VM rebooted?\n");
      return;
    }
    else {
      // Resume the sensing context
      call Synch.resumeContext(sensingContext, sensingContext);
      call Stacks.pushReading(sensingContext, MATE_TYPE_TTSR, datum);
      sensingContext = NULL;
    }

    // Here is the queue alternation: after an TSR reading, schedule
    // an PAR reading first
    if (!call Queue.empty(&sensePARWaitQueue)) {
      MateContext* senser = call Queue.dequeue(NULL, &sensePARWaitQueue);
      execSensePAR(senser);
    }
    else if (!call Queue.empty(&senseTSRWaitQueue)) {
      MateContext* senser = call Queue.dequeue(NULL, &senseTSRWaitQueue);
      execSenseTSR(senser);
    }
    return;
  }

    event void EngineStatus.rebooted() {
    atomic {
      sensingContext = NULL;
      call Queue.init(&sensePARWaitQueue);
      call Queue.init(&senseTSRWaitQueue);
    }
  }

}
