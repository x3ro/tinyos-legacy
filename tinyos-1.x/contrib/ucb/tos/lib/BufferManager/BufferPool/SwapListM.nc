/*
 *
 * "Copyright (c) 2002-2005 The Regents of the University  of California.  
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
 */
/**
 * This module implements a FreeList of buffers
 * using CircleQueues. It is reserved by the	     
 * routing component for buffer swapping.	     
 *	     
 * Author:  	Barbara Hohlt 	
 * Project:     Buffer Manager	
 *	     
 * @author  Barbara Hohlt
 * @date    January 2003
 */
#ifndef FREELISTLENGTH
#define FREELISTLENGTH 32
#endif
#ifndef NUMBUFFERS
#define NUMBUFFERS 20
#endif

module SwapListM {
  provides interface StdControl as Control;
  provides interface List as FreeList;

  uses interface StdControl as SubControl;
  uses interface CircleQ; 
}


implementation {

  /* freeList */
  CircleQueue bufferQueue;
  CircleQueue *freeList;
  uint16_t q_len;
  uint16_t b_rem;
  uint16_t b_len;
  uint32_t bufQ[FREELISTLENGTH];

  TOS_Msg bufs[NUMBUFFERS]; /* free buffers */

  result_t makeQ(); 

  command result_t Control.init() { 

     call SubControl.init();

    /* create the free list */
    q_len = ( sizeof bufQ / 4 );
    b_len = ( sizeof bufs / sizeof (TOS_Msg) );
    b_rem = (uint32_t)&bufs[0] % 4 ; 
    freeList = &bufferQueue;
    call CircleQ.set(freeList,bufQ,q_len);
    makeQ(); /* add some free buffers */

     return SUCCESS; 
   }

  command result_t Control.start() { 
    call SubControl.start();
    return SUCCESS; 
  }

  command result_t Control.stop() { 
    call SubControl.stop() ;
    return SUCCESS; 
  }

  /* This module is limited to making at the most
   * free buffers up to cq_size.
   */
  result_t makeQ() {
	uint16_t c, i;

  	c = b_len; 
   /*
    * Since this is a freeList, you need
    * to start out with some fresh buffers.
    */

	for(i=0; i<c; i++) {
	    if (i >= q_len)
		break; 
	    call CircleQ.enqueue(freeList,&bufs[i]);
        }

	c = call CircleQ.getCount(freeList);
	dbg(DBG_ROUTE, "FreeListM: add %u buffers.\n", c);

   return SUCCESS;
  }

  command bool FreeList.empty() {
    return call CircleQ.empty(freeList);
  }

  /* is this msg ptr a member of bufs ? */
  command bool FreeList.member(TOS_MsgPtr mem) {
    bool rval = FALSE;

    if ((mem >= &bufs[0]) && (mem <= &bufs[b_len-1])) { 
	if ( ((uint32_t)mem % 4) == b_rem )
	  rval = TRUE;
    } else {
	dbg(DBG_ROUTE, "FreeListM: NOT MEMBER\n");
	dbg(DBG_ROUTE, "	message 0x%x.\n",mem);
	dbg(DBG_ROUTE, "	bufs[0] 0x%x.\n",&bufs[0]);
	dbg(DBG_ROUTE, "	bufs[%u] 0x%x.\n",b_len-1,&bufs[b_len-1]);
    }

    return rval;
  }

  command result_t FreeList.enqueue(TOS_MsgPtr element) {
    return call CircleQ.enqueue(freeList, element);
  }

  command TOS_MsgPtr FreeList.dequeue() {
    dbg(DBG_ROUTE, "FreeListM: dequeue.\n");
    return call CircleQ.dequeue(freeList);
  }

  command uint8_t FreeList.getOccupancy() {
    return call CircleQ.getCount(freeList);
  }
}
