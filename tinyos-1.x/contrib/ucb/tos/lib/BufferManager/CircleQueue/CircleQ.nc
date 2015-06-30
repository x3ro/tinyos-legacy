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
/*
 * Author:	Barbara Hohlt		
 * Project: 	CircleQueue	
 *
 */

/**
 * Interface for operating on circle queues
 * with buffers of type TOS_MsgPtr.
 *
 *	typedef struct CircleQueue {
 *	    int in;
 * 	    int out;
 * 	    int count;
 *	    int cq_size;
 * 	    uint32_t *s;
 *	} CircleQueue;
 *
 * @author  Barbara Hohlt
 * @date    January 2003 
 */
includes CQ;

interface CircleQ {

  /**
   * Initialize a queue.
   *
   * @param queue The queue to initialize.
   * @param buf  A pointer to an array of TOS_MsgPtr. 
   * @param len The size of buf. 
   *
   * @return SUCCESS if initialized properly, FAIL otherwise.
   */
  
  command result_t set(CircleQueue* queue, uint32_t buf[], uint16_t len);


  /**
   * Whether a queue is empty.
   *
   * @param queue The queue whose emptiness is being queried.
   *
   * @return TRUE if empty, FALSE otherwise.
   */
  
  command bool empty(CircleQueue* queue);

  /**
   * Enqueue a message onto a queue.
   *
   * @param queue The queue on which the element is to be placed.
   *
   * @param element The message to be placed on the queue.
   *
   * @return SUCCESS if enqueued properly, FAIL otherwise.
   */
  
  command result_t enqueue(CircleQueue* queue,
			   TOS_MsgPtr element);

  /**
   * Dequeue the next element from a queue.
   *
   * @param queue The queue from which the element is to be removed.
   *
   * @return The removed element, NULL if queue was empty.
   */

  command TOS_MsgPtr dequeue(CircleQueue* queue);

  /**
   * Return the number of entries in the queue
   *
   * @return The number of entries in the queue.
   */
  command uint8_t getCount(CircleQueue* queue);

}

