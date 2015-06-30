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
 * Authors:		Philip Levis
 * Date last modified:  7/21/02
 *
 *
 */
includes BombillaMsgs;
includes Bombilla;

/**
 * Interface for Bombilla lock accessors and mutators.
 *
 */


interface BombillaLocks {

  /**
   * Lock the specified lock on behalf of a context. Does not perform
   * bounds checks.
   * 
   * @param context The locking context.
   *
   * @param locks An array of locks.
   *
   * @param lockNum Which lock in the array to lock.
   *
   * @return SUCCESS if the lock is successfully locked, FAIL otherwise.
   */

  command result_t lock(BombillaContext* context, BombillaLock* locks, uint8_t lockNum);

  /**
   * Unlock the specified lock on behalf of a context. Does not perform
   * bounds checks. The specified lock must be held by context for this
   * operation to succeed.
   * 
   * @param context The unlocking context.
   *
   * @param locks An array of locks.
   *
   * @param lockNum Which lock in the array to unlock.
   *
   * @return SUCCESS if the lock is successfully unlocked, FAIL otherwise.
   */

  command result_t unlock(BombillaContext* context, BombillaLock* locks, uint8_t lockNum);

  /**
   * Whether a lock is locked or not. Does not perform bounds checks.
   * 
   * @param locks An array of locks.
   *
   * @param lockNum Which lock in the array to check.
   *
   * @return TRUE if locked, FALSE if unlocked.
   */

  command bool isLocked(BombillaLock* locks, uint8_t lockNum);

  /**
   * Whether a lock is held by a certain context.
   *
   * @param locks An array of locks.
   *
   * @param lockNum Which lock in the array to check.
   *
   * @param context The context whose ownership is being queried.
   *
   * @return TRUE if the lock is held by context, FALSE otherwise.
   */
  	
  command bool isHeldBy(BombillaLock* locks, uint8_t lockNum, BombillaContext* context);

}

