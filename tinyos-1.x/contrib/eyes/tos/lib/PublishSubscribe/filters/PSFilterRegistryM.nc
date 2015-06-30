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
 * $Revision: 1.1 $
 * $Date: 2005/11/17 13:20:30 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

module PSFilterRegistryM {
  // exported to the filter component
  provides interface PSSubscriptionIntercept as SubscriptionSendIntercept[uint8_t priority];
  provides interface PSSubscriptionIntercept as SubscriptionReceiveIntercept[uint8_t priority];
  provides interface PSNotificationIntercept as NotificationSendIntercept[uint8_t priority];
  provides interface PSNotificationIntercept as NotificationReceiveIntercept[uint8_t priority];

  // for the broker/routing (wired in PSFilterRegistryC)
  provides interface Send as SendSubscriptionBroker;
  uses interface Send as SendSubscriptionBroadcast;
  uses interface Receive as ReceiveSubscriptionBroadcast;
  provides interface Receive as ReceiveSubscriptionBroker;
  
  provides interface Send as SendNotificationBroker;
  uses interface Send as SendNotificationConvergecast;
  uses interface Receive as ReceiveNotificationConvergecast;
  provides interface Receive as ReceiveNotificationBroker;
  
} implementation {
  
                           /* subscriptions */
  
  command result_t SendSubscriptionBroker.send(TOS_MsgPtr msg, uint16_t length)
  {
    uint8_t i;
    uint16_t dummy;
    for (i=0; i<NUM_SUBSCRIPTION_SEND_INTERCEPT; i++)
      if (signal SubscriptionSendIntercept.intercept[i]((ps_subscription_msg_t *)
           call SendSubscriptionBroker.getBuffer(msg, &dummy)) != PS_SUCCESS)
      {
        signal SendSubscriptionBroker.sendDone(msg, SUCCESS);
        return SUCCESS;
      }
    return call SendSubscriptionBroadcast.send(msg, length);
  }

  command void* SendSubscriptionBroker.getBuffer(TOS_MsgPtr msg, uint16_t* length)
  {
    return call SendSubscriptionBroadcast.getBuffer(msg, length);
  }

  event result_t SendSubscriptionBroadcast.sendDone(TOS_MsgPtr msg, result_t success)
  {
    return signal SendSubscriptionBroker.sendDone(msg, success);
  }

  event TOS_MsgPtr ReceiveSubscriptionBroadcast.receive(
      TOS_MsgPtr msg, void* payload, uint16_t payloadLen)
  {
    uint8_t i;
    uint16_t dummy;
    for (i=0; i<NUM_SUBSCRIPTION_RECEIVE_INTERCEPT; i++)
      if (signal SubscriptionReceiveIntercept.intercept[i]((ps_subscription_msg_t *)
           call SendSubscriptionBroker.getBuffer(msg, &dummy)) != PS_SUCCESS)
        return msg;
    return signal ReceiveSubscriptionBroker.receive(msg,  payload, payloadLen);
  }

  default event ps_result_t SubscriptionReceiveIntercept.intercept[uint8_t priority](
      ps_subscription_msg_t *subscription_msg)
  {
    return PS_SUCCESS;
  }
  
  default event ps_result_t SubscriptionSendIntercept.intercept[uint8_t priority](
      ps_subscription_msg_t *subscription_msg)
  {
    return PS_SUCCESS;
  }

                           /* notifications */
  
  command result_t SendNotificationBroker.send(TOS_MsgPtr msg, uint16_t length)
  {
    uint8_t i;
    uint16_t dummy;
    for (i=0; i<NUM_NOTIFICATION_SEND_INTERCEPT; i++)
      if (signal NotificationSendIntercept.intercept[i]((ps_notification_msg_t *)
           call SendNotificationBroker.getBuffer(msg, &dummy)) != PS_SUCCESS)
      {
        signal SendNotificationBroker.sendDone(msg, SUCCESS);
        return SUCCESS;
      }
    return call SendNotificationConvergecast.send(msg, length);
  }

  command void* SendNotificationBroker.getBuffer(TOS_MsgPtr msg, uint16_t* length)
  {
    return call SendNotificationConvergecast.getBuffer(msg, length);
  }

  event result_t SendNotificationConvergecast.sendDone(TOS_MsgPtr msg, result_t success)
  {
    return signal SendNotificationBroker.sendDone(msg, success);
  }

  event TOS_MsgPtr ReceiveNotificationConvergecast.receive(
      TOS_MsgPtr msg, void* payload, uint16_t payloadLen)
  {
    uint8_t i;
    uint16_t dummy;
    for (i=0; i<NUM_NOTIFICATION_RECEIVE_INTERCEPT; i++)
      if (signal NotificationReceiveIntercept.intercept[i]((ps_notification_msg_t *)
           call SendNotificationBroker.getBuffer(msg, &dummy)) != PS_SUCCESS)
        return msg;
    return signal ReceiveNotificationBroker.receive(msg,  payload, payloadLen);
  }
  
  default event ps_result_t NotificationReceiveIntercept.intercept[uint8_t priority](
      ps_notification_msg_t *notifications_msg)
  {
    return PS_SUCCESS;
  }
  
  default event ps_result_t NotificationSendIntercept.intercept[uint8_t priority](
      ps_notification_msg_t *notifications_msg)
  {
    return PS_SUCCESS;
  }
}

