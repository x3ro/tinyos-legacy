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
 * Date last modified:  7/18/02
 *
 *
 */
includes BombillaMsgs;
includes Bombilla;

/**
 * Interface for operating on Bombilla context queues.
 *
 */

interface BombillaQueue {

  /**
   * Initialize a queue.
   *
   * @param queue The queue to initialize.
   *
   * @return SUCCESS if initialized properly, FAIL otherwise.
   */
  
  command result_t init(BombillaQueue* queue);


  /**
   * Whether a queue is empty.
   *
   * @param queue The queue whose emptiness is being queried.
   *
   * @return TRUE if empty, FALSE otherwise.
   */
  
  command bool empty(BombillaQueue* queue);

  /**
   * Enqueue a context onto a queue on behalf of a context. The context
   * to be put on the queue cannot currently be on another queue.
   *
   * @param context The context performing the enqueue operation.
   *
   * @param queue The queue on which the element is to be placed.
   *
   * @param element The context to be placed on the queue.
   *
   * @return SUCCESS if enqueued properly, FAIL otherwise.
   */
  
  command result_t enqueue(BombillaContext* context,
			   BombillaQueue* queue,
			   BombillaContext* element);

  /**
   * Dequeue the next context from a queue.
   *
   * @param context The context performing the dequeue operation.
   *
   * @param queue The queue from which the context is to be removed.
   *
   * @return The removed context, NULL if queue was empty.
   */

  command BombillaContext* dequeue(BombillaContext* context,
				   BombillaQueue* queue);


  /**
   * Remove a specific context element from a queue.
   *
   * @param context The context performing the remove operation.
   *
   * @param queue The queue from which the element is to be removed.
   *
   * @param element The context to be removed from the queue.
   *
   * @return SUCCESS if removed properly, FAIL if not removed or
   * element was not on queue.
   */
  
  command result_t remove(BombillaContext* context,
			  BombillaQueue* queue,
			  BombillaContext* element);
}

