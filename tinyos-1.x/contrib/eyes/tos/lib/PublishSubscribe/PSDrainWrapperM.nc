/*
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.2 $
 * $Date: 2005/11/09 20:10:44 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author: Stefano Niccolai (TOSSIM adaptation) 
 * ========================================================================
 */

module PSDrainWrapperM {
  provides {
    interface Send;
  }
  uses {
    interface SendMsg as SendDrain;
    interface Send as SendGetBuffer;
    interface Intercept[uint8_t id];
    interface BareSendMsg as SendUART;
  }
}
implementation {
  
  bool uarting=FALSE;	
	
  command result_t Send.send(TOS_MsgPtr msg, uint16_t length)
  {
    	uint16_t maxLength;
    	ps_notification_msg_t *notificationMsg;
    	notificationMsg = call SendGetBuffer.getBuffer(msg, &maxLength);
#ifdef PLATFORM_PC
      if (TOS_LOCAL_ADDRESS == 0){
	      DrainMsg *drainMsg = (DrainMsg *)msg->data;
    	  msg->length = offsetof(DrainMsg,data) + length;
	      drainMsg->dest = TOSSIM_RES_ADDRESS;
	      drainMsg->source = TOS_LOCAL_ADDRESS;
	      return !signal Intercept.intercept[AM_PS_NOTIFICATION_MSG](msg,&msg->data[0],length);
      }
      else
#endif
      {
    	  return call SendDrain.send(TOS_DEFAULT_ADDR, length, msg); //notificationMsg->subscriberID, length, msg);
      }
  }

  event result_t SendDrain.sendDone(TOS_MsgPtr msg, result_t success)
  {
    return signal Send.sendDone(msg, success);
  }
    
  command void* Send.getBuffer(TOS_MsgPtr msg, uint16_t* length)
  {
    return call SendGetBuffer.getBuffer(msg, length);
  }
  
  event result_t SendGetBuffer.sendDone(TOS_MsgPtr msg, result_t success)
  {
    // will not happen.
    return SUCCESS;
  }

  event result_t Intercept.intercept[uint8_t id](
      TOS_MsgPtr msg, void* payload, uint16_t payloadLen)
  {
#ifdef PLATFORM_PC
    bool busy;
    atomic{
	    busy=uarting;
	    uarting=TRUE;
    }
    if(!busy){
      DrainMsg *drainMsg = (DrainMsg *)msg->data;
	    if (TOS_LOCAL_ADDRESS == 0 && drainMsg->dest == TOSSIM_RES_ADDRESS){
        result_t ris;
        ps_notification_msg_t *notificationMsg;
        uint16_t maxLength;
        notificationMsg = call SendGetBuffer.getBuffer(msg, &maxLength);
	      msg->addr = TOS_UART_ADDR;
	      msg->type = AM_DRAINMSG;
        ris=call SendUART.send(msg);
        if(ris==FAIL){
			    uarting=FALSE;
			    return SUCCESS;
        }
        return FAIL;
      }
    } 
#endif
    return SUCCESS;
  }
  
  event result_t SendUART.sendDone(TOS_MsgPtr msg, result_t success)
  {
    uint16_t maxLength;
    ps_notification_msg_t *notificationMsg;
    bool ris=SUCCESS;    
    notificationMsg = call SendGetBuffer.getBuffer(msg, &maxLength);
    if(notificationMsg->sourceAddress == 0)
    		ris=signal Send.sendDone(msg, success);
    atomic uarting=FALSE;    
    return ris;
  }
}





