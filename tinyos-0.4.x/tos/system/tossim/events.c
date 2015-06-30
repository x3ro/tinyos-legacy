/*                                                                      tab:4
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
 *   FILE: events.c
 * AUTHOR: pal
 *   DESC: Implementation of events.
 */


#include <stdlib.h>
#include "dbg.h"
#include "events.h"
#include "tos.h"
#include "super.h"

void event_default_cleanup(event_t* event) {
  free(event->data);
}

void event_total_cleanup(event_t* event) {
  free(event->data);
  free(event);
}

void event_clocktick_handle(event_t* event,
			    struct TOS_state* state) {


  event_queue_t* queue = &(state->queue);
  clock_tick_data_t* data = (clock_tick_data_t*)event->data;
  TOS_LOCAL_ADDRESS = (short)(event->mote & 0xffff);

  if (TOS_LOCAL_ADDRESS != event->mote) {
    printf("ERROR!\n");
  }

  if (data->valid) {
    dbg(DBG_CLOCK, ("CLOCK: event handled for mote %i at %lli with interval of %i.\n", event->mote, event->time, data->interval));
    
    event->time = event->time + data->interval;
    queue_insert_event(queue, event);
    
    TOS_ISSUE_INTERRUPT(_output_compare2_)();
  }
  else {
    dbg(DBG_CLOCK, ("CLOCK: invalid event discarded.\n"));

    event->cleanup(event);
    free(event);
  }
}

void event_clocktick_create(event_t* event, int mote, long long time, int interval) {
  //long long time = THIS_NODE.time;

  clock_tick_data_t* data = malloc(sizeof(clock_tick_data_t));
  data->interval = interval;
  data->mote = mote;
  data->valid = 1;
  
  event->mote = mote;
  event->pause = 1;
  event->data = data;
  event->time = time;
  event->handle = event_clocktick_handle;
  event->cleanup = event_default_cleanup;
}

void event_clocktick_invalidate(event_t* event) {
  clock_tick_data_t* data = event->data;
  data->valid = 0;
}
