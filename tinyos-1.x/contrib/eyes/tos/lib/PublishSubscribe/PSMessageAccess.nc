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
interface PSMessageAccess { 

  /**  
   *
   * The message lock realizes to following mechanism: A
   * ps_subscription_msg_t and a ps_notification_msg_t may not be
   * accessed by an application between the call to subscribe() (or
   * publish()) and the respective done() event. To guarantee this, an
   * agent will set a "lock" flag before sending and remove the flag
   * when the message has been sent. The PSMessageAccessM will only
   * grant access to a handle whose flag is cleared and block it
   * otherwise. 
   */
  command void setLockSubscription(ps_subscription_handle_t handle);
  command void clearLockSubscription(ps_subscription_handle_t handle);
  command bool isLockedSubscription(ps_subscription_handle_t handle);
  command void setLockNotification(ps_notification_handle_t handle);
  command void clearLockNotification(ps_notification_handle_t handle);
  command bool isLockedNotification(ps_notification_handle_t handle);

  command ps_subscription_msg_t* getSubscriptionMsg(const ps_subscription_handle_t handle);
  command uint16_t getSizeSubscriptionMsg(ps_subscription_msg_t *submsg);
  command ps_notification_msg_t* getNotificationMsg(const ps_notification_handle_t handle);
  command uint16_t getSizeNotificationMsg(ps_notification_msg_t *submsg);
  
}

