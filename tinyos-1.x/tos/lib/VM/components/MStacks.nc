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
 * History:   Oct.  6, 2004           Separated types from stacks.
 *            Jul. 19, 2004           Incorporated new type classification.
 *	     
 *
 */

/**
 * @author Philip Levis
 */


includes Mate;

module MStacks {
  provides interface MateStacks as Stacks;
  uses interface MateError;
}


implementation {

  MateOperandStack stacks[MATE_CONTEXT_NUM];
  
  command result_t Stacks.resetStacks(MateContext* context) {
    stacks[context->which].sp = 0;
    return SUCCESS;
  }
  
  command result_t Stacks.pushValue(MateContext* context, 
				    int16_t val) {
    if (stacks[context->which].sp >= MATE_OPDEPTH) {
      dbg(DBG_ERROR, "VM: Tried to push value off end of stack.\n");
      call MateError.error(context, MATE_ERROR_STACK_OVERFLOW);
      return FAIL;
    }
    else {
      uint8_t sIndex = stacks[context->which].sp;
      stacks[context->which].stack[(int)sIndex].type = MATE_TYPE_INTEGER;
      stacks[context->which].stack[(int)sIndex].value.var = val;
      stacks[context->which].sp++;
      return SUCCESS;
    }
  }

  command result_t Stacks.pushReading(MateContext* context, 
				      uint8_t type, 
				      int16_t val) {
    if (stacks[context->which].sp >= MATE_OPDEPTH) {
      dbg(DBG_ERROR, "VM: Tried to push value off end of stack.\n");
      call MateError.error(context, MATE_ERROR_STACK_OVERFLOW);
      return FAIL;
    }
    else {
      uint8_t sIndex = stacks[context->which].sp;
      stacks[context->which].stack[(int)sIndex].type = type;
      stacks[context->which].stack[(int)sIndex].value.var = val;
      stacks[context->which].sp++;
      return SUCCESS;
    }
    return SUCCESS;
  }

  command result_t Stacks.pushBuffer(MateContext* context, 
                                     MateDataBuffer* buffer) {
    if (stacks[context->which].sp >= MATE_OPDEPTH) {
      dbg(DBG_ERROR, "VM: Tried to push value off end of stack.\n");
      call MateError.error(context, MATE_ERROR_STACK_OVERFLOW);
      return FAIL;
    }
    else {
      uint8_t sIndex = stacks[context->which].sp;
      stacks[context->which].stack[(int)sIndex].type = MATE_TYPE_BUFFER;
      stacks[context->which].stack[(int)sIndex].buffer.var = buffer;
      stacks[context->which].sp++;
      return SUCCESS;
    }

    return SUCCESS;
  }

  command result_t Stacks.pushOperand(MateContext* context, 
				      MateStackVariable* var) {
    if (stacks[context->which].sp >= MATE_OPDEPTH) {
      dbg(DBG_ERROR, "VM: Tried to push value off end of stack.\n");
      call MateError.error(context, MATE_ERROR_STACK_OVERFLOW);
      return FAIL;
    }
    else {
      uint8_t sIndex = stacks[context->which].sp;
      stacks[context->which].stack[(int)sIndex] = *var;
      stacks[context->which].sp++;
      return SUCCESS;
    }

    return SUCCESS;
  }

  command MateStackVariable* Stacks.popOperand(MateContext* context) {

    MateStackVariable* var;
    if (stacks[context->which].sp == 0) {
      dbg(DBG_ERROR, "VM: Tried to pop off end of stack.\n");
      stacks[context->which].stack[0].type = MATE_TYPE_NONE;
      call MateError.error(context, MATE_ERROR_STACK_UNDERFLOW);
      return &(stacks[context->which].stack[0]);
    }
    else {
      uint8_t sIndex;
      stacks[context->which].sp--;
      sIndex = stacks[context->which].sp;
      var = &(stacks[context->which].stack[(int)sIndex]);
      return var;
    }
    return NULL;

  }

  command uint8_t Stacks.getOpStackDepth(MateContext* context) {
    return stacks[context->which].sp;
  }
  
}
  
    
  
  

  
  




