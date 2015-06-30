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
// Comments provided by Phoebus Chen, which may or may not be entirely accurate
// No chnages from the original that lies in SystemC/common
// $Id: moving_average.h,v 1.1.1.1 2004/10/15 01:34:08 phoebusc Exp $


// Description: Efficiently calculate the moving average for a series of
// uint16_t values.

#ifndef _H_moving_average_h
#define _H_moving_average_h


typedef uint16_t ma_data_t;
typedef uint32_t ma_sum_t;


/** Note that a separate array of type ma_data_t[SampleNumber] needs to
 *  be declared in addition to this data structure. This data
 *  structure only does the bookkeeping for the array.
 */
typedef struct {
  //first three entries are pointers to the data array
  ma_data_t* begin;
  ma_data_t* end;
  ma_data_t* current;
  ma_sum_t sum;
  ma_sum_t n; //number of valid entries
  int n_init; //number of entries that still need to be initialized
  ma_data_t avg;
} moving_average_t;


/** Initializes the Moving Average Data structures.<BR>
 *  Input to Function:
 *  <OL>
 *   <LI> </CODE> moving_average_t <CODE> is the actual array containing
 *        entries used for computing the moving average </LI> 
 *   <LI> <CODE> begin </CODE> contains the base address of the array
 *        used for computing the moving average </LI>
 *   <LI> <CODE> end </CODE> contains the end address of the array
 *        used for computing the moving average </LI>
 *  </OL>
 */
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

  // ma->n/2 is used for rounding up.  This is integer arithmetic.
  // Somehow the compiler knows to optimize it into a bit shift.
  ma->avg = ma->n ? ((ma->sum + ma->n/2) / ma->n) : 0;
  return ma->avg;
}



//Exponentially Weighted Moving Average

// Does not need additional data structures
typedef struct {
  float mean;
  float alpha;
  bool initialized;
} ewma_t;


/** Adds the value <CODE> x </CODE> to the exponentially weighted
 *  moving average using <CODE> ewma_t->alpha </CODE>as the weighting
 *  factor.  The variable holding the exponentially weighted moving
 *  average is incorrectly named <CODE> movingAvg </CODE>.
 */
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



//Running Average (of all numbers, not a window of numbers like Moving Average)

// Does not need additional data structures
typedef struct {
  float mean;
  uint16_t count;
} runningAvg_t;


/** Adds the value <CODE> x </CODE> to the running average.  The
 *  variable holding the running average is incorrectly named <CODE>
 *  movingAvg </CODE>.
 */
runningAvg_t* addToRunningAvg(float x, runningAvg_t *movingAvg)
{
  movingAvg->mean = (movingAvg->mean*movingAvg->count + x)/movingAvg->count+1;
  movingAvg->count++;
  return movingAvg;
}




#endif // _H_moving_average_h

