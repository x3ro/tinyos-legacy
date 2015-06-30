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
 * $Date: 2005/10/19 14:00:59 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

includes PS;
module PSSubscriberAgentArbiterM {
  provides {
     interface PSSubscriptionIDReserve[uint8_t agentID];
     interface PSNotificationReceive[uint8_t agentID];
  }  uses {
    interface PSNotificationReceive as BrokerReceive[ps_subscription_ID_t subscriptionID];
    interface PSMessageAccess;
  }
}
implementation {
  struct agent_reservation_t {
    ps_subscription_ID_t first;
    ps_subscription_ID_t last;
  };
  
  struct agent_reservation_t agentReservation[uniqueCount("PS_SUBSCRIBER_AGENT_ID")];
  uint16_t reserved = 1;  // subscription ID zero is reserved !
  
  command ps_result_t PSSubscriptionIDReserve.reserveSubscriptionID[uint8_t agentID](
      uint16_t count, 
      ps_subscription_ID_t *firstReserved)
  {
    *firstReserved = reserved; 
    reserved += count;
    agentReservation[agentID].first = *firstReserved;
    agentReservation[agentID].last = *firstReserved + count - 1;
    return SUCCESS;
  }

  event void BrokerReceive.receive[ps_subscription_ID_t subscriptionID](
      ps_notification_handle_t handle)
  {
    uint16_t i;
    ps_notification_msg_t *notificationMsg;
    notificationMsg = call PSMessageAccess.getNotificationMsg(handle);
    for (i=0; i<uniqueCount("PS_SUBSCRIBER_AGENT_ID"); i++)
      if (agentReservation[i].first <= notificationMsg->subscriptionID &&
          notificationMsg->subscriptionID <= agentReservation[i].last){
        signal PSNotificationReceive.receive[i](handle);
        return;
      }
  }
  
  default event void PSNotificationReceive.receive[uint8_t agentID](
      ps_notification_handle_t handle){}

}
