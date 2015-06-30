/*                                                                      tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
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
 *   FILE: event_queue.h
 * AUTHOR: pal
 *   DESC: Event priority queue for TOS simulation.
 */

#ifndef EVENT_QUEUE_H_INCLUDED
#define EVENT_QUEUE_H_INCLUDED

#include "heap.h"
#include <sys/types.h>

//#include "tossim.h"

struct TOS_state;

typedef struct event_queue {
  int pause;
  heap_t heap;
  pthread_mutex_t lock;
} event_queue_t;

typedef struct event {
  long long time;
  int mote;
  int pause; // Whether this event causes the event queue to pause
  void* data;
  
  void (*handle)(struct event*, struct TOS_state*);
  void (*cleanup)(struct event*);
} event_t;


void queue_init(event_queue_t* queue, int pause);
void queue_insert_event(event_queue_t* queue, event_t* event);
event_t* queue_pop_event(event_queue_t* queue);
void queue_handle_next_event(event_queue_t* queue);
int queue_is_empty(event_queue_t* queue);
long long queue_peek_event_time(event_queue_t* queue);

#endif // EVENT_QUEUE_H_INCLUDED
