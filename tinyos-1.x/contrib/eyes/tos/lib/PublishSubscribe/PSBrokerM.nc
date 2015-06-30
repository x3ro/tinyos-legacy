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
 * $Revision: 1.7 $
 * $Date: 2006/03/22 12:07:16 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/* WHAT IS NEW?
   - agents
   - dynamic mem alloc 
        - for subscription table
        - for subscription/notification messages
   - generic attributes (attribute container)
   - debug messages
   - new message format: notification/subscription pairs 
   - network types
 */
includes PS;
includes AM;
module PSBrokerM {
  provides {
     interface StdControl;
     interface PSSubscriptionSend[ps_subscription_ID_t subscriptionID];
     interface PSNotificationSend[uint8_t agentID];
     interface PSSubscriptionListener;
     interface PSNotificationReceive[ps_subscription_ID_t subscriptionID];
     interface PSMessageOffsets;
  }  uses {
    // MATCHING
    interface PSOperation[uint16_t attrID]; 
    
    // ROUTING
      // notifications
    interface Send as SendNotification;
    interface Receive as ReceiveNotification;
    interface RouteControl as RouteControlNotification;
      // subscriptions
    interface Send as SendSubscription;
    interface Receive as ReceiveSubscription;
    
    // STATUS / DEBUG
#if defined(PS_EVENT_REPORT)
    interface LocalTime;
    interface EventReport;
#endif
#if defined(PLATFORM_PC)
    interface Timer;
#endif
    interface Leds;

    // DYNAMIC MEMORY
    interface MemAlloc;
   }
}
implementation {

  ps_subscription_handle_t **m_subTable;  
  uint8_t m_retryCountAllocSubtableSlots;
  uint8_t m_retryCountAllocRecvBuf;
  ps_subscription_msg_container_t **m_subscriptionRecvBuf;
  uint8_t m_allocLock;
  bool m_notificationSendLock;
  ps_notification_handle_t m_notificationSendHandle;
  ps_subscription_handle_t m_subscriptionSendHandle;
  ps_subscription_handle_t m_subscriptionOldHandle;
  uint8_t m_notificationID;
  uint16_t m_subTableSendIndex;
  uint8_t m_memNotificationRecv[sizeof(ps_notification_msg_t) + 
    sizeof(ps_notification_msg_container_t) - sizeof(TOS_Msg)];
  ps_notification_msg_container_t *m_notificationRecvBuf;
#ifdef PS_EVENT_REPORT
  uint8_t m_notificationSendCount;
#endif

  enum {
    SUBTABLE_SLOTS_INCREMENT_SIZE = 5,
    SUBTABLE_SLOTS_INITIAL_NUM = 5,
    SUBTABLE_MIN_EMPTY_SLOTS = 2,
    SUBTABLE_SLOT_MARKED_EMPTY = 0,
    SUBTABLE_SLOT_MARKED_RESERVED = 1,
  };

  void task allocSubtableSlots();
  void task subscriptionReceived();
  void task notificationReceived();
  void task deallocateDeletePending();
  void task publishNext();
  void task psInitialized();
  void task showInitStart();
  void task showInitEnd();
  
  enum {
    ALLOC_LOCK_NONE,
    ALLOC_LOCK_SUBTABLE,
    ALLOC_LOCK_RECVBUF,
    ALLOC_LOCK_SENDENTRY,
    ALLOC_LOCK_SHRINK_ENTRY,

    ALLOC_MAX_RETRIES = 50, // TinyAlloc itself reposts *a lot*

    ALLOC_LOCK_LOCAL_SUBSCRIBE,
    ALLOC_LOCK_LOCAL_MODIFY,
    ALLOC_LOCK_RECEIVED_SUBSCRIBE,
    ALLOC_LOCK_RECEIVED_MODIFY,
  };

  bool getMemAllocLock(uint8_t type)
  {
    if (m_allocLock == ALLOC_LOCK_NONE)
    {
      m_allocLock = type;
      return TRUE;
    } else
      return FALSE;
  }

  void releaseMemAllocLock()
  {
    m_allocLock = ALLOC_LOCK_NONE;
  }
  
  bool getNotificationSendLock(ps_notification_handle_t handle, uint8_t notificationID)
  {
    if (!m_notificationSendLock)
    {
      m_notificationSendHandle = handle;
      m_notificationID = notificationID;
      m_notificationSendLock = TRUE;
      return TRUE;
    } else
      return FALSE;
  }

  ps_notification_handle_t getNotificationLockHandle()
  {
    return m_notificationSendHandle;
  }

  void releaseNotificationLock(ps_notification_handle_t *handle, uint8_t *notificationID)
  {
    *handle = m_notificationSendHandle;
    *notificationID = m_notificationID;
    m_notificationSendLock = FALSE;
  }

  void task showInitStart()
  {
    call Leds.redOn();
    call Leds.yellowOn();
    call Leds.greenOn();
  }
  
  void task showInitEnd()
  {
    call Leds.redOff();
    call Leds.yellowOff();
    call Leds.greenOff();
  }

  command result_t StdControl.init() {
    call Leds.init();
    m_subTable = 0;
    m_allocLock = ALLOC_LOCK_NONE;
    m_subscriptionRecvBuf = 0;
    m_notificationRecvBuf = (ps_notification_msg_container_t*) &m_memNotificationRecv;
    post showInitStart();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t StdControl.start() 
  {
    post allocSubtableSlots();
    return SUCCESS;
  }

#ifdef PS_EVENT_REPORT
  void task psInitialized()
  {
    if (m_subscriptionRecvBuf)
      call EventReport.send(EVENT_INITIALIZED, call LocalTime.read(), 0, 0);
  }
#endif

  uint16_t numEmptySubtableSlots()
  {
    uint16_t numSubTableSlots;
    uint16_t num = 0, i;
    
    if (m_subTable)
    {
      numSubTableSlots = call MemAlloc.size((Handle) m_subTable) / sizeof(Handle);
      for (i=0; i<numSubTableSlots; i++)
        if (!(*m_subTable)[i])
          num++;
    }
    return num;
  }

  ps_subtable_entry_t*** getEmptySubtableSlot()
  {
    uint16_t numSubTableSlots, i;
    
    if (m_subTable)
    {
      numSubTableSlots = call MemAlloc.size((Handle) m_subTable) / sizeof(Handle);
      for (i=0; i<numSubTableSlots; i++)
        if (!(*m_subTable)[i])
          return (ps_subtable_entry_t***) &((*m_subTable)[i]);
    }
    return 0;
  }
  

  uint16_t numSubtableSlots()
  {
    if (m_subTable)
      return call MemAlloc.size((Handle) m_subTable) / sizeof(Handle);
    else
      return 0;
  }

  uint16_t numUsedSubtableSlots()
  {
    uint16_t numSubTableSlots, i, count = 0;
    if (m_subTable)
    {
      numSubTableSlots = call MemAlloc.size((Handle) m_subTable) / sizeof(Handle);
      for (i=0; i<numSubTableSlots; i++)
        if ((*m_subTable)[i] && !((*((*m_subTable)[i]))->flags & ENTRY_FLAGS))
          count++;
    }
    return count;
  }


  /**
   * Tries to find an empty slot in the subtable and 
   * put a Handle (== **entry) there.
   *
   * @param entry A Handle to a subscriber table entry
   * @return TRUE if successful, false otherwise.
   */
  bool fillFreeSubtableSlot(ps_subtable_entry_t** entry)
  {
    ps_subtable_entry_t*** emptyEntry = getEmptySubtableSlot();
    if (emptyEntry)
    {
      *emptyEntry = entry;
      return TRUE;
    }
    return FALSE;
  }
          
  void task allocSubtableSlots()
  {
    result_t result;
    
    if (numEmptySubtableSlots() >= SUBTABLE_MIN_EMPTY_SLOTS)
      return; // no need to allocate
    if (!getMemAllocLock(ALLOC_LOCK_SUBTABLE)){
      post allocSubtableSlots();
      return;
    }
    if (!m_subTable) // build new table
      result = call MemAlloc.allocate((HandlePtr) &m_subTable, 
          sizeof(Handle*) * SUBTABLE_SLOTS_INITIAL_NUM);
    else // extend existing table
      result = call MemAlloc.reallocate((Handle) m_subTable, 
          call MemAlloc.size((Handle) m_subTable) + 
          sizeof(Handle*) * SUBTABLE_SLOTS_INCREMENT_SIZE);
    if (result != SUCCESS)
    {
      releaseMemAllocLock();
      if (!m_subTable) // don't give up if we haven't even initialized
        post allocSubtableSlots();
      else 
        if (m_retryCountAllocSubtableSlots++ < ALLOC_MAX_RETRIES)
          post allocSubtableSlots();
        else // give up, we're probably out of heap mem
          m_retryCountAllocSubtableSlots = 0; 
    }
  }

  void task allocRecvBuf()
  {
    uint16_t length;
    if (m_subscriptionRecvBuf)
      return; // already allocated, nothing to do
    if (!getMemAllocLock(ALLOC_LOCK_RECVBUF))
    {
      post allocRecvBuf();
      return;
    }
    if (numEmptySubtableSlots() == 0)
    {
      releaseMemAllocLock();
      post allocSubtableSlots();
      return;
    }
    length = call PSMessageOffsets.getNotificationMsgMaxLength() +
      sizeof(ps_notification_msg_container_t) - sizeof(TOS_Msg);
    if (length < (call PSMessageOffsets.getSubscriptionMsgMaxLength()
          + sizeof(ps_notification_msg_container_t) - sizeof(TOS_Msg)) )
      length = call PSMessageOffsets.getSubscriptionMsgMaxLength();
    if (call MemAlloc.allocate((HandlePtr) &m_subscriptionRecvBuf, length) != SUCCESS){
      releaseMemAllocLock();
      if (m_retryCountAllocRecvBuf++ < ALLOC_MAX_RETRIES)
        post allocRecvBuf();
      else // give up, we're probably out of heap mem
        m_retryCountAllocRecvBuf = 0; 
    }
  }

  event result_t MemAlloc.allocComplete(HandlePtr handle, result_t success)
  {
    uint16_t i, allocLock = m_allocLock;

    releaseMemAllocLock(); 
    switch (allocLock) 
    {
      case ALLOC_LOCK_SUBTABLE:
        if (!success)
        {
          // We could not reserve mem on heap for initial
          // subscriber table (should not happen). Retry.
          post allocSubtableSlots();
        } else {
          // SubscriberTable initialized  
          for (i=0; i<SUBTABLE_SLOTS_INITIAL_NUM; i++)
            ((*m_subTable)[i]) = SUBTABLE_SLOT_MARKED_EMPTY;
          post allocRecvBuf();
          post showInitEnd();
#ifdef PS_EVENT_REPORT
          post psInitialized();
#endif
        }
        m_retryCountAllocSubtableSlots = 0;
        break;
      case ALLOC_LOCK_RECVBUF:
        if (!success)
        {
          if (m_retryCountAllocRecvBuf++ < ALLOC_MAX_RETRIES){
            call MemAlloc.compact();
            post allocRecvBuf();
          } else {
            // give up, we're probably out of heap mem.
            dbg(DBG_TEMP,"Cannot allocate receiveBuffer (available heap = %d)!\n",
                call MemAlloc.freeBytes());
            m_retryCountAllocRecvBuf = 0; 
          }
        } else {
          // now **m_subscriptionRecvBuf is newly allocated entry, but 
          // it is not part of the subscription table yet,
          // let's hook it up there (we checked and there is
          // now at least one slot empty).
          fillFreeSubtableSlot(m_subscriptionRecvBuf);
          (*m_subscriptionRecvBuf)->flags = ENTRY_EMPTY;
          if (numEmptySubtableSlots() < SUBTABLE_MIN_EMPTY_SLOTS)
            post allocSubtableSlots();
          //testAlloc();  // debug
          //testReceive();
        }
        break;
      case ALLOC_LOCK_SENDENTRY:
        {
          ps_subscription_msg_t *subscriptionMsg;
          subscriptionMsg = &(*m_subscriptionSendHandle)->subscriptionMsg;
          if (!success || 
              call SendSubscription.send(&(*m_subscriptionSendHandle)->tosMsg, 
              subscriptionMsg->dataLength + sizeof(ps_subscription_msg_t)) != SUCCESS)
             signal PSSubscriptionSend.sendDone[subscriptionMsg->subscriptionID](
                     m_subscriptionSendHandle, PS_FAIL_ALLOC);
          break;
        }
    }
    return SUCCESS;
  }
  
  event result_t MemAlloc.reallocComplete(Handle handle, result_t success)
  {
    uint16_t i, allocLock = m_allocLock;
    Handle *eraser;

    releaseMemAllocLock(); 
    switch (allocLock) 
    {
      case ALLOC_LOCK_SUBTABLE:
        if (!success)
        {
          if (m_retryCountAllocSubtableSlots++ < ALLOC_MAX_RETRIES)
            post allocSubtableSlots();
          else // give up, we're probably out of heap mem.
            m_retryCountAllocSubtableSlots = 0; 
        } else {
          eraser = (Handle*) *m_subTable + (call MemAlloc.size(handle)/sizeof(Handle)) - 1;
          // the substable was extended, initialize new slots
          for (i=0; i<SUBTABLE_SLOTS_INCREMENT_SIZE; i++)
            *eraser-- = SUBTABLE_SLOT_MARKED_EMPTY;
        }
        break;
      case ALLOC_LOCK_SHRINK_ENTRY:
        break;
    }
    return SUCCESS;
  }

  event result_t MemAlloc.compactComplete(){ return SUCCESS;}
  ps_subscription_handle_t getSubtableEntry(uint16_t num)
  {
    if (num >= numSubtableSlots())
      return 0;
    else
      return (ps_subscription_handle_t) (*m_subTable)[num];
  }

  bool deleteSubtableEntry(uint16_t num)
  {
    if (num >= numSubtableSlots())
      return FALSE;
    else 
    {
      (*m_subTable)[num] = SUBTABLE_SLOT_MARKED_EMPTY;
      return TRUE;
    }
  }

  ps_subscription_handle_t getRegisteredSubscription(
        ps_subscriber_ID_t *subscriberID,
        ps_subscription_ID_tag_t *subscriptionID)
  {
    uint16_t i, slots = numSubtableSlots();
    ps_subscription_handle_t handle;
    for (i=0; i<slots; i++)
      if ((handle = getSubtableEntry(i)) && 
          !((*handle)->flags & ENTRY_FLAGS) &&
          (*handle)->subscriptionMsg.subscriberID == *subscriberID &&
          (*handle)->subscriptionMsg.subscriptionID == *subscriptionID)
        return handle;
    return 0;
  }

  ps_notification_msg_t* getNotificationMsg(ps_notification_msg_container_t *nContainer)
  {
    uint16_t length;
    if (nContainer->flags & MSG_TYPE_NOTIFICATION)
      return &(nContainer->notificationMsg);
    else
      return call SendNotification.getBuffer(&nContainer->tosMsg, &length);
  }
  
  ps_subscription_msg_t* getSubscriptionMsg(ps_subscription_msg_container_t *sContainer)
  {
    uint16_t length;
    if (sContainer->flags & MSG_TYPE_SUBSCRIPTION)
      return &sContainer->subscriptionMsg;
    else
      return call SendSubscription.getBuffer(&sContainer->tosMsg, &length);
  }

  bool matchesSubscription(ps_notification_msg_container_t *nContainer, 
      ps_subscription_msg_container_t *sContainer)
  {
    ps_notification_msg_t *notificationMsg;
    ps_subscription_msg_t *subscriptionMsg;
    uint16_t offsetSubscription = 0, offsetNotification;
    ps_container_t *itemContainerS, *itemContainerN;
    ps_attr_ID_t *attribIDSubscription, *attribIDNotification;
    
    notificationMsg = getNotificationMsg(nContainer);
    subscriptionMsg = getSubscriptionMsg(sContainer);
    
    // check: for every constraint in the subscription there must
    // be a matching attribute-value-pair in the notification
    while (offsetSubscription < subscriptionMsg->dataLength)
    {
      itemContainerS = (ps_container_t*) &subscriptionMsg->data[offsetSubscription];
      offsetSubscription += itemContainerS->header.totalLength;
      if (itemContainerS->header.type != PS_ITEM_TYPE_CONSTRAINT)
        continue;
      attribIDSubscription = &itemContainerS->constraint.attributeID;
      offsetNotification = 0;
      while (offsetNotification < notificationMsg->dataLength)
      {
        itemContainerN = (ps_container_t*) &notificationMsg->data[offsetNotification];
        offsetNotification += itemContainerN->header.totalLength;
        if (itemContainerN->header.type != PS_ITEM_TYPE_AVPAIR)
          continue;
        attribIDNotification = &itemContainerN->avpair.attributeID;
        if (*attribIDSubscription == *attribIDNotification)
          if (call PSOperation.isMatching[*attribIDSubscription](
                itemContainerN->avpair.value,
                &itemContainerS->constraint.operationID,
                itemContainerS->constraint.value))
          {
            offsetNotification = 0;
            break; // match !
          }
      }
      if (offsetNotification >= notificationMsg->dataLength)
        return FALSE;
    }
    return TRUE;
  }

  default command bool PSOperation.isMatching[uint16_t attrib](
      const void *value1, const ps_opr_ID_t *operation, const void *value2)
  {
    // if no attribute component is registered the match is
    // FALSE by default
    return FALSE;
  }

  command uint16_t PSMessageOffsets.getSubscriptionMsgOffset()
  {
    uint16_t length;
    uint8_t *buffer;
    TOS_Msg msg;
    buffer = call SendSubscription.getBuffer(&msg, &length);
    return (buffer - (uint8_t*) &msg);
  }
  
  command uint16_t PSMessageOffsets.getNotificationMsgOffset()
  {
    uint16_t length;
    uint8_t *buffer;
    TOS_Msg msg;
    buffer = call SendNotification.getBuffer(&msg, &length);
    return (buffer - (uint8_t*) &msg);
  }

  command uint16_t PSMessageOffsets.getSubscriptionMsgMaxLength()
  {
    uint16_t length;
    uint8_t *buffer;
    TOS_Msg msg;
    buffer = call SendSubscription.getBuffer(&msg, &length);
    return length;
  }

  command uint16_t PSMessageOffsets.getNotificationMsgMaxLength()
  {
    uint16_t length;
    uint8_t *buffer;
    TOS_Msg msg;
    buffer = call SendNotification.getBuffer(&msg, &length);
    return length;
  }

  command ps_subscription_handle_t PSMessageOffsets.getSubscriptionHandle(
        ps_subscription_ID_t subscriptionID)
  {
    uint16_t i, slots = numSubtableSlots();
    ps_subscription_handle_t handle;
    for (i=0; i<slots; i++)
      if ((handle = getSubtableEntry(i)) && 
          !((*handle)->flags & ENTRY_FLAGS) &&
          (*handle)->subscriptionMsg.subscriptionID == subscriptionID)
        return handle;
    return 0;
  }

  /***********************************************************************
   * Notifications
   ***********************************************************************/

  command ps_result_t PSNotificationSend.send[uint8_t notificationID](
      ps_notification_handle_t handle)
  {
    uint16_t length;
    ps_notification_msg_t *notificationMsg;

    if (!((*handle)->flags & MSG_TYPE_TOSMSG)){
      STATUSMSG(NOTIFICATION_SENT_FAIL,"Clone fail!\n");
      return PS_FAIL_CLONE;
    }
    if (!getNotificationSendLock(handle, notificationID)){
      STATUSMSG(NOTIFICATION_SENT_FAIL,"Lock fail!\n");
      return PS_FAIL_BUSY;
    }
    notificationMsg = (ps_notification_msg_t *) 
      call SendNotification.getBuffer(&((*handle)->tosMsg), &length);
    notificationMsg->parentAddress = call RouteControlNotification.getParent();
    notificationMsg->sourceAddress = TOS_LOCAL_ADDRESS;
    m_subTableSendIndex = 0;
#ifdef PS_EVENT_REPORT
    m_notificationSendCount = 0;
#endif    
    post publishNext();
    return PS_SUCCESS;
  }

  void task publishNext()
  {
    uint16_t length;
    uint8_t notificationID;
    ps_notification_handle_t nHandle;
    ps_subscription_handle_t sHandle;
    ps_notification_msg_t *notificationMsg;
    ps_subscription_msg_t *subscriptionMsg;
    uint16_t slots;

    nHandle = getNotificationLockHandle();
    notificationMsg = (ps_notification_msg_t *) 
      call SendNotification.getBuffer(&((*nHandle)->tosMsg), &length);
    slots = numSubtableSlots();
    while (m_subTableSendIndex < slots)
    {
      if (!(sHandle = getSubtableEntry(m_subTableSendIndex)) || 
          (*sHandle)->flags & ENTRY_FLAGS)
      {
        m_subTableSendIndex++;
        continue;
      }
      if (matchesSubscription(*nHandle, *sHandle))
      {
        subscriptionMsg = getSubscriptionMsg(*sHandle);
        notificationMsg->subscriberID = subscriptionMsg->subscriberID;
        notificationMsg->subscriptionID = subscriptionMsg->subscriptionID;
        notificationMsg->modificationCounter = subscriptionMsg->modificationCounter;
        if (call SendNotification.send( &(*nHandle)->tosMsg, 
                 sizeof(ps_notification_msg_t) + notificationMsg->dataLength) 
            == SUCCESS){
          return;  // publishNext will be posted from PSNotificationSend.sendDone();
        } else {
          // routing layer busy, let's try again later
          // repost with same m_subTableSendIndex 
          if (post publishNext() == FAIL)
          { 
            STATUSMSG(NOTIFICATION_SENT_FAIL,"Task queue full(1)!");
            releaseNotificationLock(&nHandle, &notificationID);          // give up 
          }
          return;
        }
      } else 
        // no match, check next entry
        m_subTableSendIndex++;
    } // while
    // all done
    releaseNotificationLock(&nHandle, &notificationID);
#ifdef PS_EVENT_REPORT    
    if (!m_notificationSendCount)
      call EventReport.send(EVENT_NO_MATCH, call LocalTime.read(), 0, 0);
#endif
    signal PSNotificationSend.sendDone[notificationID](nHandle, PS_SUCCESS);
  }

  event result_t SendNotification.sendDone(TOS_MsgPtr msg, result_t success)
  {
    uint8_t notificationID;
    uint16_t length;
    ps_notification_handle_t nHandle;
    ps_notification_msg_t *notificationMsg;
    
    nHandle = getNotificationLockHandle();
    notificationMsg = (ps_notification_msg_t *) 
      call SendNotification.getBuffer(&((*nHandle)->tosMsg), &length);
    if (success == SUCCESS){
      m_subTableSendIndex++;
      call Leds.yellowToggle();
#ifdef PS_EVENT_REPORT
        m_notificationSendCount++;
        call EventReport.send(EVENT_NOTIFICATION_SENT, msg->time_us, 
            notificationMsg->subscriberID, notificationMsg->subscriptionID);
#endif
      dbg(DBG_TEMP,"Node %d sent notification, parent = %d, source = %d, subscriberID = %d, subscriptionID = %d, modificationCounter = %d, flags = %d, dataLength = %d\n", 
          TOS_LOCAL_ADDRESS,
          notificationMsg->parentAddress,
          notificationMsg->sourceAddress,
          notificationMsg->subscriberID,
          notificationMsg->subscriptionID,
          notificationMsg->modificationCounter,
          notificationMsg->flags,
          notificationMsg->dataLength
         );
    }
#if !defined(PLATFORM_PC)
    if (post publishNext() == FAIL){
      releaseNotificationLock(&nHandle, &notificationID);
      signal PSNotificationSend.sendDone[notificationID](nHandle, PS_FAIL);
      STATUSMSG(NOTIFICATION_SENT_FAIL,"Task queue full(2)!");
    }
#else
    // avoid infinite loop in TOSSIM
    call Timer.start(TIMER_ONE_SHOT, 10);
#endif
    return SUCCESS;
  }
  
#if defined(PLATFORM_PC)
  event result_t Timer.fired(){
    post  publishNext();
    return SUCCESS;
  }
#endif

  default event void PSNotificationSend.sendDone[uint8_t notificationID]
   (ps_notification_handle_t handle, ps_result_t result){return ;}
  
  event TOS_MsgPtr ReceiveNotification.receive(TOS_MsgPtr msg, 
      void* payload, uint16_t payloadLen)
  {
    // We have received a notification destined for us
    // i.e. we are subscriber.
    ps_notification_msg_t *notificationMsg;

    notificationMsg = (ps_notification_msg_t *) payload;
    if (notificationMsg->subscriberID != TOS_LOCAL_ADDRESS)
      return msg;  
    
    if (!(m_notificationRecvBuf->flags & ENTRY_EMPTY))
    {
      STATUSMSG(NOTIFICATION_RECEIVED_FAIL,"Src: %d, Parent: %d", 
          (uint16_t) notificationMsg->sourceAddress, 
          (uint16_t) notificationMsg->parentAddress);
      return FAIL;  // drop it
    }
    m_notificationRecvBuf->flags = MSG_TYPE_NOTIFICATION & (~ENTRY_EMPTY);
    // copy notification into buffer (do signalling later).
    memcpy (&m_notificationRecvBuf->notificationMsg, payload, payloadLen);
    post notificationReceived();
    return msg;
  }

  void task notificationReceived()
  {
    ps_notification_msg_t *notificationMsg;
    ps_subscription_handle_t registeredSubscription;
    
    notificationMsg = &m_notificationRecvBuf->notificationMsg;
    registeredSubscription = getRegisteredSubscription(
        &(notificationMsg->subscriberID),
        &(notificationMsg->subscriptionID));
    if (registeredSubscription && !((*registeredSubscription)->flags & ENTRY_FLAGS) &&
        matchesSubscription(m_notificationRecvBuf, *registeredSubscription) )
    {
      signal PSNotificationReceive.receive[notificationMsg->subscriptionID](
        &m_notificationRecvBuf);
      STATUSMSG(NOTIFICATION_RECEIVED_SUCCESS,"Src: %d, Parent: %d", 
          (uint16_t) notificationMsg->sourceAddress, 
          (uint16_t) notificationMsg->parentAddress);
    } else {
      STATUSMSG(NOTIFICATION_RECEIVED_FAIL,"Not registered %d, %d", 
          (uint16_t) notificationMsg->subscriberID, 
          (uint16_t) notificationMsg->subscriptionID);
    }
    m_notificationRecvBuf->flags |= ENTRY_EMPTY;
  }

  default event void PSNotificationReceive.receive[ps_subscription_ID_t subscriptionID](
      ps_notification_handle_t handle)
  {
    return;
  }

  /***********************************************************************
   * Subscriptions
   ***********************************************************************/

  command ps_result_t PSSubscriptionSend.send[ps_subscription_ID_t subscriptionID](
      ps_subscription_handle_t handle)
  {
    uint16_t length;
    ps_subscription_msg_t *subscriptionMsg;
    ps_subscription_handle_t registeredSubscription;
    ps_subtable_entry_t*** emptySubtableSlot;
    
    subscriptionMsg = &(*handle)->subscriptionMsg;
    registeredSubscription = getRegisteredSubscription(
        &(subscriptionMsg->subscriberID),
        &(subscriptionMsg->subscriptionID));

    if (!((*handle)->flags & MSG_TYPE_TOSMSG)){
      STATUSMSG(SUBSCRIPTION_SENT_FAIL,"Clone fail!");
      return PS_FAIL_CLONE;
    }
    if (subscriptionMsg->flags & MSG_FLAG_UNSUBSCRIBE && !registeredSubscription){
      // it's an unsubscribe for a subscription that
      // never got registered: FAIL.
      STATUSMSG(SUBSCRIPTION_SENT_FAIL,"Unsubscribe fail!");
      return PS_FAIL_UNSUBSCRIBE;
    }

    m_subscriptionSendHandle = handle;
    m_subscriptionOldHandle = registeredSubscription;
    if (subscriptionMsg->flags & MSG_FLAG_UNSUBSCRIBE)
    {
      if (call SendSubscription.send(&(*handle)->tosMsg, 
          subscriptionMsg->dataLength + sizeof(ps_subscription_msg_t)) != SUCCESS){
        STATUSMSG(SUBSCRIPTION_SENT_FAIL,"Routing busy!");
        return PS_FAIL_ROUTING;
      } else 
        return PS_SUCCESS;  // go on in sendDone
    } else { 
      // it's either a modification or a new subscription
      // in both case we need to allocate an entry in the subtable
      if (!getMemAllocLock(ALLOC_LOCK_SENDENTRY)){
        STATUSMSG(SUBSCRIPTION_SENT_FAIL,"Allocation fail(1)!");
        return PS_FAIL_ALLOC;
      }
      if (!(emptySubtableSlot = getEmptySubtableSlot()))
      {
        STATUSMSG(SUBSCRIPTION_SENT_FAIL,"Allocation fail(2)!");
        post allocSubtableSlots();
        return PS_FAIL_ALLOC;
      }
      length = subscriptionMsg->dataLength + sizeof(ps_subscription_msg_t) +
        sizeof(ps_notification_msg_container_t) - sizeof(TOS_Msg);
      if (call MemAlloc.allocate((HandlePtr) *emptySubtableSlot, length) != SUCCESS)
      {
        releaseMemAllocLock();
        STATUSMSG(SUBSCRIPTION_SENT_FAIL,"Allocation fail(3)!");
        return PS_FAIL_ALLOC;
      }
    }
    return PS_SUCCESS;
  }

  event result_t SendSubscription.sendDone(TOS_MsgPtr msg, result_t success)
  {
    ps_subscription_msg_t *subscriptionMsg;
    
    subscriptionMsg = &(*m_subscriptionSendHandle)->subscriptionMsg;
    if (success != SUCCESS){
      signal PSSubscriptionSend.sendDone[subscriptionMsg->subscriptionID](
          m_subscriptionSendHandle, PS_FAIL_ALLOC);
      STATUSMSG(SUBSCRIPTION_SENT_FAIL,"Routing fail!");
      return SUCCESS;
    } else {
      (*m_subscriptionOldHandle)->flags |= ENTRY_DELETE_PENDING;
      signal PSSubscriptionSend.sendDone[subscriptionMsg->subscriptionID](
          m_subscriptionSendHandle, PS_FAIL_ALLOC);
      post deallocateDeletePending();
      STATUSMSG(SUBSCRIPTION_SENT_FAIL,"Allocation fail(4)!");
      return SUCCESS;
    }
    STATUSMSG(SUBSCRIPTION_SENT_SUCCESS,"Snk: %d, SID: %d ModC: %d", 
          (uint16_t) subscriptionMsg->subscriberID, 
          (uint16_t) subscriptionMsg->subscriptionID,
          (uint16_t) subscriptionMsg->modificationCounter);
    return SUCCESS;
  }
   
  default event void PSSubscriptionSend.sendDone[ps_subscription_ID_t id](
      ps_subscription_handle_t handle, ps_result_t result){}

  void task deallocateDeletePending()
  {
    uint16_t i, slots = numSubtableSlots();
    ps_subscription_handle_t handle;
    for (i=0; i<slots; i++)
      if ( (handle = getSubtableEntry(i)) && (*handle)->flags & ENTRY_DELETE_PENDING)
      {
        if (call MemAlloc.free((Handle) handle) == SUCCESS)
          deleteSubtableEntry(i); // else
        else
          post deallocateDeletePending();
      }
  }


  event TOS_MsgPtr ReceiveSubscription.receive(TOS_MsgPtr msg, void* payload, uint16_t payloadLen)
  {
    ps_subscription_msg_t *subscriptionMsg;
    ps_subscription_handle_t handle;
    
    subscriptionMsg = (ps_subscription_msg_t *) payload;
    handle = getRegisteredSubscription(
        &(subscriptionMsg->subscriberID),
        &(subscriptionMsg->subscriptionID));
    
#ifdef PS_EVENT_REPORT
    call EventReport.send(EVENT_SUBSCRIPTION_RCVD, msg->time_us, 
            subscriptionMsg->subscriberID, subscriptionMsg->subscriptionID);
#endif
    dbg(DBG_TEMP,"Received subscription, subscriberID = %d, subscriptionID = %d, modificationCounter = %d, flags = %d, dataLength = %d, free heap = %d\n", 
          subscriptionMsg->subscriberID,
          subscriptionMsg->subscriptionID,
          subscriptionMsg->modificationCounter,
          subscriptionMsg->flags,
          subscriptionMsg->dataLength, 
          call MemAlloc.freeBytes());

    // check if it is an unsubscribe 
    if (subscriptionMsg->flags & MSG_FLAG_UNSUBSCRIBE){
      if (!handle || 
          subscriptionMsg->modificationCounter <= (*handle)->subscriptionMsg.modificationCounter)
      {
        // it's an unsubscribe for a subscription that
        // never got registered: drop it.
        // note: this implies that if we get the original
        // subscription later, it will get registered ...      
        STATUSMSG(SUBSCRIPTION_RECEIVED_UNSUBSCRIBE_FAIL,"Snk: %d SID: %d, ModC: %d", 
          (uint16_t) subscriptionMsg->subscriberID,
          (uint16_t) subscriptionMsg->subscriptionID,
          (uint16_t) subscriptionMsg->modificationCounter);
        return msg;  // drop it
      } else {
        // it's an unsubscribe for a subscription that
        // is registered: mark it unsubscribe. deallocate 
        // and signal to app later.
        (*handle)->flags = (*handle)->flags | ENTRY_UNSUBSCRIBE;
        post subscriptionReceived();
        return msg;
      }
    }
    // it's either a new subscription or modification.
    // check if we got a newer (or same) subscription 
    // with same ID installed (then drop it)
    if (handle && 
        subscriptionMsg->modificationCounter <= (*handle)->subscriptionMsg.modificationCounter)
    {
      STATUSMSG(SUBSCRIPTION_RECEIVED_MODIFY_FAIL,"Snk: %d SID: %d, ModC: %d", 
          (uint16_t) subscriptionMsg->subscriberID,
          (uint16_t) subscriptionMsg->subscriptionID,
          (uint16_t) subscriptionMsg->modificationCounter);
      return msg;  // drop it
    }
    // it's either new subscription or a valid modification. check if we
    // got an empty receive buffer (if not, very unlikely!, drop it).
    if (!m_subscriptionRecvBuf)
    {
      STATUSMSG(SUBSCRIPTION_RECEIVED_FAIL,"Snk: %d SID: %d, ModC: %d", 
          (uint16_t) subscriptionMsg->subscriberID,
          (uint16_t) subscriptionMsg->subscriptionID,
          (uint16_t) subscriptionMsg->modificationCounter);
      post allocRecvBuf();
      return msg;  // drop it
    }
    if (handle)
    {
      // it's a modification: mark old entry stale
      (*handle)->flags = (*handle)->flags | ENTRY_STALE;
      (*m_subscriptionRecvBuf)->flags = ENTRY_MODIFIED | MSG_TYPE_SUBSCRIPTION;
    } else {
      (*m_subscriptionRecvBuf)->flags = ENTRY_NEW | MSG_TYPE_SUBSCRIPTION;
    }
    // copy subscription into allocated entry 
    // (do signalling later).
    memcpy (&(*m_subscriptionRecvBuf)->subscriptionMsg, payload, payloadLen);
    m_subscriptionRecvBuf = 0;  // mark recvBuffer empty
    post subscriptionReceived();
    call Leds.redToggle();
    post allocRecvBuf();
    return msg;
  }

  void task subscriptionReceived()
  {
    uint16_t i, j, slots = numSubtableSlots();
    ps_subscription_handle_t handle, oldHandle = 0;
    for (i=0; i<slots; i++)
      if ( (handle = getSubtableEntry(i)) && (*handle)->flags & ENTRY_FLAGS)
      {
        if ((*handle)->flags & ENTRY_UNSUBSCRIBE)
        {
          signal PSSubscriptionListener.receivedUnsubscribe(handle);
          (*handle)->flags = (*handle)->flags | ENTRY_INVALID;
          STATUSMSG(SUBSCRIPTION_RECEIVED_UNSUBSCRIBE_SUCCESS,"Snk: %d SID: %d Entries: %d", 
            (uint16_t) (*handle)->subscriptionMsg.subscriberID,
            (uint16_t) (*handle)->subscriptionMsg.subscriptionID,
            (uint16_t) numUsedSubtableSlots());
        } else 
          if ((*handle)->flags & ENTRY_MODIFIED)
          {
            for (j=0; j<slots; j++)
              if ( (oldHandle = getSubtableEntry(j)) && (*oldHandle)->flags & ENTRY_STALE
                  && (*oldHandle)->subscriptionMsg.subscriberID == 
                     (*handle)->subscriptionMsg.subscriberID
                  && (*oldHandle)->subscriptionMsg.subscriptionID == 
                     (*handle)->subscriptionMsg.subscriptionID)
                break;
            signal PSSubscriptionListener.receivedModify(oldHandle, handle);
            (*oldHandle)->flags = ENTRY_INVALID;
            (*handle)->flags = (*handle)->flags & ~ENTRY_FLAGS;
            STATUSMSG(SUBSCRIPTION_RECEIVED_MODIFY_SUCCESS,"MSnk: %d SID: %d, ModC: %d Entries: %d", 
              (uint16_t) (*handle)->subscriptionMsg.subscriberID,
              (uint16_t) (*handle)->subscriptionMsg.subscriptionID,
              (uint16_t) (*handle)->subscriptionMsg.modificationCounter,
              (uint16_t) numUsedSubtableSlots());
          } else
            if ((*handle)->flags & ENTRY_NEW)
            {
              (*handle)->flags = (*handle)->flags & ~ENTRY_FLAGS;
              signal PSSubscriptionListener.receivedNew(handle);
              if (getMemAllocLock(ALLOC_LOCK_SHRINK_ENTRY))
              {
                // shrink to size actually needed 
                if ( call MemAlloc.reallocate((Handle) handle, 
                     sizeof(ps_subscription_msg_container_t) - sizeof(TOS_Msg) +
                     sizeof(ps_subscription_msg_t) + (*handle)->subscriptionMsg.dataLength)
                    != SUCCESS)
                  releaseMemAllocLock(); 
              }
              STATUSMSG(SUBSCRIPTION_RECEIVED_NEW_SUCCESS,"NSnk: %d SID: %d, ModC: %d Entries: %d.", 
                (uint16_t) (*handle)->subscriptionMsg.subscriberID,
                (uint16_t) (*handle)->subscriptionMsg.subscriptionID,
                (uint16_t) (*handle)->subscriptionMsg.modificationCounter,
                (uint16_t) numUsedSubtableSlots());
            }
        if ((*handle)->flags & ENTRY_INVALID)
          if (call MemAlloc.free((Handle) handle) > 0)
            deleteSubtableEntry(i);
      }
  }

  default event void PSSubscriptionListener.receivedNew(const ps_subscription_handle_t handle){}
  default event void PSSubscriptionListener.receivedModify(const ps_subscription_handle_t oldHandle,
      const ps_subscription_handle_t newHandle){}
  default event void PSSubscriptionListener.receivedUnsubscribe(ps_subscription_handle_t handle){}


                                /* Debug */

  // This function is testing whether the allocation process is working
  // correctly: It writes test data into the newly allocated m_subscriptionRecvBuf,
  // and allocates another m_subscriptionRecvBuf. After 15 times the content
  // of the buffers is checked and so is the content of the  m_subTable.
  // (which has been been reallocated in between).
  // To run the test uncomment the function call in MemAlloc.allocComplete().
  /*
  uint8_t count;
  Handle first;
  TOS_Msg tosMsg;   // debug
  void testAlloc();  // debug
  void testReceive();  // debug
  uint16_t debugSubTableCount;  // debug
  void testAlloc()
  {  // debug
    uint16_t i,j;
    if (m_subscriptionRecvBuf)
    {
      //write data into allocated buffer
      if (!count)
        first = (Handle) m_subscriptionRecvBuf;
      memset((uint8_t*)*m_subscriptionRecvBuf, count++, 
          call PSMessageOffsets.getSubscriptionMsgMaxLength());
      m_subscriptionRecvBuf = 0;
    }
    if (count == 15)  // variable
    {
      // check if substable content is correct (if all handles
      // are the same) and if each entry (ps_subscription_msg_t) 
      // is correct (if the data we have written is still there).
      // flash three LEDs if successful
      call Leds.redOff();
      for (i=0; i<count-1; i++)
        if (first+i != (Handle) (**m_subTable)+i)
          return;
      call Leds.redOn();
      for (i=0; i<count-1; i++)
        for (j=0; j<call PSMessageOffsets.getSubscriptionMsgMaxLength(); j++)
          if ( ((int8_t*)(*(first+i)))[i] != i)
            return;
      call Leds.yellowOn();
      call Leds.greenOn();
    } else  
      post allocRecvBuf();
  }

  bool done = FALSE;
  void testReceive()
  {
    uint16_t length;
    ps_subscription_msg_t *subscriptionMsg;
    ps_container_t *cc1, *cc, *cc2;
    ps_container_t *avp1;
    subscriptionMsg = (ps_subscription_msg_t *) 
      call SendSubscription.getBuffer(&tosMsg, &length);
    if (done)
      return;
    done = TRUE;
    subscriptionMsg->subscriberID = 1;
    subscriptionMsg->subscriptionID = 2;
    subscriptionMsg->modificationCounter = 0;
    subscriptionMsg->flags = 0; // new usbscription
    
    cc = (ps_container_t*) subscriptionMsg->data;
    cc->header.type = PS_ITEM_TYPE_CONSTRAINT;
    cc->header.totalLength = sizeof(ps_item_header_t) + sizeof(ps_constraint_t) + 1;
    cc->constraint.attributeID = 0x10;
    cc->constraint.operationID = 0x11;
    cc->constraint.value[0] = 0x12;

    avp1 = (ps_container_t*) (subscriptionMsg->data + cc->header.totalLength);
    avp1->header.type = PS_ITEM_TYPE_AVPAIR;
    avp1->header.totalLength = sizeof(ps_item_header_t) + sizeof(ps_avpair_t) + 1;
    avp1->avpair.attributeID = 0x20;
    avp1->avpair.value[0] = 0x21;

    subscriptionMsg->dataLength = cc->header.totalLength + avp1->header.totalLength;
    signal ReceiveSubscription.receive(&tosMsg, 
        subscriptionMsg, sizeof(ps_subscription_msg_t) + subscriptionMsg->dataLength);
  }
  */
}

