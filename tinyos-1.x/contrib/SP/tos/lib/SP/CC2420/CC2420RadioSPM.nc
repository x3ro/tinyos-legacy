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
module CC2420RadioSPM {
  provides {
    interface SplitControl;
    interface SPLinkAdaptor;
    interface SendSP as Send;
    interface ReceiveSP as Receive;
  } uses {
    interface SplitControl as RadioControl;
    interface BareSendMsg as LowerSend;
    interface ReceiveMsg as LowerReceive;
    interface MacControl as LowerMacControl;
    //interface MacBackoff as LowerMacBackoff;
    interface SPNeighbor;
  }
}
implementation {
  
  TOS_MsgPtr currentMsg;
  sp_message_t* currentSPMsg;
  TOS_Msg ackMsg;
  bool ackMsg_Busy;
  sp_link_state_t radioState;
  
  uint8_t findMatch(uint16_t _addr);
  task void SendMessage() {
    ackMsg.type = 0x49;
    ackMsg.group = TOS_AM_GROUP;
    ackMsg.addr = TOS_BCAST_ADDR;
    ackMsg.length = 0;
    ackMsg.fcflo = CC2420_DEF_FCF_LO;
    call LowerSend.send(&ackMsg);
  }
  
  command result_t SplitControl.init() {
    ackMsg_Busy = FALSE;
    currentMsg = NULL;
    currentSPMsg = NULL;
    atomic radioState = SP_LINK_SLEEP;
    return call RadioControl.init();
  }

  event result_t RadioControl.initDone() {
    return signal SplitControl.initDone();
  }

  command result_t SplitControl.start() {
    return call RadioControl.start();
  }

  event result_t RadioControl.startDone() {
    //post SendMessage();
    atomic radioState = SP_LINK_AWAKE;
    return signal SplitControl.startDone();
  }

  command result_t SplitControl.stop() {
    return call RadioControl.stop();
  }

  event result_t RadioControl.stopDone() {
    return signal SplitControl.stopDone();
  }
  
  command result_t SPLinkAdaptor.find() {
    return SUCCESS;
  }

  command result_t SPLinkAdaptor.findDone() {
    return SUCCESS;
  }

  async command sp_link_state_t SPLinkAdaptor.getState() {
    return radioState;
  }

  command result_t Send.send(sp_message_t* pMsg) {
    sp_neighbor_t* _neigh = call SPNeighbor.get(pMsg->sp_handle);
    bool errorHere = FALSE;
    dbg(DBG_USR3, "CC2420RadioSPM: Send called with value %d\n", pMsg->msg->data[0]);
    dbg(DBG_USR3, "Message Handle: %d, Neighbor Handle: %d\n", pMsg->sp_handle, _neigh->sp_handle);
    atomic {
      if ((_neigh == NULL) ||
          (currentSPMsg != NULL) ||
	  (radioState != SP_LINK_AWAKE))
	    errorHere = TRUE;
    }
    if (errorHere) {
      dbg(DBG_USR3, "CC2420RadioSPM: Error, return Failure\n");
      return FAIL;
    }
    atomic {
      radioState = SP_LINK_BUSY;
      pMsg->msg->type = pMsg->service;
      pMsg->msg->group = TOS_AM_GROUP;
      if(_neigh->sp_handle == TOS_BCAST_HANDLE) {
        dbg(DBG_USR3, "Setting address to Bcast: %d\n", TOS_BCAST_ADDR);
	pMsg->msg->addr = TOS_BCAST_ADDR;
	dbg(DBG_USR3, "Address set to: %d\n", pMsg->msg->addr);
      }
      else {
        dbg(DBG_USR3, "Setting address to: %d\n", _neigh->addrLL.addr.link_addr);
        pMsg->msg->addr = _neigh->addrLL.addr.link_addr;
      }
      if (pMsg->reliability)
        call LowerMacControl.enableAck();
      if (pMsg->src) {
        pMsg->msg->data[1] = (uint8_t) ((TOS_LOCAL_ADDRESS & 0xFF00) >> 8);
	pMsg->msg->data[0] = (uint8_t) (TOS_LOCAL_ADDRESS & 0x00FF);
	pMsg->msg->length = pMsg->length + 2;
	pMsg->msg->fcflo = CC2420_DEF_FCF_LO_SOURCE;
      }
      else {
        pMsg->msg->length = pMsg->length;
	pMsg->msg->fcflo = CC2420_DEF_FCF_LO;
      }
    }
    if (call LowerSend.send(pMsg->msg) == SUCCESS) {
      dbg(DBG_USR3, "LowerSend.send with value: %d to %d\n", pMsg->msg->data[0], pMsg->msg->addr);
      atomic {
        currentSPMsg = pMsg;
	currentMsg = pMsg->msg;
      }
      return SUCCESS;
    }
    return FAIL;
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
    call LowerMacControl.disableAck();
    atomic radioState = SP_LINK_AWAKE;
    if(pMsg == &ackMsg) {
      dbg(DBG_USR3, "Ack Msg with dsn %d sent successfully\n");
      atomic ackMsg_Busy = FALSE;
      return SUCCESS;
    }
    
    dbg(DBG_USR3, "reliability: %d, pMsg->ack: %d\n", currentSPMsg->reliability, pMsg->ack);

    
    if ((currentSPMsg->reliability == TRUE) &&
        (pMsg->ack == 0)) {
	  atomic {
	    currentSPMsg = NULL;
	    currentMsg = NULL;
	  }
	  return signal Send.sendDone(pMsg, FAIL);
    }
    atomic {
      currentSPMsg = NULL;
      currentMsg = NULL;
    }
    dbg(DBG_USR3, "CC2420RadioM.sendDone: count: %d, result: %d\n", pMsg->data[0], result);
    return signal Send.sendDone(pMsg,result);
  }
  
  event TOS_MsgPtr LowerReceive.receive(TOS_MsgPtr pMsg) {
    uint8_t dest_handle;
    uint8_t source_handle;
    uint16_t source;
    dbg(DBG_USR3, "LowerReceive.receive, addressed to %d, dsn %d\n", pMsg->addr, pMsg->dsn);
    // If a packet was requested, send it immediately
    // If can't send immediately, ack dropped (CHANGE?)
    if ((pMsg->addr == TOS_LOCAL_ADDRESS) &&
        (pMsg->fcfhi == CC2420_DEF_FCF_HI_ACK) &&
	(pMsg->crc) &&
	(!ackMsg_Busy)) {
	  dbg(DBG_USR3, "Message from %d needs ack!\n", pMsg->data[0]);
	  ackMsg.fcflo = CC2420_DEF_FCF_LO;
	  ackMsg.fcfhi = CC2420_DEF_FCF_TYPE_ACK;
	  ackMsg.dsn = pMsg->dsn;
	  ackMsg.addr = TOS_BCAST_ADDR;
	  ackMsg.length = 0;

	  if(radioState == SP_LINK_AWAKE) {
	    //call LowerMacControl.disableCCA()
	    dbg(DBG_USR3, "Trying to send ack\n");
	    atomic radioState = SP_LINK_BUSY;
	    if (call LowerSend.send(&ackMsg) == SUCCESS) {
	      atomic ackMsg_Busy = TRUE;
	      dbg(DBG_USR3, "Ack sent\n");
	    }
	  }
    }
    if (pMsg->addr == TOS_LOCAL_ADDRESS)
      dest_handle = TOS_LOCAL_HANDLE;
    else if (pMsg->addr == TOS_BCAST_ADDR)
      dest_handle = TOS_BCAST_HANDLE;
    else
      dest_handle = findMatch(pMsg->addr);
    
    // This is a normal packet
    // Source embedded
    if (pMsg->fcflo == CC2420_DEF_FCF_LO_SOURCE) {
      source = (uint16_t)(pMsg->data[1]) << 8;
      source += (uint16_t)(pMsg->data[0]);
      source_handle = findMatch(source);
      return signal Receive.receive(pMsg,
                                    &pMsg->data[2],
				    pMsg->length - 2,
				    source_handle,
				    dest_handle,
				    pMsg->type,
				    pMsg->group);
    }
    else {
      return signal Receive.receive(pMsg,
                                    &pMsg->data[0],
				    pMsg->length,
				    TOS_NO_HANDLE,
				    dest_handle,
				    pMsg->type,
				    pMsg->group);
    }
  }

  uint8_t findMatch(uint16_t _addr) {
    int i = 0;
    sp_neighbor_t* _neigh;
    for (i = 0; i < call SPNeighbor.max_neighbors(); i++) {
      _neigh = call SPNeighbor.get(i);;
      if ((_neigh != NULL) &&
         (_neigh->addrLL.addr.link_addr == _addr))
        return (uint8_t)(i);
    }
    return TOS_OTHER_HANDLE;
  }

  command sp_neighbor_t* SPLinkAdaptor.findNode(sp_neighbor_t* _neigh, TOS_MsgPtr _msg) {
    uint8_t _tmpIndex = TOS_NO_HANDLE;
    uint16_t _tmpAddress;
    
    if (_neigh != NULL) 
      _tmpIndex = findMatch(_neigh->addrLL.addr.link_addr);
    if (_tmpIndex != TOS_NO_HANDLE)
      return call SPNeighbor.get(_tmpIndex);
    else if ((_msg != NULL) && (_msg->fcflo == CC2420_DEF_FCF_LO_SOURCE)) {
      _tmpAddress = (uint16_t)(_msg->data[1]) << 8;
      _tmpAddress += (uint16_t)(_msg->data[0]);
      _tmpIndex = findMatch(_tmpAddress);
      if (_tmpIndex != TOS_NO_HANDLE)
        return call SPNeighbor.get(_tmpIndex);
    }
    return NULL;
  }

  command addr_struct* SPLinkAdaptor.getAddress(TOS_MsgPtr _msg) {
    addr_struct _tmpStruct;
    if (_msg->fcflo != CC2420_DEF_FCF_LO_SOURCE)
      return NULL;
    _tmpStruct.addr_type = CC2420_ADDR_TYPE;
    _tmpStruct.addr.link_addr = (uint16_t)(_msg->data[1]) << 8;
    _tmpStruct.addr.link_addr += (uint16_t)(_msg->data[0]);
    return &_tmpStruct;
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
  
