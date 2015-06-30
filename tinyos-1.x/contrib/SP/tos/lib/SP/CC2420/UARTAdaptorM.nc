/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * @modified 3/8/06
 *
 * @author Arsalan Tavakoli <arsalan@cs.berkeley.edu>
 * @author Sukun Kim <binetude@cs.berkeley.edu>
 */
module UARTAdaptorM {
  provides {
    interface StdControl;
    interface SendSP as Send;
    interface ReceiveSP as Receive;
  }
  uses {
    interface StdControl as LowerControl;
    interface BareSendMsg as LowerSend;
    interface ReceiveMsg as LowerReceive;
    interface SPNeighbor;
    interface Leds;
  }
}
implementation {
 
  
  uint8_t findMatch(uint16_t _addr);
  
  TOS_Msg _tmpMsg;
  /*task void startSending() {
   if(!call LowerSend.send(&_tmpMsg))
     call Leds.yellowToggle();
   else
     call Leds.redToggle();
  }*/
 
  command result_t StdControl.init() {
    /*_tmpMsg.type = 0x49;
    _tmpMsg.group = TOS_AM_GROUP;
    _tmpMsg.addr = TOS_UART_ADDR;
    _tmpMsg.length = 0;*/
    call Leds.init();
    return call LowerControl.init();
  }

  command result_t StdControl.start() {
    /*result_t _tmp = call LowerControl.start();
    post startSending();
    return _tmp;*/
    return call LowerControl.start();
  }

  command result_t StdControl.stop() {
    return call LowerControl.stop();
  }

  command result_t Send.send(sp_message_t* pMsg) {
    atomic {
      pMsg->msg->type = pMsg->service;
      pMsg->msg->group = TOS_AM_GROUP;
      pMsg->msg->addr = TOS_UART_ADDR;
      if(pMsg->src) {
	pMsg->msg->fcflo = CC2420_DEF_FCF_LO_SOURCE;
	pMsg->msg->data[1] = (uint8_t)((TOS_LOCAL_ADDRESS & 0xFF00) >> 8);
	pMsg->msg->data[0] = (uint8_t)(TOS_LOCAL_ADDRESS & 0x00FF);
	pMsg->msg->length = pMsg->length + 2;
      }
      else {
        pMsg->msg->length = pMsg->length;
	pMsg->msg->fcflo = CC2420_DEF_FCF_LO;
      }
    }
    if (call LowerSend.send(pMsg->msg) == SUCCESS) {
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command void* Send.getBuffer(TOS_MsgPtr pMsg, uint16_t* length, bool src) {
    if (src) {
      *length = TOSH_DATA_LENGTH - 2;
      return &pMsg->data[2];
    }
    *length = TOSH_DATA_LENGTH;
    return &pMsg->data[0];
  }

  event result_t LowerSend.sendDone(TOS_MsgPtr pMsg, result_t result) {
    /*call Leds.greenToggle();
    post startSending();
    return SUCCESS;*/
    return signal Send.sendDone(pMsg, result);
  }

  event TOS_MsgPtr LowerReceive.receive(TOS_MsgPtr pMsg) {
    uint8_t dest_handle;
    //uint8_t source_handle;
    //uint16_t source;
    
    if (pMsg->addr == TOS_LOCAL_ADDRESS)
      dest_handle = TOS_LOCAL_HANDLE;
    else if (pMsg->addr == TOS_BCAST_ADDR)
      dest_handle = TOS_BCAST_HANDLE;
    else
      dest_handle = findMatch(pMsg->addr);
    
    return signal Receive.receive(pMsg,
                                  &pMsg->data[0],
				  pMsg->length,
				  TOS_UART_HANDLE,
				  dest_handle,
				  pMsg->type,
				  pMsg->group);
  }

  uint8_t findMatch(uint16_t _addr) {
    int i = 0;
    sp_neighbor_t* _neigh;
    for (i = 0; i < call SPNeighbor.max_neighbors(); i++) {
      _neigh = call SPNeighbor.get(i);
      if ((_neigh != NULL) &&
          (_neigh->addrLL.addr.link_addr == _addr))
        return (uint8_t)(i);
    }
    return TOS_OTHER_HANDLE;
  }

  event result_t SPNeighbor.admit(sp_neighbor_t* neighbor) {
    return SUCCESS;
  }

  event void SPNeighbor.evicted(sp_neighbor_t* neighbor) {
    return;
  }

  event void SPNeighbor.expired(sp_neighbor_t* neighbor, uint32_t timeon, uint32_t timeoff) {
    return;
  }
}
      
