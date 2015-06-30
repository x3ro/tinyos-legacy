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
 * Methods for operating on CircleQueue.	     
 *	     
 *	     
 * Author:  	Barbara Hohlt 	
 * Project:    	CircleQueue	
 *	     
 *	     
 *	     
 * @author  Barbara Hohlt
 * @date    January 2003
 */


module CircleQueueM {
  provides interface StdControl as Control;
  provides interface CircleQ as Queue;
}


implementation {

  command result_t Control.init() { return SUCCESS; }
  command result_t Control.start() { return SUCCESS; }
  command result_t Control.stop() { return SUCCESS; }

  command result_t Queue.set(CircleQueue* queue, uint32_t buf[],uint16_t len) {

   queue->in = 0;
   queue->out = 0;
   queue->count = 0;
   queue->cq_size = len; 
   queue->s = buf;

   dbg(DBG_TEMP, "CircleQueue: Sizeof s %d on 0x%x\n", queue->cq_size,queue);

   return SUCCESS;
  }

  command bool Queue.empty(CircleQueue* queue) {
//    dbg(DBG_TEMP, "CircleQueue: Testing if queue at 0x%x is empty: %s.\n", queue, (queue->count)? "true":"false");
    return (queue->count == 0) ; 
  }

  command result_t Queue.enqueue( CircleQueue* queue,
				 TOS_MsgPtr element) {
//    dbg(DBG_TEMP, "CircleQueue: Enqueue on 0x%x\n", queue);
    if (queue->count >= queue->cq_size) {
//       dbg(DBG_TEMP, "CircleQueue: Enqueue queue FULL on 0x%x\n", queue);
      return FAIL;
    }

    queue->s[queue->in] = (uint32_t) element;
    queue->in = (queue->in + 1) % queue->cq_size;
    queue->count++;

    return SUCCESS;
  }

  command TOS_MsgPtr Queue.dequeue(CircleQueue* queue) {
    TOS_MsgPtr rval;

    if (queue->count == 0) {
      dbg(DBG_TEMP, "CircleQueue: Dequeue queue EMPTY on 0x%x\n", queue);
      return NULL;
    }
    
    rval = (TOS_MsgPtr) queue->s[queue->out]; 
    queue->out = (queue->out + 1) % queue->cq_size;
    queue->count--;

    dbg(DBG_TEMP, "CircleQueue: Dequeue from 0x%x\n", queue);
    return rval;
  }

  command uint8_t Queue.getCount(CircleQueue* queue) {
    return (uint8_t) queue->count;
  }
}

