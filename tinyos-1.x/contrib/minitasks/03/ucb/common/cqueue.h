/* "Copyright (c) 2000-2002 The Regents of the University of California.  
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
 */

// Authors: Cory Sharp
// $Id: cqueue.h,v 1.1 2003/05/04 03:25:47 cssharp Exp $

// Description: Provide index manipulation for a circular queue or stack.
// It manipulates integer indices into presumably an array you're keeping
// somewhere else.  If the queue is nonempty, then front and back index to
// the respectively valid entries in the data array.  If the array is empty,
// then front and back both point to the (invalid) element one past the end
// of the array.  pop_front, pop_back, push_front, push_back, is_empty, and
// is_full all do the expected things.  pop_* return FAIL if the resulting
// queue is empty.  push_* return FAIL if queue was already full.

#ifndef _H_cqueue_h
#define _H_cqueue_h

//typedef unsigned int cqueue_index_t;
typedef uint8_t cqueue_index_t;

typedef struct
{
  cqueue_index_t front;
  cqueue_index_t back;
  cqueue_index_t size;
} cqueue_t;

// if front == back == size, then the list is empty
// otherwise, front points to the current front element
// and back points to the current back element

void init_cqueue( cqueue_t* cq, cqueue_index_t size )
{
  cq->front = size;
  cq->back  = size;
  cq->size  = size;
}


cqueue_index_t priv_inc_cqueue( cqueue_t* cq, cqueue_index_t n )
{
  return (++n == cq->size) ? 0 : n;
}


cqueue_index_t priv_dec_cqueue( cqueue_t* cq, cqueue_index_t n )
{
  return n ? (n-1) : (cq->size-1);
}


bool is_empty_cqueue( cqueue_t* cq )
{
  return (cq->front == cq->size) ? TRUE : FALSE;
}


bool is_full_cqueue( cqueue_t* cq )
{
  return (priv_dec_cqueue(cq, cq->back) == cq->front) ? TRUE : FALSE;
}


// return SUCCESS if cq->front points to a valid (but unassigned) element
// return FAIL if cq is full
result_t push_front_cqueue( cqueue_t* cq )
{
  if( is_empty_cqueue( cq ) == TRUE )
  {
    cq->front = 0;
    cq->back  = 0;
  }
  else
  {
    cqueue_index_t newfront = priv_inc_cqueue( cq, cq->front );

    if( newfront == cq->back )
      return FAIL;

    cq->front = newfront;
  }

  return SUCCESS;
}


// return SUCCESS if cq->back points to a valid (but unassigned) element
// return FAIL if cq is full
result_t push_back_cqueue( cqueue_t* cq )
{
  if( is_empty_cqueue( cq ) == TRUE )
  {
    cq->front = 0;
    cq->back  = 0;
  }
  else
  {
    cqueue_index_t newback = priv_dec_cqueue( cq, cq->back );

    if( newback == cq->front )
      return FAIL;

    cq->back = newback;
  }

  return SUCCESS;
}


// return SUCCESS if cq->front now points to a valid element
// return FAIL if cq was empty or is now empty
result_t pop_front_cqueue( cqueue_t* cq )
{
  if( is_empty_cqueue( cq ) )
    return FAIL;

  if( cq->front == cq->back )
  {
    cq->front = cq->size;
    cq->back  = cq->size;
    return FAIL;
  }

  cq->front = priv_dec_cqueue( cq, cq->front );
  return SUCCESS;
}


// return SUCCESS if cq->back now points to a valid element
// return FAIL if cq was empty or is now empty
result_t pop_back_cqueue( cqueue_t* cq )
{
  if( is_empty_cqueue( cq ) )
    return FAIL;

  if( cq->front == cq->back )
  {
    cq->front = cq->size;
    cq->back  = cq->size;
    return FAIL;
  }

  cq->back = priv_inc_cqueue( cq, cq->back );
  return SUCCESS;
}


// return SUCCESS if cq->front points to a valid (but unassigned) element
// in contrast to push_front_queue, if cq is full this function deletes the
// last element and pushes the back up one.
result_t forcibly_push_front_cqueue( cqueue_t* cq )
{
  if( is_empty_cqueue( cq ) == TRUE )
  {
    cq->front = 0;
    cq->back  = 0;
  }
  else
  {
    cqueue_index_t newfront = priv_inc_cqueue( cq, cq->front );

    if( newfront == cq->back )
      cq->back=priv_inc_cqueue(cq, cq->back);
    //      return FAIL;

    cq->front = newfront;
  }

  return SUCCESS;
}


// return SUCCESS if cq->back points to a valid (but unassigned) element
// in contrast to push_back_queue, if cq is full this function deletes the
// first element and pushes the front down one.
result_t forcibly_push_back_cqueue( cqueue_t* cq )
{
  if( is_empty_cqueue( cq ) == TRUE )
  {
    cq->front = 0;
    cq->back  = 0;
  }
  else
  {
    cqueue_index_t newback = priv_dec_cqueue( cq, cq->back );

    if( newback == cq->front )
      cq->front = priv_dec_cqueue(cq, cq->front);
    //      return FAIL;

    cq->back = newback;
  }

  return SUCCESS;
}


#endif // _H_cqueue_h

