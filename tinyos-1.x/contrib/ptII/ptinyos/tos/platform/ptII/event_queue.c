// $Id: event_queue.c,v 1.4 2006/11/10 03:36:28 celaine Exp $

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

// Viptos: functions to create and enter and exit monitor.
extern void *ptII_createMonitorObject();
extern int ptII_MonitorEnter(void *monitorObject);
extern int ptII_MonitorExit(void *monitorObject);

//*********renamed from length to event_queue_length
struct timespec event_queue_length;

//static void dbg(TOS_dbg_mode mode, const char *format, ...); 

void queue_init(event_queue_t* queue, int fpause) {
  init_heap(&(queue->heap));
  queue->pause = fpause;
  //pthread_mutex_init(&(queue->lock), NULL);

  // Viptos: Initialize event queue with lock object.
  queue->lock = ptII_createMonitorObject();
}

// celaine
extern void ptII_queue_insert_event(long long eventTime);

void queue_insert_event(event_queue_t* queue, event_t* event) {
  ptII_queue_insert_event(event->time);

  // Viptos: Replacing pthread objects with JNI objects.
  ptII_MonitorEnter(queue->lock);

  //pthread_mutex_lock(&(queue->lock));
  heap_insert(&(queue->heap), event, event->time);
  //pthread_mutex_unlock(&(queue->lock));

  ptII_MonitorExit(queue->lock);
}

event_t* queue_pop_event(event_queue_t* queue) {
  long long ftime;
  event_t* event;

  // Viptos: Replacing pthread objects with JNI objects.
  ptII_MonitorEnter(queue->lock);
  
  //pthread_mutex_lock(&(queue->lock));
  event = (event_t*)(heap_pop_min_data(&(queue->heap), &ftime));
  //pthread_mutex_unlock(&(queue->lock));

  ptII_MonitorExit(queue->lock);
  
  if(dbg_active(DBG_QUEUE)) {
    char timeStr[128];
    timeStr[0] = 0;
    printOtherTime(timeStr, 128, ftime);
    // Viptos: _PTII_NODEID is passed to the preprocessor as a macro definition.
    // Viptos: We assume that there is only one node per TOSSIM.
    //dbg(DBG_QUEUE, "Popping event for mote %i with time %s.\n", event->mote, timeStr);
    dbg(DBG_QUEUE, "Popping event for mote %i with time %s.\n", _PTII_NODEID, timeStr);
  }
  
  if (queue->pause > 0 && event->pause) {
    sleep(queue->pause);
    //dbg(DBG_ALL, "\n");
  }
  
  return event;
}

int queue_is_empty(event_queue_t* queue) {
  int rval;
  
  // Viptos: Replacing pthread objects with JNI objects.
  ptII_MonitorEnter(queue->lock);
  
  //pthread_mutex_lock(&(queue->lock));
  rval = heap_is_empty(&(queue->heap));
  //pthread_mutex_unlock(&(queue->lock));

  ptII_MonitorExit(queue->lock);

  return rval;
}

long long queue_peek_event_time(event_queue_t* queue) {
  long long rval;

  // Viptos: Replacing pthread objects with JNI objects.
  ptII_MonitorEnter(queue->lock);
  
  //pthread_mutex_lock(&(queue->lock));
  if (heap_is_empty(&(queue->heap))) {
    rval = -1;
  }
  else {
    rval = heap_get_min_key(&(queue->heap));
  }

  //pthread_mutex_unlock(&(queue->lock));

  ptII_MonitorExit(queue->lock);
  
  return rval;
}

void queue_handle_next_event(event_queue_t* queue) {
  event_t* event = queue_pop_event(queue);
  if (event != NULL) {
    if (tos_state.moteOn[event->mote] || event->force) {
      NODE_NUM = event->mote;

      // Viptos: _PTII_NODEID is passed to the preprocessor as a macro definition.
      // Viptos: We assume that there is only one node per TOSSIM.
      //dbg(DBG_QUEUE, "Setting TOS_LOCAL_ADDRESS to %hi\n", (short)(event->mote & 0xffff));
      dbg(DBG_QUEUE, "Setting TOS_LOCAL_ADDRESS to %hi\n", (short)(_PTII_NODEID & 0xffff));
      //atomic TOS_LOCAL_ADDRESS = (short)(event->mote & 0xffff);
      atomic TOS_LOCAL_ADDRESS = (short)(_PTII_NODEID & 0xffff);

      event->handle(event, &tos_state); 
    } 
  }
}


