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
 * $Date: 2005/11/09 20:15:22 $ @author: Jan Hauer
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */


/**
  * 
  * This interface will signal incoming subscriptions to
  * potential publishers. A publisher may (but does not
  * have to) use this interface to stay informed about the
  * currently valid set of subscriptions, before it
  * decides to publish a notification.
  *  
  */
includes PS; 
interface PSSubscriptionListener 
{     
  /** 
   * A subscription was received and should be responded
   * with notification(s) if possible. The subscription
   * is represented by a handle and can (only) be
   * accessed via the PSSubscriptionAccess interface
   * (read-only). The handle is valid until a
   * receivedModify() or receivedUnsubscribe() event is
   * signalled.
   * 
   * @param handle A handle for accessing the
   * subscription.
   */
  event void receivedNew(const ps_subscription_handle_t
      handle);

  /** 
   * Received a modification request for an already
   * registered subscription.  The old handle becomes
   * invalid after the eventhandler returns (it may be
   * used to access the old subscription "one last time",
   * during this event).  The new handle represents the
   * modified subscription and is valid from the time this
   * event is signalled until a receivedModify() or
   * receivedUnsubscribe() event is signalled.
   */
  event void receivedModify(const ps_subscription_handle_t
      oldHandle, const ps_subscription_handle_t
      newHandle);
  
  /** 
   * Received an unsubscribe of an already registered
   * subscription.  The old handle becomes invalid after
   * the eventhandler returns (it may be used to access
   * the old subscription "one last time", during this
   * event).  
   */
  event void receivedUnsubscribe(const
      ps_subscription_handle_t handle); 
}

