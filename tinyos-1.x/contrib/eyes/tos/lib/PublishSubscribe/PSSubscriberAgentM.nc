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
 
generic module PSSubscriberAgentM(uint16_t maxSubscriptions)
{
  provides {
   interface StdControl;
   interface PSSubscribe;             
  } uses {
   interface PSSubscriptionIDReserve as IDReserve;
   interface PSSubscriptionSend;
   interface PSNotificationReceive;
   interface PSMessageAccess;
  }

} implementation {
 
  ps_subscription_ID_t *firstID;
  uint16_t usedIDs;
  bool m_lock = FALSE;

  ps_result_t setLock(ps_subscription_handle_t handle)
  {
    bool locked;
    atomic {
      locked = m_lock;
      m_lock = TRUE;
    }
    if (locked)
      return PS_FAIL_BUSY;
    if (call PSMessageAccess.isLockedSubscription(handle)){
      m_lock = FALSE;
      return PS_FAIL_MSG_LOCK;
    }
    call PSMessageAccess.setLockSubscription(handle);
    return PS_SUCCESS;
  }

  inline void releaseLock(ps_subscription_handle_t handle)
  {
    m_lock = FALSE;
    call PSMessageAccess.clearLockSubscription(handle);
  }

  command result_t StdControl.init() {
    call IDReserve.reserveSubscriptionID(maxSubscriptions, firstID);
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command ps_result_t PSSubscribe.subscribe(ps_subscription_handle_t handle)
  {
    ps_subscription_msg_t *subscriptionMsg;
    ps_result_t result = setLock(handle);
    
    if (result == PS_SUCCESS){
      subscriptionMsg = call PSMessageAccess.getSubscriptionMsg(handle);
      if (!subscriptionMsg->subscriptionID){
        // a zero subscriptionID equals a new subscription, because
        // this ID is (locally) reserved. initialize fields now.
        if (usedIDs >= maxSubscriptions){
          releaseLock(handle);
          return PS_FAIL_SAGENT;
        }
        subscriptionMsg->subscriberID = TOS_LOCAL_ADDRESS;
        subscriptionMsg->subscriptionID = *firstID + usedIDs++;
        subscriptionMsg->modificationCounter = 0;
        if ((result = call PSSubscriptionSend.send(handle)) != PS_SUCCESS){
          releaseLock(handle);
          usedIDs--;
          subscriptionMsg->subscriptionID = 0;
        } 
      } else {
        // modification of an old subscription
        subscriptionMsg->modificationCounter++;
        if ((result = call PSSubscriptionSend.send(handle)) != PS_SUCCESS){
          subscriptionMsg->modificationCounter--;
          releaseLock(handle);
        }
      }
    }
    return result;
  }
    
  default event void PSSubscribe.subscribeDone(ps_subscription_handle_t handle, 
                           ps_subscription_ID_t subscriptionID,
                           ps_result_t result){}

  default event void PSSubscribe.notificationReceived(const ps_notification_handle_t token,
                                  ps_subscription_ID_t subscriptionID){}

  event void PSSubscriptionSend.sendDone(ps_subscription_handle_t handle, ps_result_t result)
  {
    ps_subscription_msg_t *subscriptionMsg;
    subscriptionMsg = call PSMessageAccess.getSubscriptionMsg(handle);
    
    releaseLock(handle);
    if (result != PS_SUCCESS){
      if (subscriptionMsg->modificationCounter == 0){
        usedIDs--;
        subscriptionMsg->subscriptionID = 0;
      } else
        subscriptionMsg->modificationCounter--;
    }
    signal PSSubscribe.subscribeDone(handle, subscriptionMsg->subscriptionID, result);
  }

  event void PSNotificationReceive.receive(ps_notification_handle_t handle)
  {
    ps_notification_msg_t *notificationMsg;
    notificationMsg = call PSMessageAccess.getNotificationMsg(handle);
    signal PSSubscribe.notificationReceived(handle, notificationMsg->subscriptionID);
  }
}
