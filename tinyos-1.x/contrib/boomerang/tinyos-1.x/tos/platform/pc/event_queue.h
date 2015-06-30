// $Id: event_queue.h,v 1.1.1.1 2007/11/05 19:10:17 jpolastre Exp $

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
 *   FILE: event_queue.h
 * AUTHOR: pal
 *   DESC: Event priority queue for TOS simulation.
 *
 *   The event queue is the core of the TinyOS simulator. It is a wrapper
 *   around the heap functionality, providing synchronization (dynamic
 *   packet injection is performed by a separate thread that inserts events
 *   into the queue) and presenting a simulation-specific interface to the
 *   heap (every event is associated with an mote ID, etc.).
 *
 *
 */

/**
 * @author Philip Levis
 * @author pal
 */


#ifndef EVENT_QUEUE_H_INCLUDED
#define EVENT_QUEUE_H_INCLUDED

#include <heap_array.h>
#include <pthread.h>

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
  int force; // Whether this event type should always be executed
             // even if a mote is "turned off"
  void* data;
  
  void (*handle)(struct event*, struct TOS_state*);
  void (*cleanup)(struct event*);
} event_t;


void queue_init(event_queue_t* queue, int fpause);
void queue_insert_event(event_queue_t* queue, event_t* event);
event_t* queue_pop_event(event_queue_t* queue);
void queue_handle_next_event(event_queue_t* queue);
int queue_is_empty(event_queue_t* queue);
long long queue_peek_event_time(event_queue_t* queue);


#endif // EVENT_QUEUE_H_INCLUDED
