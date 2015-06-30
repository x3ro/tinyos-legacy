// $Id: SendRxnM.nc,v 1.9 2006/05/18 19:58:40 chien-liang Exp $

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
 * Sends the reactions of an agent.
 *
 * @author Chien-Liang Fok
 * @version 1.3
 */
module SendRxnM {
  provides {
    interface StdControl;
    interface PartialAgentSenderI as SendRxn;
  }
  uses {
    interface MessageBufferI;
    interface RxnMgrI;
    
    interface SendMsg as Send_Rxn;
    interface ReceiveMsg as Rcv_Ack;

    interface Timer as Ack_Timer;   
    interface ErrorMgrI as Error;
  }
}
implementation {
  uint8_t _numRetransmits, _msgNum;  // the number of reactions that have been sent  
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
  
  inline void sendFail() 
  {
    #if DEBUG_AGENT_SENDER
      dbg(DBG_USR1, "SendRxnM: send failed!\n");
    #endif        
  
    _waiting = FALSE;
    
    if (++_numRetransmits < AGILLA_SNDR_MAX_RETRANSMITS) {
      if (!post doSend())
        signal SendRxn.sendDone(_context, FAIL);                
    } else 
      signal SendRxn.sendDone(_context, FAIL);                    
  }  
    
  command result_t SendRxn.send(AgillaAgentContext* context, AgillaAgentID id,
    uint8_t op, uint16_t dest, uint16_t final_dest) 
  {      
    if (post doSend()) {                      
      _numRetransmits = _msgNum = 0;
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

    #if DEBUG_AGENT_SENDER
      dbg(DBG_USR1, "SendRxnM: task doSend(): task called.\n");
    #endif        

    
    if (msg != NULL) 
    {
      struct AgillaRxnMsg *rxnMsg = (struct AgillaRxnMsg *)msg->data;
      rxnMsg->msgNum = _msgNum;    
      if(call RxnMgrI.getRxn(&_context->id, _msgNum, &rxnMsg->rxn)) 
      {
        rxnMsg->rxn.id = _id;  // update the ID
        if (!call Send_Rxn.send(_dest, sizeof(AgillaRxnMsg), msg))
          sendFail();     
        else 
        {
          #if DEBUG_AGENT_SENDER
            dbg(DBG_USR1, "SendRxnM: task doSend(): Sent rxn message %i.\n", _msgNum);
          #endif      
          _waiting = TRUE;
          call Ack_Timer.start(TIMER_ONE_SHOT, AGILLA_SNDR_RXMIT_TIMER);              
        }
      } else {             
        dbg(DBG_USR1, "SendRxnM.doSend(): ERROR: could not get reaction %i of agent %i\n", _msgNum, _context->id.id);
        call Error.errord(_context, AGILLA_ERROR_RXN_NOT_FOUND, _msgNum);
        call MessageBufferI.freeMsg(msg);
        signal SendRxn.sendDone(_context, FAIL);
      }
    } else
    {
      #if DEBUG_AGENT_SENDER
        dbg(DBG_USR1, "SendRxnM: task doSend(): Failed to allocated buffer, retry timer set.\n");
      #endif        
      call Ack_Timer.start(TIMER_ONE_SHOT, AGILLA_SNDR_RXMIT_TIMER);     
    }
  }
  
  /**
   * This is executed whenever an ACK message times out.
   */
  event result_t Ack_Timer.fired() 
  {  
    if (_waiting) 
    {
      #if DEBUG_AGENT_SENDER
        dbg(DBG_USR1, "SendRxnM: ACK timer fired...\n");
      #endif          
      sendFail();      
    }
    return SUCCESS;
  }
  
  /**
   * This is signalled when an ACK message is received.
   */
  event TOS_MsgPtr Rcv_Ack.receive(TOS_MsgPtr m) 
  {
    AgillaAckRxnMsg* aMsg = (AgillaAckRxnMsg*)m->data;
  
    #if DEBUG_AGENT_SENDER
      dbg(DBG_USR1, "SendRxnM: Received an ACK...\n");
    #endif       
    
    if (aMsg->id.id == _id.id) 
    {
      _waiting = FALSE;
      call Ack_Timer.stop();
      if (aMsg->accept) {
        #if DEBUG_AGENT_SENDER
          dbg(DBG_USR1, "SendRxnM: Received a SUCCESS ACK.\n");
        #endif                    
        if (++_msgNum <  call RxnMgrI.numRxns(&_context->id))
          post doSend();
        else
          signal SendRxn.sendDone(_context, SUCCESS);  
      } else {
        #if DEBUG_AGENT_SENDER
          dbg(DBG_USR1, "SendRxnM: Received a REJECT ACK.\n");
        #endif              
        signal SendRxn.sendDone(_context, FAIL);               
      }
    } else {
        #if DEBUG_AGENT_SENDER
          dbg(DBG_USR1, "SendRxnM: Received an ACK for the wrong agent (%i != %i).\n", aMsg->id.id, _id.id);
        #endif        
    }
    return m;
  }
  
  event result_t Send_Rxn.sendDone(TOS_MsgPtr m, result_t success)    { 
    call MessageBufferI.freeMsg(m);
    return SUCCESS; 
  } 
}
