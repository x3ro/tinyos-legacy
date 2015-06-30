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

/**
 * @file 	PXA27Xdynqueue.c 
 * @author	Josh Herbach
 * Revision:	1.0
 * Date:	09/02/2005
 *
 * Modified By: Junaith Ahemed Shahabdeen
 */

#include <MessageDefines.h>
#include <PXA27Xdynqueue.h>

//#define MIN_PHYS_LENGTH 2
#define MIN_PHYS_LENGTH (BIN_DATA_WINDOW_SIZE + 1)

struct DynQueue_T
{
  int iLength;
  int iPhysLength;
  int index;
  const void **ppvQueue;
};


DynQueue DynQueue_new()
{
  DynQueue oDynQueue;

  oDynQueue = (DynQueue)malloc(sizeof(struct DynQueue_T));
  //assert(oDynQueue != NULL);
  if(oDynQueue == NULL)
    return NULL;
   
  oDynQueue->iLength = 0;
  oDynQueue->iPhysLength = MIN_PHYS_LENGTH;
  oDynQueue->ppvQueue = 
  (const void**)calloc(oDynQueue->iPhysLength, sizeof(void*));
  //assert(oDynQueue->ppvQueue != NULL);
  if(oDynQueue->ppvQueue == NULL)
    return NULL;

  oDynQueue->index = 0;
  return oDynQueue;
}

/*------------------------------------------------------------------*/
void DynQueue_free(DynQueue oDynQueue)
{
  if (oDynQueue == NULL)
    return;
   
  free(oDynQueue->ppvQueue);
  free(oDynQueue);
}

/*------------------------------------------------------------------*/

int DynQueue_getLength(DynQueue oDynQueue)
{
  //assert(oDynQueue != NULL);
  if(oDynQueue == NULL)
    return 0;
  return oDynQueue->iLength;
}

/*------------------------------------------------------------------*/

/* Returns the first element of oDynQueue without removing it.*/
void *DynQueue_peek(DynQueue oDynQueue)
{
  //assert(oDynQueue != NULL);
  //assert(oDynQueue->iLength > 0);
  if(oDynQueue == NULL || oDynQueue->iLength <= 0)
    return NULL;
  return (void*)(oDynQueue->ppvQueue)[oDynQueue->index];
}

/*------------------------------------------------------------------*/

/* Shift the elements to the start of the array
	or double the physical length of oDynQueue. */
static void DynQueue_shiftgrow(DynQueue oDynQueue)
{
  //assert(oDynQueue != NULL);
  if(oDynQueue == NULL)
    return;
  //choosing to waste space over wasting time by not always shifting
  if(oDynQueue->index > 2 && oDynQueue->index > oDynQueue->iPhysLength / 8)
  {
    memmove((void *)oDynQueue->ppvQueue, 
            (void *)(oDynQueue->ppvQueue + oDynQueue->index), 
            sizeof(void *) * oDynQueue->iLength);
    oDynQueue->index = 0;
  }
  else
  {
    oDynQueue->iPhysLength *= 2;
    oDynQueue->ppvQueue =  (const void**)realloc(oDynQueue->ppvQueue, 
		    sizeof(void*) * oDynQueue->iPhysLength);
    //assert(oDynQueue->ppvQueue != NULL);
  }
}

/*------------------------------------------------------------------*/

static void DynQueue_shiftshrink(DynQueue oDynQueue)

/* Shift the elements to the start of the array
	and halves the physical length of oDynQueue.*/
{
	//assert(oDynQueue != NULL);
	if(oDynQueue == NULL)
		return;
  //choosing to waste space over wasting time by not always shifting
	if(oDynQueue->index > 0)
	{
		memmove((void *)oDynQueue->ppvQueue, (void *)(oDynQueue->ppvQueue + oDynQueue->index), 
										sizeof(void *) * oDynQueue->iLength);
		oDynQueue->index = 0;
	}
	oDynQueue->iPhysLength /= 2;
	oDynQueue->ppvQueue = (const void**)realloc(oDynQueue->ppvQueue, 
									sizeof(void*) * oDynQueue->iPhysLength);
	//assert(oDynQueue->ppvQueue != NULL);
}

/*------------------------------------------------------------------*/

void DynQueue_enqueue(DynQueue oDynQueue, const void *pvItem)
/* Adds pvItem to oDynQueue.*/
{
	//assert(oDynQueue != NULL);
	if(oDynQueue == NULL)
		return;

	if (oDynQueue->iLength + oDynQueue->index == oDynQueue->iPhysLength)
		DynQueue_shiftgrow(oDynQueue);

	oDynQueue->ppvQueue[oDynQueue->index + oDynQueue->iLength] = pvItem;
	oDynQueue->iLength++;
}

/*------------------------------------------------------------------*/

void *DynQueue_dequeue(DynQueue oDynQueue)
/* Dequeues the first element of oDynQueue.*/
{
	const void *pvItem;

	//assert(oDynQueue != NULL);
	//assert(oDynQueue->iLength > 0);
	if(oDynQueue == NULL || oDynQueue->iLength <= 0)
		return NULL;

	pvItem = oDynQueue->ppvQueue[oDynQueue->index];
	oDynQueue->ppvQueue[oDynQueue->index] = NULL;

	oDynQueue->iLength--;
	oDynQueue->index++;

	if(oDynQueue->iLength + 5 < oDynQueue->iPhysLength / 2)
		DynQueue_shiftshrink(oDynQueue);
	return (void*)pvItem;
}

/*------------------------------------------------------------------*/

void DynQueue_push(DynQueue oDynQueue, const void *pvItem)
{
	//assert(oDynQueue != NULL);
	if(oDynQueue == NULL)
		return;

	if(oDynQueue->iLength == oDynQueue->iPhysLength) //if <- is true, then index == 0
		DynQueue_shiftgrow(oDynQueue);

	if(oDynQueue->index > 0)
		oDynQueue->index--;
	else//assumed index == 0
		memmove((void *)(oDynQueue->ppvQueue + 1), (void *)oDynQueue->ppvQueue, sizeof(void *) * oDynQueue->iLength);
	oDynQueue->iLength++;
	oDynQueue->ppvQueue[oDynQueue->index] = pvItem;
}
