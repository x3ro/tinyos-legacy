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
// $Id: moving_average.h,v 1.2 2004/03/19 02:23:39 kaminw Exp $

// Description: Efficiently calculate the moving average for a series of
// uint16_t values.

#ifndef _H_moving_average_h
#define _H_moving_average_h


typedef uint16_t ma_data_t;
typedef uint32_t ma_sum_t;


typedef struct {
  ma_data_t* begin;
  ma_data_t* end;
  ma_data_t* current;
  ma_sum_t sum;
  ma_sum_t n;
  int n_init;
  ma_data_t avg;
} moving_average_t;


void init_moving_average(
    moving_average_t* ma,
    ma_data_t* begin,
    ma_data_t* end
  )
{
  ma_data_t* ii;

  ma->begin   = begin;
  ma->end     = end;
  ma->current = begin;
  ma->sum     = 0;
  ma->n       = 0;
  ma->n_init  = end - begin;

  for( ii=begin; ii!=end; ii++ )
    *ii = 0;
}


ma_data_t add_moving_average(
    moving_average_t* ma,
    ma_data_t val
  )
{
  ma->sum -= *(ma->current);
  *(ma->current) = val;
  ma->sum += val;

  if( ++(ma->current) == ma->end )
    ma->current = ma->begin;

  if( ma->n_init > 0 )
  {
    ma->n_init--;
    ma->n++;
  }

  ma->avg = ma->n ? ((ma->sum + ma->n/2) / ma->n) : 0;
  return ma->avg;
}


typedef struct {
  ma_data_t* begin;
  ma_data_t* end;
  ma_data_t* current;
  uint8_t n;
  uint8_t size;
} moving_window_t;


void init_moving_window(
    moving_window_t* ma,
    ma_data_t* begin,
    ma_data_t* end
  )
{
  //ma_data_t* ii;

  ma->begin   = begin;
  ma->end     = end;
  ma->current = begin;
  ma->n       = 0;
  ma->size    = end - begin + 1;

  //for( ii=begin; ii!=end; ii++ )
  //  *ii = 0;
}


void add_moving_window(
    moving_window_t* ma,
    ma_data_t val
  )
{
  *(ma->current) = val;

  if( (ma->current)++ == ma->end )
    ma->current = ma->begin;

  if( ma->n < ma->size )
  {
    ma->n++;
  }
}

typedef struct {
  float mean;
  float alpha;
  bool initialized;
} ewma_t;

ewma_t* addToEWMA(float x, ewma_t *movingAvg)
{
  if(movingAvg->initialized == FALSE){
	  movingAvg->mean = x;
	  movingAvg->initialized = TRUE;
  }
  else{
	  movingAvg->mean = (1-movingAvg->alpha)*x + movingAvg->alpha*movingAvg->mean;
  }
  return movingAvg;
}




typedef struct {
  float mean;
  uint16_t count;
} runningAvg_t;

runningAvg_t* addToRunningAvg(float x, runningAvg_t *movingAvg)
{
  movingAvg->mean = (movingAvg->mean*movingAvg->count + x)/movingAvg->count+1;
  movingAvg->count++;
  return movingAvg;
}


#endif // _H_moving_average_h

