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
 * $Date: 2005/11/09 20:15:22 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * This interface is used by an application to disseminate
 * a subscription in the network. A subscription is
 * represented by a ps_subscription_handle_t and created
 * and modified via the PSSubscriptionAccess interface.
 */
includes PS; 
interface PSSubscribe 
{ 
  /** 
    * Disseminates a subscription in the network.  The
    * subscription must not be accessed until sendDone()
    * is signalled (the PSSubscriptionAccess interface
    * will block access).
    *
    * @param handle The handle representing the
    * subscription message.
    *
    * @return Whether the subscribe request was
    * successful: SUCCESS means a subscribeDone() event
    * will be signaled later, otherwise not.
    * 
    */
  command ps_result_t subscribe(ps_subscription_handle_t
      handle);

  /**
    * The subscription was sent out.  It may now be
    * accessed again, the content of the subscription (all
    * constraints and instructions) is unchanged. Changing
    * it and calling subscribe() will modify (overwrite)
    * the subscription. It may also be deallocated, but
    * then, to modify the subscription a newly allocated
    * has to be assigned the same subscriptionID.
    *
    * @param handle The handle representing the
    * subscription message.
    * 
    * @param subscriptionID The (locally) unique ID for
    * the subscription.
    */ 
  event void subscribeDone(ps_subscription_handle_t
      handle, ps_subscription_ID_t subscriptionID,
      ps_result_t result); 

  /** 
    * A matching notification for the current subscription
    * has been received. The notification is represented
    * by a handle and may only be accessed via the
    * PSNotificationAccess interface.  It is read-only and
    * only allocated during this event, no global
    * reference to the handle may be stored.
    * PSNotificationAccess.clone() can be used to create a
    * private copy of it.
    * 
    * @param handle A handle for accessing the
    * notification.  
    * 
    * @param subscriptionID The ID of the matching
    * subscription.
    */
  event void notificationReceived(const
      ps_notification_handle_t handle,
      ps_subscription_ID_t subscriptionID); 
}

