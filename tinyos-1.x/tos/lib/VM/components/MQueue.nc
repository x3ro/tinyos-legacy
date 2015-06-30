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
 * History:   July 25, 2004
 *	     
 *
 */

/**
 * @author Philip Levis
 */


includes Mate;

module MQueue {
  provides interface MateQueue as Queue;
  uses interface MateError;
}


implementation {

  void list_insert_before(list_link_t* before, list_link_t* toInsert) {
    toInsert->l_next = before;
    toInsert->l_prev = before->l_prev;
    before->l_prev->l_next = toInsert;
    before->l_prev = toInsert;
  }

  void list_insert_head(list_t* list, list_link_t* element) {
    list_insert_before(list->l_next, element);
  } 

  void list_insert_tail(list_t* list, list_link_t* element) {
    list_insert_before(list, element);
  } 

  void list_remove(list_link_t* ll) {
    list_link_t *before = ll->l_prev;
    list_link_t *after = ll->l_next;
    if (before->l_next != ll &&
	after->l_prev != ll) {
      ll->l_next = 0;
      ll->l_prev = 0;
      return;
    }
    else if (before->l_next != ll ||
	     after->l_prev != ll) {
      dbg(DBG_ERROR, "VM: ERROR: corrupted queue\n");
      return;
    }
    before->l_next = after;
    after->l_prev = before;
    ll->l_next = 0;
    ll->l_prev = 0;        
  }

  void list_remove_head(list_t* list) {
    list_remove((list)->l_next);
  }

  void list_remove_tail(list_t* list) {
    list_remove((list)->l_prev);
  }

  void list_init(list_t* list) {
    dbg(DBG_BOOT, "QUEUE: Initializing queue at 0x%x.\n", list);
    list->l_next = list->l_prev = list;
  }
	
  bool list_empty(list_t* list) {
    return ((list->l_next == list)? TRUE:FALSE);
  }

  command result_t Queue.init(MateQueue* queue) {
    dbg(DBG_USR2, "VM: Initializing queue 0x%x\n", queue);
    list_init(&queue->queue);
    return SUCCESS;
  }

  command bool Queue.empty(MateQueue* queue) {
    bool emp = list_empty(&queue->queue);
    dbg(DBG_USR2, "VM: Testing if queue at 0x%x is empty: %s.\n", queue, (emp)? "true":"false");
    return emp;
  }

  command result_t Queue.enqueue(MateContext* context,
				 MateQueue* queue,
				 MateContext* element) {
    dbg(DBG_USR2, "VM (%i): Enqueue %i on 0x%x...", (int)context->which, (int)element->which, queue);
    if (element->queue) {
      call MateError.error(context, MATE_ERROR_QUEUE_ENQUEUE);
      dbg_clear(DBG_USR2, "FAILURE, already there\n");
      return FAIL;
    }
    element->queue = queue;
    list_insert_head(&queue->queue, &element->link);
    dbg_clear(DBG_USR2, "success\n");
    return SUCCESS;
  }

  command MateContext* Queue.dequeue(MateContext* context,
					 MateQueue* queue) {
    MateContext* rval;
    list_link_t* listLink;;

    if (list_empty(&queue->queue)) {
      call MateError.error(context, MATE_ERROR_QUEUE_DEQUEUE);
      return NULL;
    }
    
    listLink = queue->queue.l_prev;
    rval = (MateContext*)((char*)listLink - offsetof(MateContext, link));
    list_remove(listLink);
    rval->link.l_next = 0;
    rval->link.l_prev = 0;
    rval->queue = NULL;
    if (rval != NULL) {
      dbg(DBG_USR2, "VM: Dequeuing context %i from queue 0x%x.\n", (int)rval->which, queue);
    }
    //dbg(DBG_USR2, "VM (%i): Dequeue %i from 0x%x\n", (int)context->which, (int)rval->which, queue);
    return rval;
  }

  command result_t Queue.remove(MateContext* context,
				MateQueue* queue,
				MateContext* element) {
    dbg(DBG_USR2, "VM (%i): Removing context %i from queue 0x%x.\n", (int)context->which, (int)element->which, queue);
    if (element->queue != queue) {
      call MateError.error(context, MATE_ERROR_QUEUE_REMOVE);
      return FAIL;
    }
    element->queue = NULL;
    if (!(element->link.l_next && element->link.l_prev)) {
      call MateError.error(context, MATE_ERROR_QUEUE_REMOVE);
      return FAIL;
    }
    else {
      list_remove(&element->link);
      return SUCCESS;
    }
  }


}

