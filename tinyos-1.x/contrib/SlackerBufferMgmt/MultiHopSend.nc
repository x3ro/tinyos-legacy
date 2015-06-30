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
/*
 *	SlackerQueues
 *
 * Author:	Barbara Hohlt
 * Project:     FPS	
 *
 *
 * This module is an example of implementing a simple fifo forwarding queue 
 * with free list using SlackerQueues.
 *
 */

module MultiHopSend {
 
  
  provides {
    interface StdControl as Control;
    interface Send as Send; /* route-thru traffic */
    interface Send as SendApp; /* origin traffic */
    interface ActiveNotify;
  }

  uses {

    interface StdControl as SubControl;
    interface Leds;
    interface Timer as Timer0;
    interface RouteSelect;
    interface SendMsg as SendMsg;
    interface SlackerQ as Queue;
  }
}
implementation {

  SlackerQueue fifoQueue; 
  SlackerQueue *sendQueue; 


  /*
   *
   * Get next message from sendQueue
   * and forward
   */
  task void forwardNext() {
    TOS_MsgPtr sMsg;
    FPSmsg *message;

    if (DebugPM)
	call Leds.yellowOff();
    sMsg = NULL;
    sMsg = call Queue.dequeue(sendQueue);
    if (sMsg == NULL)
    {
        if (DebugPM) {
          call Leds.yellowOn();
        }
        dbg(DBG_ROUTE, "MultiHopSend: no messages to send.\n");

	return;
    }

    /* call RouteSelect.initializeFields(sMsg,AM_FPSMSG); dummy code */

    if (call RouteSelect.selectRoute(sMsg,AM_FPSMSG) != SUCCESS) {
        return ;
    }

    /* Forward route-thru and origin traffic */
    if ( call SendMsg.send(sMsg->addr,sizeof(FPSmsg),sMsg)) {
	if (SendLeds)
    	    call Leds.redOn();
        dbg(DBG_ROUTE, "MultiHopSend:forwardNext() succeeded.\n");

    } else { 
	  message = (FPSmsg *) sMsg->data;
          if (message->originaddr == TOS_LOCAL_ADDRESS)
          {
                /* return sMsg buffer to application */
                signal SendApp.sendDone(sMsg, FAIL);
          } else {
                /* return sMsg buffer to the free list */
                signal Send.sendDone(sMsg, FAIL);
          }
        dbg(DBG_ROUTE, "MultiHopSend:forwardNext() failed.\n");
    }

    return ;
  }

  command result_t Control.init() {

    dbg(DBG_BOOT|DBG_ROUTE, "MultiHopSend: Initialized.\n");

    /* create the forwarding queue */
    sendQueue = &fifoQueue;

    call Leds.init();

    call SubControl.init();

    call Queue.makeQ(sendQueue, 0); 

    return SUCCESS;
  }
  
  command result_t Control.start() {
        dbg(DBG_BOOT|DBG_ROUTE, "MultiHopSend: Started.\n");

	call SubControl.start();
	call Timer0.start(TIMER_REPEAT,3200);

	return SUCCESS;
  }
  
  command result_t Control.stop() {
        dbg(DBG_BOOT|DBG_ROUTE, "MultiHopSend: Stopped.\n");
 	call Timer0.stop();
	return call SubControl.stop();
  }

  /* Notifies the application that it is time to send a message */
  event result_t Timer0.fired()
  {
        signal ActiveNotify.activated();
	return SUCCESS;
  }

  /*
   *  getBuffer 
   * 
   *  called by application layer 
   * 
   *  - return sizeof FPS data buffer 
   *  - return pointer to FPSmsg data buffer 
   * 
   */ 
  command void* SendApp.getBuffer(TOS_MsgPtr msg, uint16_t* len) {
    FPSmsg *message = (FPSmsg *) msg->data;

    dbg(DBG_ROUTE, "MultiHopSend: getBuffer on message at 0x%x.\n", msg);

    *len = TOSH_DATA_LENGTH - offsetof(FPSmsg,data);
    return (void*)message->data;
  }

  /* Route-thru traffice never calls this. */
   command void* Send.getBuffer(TOS_MsgPtr msg, uint16_t* len) {
    return (void*)msg->data;
  }


 /* Queue route-thru traffic */
 command result_t Send.send(TOS_MsgPtr msg, uint16_t len) {
    FPSmsg *message = (FPSmsg *)msg->data;
    result_t rval;
                                                                                
    dbg(DBG_ROUTE, "MultiHopSend: Put route-thru message on sendQueue at 0x%x.\n", msg);
                                                                                
    message->sourceaddr = TOS_LOCAL_ADDRESS;
    message->hopcount++;
                                                                                
    /* put message on sendQueue ... */
    rval = FAIL;
    rval = call Queue.enqueue(sendQueue,msg);
    if (rval == FAIL)
    {
        if (DebugPM) {
          call Leds.redOn();
        }
        /* return msg buffer to the free list */
        dbg(DBG_ROUTE, "MultiHopSend: Enqueue message failed 0x%x.\n", msg);
        signal Send.sendDone(msg,FAIL);
    }

    post forwardNext(); /* Naive store-and-forward policy ! */
                                                                                
    return rval;
 }

 /* Queue origin traffic */
  command result_t SendApp.send(TOS_MsgPtr msg, uint16_t len) {
    FPSmsg *message = (FPSmsg *)msg->data;
    result_t rval;

    dbg(DBG_ROUTE, "MultiHopSend: Put app message on sendQueue at 0x%x.\n", msg);

    message->sourceaddr = message->originaddr = TOS_LOCAL_ADDRESS;
    message->hopcount= 0;

    /* put message on sendQueue ... */
    rval = FAIL;
    rval = call Queue.enqueue(sendQueue,msg);
    if (rval == FAIL)
    {
        if (DebugPM) {
          call Leds.redOn();
        }

  	/* return message buffer to application */
	signal SendApp.sendDone(msg,FAIL);
    }

    post forwardNext();

    return rval;
  }

  default event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
    return FAIL;
  }
  default event result_t SendApp.sendDone(TOS_MsgPtr msg, result_t success) {
    return FAIL;
  }
  
  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) 
  {
      FPSmsg *message = (FPSmsg *) msg->data;
                                                                                
      dbg(DBG_ROUTE, "MultiHopSend::SendMsg.sendDone  message 0x%x.\n",msg);
      if (SendLeds)
    	    call Leds.redOff();
                                                                                
      if (message->originaddr == TOS_LOCAL_ADDRESS)
      {
        /* return msg buffer to application */
        signal SendApp.sendDone(msg, success);
      } else {
        /* return msg buffer to the freeList */
        signal Send.sendDone(msg, success);
      }

      return SUCCESS;
  }


  default void event ActiveNotify.activated() {return;}
  default void event ActiveNotify.deactivated() {return;}

}
