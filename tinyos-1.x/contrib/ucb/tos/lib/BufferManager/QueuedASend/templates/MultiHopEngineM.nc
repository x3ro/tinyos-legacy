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
 *		MultiHopEngine
 *
 * Author:	Barbara Hohlt
 * Project:	FPS, SchedRoute, QueuedASend	
 *
 *
 * This module receives route-thru messages and uses 
 * the BufferManager/QueuedASend and buffer management.
 *
 */

module MultiHopEngineM {
  
  provides {
    interface StdControl as Control;
    interface Receive[uint8_t id];
    interface RouteControl;
  }

  uses {
    interface StdControl as SubControl;
    interface ReceiveMsg[uint8_t id];
    interface RouteControl as RouteSelectCntl;
    interface RouteSelect;
    interface List as FreeList ;
    interface SendMsg as SendMsgQ[uint8_t id];	/* QueuedASend */

    command void startApp(TOS_MsgPtr pmsg);
  }
}
implementation {
  

  command result_t Control.init() {
    dbg(DBG_BOOT|DBG_ROUTE, "MultiHopRoute: Initialized.\n");


    call SubControl.init();

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
  * - receive an TOS_MHopMsg from downstream
  * - put on sendQueue 
  * - return a free buffer from the freeList
  *
  */
  event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr m) {
    TOS_MsgPtr rBuf;
    TOS_MHopMsg *message = (TOS_MHopMsg *) m->data;

    dbg(DBG_ROUTE, "MultiHopRoute: Received a packet.\n");

    /* get a buffer from the freeList... */
    rBuf = NULL;
    rBuf = call FreeList.dequeue();
    dbg(DBG_ROUTE, "MultiHopRoute: swap buffer at 0x%x.\n", rBuf);
    if (rBuf == NULL)
    {
    	dbg(DBG_ROUTE, "MultiHopRoute: freeList empty.\n");
	return m;
    }

    /* for messages destined here, not used in this example... 
     signal Receive.receive[id](m, f, sizeof(TOS_MHopMsg)); */

    message->sourceaddr = TOS_LOCAL_ADDRESS;
    message->hopcount++;

    if ((call RouteSelect.selectRoute(m,id)) != SUCCESS) {
	call FreeList.enqueue(rBuf);
	return m;
    }

    /* put on send queue */
    if ((call SendMsgQ.send[id](m->addr,sizeof(TOS_MHopMsg),m)) != SUCCESS) {
      call FreeList.enqueue(rBuf);
      return m;
    } else
      return rBuf;
  }

  event result_t SendMsgQ.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
    dbg(DBG_ROUTE, "MultiHopRoute: sendDone message at 0x%x.\n", msg);
    call FreeList.enqueue(msg);
    return success;
  }

  default event TOS_MsgPtr Receive.receive[uint8_t id](TOS_MsgPtr msg, void* payload, 
					uint16_t payloadLen) { return msg; }


  command uint16_t RouteControl.getParent() {
    return call RouteSelectCntl.getParent();
  }

  command uint8_t RouteControl.getQuality() {
    return call RouteSelectCntl.getQuality();
  }

  command uint8_t RouteControl.getDepth() {
    return call RouteSelectCntl.getDepth();
  }

  command uint8_t RouteControl.getOccupancy() {
    return (uint8_t)1;
  }

  command uint16_t RouteControl.getSender(TOS_MsgPtr msg) {
    TOS_MHopMsg	 *pMHMsg = (TOS_MHopMsg *)msg->data;
    return pMHMsg->sourceaddr;
  }

  command result_t RouteControl.setUpdateInterval(uint16_t Interval) {
    return call RouteSelectCntl.setUpdateInterval(Interval);
  }

  command result_t RouteControl.manualUpdate() {
    return call RouteSelectCntl.manualUpdate();
  }
}
