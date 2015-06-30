/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
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
 * Authors:   Neil Patel
 * History:   July 19, 2002
 *	     
 *
 */

includes Bombilla;

module BError {
  uses {
    interface Leds;
    interface BombillaContextComm as Comm;
    interface Timer;
    interface SendMsg as SendError;
  }
  provides interface BombillaError;
}

implementation {
  BombillaState* state;
  
  event result_t Comm.registerCapsule(BombillaState* data) {
    state = data;
    return SUCCESS;
  }
  
  event result_t Comm.analyzeLockSets(BombillaState* s) {
    return SUCCESS;
  }

  command result_t BombillaError.error(BombillaContext* context, uint8_t cause) {
    state->inErrorState = TRUE;
    dbg(DBG_ERROR|DBG_USR1, "VM: Entering ERROR state. Context: %i, cause %i\n", (int)context->which, (int)cause);
    call Leds.redOn();
    call Leds.greenOn();
    call Leds.yellowOn();
    call Timer.start(TIMER_REPEAT, 1000);
    state->errorContext = context;
    if (context != NULL) {
      state->errorContext = context;
      state->errorMsg.context = context->which;
      state->errorMsg.reason = cause;
      state->errorMsg.capsule = context->capsule->capsule.type;
      state->errorMsg.instruction = context->pc - 1;
      context->state = BOMB_STATE_HALT;
    }
    else {
      state->errorMsg.context = BOMB_CAPSULE_INVALID;
      state->errorMsg.reason = cause;
      state->errorMsg.capsule = BOMB_CAPSULE_INVALID;
      state->errorMsg.instruction = 255;
    }
    return SUCCESS;
  }

  event result_t Timer.fired() {
    dbg(DBG_USR1|DBG_ERROR, "VM: ERROR\n");
    if (!state->inErrorState) {
      call Timer.stop();
      return FAIL;
    }
    call Leds.redToggle();
    call Leds.greenToggle();
    call Leds.yellowToggle();
    nmemcpy(state->errorContext->msg.data,
            &state->errorMsg,
            sizeof(BombillaErrorMsg));

    if (state->errorFlipFlop) {
      call SendError.send(TOS_UART_ADDR,
                          sizeof(BombillaErrorMsg),
                          (TOS_MsgPtr)&(state->errorContext->msg));
    }
    else {
      call SendError.send(TOS_BCAST_ADDR,
                          sizeof(BombillaErrorMsg),
                          (TOS_MsgPtr)&(state->errorContext->msg));
    }
    state->errorFlipFlop = !state->errorFlipFlop;
    return SUCCESS;
  }

  event result_t SendError.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }
}
