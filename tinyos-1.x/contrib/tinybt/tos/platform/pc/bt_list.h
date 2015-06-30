/*                                                                      tab:4
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
/*                                                                      tab:4
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
 *      Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *      Redistributions in binary form must reproduce the above copyright
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
 * Generic list support for the BT code.
 *
 * <p>Lifted from the Bombilla source.</p> */

#ifndef __BT_LIST_H__
#define __BT_LIST_H__

/* Look up the documentation in tos/types/list.h */
#include "list.h"

/** We can get away with including code in .h files because of the way
    TinyOS works... (Kids, don't do this at home!). */

void list_insert_before(list_link_t* before, list_link_t* new) {
  new->l_next = before;
  new->l_prev = before->l_prev;
  before->l_prev->l_next = new;
  before->l_prev = new;
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


/**
 * Get the size of the list. 
 *
 * \param list a pointer to a list
 * \return The number of elements in the list
*/
int list_size(list_t * list) {
  list_link_t *mylink;
  int res = 0;
  for (mylink = list->l_next; mylink != list; mylink = mylink->l_next) {
    res++;
  }
  return res;
}

#endif
