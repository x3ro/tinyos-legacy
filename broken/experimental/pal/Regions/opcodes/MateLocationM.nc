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
 * Authors:   Phil Levis
 * History:   May 11, 2004         Inception.
 *
 */

/**
 * @author Phil Levis
 */


includes Mate;

module MateLocationM {
  provides {
    interface MateBytecode as LocationX;
    interface MateBytecode as LocationY;
    interface StdControl;
  }
  uses {
    interface MateQueue as Queue;
    interface MateStacks as Stacks;
    interface MateContextSynch as Synch;
    interface MateTypes as Types;
    interface MateEngineStatus as EngineStatus;
    
    interface Location;
  }
}

implementation {

  typedef enum {
    LOCATION_X,
    LOCATION_Y,
    LOCATION_Z
  } MateLocationWhich;

  MateQueue waitQueue;
  MateContext* currentContext;
  MateLocationWhich which;
  location_3d_t myLoc;
  
  command result_t StdControl.init() {
    call Queue.init(&waitQueue);
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;    
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command uint8_t LocationX.byteLength() {return 1;}
  command uint8_t LocationY.byteLength() {return 1;}


  result_t getLocation(MateContext* context, MateLocationWhich dir) {
    if (currentContext != NULL) {
      context->pc--;
      context->state = MATE_STATE_SEND_WAIT;
      call Queue.enqueue(context, &waitQueue, context);
    }
    else {
      if (call Location.getLocation() == SUCCESS) {
	which = dir;
	currentContext = context;
	context->state = MATE_STATE_SENDING;
      }
      else {
	context->pc--;
	context->state = MATE_STATE_SEND_WAIT;
	call Queue.enqueue(context, &waitQueue, context);
      }
    }
    call Synch.releaseLocks(context, context);
    call Synch.yieldContext(context);
    return SUCCESS;
  }

  task void locationTask() {
    if (currentContext != NULL) {
      if (which == LOCATION_X) {
	call Stacks.pushValue(currentContext, (uint16_t)myLoc.x);
      }
      else if (which == LOCATION_Y) {
	call Stacks.pushValue(currentContext, (uint16_t)myLoc.y);
      }
      else if (which == LOCATION_Z) {
	call Stacks.pushValue(currentContext, (uint16_t)myLoc.z);
      }
      else {
	dbg(DBG_USR1|DBG_ERROR, "MateLocationM: Unknown location direction: %i!\n", (int)which);
	call Stacks.pushValue(currentContext, 0);
      }
      call Synch.resumeContext(currentContext, currentContext);
      currentContext = NULL;
    }
    if (!call Queue.empty(&waitQueue)) {
      MateContext* newContext = call Queue.dequeue(currentContext, &waitQueue);
      call Synch.resumeContext(newContext, newContext);
    }
  }
  
  async event void Location.locationDone(location_3d_t* loc) {
    atomic {
      nmemcpy(&myLoc, loc, sizeof(location_3d_t));
    }
    post locationTask();
  }

  command result_t LocationX.execute(uint8_t instr,
				     MateContext* context) {
    return getLocation(context, LOCATION_X);
  }

  command result_t LocationY.execute(uint8_t instr,
				     MateContext* context) {
    return getLocation(context, LOCATION_Y);
  }

  event void EngineStatus.rebooted() {
    currentContext = NULL;
    call Queue.init(&waitQueue);
  }

  event result_t Synch.makeRunnable(MateContext* context) {
    return SUCCESS;
  }
}
