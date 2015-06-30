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
generic configuration PSPublisherAgentC()
{

  provides interface PSPublish;               // send out notification messsages
  provides interface PSSubscriptionListener;  // listen to incoming subscriptions
  provides interface PSNotificationAccess;  // build notification messages
  provides interface PSSubscriptionAccess;  // examine received subscriptions

} implementation {
  components PSBrokerC, PSMessageAccessC, new PSPublisherAgentM() as PublisherAgent;
   
  enum {
    NOTIFICATION_ID = unique("PS_NOTIFICATION_ID"),
    MESSAGE_ACCESS_ID = unique("PS_MESSAGE_ACCESS_ID"),
  };

  PSSubscriptionAccess = PSMessageAccessC.PSSubscriptionAccess[MESSAGE_ACCESS_ID];
  PSNotificationAccess = PSMessageAccessC.PSNotificationAccess[MESSAGE_ACCESS_ID];
  PSPublish = PublisherAgent;
  PSSubscriptionListener = PSBrokerC;

  PublisherAgent.PSNotificationSend -> PSBrokerC.PSNotificationSend[NOTIFICATION_ID];
  PublisherAgent.PSMessageAccess -> PSMessageAccessC;
}
