// $Id: SendHeapM.nc,v 1.8 2006/05/18 19:58:40 chien-liang Exp $

/* Agilla - A middleware for wireless sensor networks.
 * Copyright (C) 2004, Washington University in Saint Louis 
 * By Chien-Liang Fok.
 * 
 * Washington University states that Agilla is free software; 
 * you can redistribute it and/or modify it under the terms of 
 * the current version of the GNU Lesser General Public License 
 * as published by the Free Software Foundation.
 * 
 * Agilla is distributed in the hope that it will be useful, but 
 * THERE ARE NO WARRANTIES, WHETHER ORAL OR WRITTEN, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO, IMPLIED WARRANTIES OF 
 * MERCHANTABILITY OR FITNESS FOR A PARTICULAR USE.
 *
 * YOU UNDERSTAND THAT AGILLA IS PROVIDED "AS IS" FOR WHICH NO 
 * WARRANTIES AS TO CAPABILITIES OR ACCURACY ARE MADE. THERE ARE NO 
 * WARRANTIES AND NO REPRESENTATION THAT AGILLA IS FREE OF 
 * INFRINGEMENT OF THIRD PARTY PATENT, COPYRIGHT, OR OTHER 
 * PROPRIETARY RIGHTS.  THERE ARE NO WARRANTIES THAT SOFTWARE IS 
 * FREE FROM "BUGS", "VIRUSES", "TROJAN HORSES", "TRAP DOORS", "WORMS", 
 * OR OTHER HARMFUL CODE.  
 *
 * YOU ASSUME THE ENTIRE RISK AS TO THE PERFORMANCE OF SOFTWARE AND/OR 
 * ASSOCIATED MATERIALS, AND TO THE PERFORMANCE AND VALIDITY OF 
 * INFORMATION GENERATED USING SOFTWARE. By using Agilla you agree to 
 * indemnify, defend, and hold harmless WU, its employees, officers and 
 * agents from any and all claims, costs, or liabilities, including 
 * attorneys fees and court costs at both the trial and appellate levels 
 * for any loss, damage, or injury caused by your actions or actions of 
 * your officers, servants, agents or third parties acting on behalf or 
 * under authorization from you, as a result of using Agilla. 
 *
 * See the GNU Lesser General Public License for more details, which can 
 * be found here: http://www.gnu.org/copyleft/lesser.html
 */


/**
 * Sends the heap of an agent.
 *
 * @author Chien-Liang Fok
 */
module SendHeapM {
  provides {
    interface StdControl;
    interface PartialAgentSenderI as SendHeap;
  }
  uses {
    interface MessageBufferI;
    interface HeapMgrI;    
    
    interface SendMsg as Send_Heap;       
    interface ReceiveMsg as Rcv_Ack;
    
    interface Timer as Ack_Timer;    
    interface ErrorMgrI as Error;
  }
}
implementation {  
  uint8_t _numRetransmits, _hpAddr, _nxtHpAddr, _numMsgs;
  uint16_t _dest;  
  AgillaAgentContext* _context;
  AgillaAgentID _id;
  bool _waiting;
  
  task void doSend();
  
  command result_t StdControl.init() {
    _waiting = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }  
  
  void sendFail() 
  {
    #if DEBUG_AGENT_SENDER
      dbg(DBG_USR1, "SendHeapM: send failed! # Retransmits = %i\n", _numRetransmits+1);
    #endif    
    _waiting = FALSE;
    if (++_numRetransmits < AGILLA_SNDR_MAX_RETRANSMITS) 
    {
      if (!post doSend()) 
      {
        dbg(DBG_USR1, "SendHeapM.sendFail: ERROR: Could not post doSend().\n");
        signal SendHeap.sendDone(_context, FAIL);  
      }
    } else
      signal SendHeap.sendDone(_context, FAIL);
  } // sendFail()
  
  command result_t SendHeap.send(AgillaAgentContext* context, AgillaAgentID id,
    uint8_t op, uint16_t dest, uint16_t final_dest) 
  {
    if (post doSend()) {      
      _numRetransmits = _hpAddr = _nxtHpAddr = _numMsgs = 0;

      _context = context;
      _id = id;
      _dest = dest;

      return SUCCESS;
    } else
      return FAIL;
  }
  
  task void doSend() 
  {
    TOS_MsgPtr msg = call MessageBufferI.getMsg();
    if (msg != NULL) 
    {
      struct AgillaHeapMsg *hpMsg = (struct AgillaHeapMsg *)msg->data;

      hpMsg->id = _id;   
      _nxtHpAddr = call HeapMgrI.fillMsg(_context, _hpAddr, hpMsg);    
      _hpAddr = hpMsg->data[0];
      
      if (call Send_Heap.send(_dest, sizeof(AgillaHeapMsg), msg)) 
      {
        #if DEBUG_AGENT_SENDER
          dbg(DBG_USR1, "SendHeapM: task doSend(): Sent heap message, nxtHpAddr = %i.\n", _nxtHpAddr);
        #endif  
        _waiting = TRUE;
        call Ack_Timer.start(TIMER_ONE_SHOT, AGILLA_SNDR_RXMIT_TIMER);               
      } else 
      {
        dbg(DBG_USR1, "SendHeapM: task doSend(): ERROR: Could not send message. \n");
        call MessageBufferI.freeMsg(msg);
        sendFail();
      }
    } else
    {
        dbg(DBG_USR1, "SendHeapM: task doSend(): ERROR: Failed to allocate message buffer, retry timer started.\n");
        call Ack_Timer.start(TIMER_ONE_SHOT, AGILLA_SNDR_RXMIT_TIMER);               
    }
  } // task doSend()

  
  event result_t Send_Heap.sendDone(TOS_MsgPtr m, result_t success) 
  { 
    call MessageBufferI.freeMsg(m);
    return SUCCESS;
  }  
  
  /**
   * This is executed whenever an ACK message times out.
   */
  event result_t Ack_Timer.fired() 
  {  
    if (_waiting)
    {
      dbg(DBG_USR1, "SendHeapM: Ack_Timer.fired(): ERROR: Timmed out while waiting for ACK.\n");
      sendFail();
    }
    return SUCCESS;
  }
  
  /**
   * This is signalled when an ACK message is received.
   */
  event TOS_MsgPtr Rcv_Ack.receive(TOS_MsgPtr m) 
  {
    AgillaAckHeapMsg* aMsg = (AgillaAckHeapMsg*)m->data;
    if (aMsg->id.id == _id.id && aMsg->addr1 == _hpAddr) 
    {
      _waiting = FALSE;
      call Ack_Timer.stop();
      
      #if DEBUG_AGENT_SENDER
        dbg(DBG_USR1, "SendHeapM: Rcv_Ack.receive: Got an ACK, accept = %i.\n", aMsg->accept);
      #endif
      
      if (aMsg->accept) 
      {        
        _hpAddr = _nxtHpAddr;          
        if (++_numMsgs == call HeapMgrI.numHeapMsgs(_context))
          signal SendHeap.sendDone(_context, SUCCESS);
        else
          post doSend();
      } else {
        dbg(DBG_USR1, "SendHeapM: Rcv_Ack.receive: ERROR: Heap message %i was rejected.\n", _hpAddr);
        signal SendHeap.sendDone(_context, FAIL);
      }
    } else
    {
      dbg(DBG_USR1, "SendHeapM: Rcv_Ack.receive: ERROR: Discarding ACK because wrong ID %i != %i, or wrong address %i != %i\n", aMsg->id.id, _id.id, aMsg->addr1, _hpAddr);
    }
    return m;
  }
}
