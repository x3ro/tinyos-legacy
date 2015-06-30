/*
 *
 *
 * "Copyright (c) 2002-2004 The Regents of the University  of California.  
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
/*
 * Author:  	Barbara Hohlt 	
 * Project:	Ivy 
 *	     
 */



module SlackerQueueM {
  provides interface SlackerQ as Queue;
}


implementation {

  TOS_Msg buf1;
  TOS_Msg buf2;
  TOS_Msg buf3;
  TOS_Msg buf4;
  TOS_Msg buf5;
  TOS_Msg buf6;
  TOS_Msg buf7;
  TOS_Msg buf8;

  command result_t Queue.init(SlackerQueue* queue, bool rQ) {
   queue->in = 0;
   queue->out = 0;
   queue->count = 0;

   /*
    * If this is a receive queue, ie freeList, then you need
    * to start out with some fresh buffers.
    */
   if (rQ) {
	call Queue.enqueue(queue, (TOS_MsgPtr)&buf1);
	call Queue.enqueue(queue, (TOS_MsgPtr)&buf2);
	call Queue.enqueue(queue, (TOS_MsgPtr)&buf3);
	call Queue.enqueue(queue, (TOS_MsgPtr)&buf4);
	call Queue.enqueue(queue, (TOS_MsgPtr)&buf5);
	call Queue.enqueue(queue, (TOS_MsgPtr)&buf6);
	call Queue.enqueue(queue, (TOS_MsgPtr)&buf7);
	call Queue.enqueue(queue, (TOS_MsgPtr)&buf8);
   }

   return SUCCESS;
  }

  command bool Queue.empty(SlackerQueue* queue) {
    dbg(DBG_TEMP, "SlackerQueue: Testing if queue at 0x%x is empty: %s.\n", queue, (queue->count)? "true":"false");
    return (queue->count == 0) ; 
  }

  command result_t Queue.enqueue( SlackerQueue* queue,
				 TOS_MsgPtr element) {
    dbg(DBG_TEMP, "SlackerQueue: Enqueue on 0x%x\n", queue);
    if (queue->count == NUM_SLOTS) {
       dbg(DBG_TEMP, "SlackerQueue: Enqueue queue FULL on 0x%x\n", queue);
      return FAIL;
    }

    queue->s[queue->in] = (uint32_t) element;
    queue->in = (queue->in + 1) % NUM_SLOTS;
    queue->count++;
    return SUCCESS;
  }

  command TOS_MsgPtr Queue.dequeue(SlackerQueue* queue) {
    TOS_MsgPtr rval;

    if (queue->count == 0) {
       dbg(DBG_TEMP, "SlackerQueue: Dequeue queue EMPTY on 0x%x\n", queue);
      return NULL;
    }
    
    rval = (TOS_MsgPtr) queue->s[queue->out]; 
    queue->out = (queue->out + 1) % NUM_SLOTS;
    queue->count--;

    dbg(DBG_TEMP, "SlackerQueue: Dequeue from 0x%x\n", queue);
    return rval;
  }
}

