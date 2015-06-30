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
// $Id: moving_average.h,v 1.1 2003/06/02 12:34:16 dlkiskis Exp $

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

  return ma->avg = (ma->sum + ma->n/2) / ma->n;
}


#endif // _H_moving_average_h

