// $Id: SendHeapM.nc,v 1.1 2005/10/13 17:12:13 chien-liang Exp $

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
 * Sends the code of an agent.
 *
 * @author Chien-Liang Fok
 * @version 1.3
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
    interface ErrorMgrI as Error;
  }
}
implementation {  
  AgillaAgentContext* _context;
  AgillaAgentID _id;
  uint8_t _numRetransmits, _hpAddr, _nxtHpAddr, _numMsgs;
  uint16_t _dest;  
  
  task void doSend();
  
  command result_t StdControl.init() {    
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }  
  
  inline void sendFail() {
    if (++_numRetransmits < AGILLA_SNDR_MAX_RETRANSMITS) {
      if (!post doSend())
        signal SendHeap.sendDone(_context, FAIL);  
    } else
      signal SendHeap.sendDone(_context, FAIL);
  }
  
  command result_t SendHeap.send(AgillaAgentContext* context, AgillaAgentID id,
    uint8_t op, uint16_t dest) 
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
  
  task void doSend() {
    TOS_MsgPtr msg = call MessageBufferI.getBuffer();
    struct AgillaHeapMsg *hpMsg = (struct AgillaHeapMsg *)msg->data;
    
    hpMsg->id = _id;   
    _nxtHpAddr = call HeapMgrI.fillMsg(_context, _hpAddr, hpMsg);    
    if (!call Send_Heap.send(_dest, sizeof(AgillaHeapMsg), msg)) 
      sendFail();
  }

  event result_t Send_Heap.sendDone(TOS_MsgPtr m, result_t success) { 
    if (!success /*|| !m->ack*/)
      sendFail();
    else {
      _hpAddr = _nxtHpAddr;
      if (++_numMsgs == call HeapMgrI.numHeapMsgs(_context))
        signal SendHeap.sendDone(_context, SUCCESS);
      else
        post doSend();    
    }
    return SUCCESS;
  }  
  
  /**
   * This is executed whenever an ACK message times out.
   */
  /*event result_t Ack_Timer.fired() {  
    _numRetransmits++;    
    
    #if DEBUG_AGENT_SENDER
    dbg(DBG_USR1, "SendHeapM: Ack_Timer.fired(): TIMED OUT! (# = %i)\n", _numRetransmits);
    #endif     
    
    if (_numRetransmits < AGILLA_SNDR_MAX_TIMEOUTS) {

      #if DEBUG_AGENT_SENDER
        dbg(DBG_USR1, "SendHeapM: Ack_Timer.fired(): Retransmitting the heap message...\n");
      #endif    

      post doSend();
    } else {
      #if DEBUG_AGENT_SENDER
      dbg(DBG_USR1, "SendHeapM: Ack_Timer.fired(): MAXIMUM number of timeouts reached! aborting\n");
      #endif    
      signalDone(FAIL);    
    }
    return SUCCESS;
  }*/  
  
  /**
   * This is signalled when an ACK message is received.
   */
  /*event TOS_MsgPtr Rcv_Ack.receive(TOS_MsgPtr m) {
    #if DEBUG_AGENT_SENDER
      dbg(DBG_USR1, "SendHeapM: Rcv_Ack.receive: got an ack!\n");
    #endif
    
    if (_state == WAITING) {
      AgillaAckHeapMsg* aMsg = (AgillaAckHeapMsg*)m->data;
      if (aMsg->id.id == _id.id && aMsg->addr1 == _addr1) {        
        call Ack_Timer.stop();
        if (aMsg->accept) {
          _hpAddr = _nxtHpAddr;          
          if (++_numMsgs == call HeapMgrI.numHeapMsgs(_context))
            signalDone(SUCCESS);
          else
            post doSend();
        } else {
          #if DEBUG_AGENT_SENDER
          dbg(DBG_USR1, "SendHeapM: Rcv_Ack.receive: The heap message %i was rejected.\n", _addr1);
          #endif            
          signalDone(FAIL);
        }
      } else {
        #if DEBUG_AGENT_SENDER
        dbg(DBG_USR1, "SendHeapM: Rcv_Ack.receive: The ACK was not for this agent.\n");
        #endif    
      }
    } else {
      #if DEBUG_AGENT_SENDER
      dbg(DBG_USR1, "SendHeapM: Rcv_Ack.receive: Received an ACK while not WAITING.\n");
      #endif
    }
    return m;
  }*/
}
