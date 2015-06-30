// $Id: Queue.nc,v 1.3 2006/05/23 21:05:59 chien-liang Exp $

/* Agilla - A middleware for wireless sensor networks.
 * Copyright (C) 2004, Washington University in Saint Louis 
 * By Chien-Liang Fok.
 * 
 * Washington University states that Agilla is free software; 
 * you can redistribute it and/or modify it under the terms of 
 * the current version of the GNU Lesser General Public License 
 * as published by the Free Software Foundation.
 * 
 * Agilla is distributed in the hope that it will be useful, but 
 * THERE ARE NO WARRANTIES, WHETHER ORAL OR WRITTEN, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO, IMPLIED WARRANTIES OF 
 * MERCHANTABILITY OR FITNESS FOR A PARTICULAR USE.
 *
 * YOU UNDERSTAND THAT AGILLA IS PROVIDED "AS IS" FOR WHICH NO 
 * WARRANTIES AS TO CAPABILITIES OR ACCURACY ARE MADE. THERE ARE NO 
 * WARRANTIES AND NO REPRESENTATION THAT AGILLA IS FREE OF 
 * INFRINGEMENT OF THIRD PARTY PATENT, COPYRIGHT, OR OTHER 
 * PROPRIETARY RIGHTS.  THERE ARE NO WARRANTIES THAT SOFTWARE IS 
 * FREE FROM "BUGS", "VIRUSES", "TROJAN HORSES", "TRAP DOORS", "WORMS", 
 * OR OTHER HARMFUL CODE.  
 *
 * YOU ASSUME THE ENTIRE RISK AS TO THE PERFORMANCE OF SOFTWARE AND/OR 
 * ASSOCIATED MATERIALS, AND TO THE PERFORMANCE AND VALIDITY OF 
 * INFORMATION GENERATED USING SOFTWARE. By using Agilla you agree to 
 * indemnify, defend, and hold harmless WU, its employees, officers and 
 * agents from any and all claims, costs, or liabilities, including 
 * attorneys fees and court costs at both the trial and appellate levels 
 * for any loss, damage, or injury caused by your actions or actions of 
 * your officers, servants, agents or third parties acting on behalf or 
 * under authorization from you, as a result of using Agilla. 
 *
 * See the GNU Lesser General Public License for more details, which can 
 * be found here: http://www.gnu.org/copyleft/lesser.html
 */

/*                  tab:4
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
/*                  tab:4
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
 *  Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *  Redistributions in binary form must reproduce the above copyright
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
 * History:   July 25, 2002
 *
 *
 */

/**
 * @author Philip Levis
 */


includes Agilla;
includes TupleSpace;
includes list;

module Queue {
  provides interface QueueI;
  uses interface ErrorMgrI;
}


