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
 * $Revision: 1.6 $
 * $Date: 2006/03/22 12:07:16 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
configuration PSBrokerC {
  provides interface StdControl;
  provides interface PSSubscriptionSend[ps_subscription_ID_t subscriptionID];
  provides interface PSNotificationSend[uint8_t agentID];
  provides interface PSSubscriptionListener;
  provides interface PSNotificationReceive[ps_subscription_ID_t subscriptionID];
  provides interface PSMessageOffsets;
}
implementation {
  components PSBrokerM, PSAttributeContainerC, TinyAllocMultipleC, LedsC;  
  
  StdControl = PSBrokerM;
  PSSubscriptionSend = PSBrokerM;
  PSNotificationSend = PSBrokerM;
  PSSubscriptionListener = PSBrokerM;
  PSNotificationReceive = PSBrokerM;
  PSMessageOffsets = PSBrokerM;

  PSBrokerM.PSOperation -> PSAttributeContainerC;
  PSBrokerM.Leds -> LedsC;

  // Default protocols for subscription dissemination (Drip) and 
  // notification collection (Drain) either used with or without filters:
  components PSDripWrapperC, PSDrainWrapperC;
#if !defined(PS_USE_FILTERS) 
  StdControl = PSDripWrapperC;
  PSBrokerM.SendSubscription -> PSDripWrapperC.Send;
  PSBrokerM.ReceiveSubscription -> PSDripWrapperC.Receive;
  PSDripWrapperC.PSMessageOffsets -> PSBrokerM;

  StdControl = PSDrainWrapperC;
  PSBrokerM.SendNotification -> PSDrainWrapperC.Send;
  PSBrokerM.ReceiveNotification -> PSDrainWrapperC.Receive;
  PSBrokerM.RouteControlNotification -> PSDrainWrapperC.RouteControl;
#else
  components PSFilterRegistryC;
  StdControl = PSDripWrapperC;
  PSBrokerM.SendSubscription -> PSFilterRegistryC.SendSubscriptionBroker;
  PSFilterRegistryC.SendSubscriptionBroadcast -> PSDripWrapperC.Send;
  PSFilterRegistryC.ReceiveSubscriptionBroadcast -> PSDripWrapperC.Receive;
  PSBrokerM.ReceiveSubscription -> PSFilterRegistryC.ReceiveSubscriptionBroker;
  PSDripWrapperC.PSMessageOffsets -> PSBrokerM;

  StdControl = PSDrainWrapperC;
  PSBrokerM.SendNotification -> PSFilterRegistryC.SendNotificationBroker;
  PSFilterRegistryC.SendNotificationConvergecast -> PSDrainWrapperC.Send;
  PSFilterRegistryC.ReceiveNotificationConvergecast -> PSDrainWrapperC.Receive;
  PSBrokerM.ReceiveNotification -> PSFilterRegistryC.ReceiveNotificationBroker; 
  PSBrokerM.RouteControlNotification -> PSDrainWrapperC.RouteControl;
#endif 
  
#if defined(PS_EVENT_REPORT)
  components EventReportC;
  PSBrokerM.LocalTime -> EventReportC;
  PSBrokerM.EventReport -> EventReportC;
#endif

#if defined(PLATFORM_PC)
  components TimerC;
  StdControl = TimerC;
  PSBrokerM.Timer -> TimerC.Timer[unique("Timer")];
#endif


  // heap manager 
  enum {
    ALLOC_ID = unique("TINY_ALLOC_MULTIPLE"),
  };
  PSBrokerM.MemAlloc -> TinyAllocMultipleC.MemAlloc[ALLOC_ID];

  // Alternative protocols for subscription dissemination (Bcast) and
  // notification collection (RSSIMultiHopRouter)
/*  
  components GenericComm as Comm, RSSIMultiHopRouter, Bcast;
  
  StdControl = Comm;
  // notifications go via multihop engine
  StdControl = RSSIMultiHopRouter; 
  PSBrokerM.SendNotification -> RSSIMultiHopRouter.Send[AM_PS_NOTIFICATION_MSG];
  PSBrokerM.ReceiveNotification -> RSSIMultiHopRouter.Intercept[AM_PS_NOTIFICATION_MSG];
  RSSIMultiHopRouter.ReceiveMsg[AM_PS_NOTIFICATION_MSG] -> Comm.ReceiveMsg[AM_PS_NOTIFICATION_MSG]; 
  PSBrokerM.RouteControlNotification -> RSSIMultiHopRouter;
  // RSSIMultiHopRouter.SendMsg already hardwired to GenericComm
  
  // subscriptions go via broadcast component
  StdControl = Bcast; 
  PSBrokerM.SendSubscription -> Bcast.Send[AM_PS_SUBSCRIPTION_MSG]; 
  PSBrokerM.ReceiveSubscription -> Bcast.Receive[AM_PS_SUBSCRIPTION_MSG];
  Bcast.ReceiveMsg[AM_PS_SUBSCRIPTION_MSG] -> Comm.ReceiveMsg[AM_PS_SUBSCRIPTION_MSG]; 
  Bcast.SendMsg -> Comm.SendMsg;
*/
}

