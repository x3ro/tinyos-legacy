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
 * Authors:		Philip Levis
 * Date last modified:  3/10/04
 *
 *
 */

/**
 * @author Philip Levis
 */

includes Mate;

/**
 * Interface that specifies the operations on operand and return
 * stacks in Mate'.
 *
 */

interface MateStacks {

  /**
   * Resets both stacks in a context; the operand stack and the
   * return stack are both emptied.
   *
   * @param context The context whose stacks should be cleared.
   *
   * @return SUCCESS if both stacks emptied, FAIL otherwise.
   */
  command result_t resetStacks(MateContext* context);

  /**
   * Push a 16-bit signed value onto a context's operand stack.
   *
   * @param context The context to modify
   *
   * @param val The value to push
   *
   * @return SUCCESS if the value was placed on the stack, FAIL
   * otherwise (e.g. stack overflow).
   */
  
  command result_t pushValue(MateContext* context, int16_t val);

  /**
   * Push a 16-bit signed sensor reading onto a context's operand stack.
   *
   * @param context The context to modify
   *
   * @param type The sensor reading type (one of BOMB_DATA_*)
   *
   * @param val The value to push
   *
   * @return SUCCESS if the value was placed on the stack, FAIL
   * otherwise (e.g. stack overflow).
   */
  
  command result_t pushReading(MateContext* context, uint8_t type, int16_t val);

  /**
   * Push a Mate data buffer onto a context's operand stack.
   *
   * @param context The context to modify
   *
   * @param buf The buffer to push
   *
   * @return SUCCESS if the value was placed on the stack, FAIL
   * otherwise (e.g. stack overflow).
   */
  
  command result_t pushBuffer(MateContext* context, MateDataBuffer* buf);

  
  /**
   * Push a generic operand onto a context's operand stack. This is
   * useful when the type of the operand is irrelevant or unknown
   * (e.g. pushing a variable that was popped).
   *
   * @param context The context to modify
   *
   * @param var The variable to push.
   *
   * @return SUCCESS if the value was placed on the stack, FAIL
   * otherwise (e.g. stack overflow).
   */
  
  command result_t pushOperand(MateContext* context, MateStackVariable* var);
  
  /**
   * Pop an operand off of a context's operand stack. If the stack is empty,
   * a variable of type BOMB_TYPE_NONE is returned.
   *
   * @param context The context to pop from.
   *
   * @return The variable popped. If the operand stack is empty when
   * called, a variable of type BOMB_TYPE_INVALID is returned.
   */
  command MateStackVariable* popOperand(MateContext* context);

  /**
   * Gets the depth of the operand stack of a context.
   *
   * @return The depth.
   */
    
  command uint8_t getOpStackDepth(MateContext* context);


}

