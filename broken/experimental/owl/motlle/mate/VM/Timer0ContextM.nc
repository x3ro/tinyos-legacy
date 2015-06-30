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
 * Authors:   Phil Levis
 * History:   Feb 6 2004         Inception.
 *
 */

/**
 * @author Phil Levis
 */


includes AM;
includes Mate;
includes MateConstants;

module Timer0ContextM {
  provides {
    interface StdControl;
    interface Timer;
  }
  
  uses {
    interface StdControl as SubControlTimer;
    interface Timer as ClockTimer;      
    interface MateContextSynch as Synch;
    interface MateAnalysis as Analysis;
    interface MateEngineControl as EngineControl;
    interface MateHandlerStore as HandlerStore;
  }
}


implementation {
  MateContext timerContext;
  
  command result_t StdControl.init() {
   result_t rval;
    rval = call SubControlTimer.init();
    timerContext.which = MATE_CONTEXT_TIMER0;
    timerContext.state = MATE_STATE_HALT;

    rval &= call HandlerStore.initializeHandler();
    timerContext.rootHandler = MATE_HANDLER_TIMER0;
    timerContext.currentHandler = timerContext.rootHandler;

    call Analysis.analyzeVars(timerContext.rootHandler);
    
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call SubControlTimer.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call SubControlTimer.stop();
    call ClockTimer.stop();
    return SUCCESS;
  }

  task void ClockEventTask() {
    if (timerContext.state == MATE_STATE_HALT) {
      call Synch.initializeContext(&timerContext);
      call Synch.resumeContext(&timerContext, &timerContext);
    }
    else {
      dbg(DBG_USR1, "VM: Timer 0 context not halted. Currently in state %i.\n", timerContext.state);
      // Can log a clock miss error here, but probably
      // not a good idea
    }
  }
  
  event result_t ClockTimer.fired() {
    dbg(DBG_USR1, "VM: Timer 0 timer fired, posting ClockEventTask.\n");
    post ClockEventTask();
    return SUCCESS;
  }

  event result_t Synch.makeRunnable(MateContext* context) {
    return SUCCESS;
  }

  
  event void HandlerStore.handlerChanged() {
    timerContext.currentHandler = timerContext.rootHandler;
    call Synch.initializeContext(&timerContext);
    call ClockTimer.stop();
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
