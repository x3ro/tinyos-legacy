/*									tab:4
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
 * Authors:		Jason Hill, Philip Levis {jhill,pal}@cs.berkeley.edu
 *
 *
 */

#include "tos.h"
#include "CLOCK.h"
#include "dbg.h"
#include "tossim.h"
#include "events.h"
#include <stdlib.h>

#define PROGMEM
#define __lpm_macro(x) *((char *)(x))

#define TINY
#ifndef TINY
unsigned char shifts[] PROGMEM = {8, 8, 7, 5, 4, 3, 2, 0};
unsigned char increment[] PROGMEM = {0, 0, 1, 7, 15, 31, 63, 255};

#define TOS_FRAME_TYPE CLOCK_frame
TOS_FRAME_BEGIN(CLOCK_frame) {
  int cnt;
  int time;
}
TOS_FRAME_END(CLOCK_frame);
#endif

/* Clock time is measured in ticks of .5 microseconds. This value was chosen
 * because it leads to a fairly good approximation of the 32KHz clock values.
 * These scale values correspond to
 *
 * 0 - off
 * 1 - 32768 ticks/second   (61.03 ticks/tick)
 * 2 - 4096 ticks/second    (488.28125 ticks/tick)
 * 3 - 1024 ticks/second    (1953.125 ticks/tick)
 * 4 - 512 ticks/second     (3906.25 ticks/tick)
 * 5 - 256 ticks/second     (7812.5 ticks/tick)
 * 6 - 128 ticks/second
 * 7 - 32 ticks/second
 */

int scales[] = {-1, 122, 976, 3906, 7812, 15625, 31250, 125000};

event_t* clockEvents[TOSNODES];


char TOS_COMMAND(CLOCK_INIT)(char interval, char scale){
  long long ticks;
  event_t* event = NULL;
  
  if (clockEvents[NODE_NUM] != NULL) {
    event_clocktick_invalidate(clockEvents[NODE_NUM]);
  }
  
  ticks = scales[(int)(scale & 0xff)] * (int)(interval & 0xff);
  
    
    
  if (ticks > 0) {
    dbg(DBG_BOOT, ("Clock initialized for mote %i to %lli ticks.\n", NODE_NUM, ticks));
    
    event = (event_t*)malloc(sizeof(event_t));
    dbg(DBG_MEM, ("malloc clock tick event: 0x%x.\n", (int)event));
    event_clocktick_create(event, NODE_NUM, tos_state.tos_time, ticks);
    TOS_queue_insert_event(event);
  }

  clockEvents[NODE_NUM] = event;
  return 1;
}


TOS_INTERRUPT_HANDLER(SIG_OUTPUT_COMPARE2, (void)) {
  TOS_SIGNAL_EVENT(CLOCK_FIRE_EVENT)();
}

char TOS_COMMAND(CLOCK_GET_TIME)(short *clock) {
    return 0;
}

char TOS_COMMAND(CLOCK_SET_TIME) (short clock) {
    return 0;
}
void event_clocktick_handle(event_t* event,
			    struct TOS_state* state) {


  event_queue_t* queue = &(state->queue);
  clock_tick_data_t* data = (clock_tick_data_t*)event->data;
  TOS_LOCAL_ADDRESS = (short)(event->mote & 0xffff);

  if (TOS_LOCAL_ADDRESS != event->mote) {
    dbg(DBG_ERROR, ("ERROR in clock tick event handler! Things are probably ver bad....\n"));
  }

  if (data->valid) {
    if (dbg_active(DBG_CLOCK)) {
      char buf[1024];
      printTime(buf, 1024);
      dbg(DBG_CLOCK, ("CLOCK: event handled for mote %i at %s with interval of %i.\n", event->mote, buf, data->interval));
    }
    
    event->time = event->time + data->interval;
    queue_insert_event(queue, event);
    
    TOS_ISSUE_INTERRUPT(SIG_OUTPUT_COMPARE2)();
  }
  else {
    dbg(DBG_CLOCK, ("CLOCK: invalid event discarded.\n"));
    
    event->cleanup(event);
  }
}

void event_clocktick_create(event_t* event, int mote, long long time, int interval) {
  //long long time = THIS_NODE.time;

  clock_tick_data_t* data = malloc(sizeof(clock_tick_data_t));
  dbg(DBG_MEM, ("malloc data entry for clock event: 0x%x\n", (int)data));
  data->interval = interval;
  data->mote = mote;
  data->valid = 1;
  
  event->mote = mote;
  event->pause = 1;
  event->data = data;
  event->time = time + interval;
  event->handle = event_clocktick_handle;
  event->cleanup = event_total_cleanup;
}

void event_clocktick_invalidate(event_t* event) {
  clock_tick_data_t* data = event->data;
  data->valid = 0;
}
