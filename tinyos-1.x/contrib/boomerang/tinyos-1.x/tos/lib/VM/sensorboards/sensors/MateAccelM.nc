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

module MateAccelM {
  
  provides {
    interface StdControl;
    interface MateBytecode as AccelX;
    interface MateBytecode as AccelY; 
  }
  
  uses {
    interface MateStacks as Stacks;
    interface MateTypes as Types;
    interface MateQueue as Queue;
    interface MateError as Error;
    interface MateContextSynch as Synch;
    interface StdControl as SubControl;
    interface MateEngineStatus as EngineStatus;
    
    interface ADC as AccelXADC;
    interface ADC as AccelYADC;
  }
}

implementation {
  MateQueue senseXWaitQueue;
  MateQueue senseYWaitQueue;
  MateContext* sensingContext;
  bool sensing;
  uint16_t reading;
  
  command result_t StdControl.init() {
    call Queue.init(&senseXWaitQueue);
    call Queue.init(&senseYWaitQueue);
    atomic {
      sensingContext = NULL;
      sensing = FALSE;
    }
    return call SubControl.init();
  }
  
  command result_t StdControl.start() {
    return call SubControl.start();
  }
  
  command result_t StdControl.stop() {
    return call SubControl.stop();
  }
  
  
  inline result_t execSenseX(MateContext* context) {
    dbg(DBG_USR1, "VM (%i): Sensing accelX.\n", (int)context->which);

    if (call AccelXADC.getData() == SUCCESS) {
      atomic {
	sensingContext = context;
	context->state = MATE_STATE_BLOCKED;
	sensing = TRUE;
      }
      call Synch.yieldContext(context);
      return SUCCESS;
    }
    else { // re-issue the instruction
      dbg(DBG_ERROR, "VM (%i): Sensor busy, reissue.\n", (int)context->which);
      context->pc--;
      return FAIL;
    }
  }
  
  inline result_t execSenseY(MateContext* context) {
    dbg(DBG_USR1, "VM (%i): Sensing accelY.\n", (int)context->which);

    if (call AccelYADC.getData() == SUCCESS) {
      atomic {
	sensingContext = context;
	context->state = MATE_STATE_BLOCKED;
	sensing = TRUE;
      }
      call Synch.yieldContext(context);
      return SUCCESS;
    }
    else { // re-issue the instruction
      dbg(DBG_ERROR, "VM (%i): Sensor busy, reissue.\n", (int)context->which);
      context->pc--;
      return FAIL;
    }
  }

  command uint8_t AccelX.byteLength() {return 1;}
  command uint8_t AccelY.byteLength() {return 1;}

  task void senseXDoneTask();
  task void senseYDoneTask();
  
  command result_t AccelX.execute(uint8_t instr,
				MateContext* context) {
    if (sensing == TRUE) {
      call Queue.enqueue(context, &senseXWaitQueue, context);
      context->state = MATE_STATE_WAITING;
      call Synch.yieldContext(context);
      return SUCCESS;
    }
    else {
      return execSenseX(context);
    }
  }
  
  command result_t AccelY.execute(uint8_t instr,
				MateContext* context) {
    if (sensing == TRUE) {
      call Queue.enqueue(context, &senseYWaitQueue, context);
      context->state = MATE_STATE_WAITING;
      call Synch.yieldContext(context);
      return SUCCESS;
    }
    else {
      return execSenseY(context);
    }
  }

  async event result_t AccelXADC.dataReady(uint16_t datum) {
    bool isMine;
    atomic {
      isMine = sensing;
    }
    if (isMine) {
      atomic {
	reading = datum;
      }
      post senseXDoneTask();
    }
    return SUCCESS;
  }

  async event result_t AccelYADC.dataReady(uint16_t datum) {
    bool isMine;
    atomic {
      isMine = sensing;
    }
    if (isMine) {
      atomic {
	reading = datum;
      }
      post senseYDoneTask();
    }
    return SUCCESS;
  }

  task void senseXDoneTask() {
    uint16_t datum;
    atomic {
      datum = reading;
    }
    dbg(DBG_USR1, "VM: AccelX reading: %i\n", (int)datum);

    atomic {
      sensing = FALSE;
    }
    if (sensingContext == NULL) {
      dbg(DBG_USR1, "VM: MateAccelM: received sensor reading, but no sending context: VM rebooted?\n");
      return;
    }
    else {
      // Resume the sensing context
      call Synch.resumeContext(sensingContext, sensingContext);
      call Stacks.pushReading(sensingContext, MATE_TYPE_MSBACCELX, datum);
      sensingContext = NULL;
    }
    // Here is the queue alternation: after an X reading, schedule
    // a Y reading first
    if (!call Queue.empty(&senseYWaitQueue)) {
      MateContext* senser = call Queue.dequeue(NULL, &senseYWaitQueue);
      execSenseY(senser);
    }
    else if (!call Queue.empty(&senseXWaitQueue)) {
      MateContext* senser = call Queue.dequeue(NULL, &senseXWaitQueue);
      execSenseX(senser);
    }
    return;
  }
  
  task void senseYDoneTask() {
    uint16_t datum;
    atomic {
      datum = reading;
    }
    dbg(DBG_USR1, "VM: AccelY reading: %i\n", (int)datum);

    atomic {
      sensing = FALSE;
    }
    if (sensingContext == NULL) {
      dbg(DBG_USR1, "VM: MateAccelM: received sensor reading, but no sending context: VM rebooted?\n");
      return;
    }
    else {
      // Resume the sensing context
      call Synch.resumeContext(sensingContext, sensingContext);
      call Stacks.pushReading(sensingContext, MATE_TYPE_MSBACCELY, datum);
      sensingContext = NULL;
    }

    // Here is the queue alternation: after an Y reading, schedule
    // an X reading first
    if (!call Queue.empty(&senseXWaitQueue)) {
      MateContext* senser = call Queue.dequeue(NULL, &senseXWaitQueue);
      execSenseX(senser);
    }
    else if (!call Queue.empty(&senseYWaitQueue)) {
      MateContext* senser = call Queue.dequeue(NULL, &senseYWaitQueue);
      execSenseY(senser);
    }
    return;
  }

    event void EngineStatus.rebooted() {
    atomic {
      sensingContext = NULL;
      call Queue.init(&senseXWaitQueue);
      call Queue.init(&senseYWaitQueue);
    }
  }

}
