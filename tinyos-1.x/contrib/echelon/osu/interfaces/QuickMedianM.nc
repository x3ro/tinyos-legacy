/*
  Q u i c k M e d i a n M . n c

  (c) Copyright 2004 The MITRE Corporation (MITRE)

   Permission is hereby granted, without payment, to copy, use, modify,
   display and distribute this software and its documentation, if any,
   for any purpose, provided, first, that the US Government and any of
   its agencies will not be charged any license fee and/or royalties for
   the use of or access to said copyright software, and provided further
   that the above copyright notice and the following three paragraphs
   shall appear in all copies of this software, including derivatives
   utilizing any portion of the copyright software.  Use of this software
   constitutes acceptance of these terms and conditions.

   IN NO EVENT SHALL MITRE BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT,
   SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE
   OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF MITRE HAS BEEN ADVISED
   OF THE POSSIBILITY OF SUCH DAMAGE.

   MITRE SPECIFICALLY DISCLAIMS ANY EXPRESS OR IMPLIED WARRANTIES
   INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
   NON-INFRINGEMENT.

   THE SOFTWARE IS PROVIDED "AS IS."  MITRE HAS NO OBLIGATION TO PROVIDE
   MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.


  The quick median algorithum will find the median of an unsorted list
  with an average of 2N comparisions.  However, the worst case
  preformance is N^2.  Data that exibits worse than O(N) times is
  extreamly rare (assuming that all possible data orderings are
  equally likely).

  However, one troubling case is when finding the Median of already
  sorted data.  This is of course troubling because it's a case that
  occures far more often then the 1/N! of the time that would be the
  case if all of the orderings were equally likely.  Spending more
  energy on selecting the piviot can avoid problems for the case of
  sorted data and several other problems that occure more often in
  real life.  It is common in the litrature to use the median of 5
  uniformly spaced points as the piviot.  This significently increases
  the amount of code.  And in the end no method of picking the pivit
  can avoid the fact that for some ordering of the data the cost is
  O(N^2).

  The algorithum used here was independentently discoverd by the
  author in 1988.  However, at that time it was already well know in
  the trade.  I have never seen it published.
*/

includes Fixed;

module QuickMedianM {
  provides interface Median;
  uses interface MinMax;
}

implementation {
  bool busy=FALSE;
  uint8_t *taskData;
  uint16_t taskLen;

// BPF 03/26/04 Implemented a different Quick Median algorithm.  The previous
// algorithm was occaisonally overwriting memory and failing.  The new
// algorithm is from the "Handbook of Data Structure and Algorithms"
// by Gonnet and Baeza-Yates.  It doesn't handle even sized arrays 
// correctly (reporting one of the two middle points rather than the
// average of the two middle values), but it appears to be more robust.
// Eventually we will try to fix the error in the original algorithm.
  void Select(uint16_t s, uint8_t *data, uint16_t lo, uint16_t up)
  {
      uint16_t i,j;
      uint8_t tempr;
      ufix16_1_t answer=0;

      while ((up>=s) && (s>=lo))
      {
        i=lo;
	j=up;
	tempr = data[s];
	data[s] = data[lo];
	data[lo] = tempr;
	while (i<j)
	{
	    while (data[j] > tempr)
		j--;
	    data[i] = data[j];
	    while ((i<j)&&(data[i]<=tempr))
	    	i++;
	    data[j]=data[i];
        }
    	data[i] = tempr;
	if (s<i)
	  up=i-1;
	else
	  lo=i+1;
      }
      answer = data[s]<<1;
      busy = FALSE;
      signal Median.Done(answer);
  }
  /*
    Pivot Region
  */
  void PivReg(uint8_t *data, uint16_t low, uint16_t high, ufix16_1_t mid)
  {
    uint8_t lowMax, highMin, temp;
    uint16_t regLen, piviot,lowLim,highLim;
    ufix16_1_t answer = 0;

    regLen  = (high - low + 1);
    if (regLen == 1) {
      busy = FALSE;
      answer = (data[low] << 1);

    } else if (regLen == 2) {
      busy = FALSE;
      answer = (uint16_t) data[low] + (uint16_t) data[high];

    } else {
      piviot = data[low];
      lowLim = low;
      highLim = high + 1;
  
      while (lowLim + 1 < highLim - 1)
        if (piviot < data[highLim - 1])
          highLim--;
	else {
          lowLim++;
          Swap8(data, lowLim,highLim - 1);
        }

      // No swap requried on the last data item
      if (piviot < data[highLim - 1])
	highLim--;
      else
	lowLim++;

      // Recurse on the intervals that contain the median
      if (mid <= ((lowLim - 1) << 1)) {
	Swap8(data, low,lowLim); // trim region of piviot
        PivReg(data, low,lowLim - 1, mid);

      } else if ((highLim << 1) <= mid)
        PivReg(data, highLim,high, mid);

      else { // We're done
	if (mid == (lowLim << 1))
	  answer = (piviot << 1);
	else if (mid < (lowLim << 1)) {
	  call MinMax.OpU8(data + low + 1, (lowLim - low), &temp,&lowMax);
	  answer = (uint16_t) lowMax + (uint16_t) piviot;
	} else { // mid > (lowLim << 1) 
	  call MinMax.OpU8
	    (data + highLim, (high - highLim + 1), &highMin,&temp);
	  answer = (uint16_t) piviot + (uint16_t) highMin;
	}
	
	busy = FALSE;
	signal Median.Done(answer);
      }
    }

  } // PivReg

  event void MinMax.DoneU8(uint8_t min, uint8_t max)
    { /* Nothing */ }

  event void MinMax.Done16(int16_t min, int16_t max)
    { /* Nothing */ }

  /*
    Main interface
  */
  task void CompMedian()
  {
    uint16_t mid;

    mid = taskLen/2;
    //PivReg(taskData, 0,taskLen-1,taskLen-1);
    Select(mid,taskData,0,taskLen-1);
  }

  command result_t Median.Start(uint8_t *data, uint16_t len)
  {
    if ( busy )
      return FAIL;
    else {
      taskData = data;
      taskLen = len;
      busy = TRUE;

      post CompMedian();
      return SUCCESS;
    }
  } // Start
} // QuickMedianM
