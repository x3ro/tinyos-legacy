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
 * Interface to Mate sychronization operations.
 *
 */

interface MateContextLocks  {

  /**
   * Returns whether the non-running context can acquire all of the
   * locks it needs in the shared lock set.
   *
   * @param context The non-running context whose runnability is being
   * checked.
   *
   * @param locks The shared lock set.
   *
   * @return TRUE if the context can acquire all of the locks it needs,
   * FALSE otherwise.
   */
  
  command bool isRunnable(MateContext* context);
  
  /**
   * The obtainer context locks its acquire set.
   *
   * @param caller The running context whose execution causes obtainer to
   * lock its acquire set (due to triggering, yield, etc.).
   *
   * @param obtainer The non-running context who is to lock its acquire set.
   *
   * @param locks The shared lock set.
   *
   * @return SUCCESS if obtainer locks all of the locks in its acquire set,
   * FALSE otherwise.
   */
  
  command result_t obtainLocks(MateContext* caller,
                               MateContext* obtainer);
			       
  /**
   * The releaser context unlocks its release set.
   *
   * @param caller The running context whose execution causes releaser
   * to unlock its release set (due to triggering, yield, etc.). This
   * is often (but not necessarily always) the same context as the
   * releaser.
   *
   * @param releaser The context who is to unlock its release set.
   *
   * @param locks The shared lock set.
   *
   * @return SUCCESS if releaser unlocks all of the locks in its release set,
   * FALSE otherwise.
   */
  
  command result_t releaseLocks(MateContext* caller,
                                MateContext* releaser);
				  
  /**
   * The releaser context unlocks all locks it holds (its held set).
   *
   * @param caller The running context whose execution causes releaser to
   * unlock its release set (due to triggering, yield, etc.). This is
   * often (but not necessarily always) the same context as releaser.
   *
   * @param releaser The running context who is to unlock its held set.
   *
   * @param locks The shared lock set.
   *
   * @return SUCCESS if releaser unlocks all of the locks in its held set,
   * FALSE otherwise.
   */
  
  command result_t releaseAllLocks(MateContext* caller,
                                   MateContext* releaser);
				   
}
