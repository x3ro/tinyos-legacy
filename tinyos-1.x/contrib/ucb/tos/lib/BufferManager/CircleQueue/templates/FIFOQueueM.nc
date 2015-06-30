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
 * This module implements a fifo queue using CircleQueue.	     
 *	     
 *	     
 * Author:  	Barbara Hohlt 	
 * Project:    	Buffer Manager	
 *	     
 * @author  Barbara Hohlt
 * @date    January 2003
 *	     
 */

#ifndef QUEUELENGTH
#define QUEUELENGTH 32
#endif

module FIFOQueueM {
  provides interface StdControl as Control;
  provides interface List as SimpleQueue;

  uses interface StdControl as SubControl;
  uses interface CircleQ as Queue; 
}


implementation {

  /* simpleQueue */
  CircleQueue fifoQueue;
  CircleQueue *simpleQueue;
  uint32_t bufQ[QUEUELENGTH];
  uint16_t q_len;

  command result_t Control.init() { 

     call SubControl.init();

    /* create a simple fifo queue */
    q_len = ( sizeof bufQ / 4 );
    simpleQueue = &fifoQueue;
    call Queue.set(simpleQueue,bufQ,q_len);

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

  command bool SimpleQueue.empty() {
    return call Queue.empty(simpleQueue);
  }

  command bool SimpleQueue.member(TOS_MsgPtr mem) {
    /* n/a */
    return FALSE;
  }


  command result_t SimpleQueue.enqueue(TOS_MsgPtr element) {
    return call Queue.enqueue(simpleQueue, element);
  }

  command TOS_MsgPtr SimpleQueue.dequeue() {
    return call Queue.dequeue(simpleQueue);
  }

  command uint8_t SimpleQueue.getOccupancy() {
    return call Queue.getCount(simpleQueue);
  }
}
