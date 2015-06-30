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
 * $Revision: 1.3 $
 * $Date: 2005/11/17 13:24:44 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

generic module PSDripWrapperM(uint8_t channels){
  provides {
    interface StdControl;
    interface Send;
    interface Receive;
  }
  uses {
    interface Receive as ReceiveDrip[uint8_t id];
    interface Drip[uint8_t id];
    interface PSMessageOffsets;
  }
}
implementation {

  
  // Drip is the default subscription dissemination protocol and it is almost
  // ideal for this task, but there is one drawback: When we receive an
  // "unsubscribe" PSBrokerM will delete the entry from the subscription
  // table.  Consequently in the Drip.rebroadcastRequest event handler we
  // cannot call Drip.rebroadcast, because we don't have any data. We cannot
  // return a default unsubscribe, because we don't know whether we have
  // received a subscription for the channel in the first place. Thus we
  // introduce a workaround: We snoop on incoming subscriptions and cache the
  // last (subscriberID, modificationCounter) that we received per
  // Drip-channel (=subscriptionID) in a struct "m_unsubscribeCache". If on
  // the Drip.rebroadcastRequest event the subscription table is empty but we
  // have a cache entry we disseminate an unsubscribe based on the cached
  // information. 

  struct {
    bool valid;
    ps_subscriber_ID_t subscriberID;
    nx_uint8_t modificationCounter;
  } m_unsubscribeCache[channels];
   
  command result_t StdControl.init() { 
    uint8_t i;
    uint16_t maxLength;
    // Drip ID 0 is reserved ! We go for [1..channels].
    for (i=1; i<channels+1; i++){
      call Drip.init[i](); 
      m_unsubscribeCache[i-1].valid = FALSE;
    }
    return SUCCESS; 
  }
  
  command result_t StdControl.start() { return SUCCESS; }
  
  command result_t StdControl.stop() { return SUCCESS; }

  // send out a subscription
  command result_t Send.send(TOS_MsgPtr msg, uint16_t length)
  {
    uint16_t maxLength;
    ps_subscription_msg_t *subscriptionMsg;
    subscriptionMsg = call Send.getBuffer(msg, &maxLength);
    call Drip.change[subscriptionMsg->subscriptionID]();
    signal Send.sendDone(msg, SUCCESS); // Drip always succeeds
    m_unsubscribeCache[subscriptionMsg->subscriptionID-1].valid = TRUE;
    m_unsubscribeCache[subscriptionMsg->subscriptionID-1].subscriberID = TOS_LOCAL_ADDRESS;
    m_unsubscribeCache[subscriptionMsg->subscriptionID-1].modificationCounter = 
      subscriptionMsg->modificationCounter;
    return SUCCESS;
  }

  // get the send buffer
  command void* Send.getBuffer(TOS_MsgPtr msg, uint16_t* length)
  {
    // This command is problematic, because the Drip interface does not
    // have an equivalent command. Assumption: Drip encapsulates payload
    // in a DripMsg at DripMsg->data and DripMsg is at TOS_Msg->data.
    DripMsg *dripmsg = (DripMsg*) msg->data;
    *length = TOSH_DATA_LENGTH - sizeof(DripMsg);
    return dripmsg->data;
  }

  event TOS_MsgPtr ReceiveDrip.receive[uint8_t id](
      TOS_MsgPtr msg, void* payload, uint16_t payloadLen)
  {
    uint16_t maxLength;
    ps_subscription_msg_t *subscriptionMsg;
    subscriptionMsg = call Send.getBuffer(msg, &maxLength);
    // snoop to keep unsubscribeCache up-to-date
    m_unsubscribeCache[id-1].valid = TRUE;
    m_unsubscribeCache[id-1].subscriberID = subscriptionMsg->subscriberID;
    m_unsubscribeCache[id-1].modificationCounter = 
      subscriptionMsg->modificationCounter;
    return signal Receive.receive(msg, payload, payloadLen);
  }

  event result_t Drip.rebroadcastRequest[uint8_t id](
      TOS_MsgPtr msg, void *pData)
  {
    ps_subscription_handle_t handle;
    bool rebroadcast = FALSE;
    uint16_t length;
    ps_subscription_msg_t *subscriptionMsg;
    handle = call PSMessageOffsets.getSubscriptionHandle(id);
    

    if (handle)
    {
      // get subscription with id "id" from subscription table and copy it into buffer 
      subscriptionMsg = &(*handle)->subscriptionMsg;
      length = sizeof(ps_subscription_msg_t) + subscriptionMsg->dataLength;
      memcpy(pData, subscriptionMsg, length);
      rebroadcast = TRUE;
    }  
    else if (m_unsubscribeCache[id-1].valid)
    {
      // create an unsubscribe 
      subscriptionMsg = call Send.getBuffer(msg, &length);
      subscriptionMsg->subscriberID = m_unsubscribeCache[id-1].subscriberID;
      subscriptionMsg->subscriptionID = id;
      subscriptionMsg->modificationCounter = m_unsubscribeCache[id-1].modificationCounter;
      subscriptionMsg->flags = MSG_FLAG_UNSUBSCRIBE;
      subscriptionMsg->dataLength = 0;
      length = sizeof(ps_subscription_msg_t) + subscriptionMsg->dataLength;
      rebroadcast = TRUE;
    }
    
    if (rebroadcast)
    {
      call Drip.rebroadcast[id](msg, pData, length);
#if defined(PLATFORM_EYESIFXV2)
    // toggle 4th Led
    if (P5OUT & 0x8)
      P5OUT &= ~0x8;
    else
      P5OUT |= 0x8;
#endif
      dbg(DBG_TEMP,"Node %d rebroadcast subscription, subscriberID = %d, subscriptionID = %d, modificationCounter = %d, flags = %d, dataLength = %d\n", 
          TOS_LOCAL_ADDRESS,
          subscriptionMsg->subscriberID,
          subscriptionMsg->subscriptionID,
          subscriptionMsg->modificationCounter,
          subscriptionMsg->flags,
          subscriptionMsg->dataLength
         );
      return SUCCESS;
    }
    //dbg(DBG_TEMP,"Node %d DripWrapper Drip.rebroadcastRequest[%d] failed.\n", TOS_LOCAL_ADDRESS, id);
    return FAIL;
  }
}