implementation {

  void list_insert_before(list_link_t* before, list_link_t* n) {
    n->l_next = before;
    n->l_prev = before->l_prev;
    before->l_prev->l_next = n;
    before->l_prev = n;
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
  
  #if DEBUG_QUEUE
  char* toString(Queue* queue) {
      switch(queue->id) {
        case AGILLA_ENGINE:
          return "AGILLA_ENGINE";
        case OP_DIRECTORY_M:
          return "OP_DIRECTORY_M";
        case OP_GET_AGENTS_CM:
          return "OP_GET_AGENTS_CM";
        case OP_GET_AGENTS_M:
          return "OP_GET_AGENTS_M";
        case OP_GET_CLOSEST_AGENT_CM:
          return "OP_GET_CLOSEST_AGENT_CM";
        case OP_GET_CLOSEST_AGENT_M:
          return "OP_GET_CLOSEST_AGENT_M";
        case OP_GET_LOCATION_CM:
          return "OP_GET_LOCATION_CM";
        case OP_GET_LOCATION_M:
          return "OP_GET_LOCATION_M";
        case OP_GET_NUM_AGENTS_CM:
          return "OP_GET_NUM_AGENTS_CM";
        case OP_GET_NUM_AGENTS_M:
          return "OP_GET_NUM_AGENTS_M";
        case OP_RTS_M:
          return "OP_RTS_M";
        case OP_SENSE_MTS310CA_M:
          return "OP_SENSE_MTS310CA_M";
        case OP_SENSE_MTS420CA_M:
          return "OP_SENSE_MTS420CA_M";
        case OP_SLEEP_M:
          return "OP_SLEEP_M";
        case OP_TS_M:
          return "OP_TS_M";
      }
      return "UNKNOWN";
  }  
  #endif

  command result_t QueueI.init(Queue* queue, uint16_t id) {
    queue->id = id;
    list_init(&queue->queue);
    #if DEBUG_QUEUE
      dbg(DBG_USR1, "Initializing queue %s.\n", toString(queue));
    #endif
    return SUCCESS;
  }

  command bool QueueI.empty(Queue* queue) {
    bool emp = list_empty(&queue->queue);
    return emp;
  }

  command result_t QueueI.enqueue(AgillaAgentContext* context,
    Queue* queue, AgillaAgentContext* element) 
  {
    #if DEBUG_QUEUE
      dbg(DBG_USR1, "QueueI.enqueue...%i\n", queue->id);
      //dbg(DBG_USR1, "VM (%i:%i): QueueI.enqueue: Enqueue on %s\n", context->id.id, context->pc, toString(queue));
    #endif
    
    if (element->queue) {
      #if DEBUG_QUEUE
        dbg(DBG_USR1, "QueueI.enqueue...ERROR...%i\n", queue->id);
        //dbg(DBG_USR1, "VM (%i:%i): QueueI.enqueue: ERROR: current queue = %s\n", context->id.id, context->pc, toString(element->queue));
      #endif    
      call ErrorMgrI.error(context, AGILLA_ERROR_QUEUE_ENQUEUE);
      return FAIL;
    }
    element->queue = queue;
    list_insert_head(&queue->queue, &element->link);
    return SUCCESS;
  }

  command AgillaAgentContext* QueueI.dequeue(AgillaAgentContext* context, Queue* queue) {
    AgillaAgentContext* rval;
    list_link_t* listLink;;
    
    #if DEBUG_QUEUE
      dbg(DBG_USR1, "QueueI.dequeue...%i\n", queue->id);
      //dbg(DBG_USR1, "VM (%i:%i): Dequeue from %s\n", context->id.id, context->pc, toString(queue));
    #endif
    if (list_empty(&queue->queue)) {
      call ErrorMgrI.error(context, AGILLA_ERROR_QUEUE_DEQUEUE);
      return NULL;
    }

    listLink = queue->queue.l_prev;
    rval = (AgillaAgentContext*)((char*)listLink - offsetof(AgillaAgentContext, link));
    list_remove(listLink);
    rval->link.l_next = 0;
    rval->link.l_prev = 0;
    rval->queue = NULL;
    //if (rval != NULL) {
    //  dbg(DBG_USR2, "VM: Dequeuing context %i from queue 0x%x.\n", (int)rval->id.id, queue);
    //}    
    return rval;
  }

  command result_t QueueI.remove(AgillaAgentContext* context,
        Queue* queue,
        AgillaAgentContext* element) {

    #if DEBUG_QUEUE
      dbg(DBG_USR1, "QueueI.remove...%i\n", queue->id);      
    #endif
    
    if (element->queue != queue) {
      call ErrorMgrI.error(context, AGILLA_ERROR_QUEUE_REMOVE);
      return FAIL;
    }
    element->queue = NULL;
    if (!(element->link.l_next && element->link.l_prev)) {
      call ErrorMgrI.error(context, AGILLA_ERROR_QUEUE_REMOVE);
      return FAIL;
    }
    else {
      list_remove(&element->link);
      return SUCCESS;
    }
  }
}

