/*		
 *
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
 *	SlackerQueues
 *
 * Author:	Barbara Hohlt
 * Project:	FPS
 *
 *
 * This module is an example of implementing a simple free list
 * with a forwarding queue using SlackerQueues.
 *
 */

module MultiHopRoute {
  
  provides {
    interface StdControl as Control;
    interface Receive;
  }

  uses {
    interface StdControl as SubControl;
    interface Send as Send;
    interface ReceiveMsg as ReceiveMsg;
    interface SlackerQ as Queue;


    command void startApp(TOS_MsgPtr pmsg);
  }
}
implementation {
  
  SlackerQueue bufferQueue;
  SlackerQueue *freeList;

  command result_t Control.init() {
    dbg(DBG_BOOT|DBG_ROUTE, "MultiHopRoute: Initialized.\n");


    call SubControl.init();

    /* create the free list */
    freeList = &bufferQueue;
    call Queue.makeQ(freeList, 1);

    return SUCCESS;
  }
  
  command result_t Control.start() {
    dbg(DBG_BOOT|DBG_ROUTE, "MultiHopRoute: Started.\n");
    return call SubControl.start();
  }
  
  command result_t Control.stop() {
    dbg(DBG_BOOT|DBG_ROUTE, "MultiHopRoute: Stopped.\n");
    return call SubControl.stop();
  }

 /*
  * ReceiveMsg.receive
  *
  * - receive an FPSmsg from downstream
  * - put on sendQueue 
  * - return a free buffer from the freeList
  *
  */
  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
    TOS_MsgPtr rBuf;
    /* FPSmsg *f = (FPSmsg *) m->data; */

    dbg(DBG_ROUTE, "MultiHopRoute: Received a packet.\n");

    /* return a buffer from the freeList... */
    rBuf = NULL;
    rBuf = call Queue.dequeue(freeList);
    if (rBuf == NULL)
    {
    	dbg(DBG_ROUTE, "MultiHopRoute: freeList empty.\n");
	return m;
    }
    /* for messages destined here, not used in this example... 
     signal Receive.receive(m, f, sizeof(FPSmsg)); */

    /* put on send queue */
    call Send.send(m,sizeof(FPSmsg));

    return rBuf;
  }

  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
    result_t rval;

    /* return msg to the freeList...*/
    rval = FAIL;
    rval = call Queue.enqueue(freeList,msg);
    if (rval == FAIL)
    {
	return FAIL;
    }

    return SUCCESS;
  }

  default event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg, void* payload, 
					uint16_t payloadLen) { return msg; }
}
