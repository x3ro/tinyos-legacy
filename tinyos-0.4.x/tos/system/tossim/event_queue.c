/*
 *   FILE: event_queue.c
 * AUTHOR: Philip Levus <pal@cs.berkeley.edu>
 *   DESC: Event queue for discrete event simulation
 */

#include "event_queue.h"
#include "tossim.h"
#include "dbg.h"
#include <unistd.h>
#include <time.h>

extern char TOS_LOCAL_ADDRESS;

struct timespec length;

void queue_init(event_queue_t* queue, int pause) {
  init_heap(&(queue->heap));
  queue->pause = pause;
  pthread_mutex_init(&(queue->lock), NULL);
}

void queue_insert_event(event_queue_t* queue, event_t* event) {
  dbg(DBG_SIM, ("Inserting event with time %lli.\n", event->time));
  pthread_mutex_lock(&(queue->lock));
  heap_insert(&(queue->heap), event, event->time);
  pthread_mutex_unlock(&(queue->lock));
}

event_t* queue_pop_event(event_queue_t* queue) {
  long long time;
  struct timespec length;
  event_t* event;

  pthread_mutex_lock(&(queue->lock));
  event = (event_t*)(heap_pop_min_data(&(queue->heap), &time));
  pthread_mutex_unlock(&(queue->lock));

  dbg(DBG_SIM, ("Popping event for mote %i with time %lli.\n", event->mote, time));

  if (queue->pause > 0 && event->pause) {
    length.tv_sec = queue->pause / 1000000;
    length.tv_nsec = (queue->pause % 1000000) * 1000;
    nanosleep(&length, NULL);
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
  int rval;
  
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
    dbg(DBG_SIM, ("Setting TOS_LOCAL_ADDRESS to %hi\n", (short)(event->mote & 0xffff)));
    TOS_LOCAL_ADDRESS = (short)(event->mote & 0xffff);
    event->handle(event, &tos_state); 
  }
}
