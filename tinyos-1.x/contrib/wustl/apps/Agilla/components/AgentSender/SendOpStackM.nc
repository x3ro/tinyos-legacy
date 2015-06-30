// $Id: SendOpStackM.nc,v 1.7 2006/05/18 19:58:40 chien-liang Exp $

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
 * Sends an agent's opstack.
 *
 * @author Chien-Liang Fok
 */
module SendOpStackM {
  provides {
    interface StdControl;
    interface PartialAgentSenderI as SendOpStack;
  }
  uses {
    interface MessageBufferI;
    interface OpStackI;    
    
    interface SendMsg as Send_OpStack;
    interface ReceiveMsg as Rcv_Ack;
    
    interface Timer as Ack_Timer;
    interface ErrorMgrI as Error;
  }
}
implementation {
  uint8_t _numRetransmits, _startAddr, _nxtStartAddr, _msgNum;
  uint16_t _dest;    // the one-hop address  
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
  
  inline void sendFail() 
  {    
    #if DEBUG_AGENT_SENDER
      dbg(DBG_USR1, "SendOpStackM: send failed!\n");
    #endif        
    _waiting = FALSE;
    if (++_numRetransmits < AGILLA_SNDR_MAX_RETRANSMITS) {
      if (!post doSend())
        signal SendOpStack.sendDone(_context, FAIL);                
    } else 
      signal SendOpStack.sendDone(_context, FAIL);                    
  }
  
  command result_t SendOpStack.send(AgillaAgentContext* context, AgillaAgentID id,
    uint8_t op, uint16_t dest, uint16_t final_dest) 
  {      
    if (post doSend()) {        
      _numRetransmits = _startAddr = _nxtStartAddr = _msgNum = 0;
      _context = context;
      _id = id;
      _dest = dest;
      return SUCCESS;
    } else
      return FAIL;
  }
  
  task void doSend() {
    TOS_MsgPtr msg = call MessageBufferI.getMsg();
    
    if (msg != NULL) 
    {
      struct AgillaOpStackMsg *osMsg = (struct AgillaOpStackMsg *)msg->data;

      osMsg->id = _id;
      osMsg->startAddr = _startAddr;        
      _nxtStartAddr = call OpStackI.fillMsg(_context, _startAddr, osMsg);    
      if (call Send_OpStack.send(_dest, sizeof(AgillaOpStackMsg), msg)) 
      {
        #if DEBUG_AGENT_SENDER
          dbg(DBG_USR1, "SendOpStackM: task doSend(): Sent opstack message %i.\n", _startAddr);
        #endif        
        _waiting = TRUE;
        call Ack_Timer.start(TIMER_ONE_SHOT, AGILLA_SNDR_RXMIT_TIMER);      
      } else 
      {
        call MessageBufferI.freeMsg(msg);
        sendFail();   
      }
    } else
    {
      #if DEBUG_AGENT_SENDER
        dbg(DBG_USR1, "SendOpStackM: task doSend(): Failed to allocate message buffer, retry timer started.\n");
      #endif            
      call Ack_Timer.start(TIMER_ONE_SHOT, AGILLA_SNDR_RXMIT_TIMER);          
    }
  } // task doSend()

  event result_t Send_OpStack.sendDone(TOS_MsgPtr m, result_t success)    
  { 
    call MessageBufferI.freeMsg(m);
    return SUCCESS;
  }
  
  /**
   * This is executed whenever an ACK message times out.
   */
  event result_t Ack_Timer.fired() {  
    if (_waiting)
      sendFail();
    return SUCCESS;
  }
  
  /**
   * This is signalled when an ACK message is received.
   */
  event TOS_MsgPtr Rcv_Ack.receive(TOS_MsgPtr m) 
  {
    AgillaAckOpStackMsg* aMsg = (AgillaAckOpStackMsg*)m->data;
    if (aMsg->id.id == _id.id && aMsg->startAddr == _startAddr) 
    {   
      _waiting = FALSE;
      call Ack_Timer.stop();
      if (aMsg->accept) {
        _startAddr = _nxtStartAddr;          
        if (++_msgNum * AGILLA_OS_MSG_SIZE < _context->opStack.sp)
          post doSend();
        else
          signal SendOpStack.sendDone(_context, SUCCESS);  
      } else {
        #if DEBUG_AGENT_SENDER
          dbg(DBG_USR1, "SendOpStackM: Rcv_Ack.receive: The opStack message %i was rejected.\n", _startAddr);
        #endif            
        signal SendOpStack.sendDone(_context, FAIL);  
      }
    }  
    return m;
  }
}
