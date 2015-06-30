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
 * This module implements the AllocSend interface. 
 * AllocSend passes messages to SendMsgQ. 
 * SendMsgR  passes messages to SendMsgQ. 
 *
 * Author:	Barbara Hohlt
 * Project:     QueuedASend	
 *
 *
 * @author  Barbara Hohlt
 * @date    March 2005 
 */

module ASendM {
 
  
  provides {
    interface StdControl as Control;
    interface AllocSend[uint8_t id]; 
    interface SendMsg as SendMsgR[uint8_t id]; 
  }

  uses {
    interface StdControl as SubControl;
    interface List as FreeList;  
    interface SendMsg as SendMsgQ;
    interface RouteSelect;
  }
}
implementation {

  command result_t Control.init() {

    dbg(DBG_BOOT|DBG_ROUTE, "ASendM: Initialized.\n");

    call SubControl.init();

    return SUCCESS;
  }
  
  command result_t Control.start() {
        dbg(DBG_BOOT|DBG_ROUTE, "ASendM: Started.\n");

	call SubControl.start();

	return SUCCESS;
  }
  
  command result_t Control.stop() {
        dbg(DBG_BOOT|DBG_ROUTE, "ASendM: Stopped.\n");
	call SubControl.stop();
	return SUCCESS; 
  }


  /* Return a buffer from the FreeList */
   command TOS_MsgPtr AllocSend.allocBuffer[uint8_t id]() {
    TOS_MsgPtr rval;

    rval = NULL;
    rval  = call FreeList.dequeue();
    dbg(DBG_ROUTE, "ASendM: allocBuffer on message at 0x%x.\n", rval);

    return rval; 
  }

  /* Return FALSE if the FreeList is empty, else TRUE */
   command bool AllocSend.hasFreeBuffers[uint8_t id]() {
    dbg(DBG_ROUTE, "ASendM: hasFreeBuffers.\n");

    return  ((call FreeList.empty()) ? FALSE : TRUE);
  }

  /* returns data portion of TOS_MHopMsg packet and length */
  /* should only be called by application ! */
  command void* AllocSend.getBuffer[uint8_t id](TOS_MsgPtr msg, uint16_t* length) {
    TOS_MHopMsg *dataPtr = (TOS_MHopMsg *)msg->data;

    msg->type = id;
   
    dbg(DBG_ROUTE, "ASendM: getBuffer.\n");

    *length = TOSH_DATA_LENGTH - offsetof(TOS_MHopMsg,data);

    return (void *) dataPtr->data;
  }

 inline void sendComplete(TOS_MsgPtr msg, result_t success) {

      /* return msg buffer to a freeList */
      if (call FreeList.member(msg)) {
        signal AllocSend.sendDone[msg->type](msg, success);
      	call FreeList.enqueue(msg);
      } else
        signal SendMsgR.sendDone[msg->type](msg, success);

   return;
 }

#ifdef SINGLE_HOP  
 /* Note, these defaults can be used if QueuedASend is not wired to
  * a MultiHop routing component. 
  */ 
 default command result_t RouteSelect.initializeFields(TOS_MsgPtr msg, uint8_t id)
 { return SUCCESS; }
 default command result_t RouteSelect.selectRoute(TOS_MsgPtr msg, uint8_t id)
 {  msg->addr = TOS_BCAST_ADDR; return SUCCESS; }
 default event result_t SendMsgR.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) 
 { return SUCCESS; }
#endif

 /* compiler seems to need this for parameterized AllocSend */
 default event result_t AllocSend.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success)
 { 
    dbg(DBG_ROUTE, "ASendM: DEFAULT sendDone  message at 0x%x.\n", msg);
    return SUCCESS; 
  }

 command result_t SendMsgR.send[uint8_t id](uint16_t address, uint8_t length, 
						TOS_MsgPtr msg) {

  dbg(DBG_ROUTE, "ASendM: Put route-thru message on sendQueue at 0x%x.\n", 
								msg);
  /* put message on sendQueue ... */
  if ((call SendMsgQ.send(address,length,msg)) != SUCCESS)
    return FAIL;
  else
    return SUCCESS;
 }

 command result_t AllocSend.send[uint8_t id](TOS_MsgPtr msg, uint16_t len) {
  uint16_t slen = offsetof(TOS_MHopMsg,data) + len;

  if (slen > TOSH_DATA_LENGTH) {
    call FreeList.enqueue(msg);
    return FAIL;
  }

  call RouteSelect.initializeFields(msg,id);

  if ((call RouteSelect.selectRoute(msg,id)) != SUCCESS) {
    call FreeList.enqueue(msg);
    return FAIL;
  }

  dbg(DBG_ROUTE, "ASendM: Put message on sendQueue at 0x%x.\n", msg);
  /* put message on sendQueue ... */
  if ((call SendMsgQ.send(msg->addr,slen,msg)) != SUCCESS) { 
    call FreeList.enqueue(msg);
    return FAIL;
  }
                                                                                
  return SUCCESS;
 }

  event result_t SendMsgQ.sendDone(TOS_MsgPtr msg, result_t success) 
  {
      dbg(DBG_ROUTE, "ASendM::SendMsg.sendDone  message 0x%x.\n",msg);

      sendComplete(msg,success);	

      return SUCCESS;
  }
}
