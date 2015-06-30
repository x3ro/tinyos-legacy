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
 * History:   July 21, 2004
 *	     
 *
 */

/**
 * @author Philip Levis
 */


includes Mate;

module MLocksSafe {
  provides interface MateLocks as Locks;
  provides command bool indexValid(uint8_t lockIndex);
  uses interface MateError;
}

implementation {
  MateLock locks[MATE_HEAPSIZE];
  
  command bool indexValid(uint8_t lockIndex) {
    if (lockIndex >= MATE_HEAPSIZE) {return FALSE;}
    else {return TRUE;}
  }

  command void Locks.reset() {
    int i;
    for (i = 0; i < MATE_HEAPSIZE; i++) {
      locks[i].holder = NULL;
    }
  }

  command result_t Locks.lock(MateContext* context,
                              uint8_t lockNum) {
    if (!(call indexValid(lockNum))) {
      call MateError.error(context, MATE_ERROR_INVALID_LOCK);
      return FAIL;
    }
    if (call Locks.isLocked(lockNum)) {
      dbg(DBG_ERROR, "VM: Context %i failed locking lock %i; already held by context %i.\n", (int)context->which, (int)lockNum, (int)locks[lockNum].holder->which);
      call MateError.error(context, MATE_ERROR_LOCK_STEAL);
      return FAIL;
    }
    locks[(int)lockNum].holder = context;
    context->heldSet[lockNum / 8] |= (1 << (lockNum % 8));
    dbg(DBG_USR2, "VM: Context %i locking lock %i\n", (int)context->which, (int)lockNum);
    return SUCCESS;
  }

  command result_t Locks.unlock(MateContext* context,
								uint8_t lockNum) {
    if (!(call indexValid(lockNum))) {
      call MateError.error(context, MATE_ERROR_INVALID_LOCK);
      return FAIL;
    }
    if (!call Locks.isLocked(lockNum)) {
      dbg(DBG_ERROR, "VM: Context %i failed unlocking lock %i: lock not held.\n", (int)context->which, (int)lockNum);
      call MateError.error(context, MATE_ERROR_UNLOCK_INVALID);
      return FAIL;
    }
    if (!(context->heldSet[lockNum / 8] & (1 << lockNum % 8 ))) {
      dbg(DBG_ERROR, "VM: Context %i failed unlocking lock %i: don't hold lock.\n", (int)context->which, (int)lockNum);
      call MateError.error(context, MATE_ERROR_UNLOCK_INVALID);
      return FAIL;
    }

    context->heldSet[lockNum / 8] &= ~(1 << (lockNum % 8));
    locks[(int)lockNum].holder = 0;
    dbg(DBG_USR2, "VM: Context %i unlocking lock %i\n", (int)context->which, (int)lockNum);

    return SUCCESS;

  }
	
  command bool Locks.isLocked(uint8_t lockNum) {
    if (!(call indexValid(lockNum))) {
      return TRUE;
    }
    return (locks[(int)lockNum].holder != 0);
  }
	
  command bool Locks.isHeldBy(uint8_t lockNum,
                              MateContext* context) {
    if (!(call indexValid(lockNum))) {
      return FALSE;
    }
    return (locks[(int)lockNum].holder == context);
  }

}

