// $Id: ReceiveCodeM.nc,v 1.5 2006/05/18 19:58:40 chien-liang Exp $

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

includes Agilla;
includes MigrationMsgs;

/**
 * Receives the code of an incomming agent.
 *
 * @author Chien-Liang Fok
 */
module ReceiveCodeM {
  uses {
    interface ReceiverCoordinatorI as CoordinatorI;
    interface CodeMgrI;
    interface ReceiveMsg as Rcv_Code;
    interface SendMsg as Send_Code_Ack;
    interface MessageBufferI;
  }    
}
implementation {
  
  void sendCodeAck(uint16_t addr, AgillaAgentID *id, uint8_t acpt, uint16_t msgNum) 
  {
    TOS_MsgPtr msg = call MessageBufferI.getMsg();
    if (msg != NULL) 
    {
      struct AgillaAckCodeMsg *aMsg = (struct AgillaAckCodeMsg *)msg->data;
      aMsg->id = *id;
      aMsg->accept = acpt;
      aMsg->msgNum = msgNum;
      if (!call Send_Code_Ack.send(addr, sizeof(AgillaAckCodeMsg), msg))
        call MessageBufferI.freeMsg(msg);
      if (acpt == AGILLA_REJECT)
        call CoordinatorI.resetBuffer(id);
    }
  }
  
  event TOS_MsgPtr Rcv_Code.receive(TOS_MsgPtr m) 
  {    
    AgillaCodeMsg *cMsg = (AgillaCodeMsg*)m->data;        
    AgillaAgentInfo* inBuf;
    
    if (!call CoordinatorI.isArriving(&cMsg->id)) 
    {           
      #if DEBUG_AGENT_RECEIVER
        dbg(DBG_USR1, "ReceiveCodeM: Rcv_Code.receive: ERROR: Agent %i is not arriving.\n", cMsg->id.id);
      #endif         
      return m;
    }
    
    inBuf = call CoordinatorI.getBuffer(&cMsg->id);
    if (inBuf == NULL) 
    {              
      #if DEBUG_AGENT_RECEIVER
        dbg(DBG_USR1, "ReceiveCodeM: Rcv_Code.receive: ERROR: Could not get incomming buffer for agent %i.\n", cMsg->id.id);
      #endif          
      return m; 
    }
    
    if (!call CoordinatorI.stopTimer(&cMsg->id)) 
    {      
      #if DEBUG_AGENT_RECEIVER
      dbg(DBG_USR1, "ReceiveCodeM: Rcv_Code.receive: ERROR: Could not stop timer for agent %i.\n", cMsg->id.id);
      #endif                   
      sendCodeAck(inBuf->reply, &cMsg->id, AGILLA_REJECT, cMsg->msgNum);
      return m;      
    }    
    
    if (!(inBuf->integrity & AGILLA_RECEIVED_CODE))  // if still waiting for code msgs
    {
      if (!call CodeMgrI.setBlock(inBuf->context, cMsg)) 
      {        
        #if DEBUG_AGENT_RECEIVER
          dbg(DBG_USR1, "ReceiveCodeM: Rcv_Code.receive: ERROR: Failed to set block %i.\n", cMsg->msgNum);      
        #endif                
        call CoordinatorI.resetBuffer(&cMsg->id);
        sendCodeAck(inBuf->reply, &cMsg->id, AGILLA_REJECT, cMsg->msgNum);
        return m;         
      }
   
      #if DEBUG_AGENT_RECEIVER
        dbg(DBG_USR1, "ReceiveCodeM: Rcv_Code.receive: Received CODE message %i of %i for agent %i.\n", 
          cMsg->msgNum+1, inBuf->nCBlocks, cMsg->id.id);      
      #endif
        
      if (cMsg->msgNum+1 == inBuf->nCBlocks)
        inBuf->integrity |= AGILLA_RECEIVED_CODE;      
    }
          
    #if DEBUG_AGENT_RECEIVER
      dbg(DBG_USR1, "ReceiveCodeM: Rcv_Code.receive: Sending ACCEPT CODE ACK (%i) back to node %i.\n", 
        cMsg->msgNum, inBuf->reply);
    #endif                
    sendCodeAck(inBuf->reply, &cMsg->id, AGILLA_ACCEPT, cMsg->msgNum);        
    
    // Check whether agent is ready to run and start the appropriate timer.
    if (inBuf->integrity == AGILLA_AGENT_READY) 
    {
      #if DEBUG_AGENT_RECEIVER
        dbg(DBG_USR1, "ReceiveCodeM: Rcv_Code.receive: Received agent %i, starting FIN timer.\n", cMsg->id.id);
      #endif         
      call CoordinatorI.startFinTimer(&cMsg->id);
    } else 
    {
      #if DEBUG_AGENT_RECEIVER
        dbg(DBG_USR1, "ReceiveCodeM: Rcv_Code.receive: Resuming ABORT timer for agent %i.\n", cMsg->id.id);
      #endif        
      call CoordinatorI.startAbortTimer(&cMsg->id);          
    }
    
    return m;
  } // Rcv_Code.receive

  event result_t Send_Code_Ack.sendDone(TOS_MsgPtr m, result_t success) 
  {
    call MessageBufferI.freeMsg(m);
    return SUCCESS; 
  }
}
