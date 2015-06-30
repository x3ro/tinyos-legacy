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
 * History:   Apr 14, 2003         Inception.
 *
 */

/**
 * @author Philip Levis <pal@cs.berkeley.edu>
 */


includes Mate;

module OPbpush3M {
  provides interface MateBytecode;
  provides interface MateBytecodeLock;
  
  uses {
    interface MateStacks as Stacks;
    interface MateEngineStatus as EngineStatus;
    interface MateLocks as Locks;
    interface MateError as Error;
  }
  
}

implementation {
  typedef enum {
    MATE_BUF_LOCK_3_0 = unique("MateLock"),
    MATE_BUF_LOCK_3_1 = unique("MateLock"),
    MATE_BUF_LOCK_3_2 = unique("MateLock"),
    MATE_BUF_LOCK_3_3 = unique("MateLock"),
    MATE_BUF_LOCK_3_4 = unique("MateLock"),
    MATE_BUF_LOCK_3_5 = unique("MateLock"),
    MATE_BUF_LOCK_3_6 = unique("MateLock"),
    MATE_BUF_LOCK_3_7 = unique("MateLock"),
    MATE_BUF_3_NUM = 8,
  } BufLockNames;
  
  MateDataBuffer buffers[MATE_BUF_3_NUM];
  
  uint8_t varToLock(uint8_t arg) {
    switch (arg) {
    case 0:
      return MATE_BUF_LOCK_3_0;
    case 1:
      return MATE_BUF_LOCK_3_1;
    case 2:
      return MATE_BUF_LOCK_3_2;
    case 3:
      return MATE_BUF_LOCK_3_3;
    case 4:
      return MATE_BUF_LOCK_3_4;
    case 5:
      return MATE_BUF_LOCK_3_5;
    case 6:
      return MATE_BUF_LOCK_3_6;
    case 7:
      return MATE_BUF_LOCK_3_7;
    default:
      return 255;
    }
  }
  
    
  command result_t MateBytecode.execute(uint8_t instr,
					    MateContext* context) {
    uint8_t lock = varToLock(instr - OP_BPUSH3);
    dbg(DBG_USR1, "VM (%i): Pushing buffer %i onto stack\n", context->which, instr & 0x1);
    if ((lock == 255) || !call Locks.isHeldBy(lock, context)) {
       call Error.error(context, MATE_ERROR_INVALID_ACCESS);
       return FAIL;
    }
    call Stacks.pushBuffer(context, &buffers[instr - OP_BPUSH3]);
    return SUCCESS;
  }
  
  command uint8_t MateBytecode.byteLength() {return 1;}
  
  command int16_t MateBytecodeLock.lockNum(uint8_t instr, uint8_t id,
					   uint8_t pc) {
    return varToLock(instr - OP_BPUSH3);
  }
  
  event void EngineStatus.rebooted() {
    int i;
    for (i=0; i < MATE_BUF_3_NUM; i++) {
      buffers[i].type = MATE_TYPE_NONE;
      buffers[i].size = 0;
    }
  }

}
