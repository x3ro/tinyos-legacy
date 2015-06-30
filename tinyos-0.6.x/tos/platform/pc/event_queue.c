/*                                                                      tab:4
 *
 *
 * "Copyright (c) 2001 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:             Philip Levis
 *
 */

/*
 *   FILE: event_queue.c
 * AUTHOR: Philip Levus <pal@cs.berkeley.edu>
 *   DESC: Event queue for discrete event simulation
 */

#include "event_queue.h"
#include "tossim.h"
#include "dbg.h"
#include "external_comm.h"
#include <unistd.h>
#include <time.h>

extern short TOS_LOCAL_ADDRESS;

struct timespec length;

void queue_init(event_queue_t* queue, int pause) {
  init_heap(&(queue->heap));
  queue->pause = pause;
  pthread_mutex_init(&(queue->lock), NULL);
}

void queue_insert_event(event_queue_t* queue, event_t* event) {
  if (dbg_active(DBG_QUEUE)) {
    char time[128];
    time[0] = 0;
    printOtherTime(time, 128, event->time);
    dbg(DBG_QUEUE, ("Inserting event with time %s.\n", time));
  }
  pthread_mutex_lock(&(queue->lock));
  heap_insert(&(queue->heap), event, event->time);
  pthread_mutex_unlock(&(queue->lock));
}

event_t* queue_pop_event(event_queue_t* queue) {
  long long time;
  event_t* event;

  pthread_mutex_lock(&(queue->lock));
  event = (event_t*)(heap_pop_min_data(&(queue->heap), &time));
  pthread_mutex_unlock(&(queue->lock));

  if(dbg_active(DBG_QUEUE)) {
    char timeStr[128];
    timeStr[0] = 0;
    printOtherTime(timeStr, 128, time);
    dbg(DBG_QUEUE, ("Popping event for mote %i with time %s.\n", event->mote, timeStr));
  }
  
  if (queue->pause > 0 && event->pause) {
    sleep(queue->pause);
    dbg(DBG_ALL, ("\n"));
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
    NODE_NUM = event->mote;
    dbg(DBG_QUEUE, ("Setting TOS_LOCAL_ADDRESS to %hi\n", (short)(event->mote & 0xffff)));
    TOS_LOCAL_ADDRESS = (short)(event->mote & 0xffff);
    event->handle(event, &tos_state); 
  }
}
