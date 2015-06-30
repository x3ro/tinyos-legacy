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
module PSStdPublisherM {
  provides interface StdControl;
  uses {
    interface StdControl as RadioControl;
    interface Leds;
    interface PSPublish;
    interface PSSubscriptionListener as Listener;
    interface PSNotificationAccess;  
    interface PSSubscriptionAccess;
    interface PSValue[uint16_t attrID];
    interface Random;
    interface Timer as NotificationTimer[uint8_t num];
  }
}
implementation {
  
  enum {
    MAX_INIT_BACKOFF = 2048,
    DEFAULT_RATE = 1000,
    MIN_RATE = 100,
    MAX_ACTIVE_SUBSCRIPTIONS = 10,
    MAX_NUM_ATTRIBUTES = 15,
    MAX_VALUE_LENGTH = 10,
    MAX_GETDATA_RETRY = 5,
    PS_INSTRUCTION_RATE = 100,
  };
  ps_subscription_handle_t m_subscription[MAX_ACTIVE_SUBSCRIPTIONS];    
  ps_subscription_handle_t m_currentSubscription;
  ps_notification_handle_t m_notification = 0;
  bool m_notificationLock;
  uint16_t m_notificationAttribCount;
  uint16_t m_notificationAttribGetValueCount;
  ps_avpair_t *m_getValueRetryAvpair;
  uint16_t m_notificationAttribIndex;
  
  bool getNextValue();
  void task allocateNotification();
  void task retryGetData();

  command result_t StdControl.init() {
    call RadioControl.init();
    call Random.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call RadioControl.start();
    post allocateNotification();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  void task allocateNotification()
  {
    if (call PSNotificationAccess.create(&m_notification) != PS_SUCCESS)
      post allocateNotification();
  }
  
  bool getNotificationLock()
  {
    if (!m_notification)
      return FALSE;
    if (m_notificationLock)
      return FALSE;
    else {
      m_notificationLock = TRUE;
      return TRUE;
    }
  }

  bool releaseNotificationLock()
  {
    bool oldLock = m_notificationLock;
    m_notificationLock = FALSE;
    return oldLock;
  }
  
  uint32_t getRate(const ps_subscription_handle_t handle)
  {
    uint16_t instructionCount = 0, valueLength, i;
    const ps_instruction_t *instruction;
    uint32_t rate = DEFAULT_RATE;
    
    if (call PSSubscriptionAccess.getInstructionCount(
          handle, &instructionCount) == PS_SUCCESS)
      for (i=0; i<instructionCount; i++)
      {
        call PSSubscriptionAccess.viewInstruction(
            handle, &instruction, &valueLength, i);
        switch (instruction->attributeID)
        {
          // see attributes.xml
          case PS_INSTRUCTION_RATE:
            rate = *((nx_uint32_t *) instruction->value);
            break;
          default:
            break;
        }
      }
    if (rate < MIN_RATE)
      rate = MIN_RATE;
    return rate;
  }
  
  event void Listener.receivedNew(const ps_subscription_handle_t handle)
  {
    uint16_t constraintCount = 0, i, temp;
    const ps_constraint_t *constraint;
    uint8_t indexFreeHandle, valueSize;
    uint32_t rate;

    for (indexFreeHandle=0; indexFreeHandle<MAX_ACTIVE_SUBSCRIPTIONS; indexFreeHandle++)
      if (!m_subscription[indexFreeHandle])
        break;
    if (indexFreeHandle == MAX_ACTIVE_SUBSCRIPTIONS)
      return; // already max number of subscriptions are serviced
    if (call PSSubscriptionAccess.getConstraintCount(handle, &constraintCount) != PS_SUCCESS)
      return; 
    rate = getRate(handle);
    for (i=0; i<constraintCount; i++)
      if ((call PSSubscriptionAccess.viewConstraint(handle, &constraint, &temp, i) 
            != PS_SUCCESS) || 
          call PSValue.getValueSize[constraint->attributeID](&valueSize) != PS_SUCCESS)
        return; // don't know a requested attribute
    
    if (call NotificationTimer.start[indexFreeHandle](TIMER_ONE_SHOT, 
          (call Random.rand() % rate + 100)) == SUCCESS)
      m_subscription[indexFreeHandle] = handle;
    return;
  }

  event void Listener.receivedModify(const ps_subscription_handle_t oldHandle,
                            const ps_subscription_handle_t newHandle)
  {
    signal Listener.receivedUnsubscribe(oldHandle);
    signal Listener.receivedNew(newHandle);
  }
    
  event void Listener.receivedUnsubscribe(const ps_subscription_handle_t handle)
  {
    uint8_t indexHandle;
    for (indexHandle=0; indexHandle<MAX_ACTIVE_SUBSCRIPTIONS; indexHandle++)
      if (m_subscription[indexHandle] == handle)
        break;
    if (indexHandle == MAX_ACTIVE_SUBSCRIPTIONS){
      return; // never got registered
    }
    m_subscription[indexHandle] = 0;
    call NotificationTimer.stop[indexHandle]();
  }

  event result_t NotificationTimer.fired[uint8_t num]()
  {
    uint32_t rate;
    call Leds.greenToggle();
    if (!m_subscription[num]){
      call NotificationTimer.stop[num]();
      return SUCCESS;
    }
    rate = getRate(m_subscription[num]);
    if (!getNotificationLock())
    {
      call NotificationTimer.start[num](TIMER_ONE_SHOT, (call Random.rand()+100) % rate);
      return SUCCESS;
    }
    m_currentSubscription = m_subscription[num];
    call PSNotificationAccess.reset(m_notification);
    call PSSubscriptionAccess.getConstraintCount(m_subscription[num], &m_notificationAttribCount);
    m_notificationAttribIndex = 0;
    if (!m_notificationAttribCount)
    {
      call PSPublish.publish(m_notification);
      releaseNotificationLock();
    } else if (!getNextValue())
      releaseNotificationLock();
    call NotificationTimer.start[num](TIMER_REPEAT, rate);
    return SUCCESS;
  }

  bool getNextValue()
  {
    const ps_constraint_t *constraint;
    ps_avpair_t *avpair;
    uint16_t temp;
    uint8_t valueSize;
    call PSSubscriptionAccess.viewConstraint(m_currentSubscription, 
        &constraint, &temp, m_notificationAttribIndex);
    call PSValue.getValueSize[constraint->attributeID](&valueSize);
    if (call PSNotificationAccess.newAVPair(m_notification, &avpair, valueSize) != PS_SUCCESS)
      return FALSE;
    avpair->attributeID = constraint->attributeID;
    if (call PSValue.getValue[avpair->attributeID](avpair->value) != PS_SUCCESS){
      m_notificationAttribGetValueCount = 0;
      m_getValueRetryAvpair = avpair;
      post retryGetData();
    }
    return TRUE;
  }

  void task retryGetData()
  {
    if (call PSValue.getValue[m_getValueRetryAvpair->attributeID]
        (m_getValueRetryAvpair->value) != PS_SUCCESS)
      if (++m_notificationAttribGetValueCount >= MAX_GETDATA_RETRY)
        releaseNotificationLock();
      else
        post retryGetData();
  }
  
  event void PSValue.valueReady[uint16_t attrID](ps_result_t result, void *buffer)
  {
    if (result == PS_SUCCESS)
    {
      m_notificationAttribIndex += 1;
      if (m_notificationAttribIndex == m_notificationAttribCount)
      {
        call PSPublish.publish(m_notification);
        releaseNotificationLock();
      } else if (!getNextValue())
        releaseNotificationLock();
    } else
      releaseNotificationLock();
  }

  event void PSPublish.publishDone(ps_notification_handle_t handle, ps_result_t result)
  {
  }

  default command ps_result_t PSValue.getValueSize[uint16_t attrID](uint8_t *valueSize)
  {
    return PS_FAIL;
  }
  
  default command ps_result_t PSValue.getValue[uint16_t attrID](void *buffer){return PS_FAIL;}

  event void PSSubscriptionAccess.createDone(ps_subscription_handle_t *handlePtr,
                        ps_result_t result){}
  event void PSSubscriptionAccess.cloneDone(const ps_subscription_handle_t originalHandle, 
                       ps_subscription_handle_t *cloneHandlePtr, 
                       ps_result_t result){}
  event void PSNotificationAccess.createDone(ps_notification_handle_t *handlePtr,
                        ps_result_t result){}
  event void PSNotificationAccess.cloneDone(ps_notification_handle_t originalHandle,
                       ps_notification_handle_t *cloneHandlePtr,
                       ps_result_t result){}
}

