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

configuration PSFilterRegistryC {
  // Interface exported to the filter component
  // @param priority denotes the order in which clients are signalled the event,
  // with 0 = first (highest priority), 255 = last (lowest priority).
  // For the unique string see PSFilter.h
  provides interface PSSubscriptionIntercept as SubscriptionSendIntercept[uint8_t priority];
  provides interface PSSubscriptionIntercept as SubscriptionReceiveIntercept[uint8_t priority];
  provides interface PSNotificationIntercept as NotificationSendIntercept[uint8_t priority];
  provides interface PSNotificationIntercept as NotificationReceiveIntercept[uint8_t priority];

  // for the broker (wired internally)
  provides interface Send as SendSubscriptionBroker;
  uses interface Send as SendSubscriptionBroadcast;
  uses interface Receive as ReceiveSubscriptionBroadcast;
  provides interface Receive as ReceiveSubscriptionBroker;
  
  provides interface Send as SendNotificationBroker;
  uses interface Send as SendNotificationConvergecast;
  uses interface Receive as ReceiveNotificationConvergecast;
  provides interface Receive as ReceiveNotificationBroker;  
}
implementation {
  components PSFilterRegistryM;

  SubscriptionSendIntercept = PSFilterRegistryM.SubscriptionSendIntercept;
  SubscriptionReceiveIntercept = PSFilterRegistryM.SubscriptionReceiveIntercept;
  NotificationSendIntercept = PSFilterRegistryM.NotificationSendIntercept;
  NotificationReceiveIntercept = PSFilterRegistryM.NotificationReceiveIntercept;

  SendSubscriptionBroker = PSFilterRegistryM.SendSubscriptionBroker;
  SendSubscriptionBroadcast = PSFilterRegistryM.SendSubscriptionBroadcast;
  ReceiveSubscriptionBroadcast = PSFilterRegistryM.ReceiveSubscriptionBroadcast;
  ReceiveSubscriptionBroker = PSFilterRegistryM.ReceiveSubscriptionBroker;
  
  SendNotificationBroker = PSFilterRegistryM.SendNotificationBroker;
  SendNotificationConvergecast = PSFilterRegistryM.SendNotificationConvergecast;
  ReceiveNotificationConvergecast = PSFilterRegistryM.ReceiveNotificationConvergecast;
  ReceiveNotificationBroker = PSFilterRegistryM.ReceiveNotificationBroker;   
}

