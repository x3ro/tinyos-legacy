/*									tab:4
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
/**
 * This module implements a simple fifo sendQueue 
 * using CircleQueues and AllocSend.
 *
 * Author:	Barbara Hohlt
 * Project:     QueuedASend	
 *
 * @author  Barbara Hohlt
 * @date    March 2005
 */

module QueuedASendM {
 
  
  provides {
    interface StdControl as Control;
    interface SendMsg as SendMsgQ; /* all out-bound messages */
    interface QueuePolicy; 
  }

  uses {

    interface StdControl as SubControl;
    interface List as SendQueue;
    interface SendMsg[uint8_t id];
    interface Leds;

  }
}
implementation {


  /*
   *
   * Get next message from sendQueue
   * and forward
   */
  task void forwardNext() {
    TOS_MsgPtr sMsg;

    sMsg = NULL;
    sMsg = call SendQueue.dequeue();
    if (sMsg == NULL)
    {
        dbg(DBG_ROUTE, "QueuedASend: no messages to send.\n");
	return;
    }


    dbg(DBG_ROUTE, "QueuedASend: parent %u.\n",sMsg->addr);
    /* Forward route-thru and origin traffic */
    if ( call SendMsg.send[sMsg->type](sMsg->addr,sizeof(TOS_MHopMsg),sMsg)) {
        dbg(DBG_ROUTE, "QueuedASend:forwardNext() succeeded.\n");

    } else { 
        /* return sMsg buffer to the free list */
        signal SendMsgQ.sendDone(sMsg, FAIL);
        dbg(DBG_ROUTE, "QueuedASend:forwardNext() failed.\n");
    }

    return ;
  }

  command result_t Control.init() {

    dbg(DBG_BOOT|DBG_ROUTE, "QueuedASend: Initialized.\n");

    call Leds.init();

    call SubControl.init();

    return SUCCESS;
  }
  
  command result_t Control.start() {
        dbg(DBG_BOOT|DBG_ROUTE, "QueuedASend: Started.\n");

	call SubControl.start();

	return SUCCESS;
  }
  
  command result_t Control.stop() {
        dbg(DBG_BOOT|DBG_ROUTE, "QueuedASend: Stopped.\n");
	call SubControl.stop();
	return SUCCESS; 
  }


 /* Queue route-thru and origin traffic */
 command result_t SendMsgQ.send(uint16_t address,uint8_t length,TOS_MsgPtr msg ) {
    result_t rval;
                                                                                
    dbg(DBG_ROUTE, "QueuedASend: Put message on sendQueue 0x%x.\n", msg);
                                                                                
    /* put message on sendQueue ... */
    rval = FAIL;
    rval = call SendQueue.enqueue(msg);
    if (rval == FAIL)
    {
        /* return msg buffer to the free list */
        dbg(DBG_ROUTE, "QueuedASend: Enqueue message failed 0x%x.\n", msg);
        signal SendMsgQ.sendDone(msg,FAIL);
    }

    signal QueuePolicy.next(); /* signal policy component */

    return rval;
 }

  /* the forwarding policy  */
  command void QueuePolicy.forward() {
    post forwardNext(); 
    return;
  }
  /* the default forwarding policy */
  default event void QueuePolicy.next() { post forwardNext(); }

  event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) 
  {
                                                                                
      dbg(DBG_ROUTE, "QueuedASend::SendMsg.sendDone  message 0x%x. :%u\n",
			msg,success);

        /* return msg buffer to the freeList */
      signal SendMsgQ.sendDone(msg, success);

      return SUCCESS;
  }
}
