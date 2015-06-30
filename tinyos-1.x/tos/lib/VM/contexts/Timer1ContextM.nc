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
 * Authors:   Philip Levis
 * History:   Feb 6  2002 Inception
 *            Mar 10 2004 Bombilla->Mate
 *
 */

/**
 * @author Philip Levis
 */


includes AM;
includes Mate;

module Timer1ContextM {
  provides {
    interface StdControl;
    interface Timer;
  }
  
  uses {
    interface StdControl as SubControlTimer;
    interface Timer as ClockTimer;      
    interface MateContextSynch as Synch;
    interface MateHandlerStore as HandlerStore;
    interface MateEngineStatus as EngineStatus;
  }
}


implementation {
  MateContext timerContext;
  
  command result_t StdControl.init() {
    result_t rval = call SubControlTimer.init();
    timerContext.which = MATE_CONTEXT_TIMER1;
    timerContext.rootHandler = MATE_HANDLER_TIMER1;

    rval &= call HandlerStore.initializeHandler();
    call Synch.initializeContext(&timerContext);    
    return rval;
  }

  command result_t StdControl.start() {
    return call SubControlTimer.start();
  }

  command result_t StdControl.stop() {
    call ClockTimer.stop();
    return call SubControlTimer.stop();
  }

  task void ClockEventTask() {
    if (timerContext.state == MATE_STATE_HALT) {
      dbg(DBG_USR1, "VM: Timer 1 context running.\n");
      call Synch.initializeContext(&timerContext);
      call Synch.resumeContext(&timerContext, &timerContext);
    }
    else {
      // drop the event
    }
  }
  
  event result_t ClockTimer.fired() {
    post ClockEventTask();
    return SUCCESS;
  }

  event void HandlerStore.handlerChanged() {
    dbg(DBG_USR3, "Timer1 Context: Handler changed.\n");
    if (timerContext.state != MATE_STATE_HALT) {
      call Synch.haltContext(&timerContext);
    }
  }

  event void EngineStatus.rebooted() {
    dbg(DBG_USR1, "Timer1 Context: VM rebooted.\n");
    call ClockTimer.stop();
    if (timerContext.state != MATE_STATE_HALT) {
      call Synch.haltContext(&timerContext);
    }
  }
  
  command result_t Timer.start(char type, uint32_t interval) {
    return call ClockTimer.start(type, interval);
  }

  command result_t Timer.stop() {
    return call ClockTimer.stop();
  }
  
  default event result_t Timer.fired() {
    return SUCCESS;
  }
}
