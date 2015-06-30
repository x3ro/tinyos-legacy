#ifndef H_reservedQueue_h
#define H_reservedQueue_h

/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
typedef struct {
  uint8_t head;
  uint8_t tail;
  uint8_t next[0];
} ReservedQueue_t;

enum {
  RQUEUE_NONE = 255,
};

void rqueue_init( ReservedQueue_t* q, uint8_t count ) {
  uint8_t* next = q->next;
  const uint8_t* nextEnd = next+count;

  q->head = RQUEUE_NONE;
  q->tail = RQUEUE_NONE;

  while( next != nextEnd )
    *next++ = RQUEUE_NONE;
}


bool rqueue_isEmpty( ReservedQueue_t* q ) {
  return (q->head == RQUEUE_NONE);
}


bool rqueue_isQueued( ReservedQueue_t* q, uint8_t id ) {
  return (q->next[id] != RQUEUE_NONE) || (q->tail == id);
}


bool rqueue_remove( ReservedQueue_t* q, uint8_t id ) {

  // is there a node to remove?
  if( (id != RQUEUE_NONE) && (q->head != RQUEUE_NONE) ) {

    // is it the head?
    if( id == q->head ) {
      q->head = q->next[id];
      if( q->head == RQUEUE_NONE )
        q->tail = RQUEUE_NONE;
    }
    // otherwise it's definitely not the head
    else {
      uint8_t prev = RQUEUE_NONE;
      uint8_t node = q->head;

      // find the node to remove in the list
      while( node != id ) {
        prev = node;
        node = q->next[node];

        // the node isn't in the list, removal not possible, done
        if( node == RQUEUE_NONE )
          return FALSE;
      }

      // remove the node (we know it's not the head from before)
      q->next[prev] = q->next[node];
      if( q->tail == node )
        q->tail = prev;
    }

    // clear the removed node's next pointer
    q->next[id] = RQUEUE_NONE;

    // sucessful removal, done
    return TRUE;
  }

  // no node was removed, done
  return FALSE;
}


uint8_t rqueue_pop( ReservedQueue_t* q ) {
  uint8_t head = q->head;
  rqueue_remove( q, head );
  return head;
}


bool rqueue_push_priv( ReservedQueue_t* q, uint8_t id, bool second ) {
  if( rqueue_isQueued( q, id ) ) {
    return FALSE;
  }

  if( q->head == RQUEUE_NONE ) {
    q->head = id;
    q->tail = id;
  }
  else if( second ) {
    // splice id in right after the head
    q->next[id] = q->next[q->head];
    q->next[q->head] = id;
    if( q->tail == q->head )
      q->tail = id;
  }
  else {
    q->next[q->tail] = id;
    q->tail = id;
  }

  return TRUE;
}


bool rqueue_push( ReservedQueue_t* q, uint8_t id ) {
  return rqueue_push_priv( q, id, FALSE );
}


bool rqueue_pushSecond( ReservedQueue_t* q, uint8_t id ) {
  return rqueue_push_priv( q, id, TRUE );
}


bool rqueue_pushFront( ReservedQueue_t* q, uint8_t id ) {
  if( rqueue_isQueued( q, id ) ) {
    return FALSE;
  }

  q->next[id] = q->head;
  q->head = id;
  if( q->tail == RQUEUE_NONE )
    q->tail = id;
  return TRUE;
}

#endif//H_reservedQueue_h
