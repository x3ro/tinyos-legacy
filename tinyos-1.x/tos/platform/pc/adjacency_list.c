// $Id: adjacency_list.c,v 1.3 2004/02/24 04:31:47 scipio Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors: Nelson Lee
 *
 */
/*
 *
 *   FILE: adjacency_list.c
 * AUTHOR: nalee
 *   DESC: adjacency list abstraction for radio models
 *
 */

link_t* allocate_link(int mote) {
  link_t* alloc_link;
  int i;
  if (0 == num_free_links) {
    alloc_link = (link_t*)malloc(sizeof(link_t) * NUM_NODES_ALLOC);
    for (i=0; i < NUM_NODES_ALLOC-1; i++) {
      alloc_link[i].next_link = &alloc_link[i+1];
    }
    alloc_link[NUM_NODES_ALLOC-1].next_link = free_list;
    free_list = alloc_link;
    num_free_links += NUM_NODES_ALLOC;
  }
  else {
    alloc_link = free_list;
  }
  
  free_list = free_list->next_link;
  alloc_link->mote = mote;
  alloc_link->next_link = NULL;
  num_free_links--;
  return alloc_link;
  
}

int deallocate_link(link_t* fLink) {
  fLink->next_link = free_list;
  free_list = fLink;
  num_free_links++;
  return SUCCESS;
}

int adjacency_list_init() {
  int i;
  free_list = (link_t*)malloc(sizeof(link_t) * NUM_NODES_ALLOC);
  for (i=0; i < NUM_NODES_ALLOC-1; i++) {
    free_list[i].next_link = &free_list[i+1];
  }
  free_list[NUM_NODES_ALLOC-1].next_link = NULL;
  num_free_links = NUM_NODES_ALLOC;
  return SUCCESS;
}

