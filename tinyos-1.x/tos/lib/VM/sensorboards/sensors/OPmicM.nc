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

module OPmicM {
  
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
    interface StdControl as SubControl;
    interface MateEngineStatus as EngineStatus;
    
    interface ADC;
  }
}

implementation {
  MateQueue senseWaitQueue;
  MateContext* sensingContext;
  bool sensing;
  uint16_t reading;
  
  command result_t StdControl.init() {
    call SubControl.init();
    call Queue.init(&senseWaitQueue);
    atomic {
      sensingContext = NULL;
      sensing = FALSE;
    }
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return call SubControl.start();
  }
  
  command result_t StdControl.stop() {
    return call SubControl.stop();
  }
  
  
  inline result_t execSense(MateContext* context) {
    dbg(DBG_USR1, "VM (%i): Sensing microphone.\n", (int)context->which);

    if (call ADC.getData() == SUCCESS) {
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
  
  task void senseDoneTask();
  
  command result_t MateBytecode.execute(uint8_t instr,
					MateContext* context) {
    dbg(DBG_USR1, "VM (%i): Sensing microphone.\n", (int)context->which);
    if (sensing == TRUE) {
      call Queue.enqueue(context, &senseWaitQueue, context);
      context->state = MATE_STATE_WAITING;
      call Synch.yieldContext(context);
      return SUCCESS;
    }
    else {
      return execSense(context);
    }
  }

  command uint8_t MateBytecode.byteLength() {return 1;}

  async event result_t ADC.dataReady(uint16_t datum) {
    bool isMine;
    atomic {
      isMine = sensing;
    }
    if (isMine) {
      atomic {
	reading = datum;
      }
      post senseDoneTask();
    }
    return SUCCESS;
  }

  task void senseDoneTask() {
    uint16_t datum;
    atomic {
      datum = reading;
    }
    dbg(DBG_USR1, "VM: mike reading: %i\n", (int)datum);

    atomic {
      sensing = FALSE;
    }
    if (sensingContext == NULL) {
      dbg(DBG_USR1, "VM: OPMicM: received sensor reading, but no sending context: VM rebooted?\n");
      return;
    }
    else {
      // Resume the sensing context
      call Synch.resumeContext(sensingContext, sensingContext);
      call Stacks.pushReading(sensingContext, MATE_TYPE_MSBMIC, datum);
      sensingContext = NULL;
    }

    if (!call Queue.empty(&senseWaitQueue)) {
      MateContext* senser = call Queue.dequeue(NULL, &senseWaitQueue);
      execSense(senser);
    }
    return;
  }
  
  event void EngineStatus.rebooted() {
    atomic {
      sensingContext = NULL;
      call Queue.init(&senseWaitQueue);
    }
  }

}
