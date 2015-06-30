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

/**
 * @author Philip Levis <pal@cs.berkeley.edu>
 * @author Neil Patel
 */


includes Mate;

module OPone_hop_regionM {

  provides {
    interface MateBytecode as Create;
    interface MateBytecode as GetNum;
    interface MateBytecode as GetElements;
    interface StdControl;
  }

  uses {
    interface MateQueue as Queue;
    interface MateContextSynch as Synch;
    interface MateError as Error;
    interface MateTypes as Types;
    interface MateStacks as Stacks;
    interface MateEngineStatus as EngineStatus;
    interface Region as RadioRegion;
  }
}

implementation {
  MateQueue sendWaitQueue;
  MateContext* sendingContext;
    
  command result_t StdControl.init() {
    call Queue.init(&sendWaitQueue);
    sendingContext = NULL;
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command uint8_t Create.byteLength() {return 1;}
  command uint8_t GetNum.byteLength() {return 1;}
  command uint8_t GetElements.byteLength() {return 1;}

  command result_t Create.execute(uint8_t instr,
				  MateContext* context) {
    
    if (call RadioRegion.getRegion() == SUCCESS) {
      dbg(DBG_USR1, "VM (%i): Creating neighborhood.\n", (int)context->which);
      context->state = MATE_STATE_SENDING;
      sendingContext = context;
    }
    else {
      dbg(DBG_USR1, "VM (%i): Neighborhood create request refused.\n", (int)context->which);
      context->pc--;
      call Queue.enqueue(context, &sendWaitQueue, context);
      context->state = MATE_STATE_SEND_WAIT;
    }
    call Synch.releaseLocks(context, context);
    call Synch.yieldContext(context);
    
    return SUCCESS;
  }

  event void RadioRegion.getDone(result_t success) {
    if (sendingContext == NULL) {
      return;
    }
    else {
      // It would be nice to check for failure here,
      // but what would you do?
      MateContext* sender = sendingContext;
      sendingContext = NULL;
      dbg(DBG_USR1, "VM (%i): Neighborhood created.\n", (int)sender);
      call Synch.resumeContext(sender, sender);
      
      if (call Queue.empty(&sendWaitQueue)) {return;}
      else {
	MateContext* newSender = call Queue.dequeue(sendingContext, &sendWaitQueue);
	if (sender->state != MATE_STATE_SEND_WAIT) {
	  call Error.error(newSender, MATE_ERROR_QUEUE_INVALID);
	}
	call Synch.resumeContext(sender, newSender);
      }
    }
  }

  command result_t GetNum.execute(uint8_t instr,
				  MateContext* context) {
    uint16_t val = (uint16_t) call RadioRegion.numNodes();
    dbg(DBG_USR1, "VM (%i): Getting neighborhood count.\n", (int)context->which);
    call Stacks.pushValue(context, val);
    return SUCCESS;
  }

  command result_t GetElements.execute(uint8_t instr,
				       MateContext* context) {
     MateStackVariable* arg = call Stacks.popOperand(context);
     if (!call Types.checkTypes(context, arg, MATE_VAR_B)) {return FAIL;}
     else {
       MateDataBuffer* buffer = arg->buffer.var;
       uint16_t* ptr;
       dbg(DBG_USR1, "VM (%i): Getting neighborhood elements.\n", (int)context->which);
       call RadioRegion.getNodes(&ptr);
       nmemcpy((uint16_t*)buffer->entries, ptr, MATE_BUF_LEN);
     }
     return SUCCESS;
  }

  event result_t Synch.makeRunnable(MateContext* context) {
    return SUCCESS;
  }
  
  event void EngineStatus.rebooted() {
    sendingContext = NULL;
    call Queue.init(&sendWaitQueue);
  }
}
