// $Id: event_queue.c,v 1.6 2004/02/24 04:31:47 scipio Exp $

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
 *
 * Authors:             Philip Levis
 *
 */

/*
 *   FILE: event_queue.c
 * AUTHOR: Philip Levis <pal@cs.berkeley.edu>
 *   DESC: Event queue for discrete event simulation
 */

#include <unistd.h>
#include <time.h>

//*********renamed from length to event_queue_length
struct timespec event_queue_length;

//static void dbg(TOS_dbg_mode mode, const char *format, ...); 

void queue_init(event_queue_t* queue, int fpause) {
  init_heap(&(queue->heap));
  queue->pause = fpause;
  pthread_mutex_init(&(queue->lock), NULL);
}

void queue_insert_event(event_queue_t* queue, event_t* event) {
  pthread_mutex_lock(&(queue->lock));
  heap_insert(&(queue->heap), event, event->time);
  pthread_mutex_unlock(&(queue->lock));
}

event_t* queue_pop_event(event_queue_t* queue) {
  long long ftime;
  event_t* event;

  pthread_mutex_lock(&(queue->lock));
  event = (event_t*)(heap_pop_min_data(&(queue->heap), &ftime));
  pthread_mutex_unlock(&(queue->lock));

  if(dbg_active(DBG_QUEUE)) {
    char timeStr[128];
    timeStr[0] = 0;
    printOtherTime(timeStr, 128, ftime);
    dbg(DBG_QUEUE, "Popping event for mote %i with time %s.\n", event->mote, timeStr);
  }
  
  if (queue->pause > 0 && event->pause) {
    sleep(queue->pause);
    //dbg(DBG_ALL, "\n");
  }
  
  return event;
}

int queue_is_empty(event_queue_t* queue) {
  int rval;
  pthread_mutex_lock(&(queue->lock));
  rval = heap_is_empty(&(queue->heap));
  pthread_mutex_unlock(&(queue->lock));
  return rval;
}

long long queue_peek_event_time(event_queue_t* queue) {
  long long rval;
  
  pthread_mutex_lock(&(queue->lock));
  if (heap_is_empty(&(queue->heap))) {
    rval = -1;
  }
  else {
    rval = heap_get_min_key(&(queue->heap));
  }

  pthread_mutex_unlock(&(queue->lock));
  return rval;
}

void queue_handle_next_event(event_queue_t* queue) {
  event_t* event = queue_pop_event(queue);
  if (event != NULL) {
    if (tos_state.moteOn[event->mote] || event->force) {
      NODE_NUM = event->mote;
      dbg(DBG_QUEUE, "Setting TOS_LOCAL_ADDRESS to %hi\n", (short)(event->mote & 0xffff));
      atomic TOS_LOCAL_ADDRESS = (short)(event->mote & 0xffff);
      event->handle(event, &tos_state); 
    } 
  }
}


