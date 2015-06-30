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
  * 
  * This interface can be used by an application to send
  * out a notification message in the network. A
  * notification message is represented by a
  * ps_notification_handle_t and created and modified via
  * the PSNotificationAccess interface.
  *
  * An application may (but does not have to) use the
  * PSSubscriptionListener interface to stay informed
  * about the currently valid set of subscriptions, before
  * it decides to publish a notification.
  *
  */
includes PS; 
interface PSPublish 
{ 
  /** 
    * 
    * Sends out a notification message in the network. The
    * handle may not be accessed until sendDone() is
    * signalled (the PSNotificationAccess commands will
    * return PS_FAIL_MSG_LOCK).  
    *
    * @param handle The handle representing the
    * notification message.
    *
    * @return Whether the publish request was successful:
    * SUCCESS means a sendDone() event will be signaled
    * later, FAIL means one will not.
    */
  command ps_result_t publish(ps_notification_handle_t
      handle);

   /**
    *
    * The notification was sent out.  It may now be
    * accessed again, the content of the notification
    * message is unchanged.  
    *
    * @param handle The handle representing the
    * notification message.
    */ 
  event void publishDone(ps_notification_handle_t handle,
      ps_result_t result); 
}

