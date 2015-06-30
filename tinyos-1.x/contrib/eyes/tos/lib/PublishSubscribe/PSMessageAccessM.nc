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
module PSMessageAccessM {
  provides {
    interface StdControl;
    interface PSSubscriptionAccess[uint16_t messageAccessID];
    interface PSNotificationAccess[uint16_t messageAccessID];
    interface PSMessageAccess;
  }
  uses interface PSMessageOffsets;
  uses interface MemAlloc;
}
implementation {
  
  enum {
    SUBSCRIPTION_CREATE,
    SUBSCRIPTION_CLONE_SUBMSG,
    SUBSCRIPTION_CLONE_TOSMSG,
    NOTIFICATION_CREATE,
    NOTIFICATION_CLONE_NOTFMSG,
    NOTIFICATION_CLONE_TOSMSG,
  };
  HandlePtr m_memHandle;
  const uint8_t* m_toBeClonedHandle;
  uint16_t m_allocCallerID;
  bool m_memLock = FALSE;
  uint8_t m_requestType;
  
  uint16_t m_subscriptionMsgOffset;
  uint16_t m_subscriptionMsgMaxLength;
  uint16_t m_notificationMsgOffset;
  uint16_t m_notificationMsgMaxLength;
  
  command result_t StdControl.init() {
    m_subscriptionMsgOffset = call PSMessageOffsets.getSubscriptionMsgOffset();
    m_subscriptionMsgMaxLength = call PSMessageOffsets.getSubscriptionMsgMaxLength();
    m_notificationMsgOffset = call PSMessageOffsets.getNotificationMsgOffset();
    m_notificationMsgMaxLength = call PSMessageOffsets.getNotificationMsgMaxLength();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  bool getMemAllocLock(uint16_t messageAccessID)
  {
    bool locked;
    atomic {
      locked = m_memLock;
      m_memLock = TRUE;
    }
    if (locked)
      return FALSE;
    m_allocCallerID = messageAccessID;
    return SUCCESS;
  }

  inline void releaseMemAllocLock()
  {
    m_memLock = FALSE;
  }
  

  event result_t MemAlloc.allocComplete(HandlePtr handle, result_t success)
  {
    uint8_t requestType = m_requestType;
    ps_result_t result = (success == SUCCESS) ? PS_SUCCESS : PS_FAIL_ALLOC;
    ps_subscription_msg_container_t **smc;
    ps_notification_msg_container_t **nmc;

    releaseMemAllocLock();
    if (success == SUCCESS)
      // all messages must stay locked, because the application
      // may have references to it
      call MemAlloc.lock(*handle);  
    switch (requestType)
    {
      case  SUBSCRIPTION_CREATE:
        smc = (ps_subscription_msg_container_t**) *handle;
        if (success == SUCCESS && *handle){
          (*smc)->flags = MSG_TYPE_TOSMSG;
          memset(&(*smc)->tosMsg, 0, sizeof(TOS_Msg));
        }
        signal PSSubscriptionAccess.createDone[m_allocCallerID](&smc, result);
        break;
      case SUBSCRIPTION_CLONE_TOSMSG:
        smc = (ps_subscription_msg_container_t**) *handle;
        if (success == SUCCESS && *handle)
          memcpy(*smc, m_toBeClonedHandle, 
              sizeof(ps_subscription_msg_container_t));
        signal PSSubscriptionAccess.cloneDone[m_allocCallerID](
            (const ps_subscription_handle_t) m_toBeClonedHandle,
            &smc, result);
      case SUBSCRIPTION_CLONE_SUBMSG:
        smc = (ps_subscription_msg_container_t**) *handle;
        if (success == SUCCESS && *handle)
          memcpy(*smc, m_toBeClonedHandle, 
              sizeof(ps_subscription_msg_container_t) -
              sizeof(TOS_Msg) + sizeof(ps_subscription_msg_t));
        signal PSSubscriptionAccess.cloneDone[m_allocCallerID](
            (const ps_subscription_handle_t) m_toBeClonedHandle,
            &smc, result);
        break;
      case NOTIFICATION_CREATE:
        nmc = (ps_notification_msg_container_t**) *handle;
        if (success == SUCCESS && *handle){
          (*nmc)->flags = MSG_TYPE_TOSMSG;
          memset(&(*nmc)->tosMsg, 0, sizeof(TOS_Msg));
        }
        signal PSNotificationAccess.createDone[m_allocCallerID](&nmc, result);
        break;
      case NOTIFICATION_CLONE_TOSMSG:
        nmc = (ps_notification_msg_container_t**) *handle;
        if (success == SUCCESS && *handle)
          memcpy(*nmc, m_toBeClonedHandle, 
              sizeof(ps_notification_msg_container_t));
        signal PSNotificationAccess.cloneDone[m_allocCallerID](
            (const ps_notification_handle_t) m_toBeClonedHandle,
            &nmc, result);
        break;
      case NOTIFICATION_CLONE_NOTFMSG:
        nmc = (ps_notification_msg_container_t**) *handle;
        if (success == SUCCESS && *handle)
          memcpy(*nmc, m_toBeClonedHandle, 
              sizeof(ps_notification_msg_container_t) -
              sizeof(TOS_Msg) + sizeof(ps_notification_msg_t));
        signal PSNotificationAccess.cloneDone[m_allocCallerID](
            (const ps_notification_handle_t) m_toBeClonedHandle,
            &nmc, result);
        break;
    }
    return SUCCESS;
  }
  
  default event void PSSubscriptionAccess.createDone[uint16_t messageAccessID](
      ps_subscription_handle_t *handlePtr,
      ps_result_t result){}

  default event void PSSubscriptionAccess.cloneDone[uint16_t messageAccessID](
      const ps_subscription_handle_t originalHandle, 
      ps_subscription_handle_t *cloneHandlePtr, 
      ps_result_t result){}
   
  default event void PSNotificationAccess.createDone[uint16_t messageAccessID](
      ps_notification_handle_t *newHandle,
      ps_result_t result){}

  default event void PSNotificationAccess.cloneDone[uint16_t messageAccessID](
      ps_notification_handle_t originalHandle,
      ps_notification_handle_t *cloneHandle,
      ps_result_t result){}

  event result_t MemAlloc.reallocComplete(Handle handle, result_t success)
  {
    return SUCCESS;
  }

  event result_t MemAlloc.compactComplete()
  {
    return SUCCESS;
  }

                   /*** data access ***/

  ps_result_t getCount(ps_item_header_t *firstHeader, uint16_t dataLength, 
      uint8_t type, uint16_t *dest)
  {
    ps_item_header_t *header;
    int16_t count = 0, length = 0;
    header = firstHeader;
    while (length < dataLength){
      if (header->type == type)
        count++;
      length += header->totalLength;
      header = (ps_item_header_t*) ((uint8_t*) header + header->totalLength);
    }
    *dest = count;
    return SUCCESS;
  }
  
  ps_result_t getConstraint(ps_item_header_t *firstHeader, uint16_t dataLength,
                            ps_constraint_t **constraint,
                            uint16_t *valueLength,
                            uint16_t num)
  {
    ps_item_header_t *header;
    int16_t count = 0, length = 0;
    header = firstHeader;
    while (length < dataLength){
      if (header->type == PS_ITEM_TYPE_CONSTRAINT){
        if (count == num){
          *constraint = &(((ps_container_t *) header)->constraint);
          *valueLength = header->totalLength - (sizeof(ps_item_header_t) + sizeof(ps_constraint_t));
          return SUCCESS;
        }
        count++;
      }
      length += header->totalLength;
      header = (ps_item_header_t*) ((uint8_t*) header + header->totalLength);
    }
    return PS_FAIL_BOUNDS;
  }

  ps_result_t newConstraint(ps_item_header_t *firstHeader, 
      nx_uint8_t *dataLength,
      ps_constraint_t **constraint,
      uint8_t valueLength,
      uint16_t lengthLeft)
  {
    uint16_t lengthNeeded;
    ps_container_t *cContainer;
    
    lengthNeeded = valueLength + (sizeof(ps_item_header_t) + sizeof(ps_constraint_t));
    if (lengthLeft < lengthNeeded)
      return PS_FAIL_BOUNDS;
    cContainer = (ps_container_t*) ((uint8_t*) firstHeader + *dataLength);
    cContainer->header.type = PS_ITEM_TYPE_CONSTRAINT;
    cContainer->header.totalLength = lengthNeeded;
    *constraint = &cContainer->constraint;
    *dataLength = *dataLength + lengthNeeded;
    return SUCCESS;
  }


  ps_result_t getAVPair(ps_item_header_t *firstHeader, uint16_t dataLength,
                        ps_avpair_t **avpair,
                        uint16_t *valueLength,
                        uint16_t num)
  {
    ps_item_header_t *header;
    int16_t count = 0, length = 0;
    header = firstHeader;
    while (length < dataLength){
      if (header->type == PS_ITEM_TYPE_AVPAIR){
        if (count == num){
          *avpair = &(((ps_container_t *) header)->avpair);
          *valueLength = header->totalLength - (sizeof(ps_item_header_t) + sizeof(ps_avpair_t));
          return SUCCESS;
        }
        count++;
      }
      length += header->totalLength;
      header = (ps_item_header_t*) ((uint8_t*) header + header->totalLength);
    }
    return PS_FAIL_BOUNDS;
  }

  ps_result_t newAVPair(ps_item_header_t *firstHeader, 
      nx_uint8_t *dataLength,
      ps_avpair_t **avpair,
      uint8_t valueLength,
      uint16_t lengthLeft)
 {
    uint16_t lengthNeeded;
    ps_container_t *avpContainer;
    
    lengthNeeded = valueLength + (sizeof(ps_item_header_t) + sizeof(ps_avpair_t));
    if (lengthLeft < lengthNeeded)
      return PS_FAIL_BOUNDS;
    avpContainer = (ps_container_t*) ((uint8_t*) firstHeader + *dataLength);
    avpContainer->header.type = PS_ITEM_TYPE_AVPAIR;
    avpContainer->header.totalLength = lengthNeeded;
    *avpair = &avpContainer->avpair;
    *dataLength = *dataLength + lengthNeeded;
    return SUCCESS;
 }


                            /* PSSubscriptionAccess */
  
  ps_subscription_msg_t* getSubscriptionMsg(const ps_subscription_handle_t handle)
  {
    if ((*handle)->flags & MSG_TYPE_SUBSCRIPTION)
      return &(*handle)->subscriptionMsg;
    else if ((*handle)->flags & MSG_TYPE_TOSMSG)
      return (ps_subscription_msg_t*) ((const uint8_t*) &(*handle)->tosMsg
                                         + m_subscriptionMsgOffset);
    return 0;
  }

  uint16_t getSizeSubscriptionMsg(ps_subscription_msg_t *submsg)
  {
    uint16_t size = sizeof(ps_subscription_msg_t);
    size += submsg->dataLength;
    return size;
  }

  bool subscriptionMsgLocked(ps_subscription_handle_t handle)
  {
    ps_subscription_msg_t *subscriptionMsg;
    subscriptionMsg = getSubscriptionMsg(handle);
    if (subscriptionMsg->flags & MSG_FLAG_LOCK)
      return TRUE;
    else
      return FALSE;
  }

  command ps_result_t PSSubscriptionAccess.create[uint16_t messageAccessID](
      ps_subscription_handle_t *handlePtr)
  { 
    if (!getMemAllocLock(messageAccessID))
      return PS_FAIL_BUSY;
    m_requestType = SUBSCRIPTION_CREATE;
    if (call MemAlloc.allocate((HandlePtr) handlePtr, 
          sizeof(ps_subscription_msg_container_t)) == FAIL){
      releaseMemAllocLock();
      return PS_FAIL_ALLOC;
    }
    return SUCCESS; 
  }
  
  command ps_result_t PSSubscriptionAccess.free[uint16_t messageAccessID](
      ps_subscription_handle_t handle)
  {
    if (subscriptionMsgLocked(handle))
      return PS_FAIL_MSG_LOCK;
    if (call MemAlloc.free((Handle) handle) != SUCCESS)
      return PS_FAIL_ALLOC;
    else
      return SUCCESS;
  }

  command ps_result_t PSSubscriptionAccess.clone[uint16_t messageAccessID](
      const ps_subscription_handle_t originalHandle,
      ps_subscription_handle_t *cloneHandlePtr)
  { 
    uint16_t length;
    if (subscriptionMsgLocked(originalHandle))
      return PS_FAIL_MSG_LOCK;
    if (!getMemAllocLock(messageAccessID))
      return PS_FAIL_BUSY;
    length = sizeof(ps_subscription_msg_container_t);
    m_requestType = SUBSCRIPTION_CLONE_TOSMSG;
    if ((*originalHandle)->flags == MSG_TYPE_SUBSCRIPTION){
      length = length - sizeof(TOS_Msg) + sizeof(ps_subscription_msg_t);
      m_requestType = SUBSCRIPTION_CLONE_SUBMSG;
    }
    m_toBeClonedHandle = (const uint8_t*) *originalHandle;
    if (call MemAlloc.allocate((HandlePtr) cloneHandlePtr, length) == FAIL){
      releaseMemAllocLock();
      return PS_FAIL_ALLOC;
    }
    return SUCCESS; 
  }

  command ps_result_t PSSubscriptionAccess.reset[uint16_t messageAccessID]
      (ps_subscription_handle_t handle)
  {
    ps_subscription_msg_t *subscriptionMsg;
    if (subscriptionMsgLocked(handle))
      return PS_FAIL_MSG_LOCK;
    else {
      subscriptionMsg = getSubscriptionMsg(handle);
      subscriptionMsg->dataLength = 0;
    }
    return SUCCESS;
  }
  
  command ps_result_t PSSubscriptionAccess.getConstraintCount
    [uint16_t messageAccessID](const ps_subscription_handle_t handle, uint16_t *count)
  { 
    ps_subscription_msg_t *subscriptionMsg;
    if (subscriptionMsgLocked(handle))
      return PS_FAIL_MSG_LOCK;
    else {
      subscriptionMsg = getSubscriptionMsg(handle);
      return getCount((ps_item_header_t*) subscriptionMsg->data, subscriptionMsg->dataLength,
         PS_ITEM_TYPE_CONSTRAINT, count);
    }
  }

  command ps_result_t PSSubscriptionAccess.getConstraint[uint16_t messageAccessID](
      ps_subscription_handle_t handle,
      ps_constraint_t **constraint,
      uint16_t *valueLength, 
      uint16_t num)
  { 
    ps_subscription_msg_t *subscriptionMsg;
    if (subscriptionMsgLocked(handle))
      return PS_FAIL_MSG_LOCK;
    else {
      subscriptionMsg = getSubscriptionMsg(handle);
      return getConstraint((ps_item_header_t*) subscriptionMsg->data, 
          subscriptionMsg->dataLength, constraint, valueLength, num);
    }
  }
  
  command ps_result_t PSSubscriptionAccess.viewConstraint[uint16_t messageAccessID](
      const ps_subscription_handle_t handle,
      const ps_constraint_t **constraint,
      uint16_t *valueLength, 
      uint16_t num)
  { 
    return call PSSubscriptionAccess.getConstraint[messageAccessID](
      (ps_subscription_handle_t) handle, (ps_constraint_t **)constraint, valueLength, num);
  }

  command ps_result_t PSSubscriptionAccess.newConstraint[uint16_t messageAccessID](
      ps_subscription_handle_t handle,
      ps_constraint_t **constraint,
      uint8_t valueLength)
  { 
    ps_subscription_msg_t *subscriptionMsg;
    if (subscriptionMsgLocked(handle))
      return PS_FAIL_MSG_LOCK;
    else {
      subscriptionMsg = getSubscriptionMsg(handle);
      return newConstraint((ps_item_header_t*) subscriptionMsg->data, 
          &subscriptionMsg->dataLength, constraint, valueLength, 
          m_subscriptionMsgMaxLength - getSizeSubscriptionMsg(subscriptionMsg));
    }
  }

  command ps_result_t PSSubscriptionAccess.markUnsubscribe[uint16_t messageAccessID](
      ps_subscription_handle_t handle)
  { 
    ps_subscription_msg_t *subscriptionMsg;
    if (subscriptionMsgLocked(handle))
      return PS_FAIL_MSG_LOCK;
    subscriptionMsg = getSubscriptionMsg(handle);
    subscriptionMsg->flags |= MSG_FLAG_UNSUBSCRIBE;
    return SUCCESS;
  }

  command ps_result_t PSSubscriptionAccess.markSubscribe[uint16_t messageAccessID](
      ps_subscription_handle_t handle)
  { 
    ps_subscription_msg_t *subscriptionMsg;
    if (subscriptionMsgLocked(handle))
      return PS_FAIL_MSG_LOCK;
    subscriptionMsg = getSubscriptionMsg(handle);
    subscriptionMsg->flags &= ~MSG_FLAG_UNSUBSCRIBE;
    return SUCCESS;
  }

  command ps_result_t PSSubscriptionAccess.setID[uint16_t messageAccessID](
      ps_subscription_handle_t handle,
      ps_subscription_ID_t subscriptionID)
  { 
    ps_subscription_msg_t *subscriptionMsg;
    subscriptionMsg = getSubscriptionMsg(handle);
    subscriptionMsg->subscriptionID = subscriptionID;
    return SUCCESS;
  }
  
  command ps_result_t PSSubscriptionAccess.getInstructionCount[uint16_t messageAccessID](
      const ps_subscription_handle_t handle, 
      uint16_t* count)
  { 
    ps_subscription_msg_t *subscriptionMsg;
    if (subscriptionMsgLocked(handle))
      return PS_FAIL_MSG_LOCK;
    else {
      subscriptionMsg = getSubscriptionMsg(handle);
      return getCount((ps_item_header_t*) subscriptionMsg->data, subscriptionMsg->dataLength,
         PS_ITEM_TYPE_AVPAIR, count);
    }
  }

  command ps_result_t PSSubscriptionAccess.getInstruction[uint16_t messageAccessID](
      ps_subscription_handle_t handle, 
      ps_instruction_t **instruction,
      uint16_t *valueLength,
      uint16_t num)
  {
    ps_subscription_msg_t *subscriptionMsg;
    if (subscriptionMsgLocked(handle))
      return PS_FAIL_MSG_LOCK;
    else {
      subscriptionMsg = getSubscriptionMsg(handle);
      return getAVPair((ps_item_header_t*) subscriptionMsg->data, 
          subscriptionMsg->dataLength, instruction, valueLength, num);
    }
  }

  command ps_result_t PSSubscriptionAccess.viewInstruction[uint16_t messageAccessID](
      const ps_subscription_handle_t handle, 
      const ps_instruction_t **instruction,
      uint16_t *valueLength,
      uint16_t num)
  {
    return call PSSubscriptionAccess.getInstruction[messageAccessID](
      (ps_subscription_handle_t) handle, (ps_instruction_t **) instruction, valueLength, num);
  }

  command ps_result_t PSSubscriptionAccess.newInstruction[uint16_t messageAccessID](
      ps_subscription_handle_t handle,
      ps_instruction_t **instruction,
      uint16_t valueLength)
  {
    ps_subscription_msg_t *subscriptionMsg;
    if (subscriptionMsgLocked(handle))
      return PS_FAIL_MSG_LOCK;
    else {
      subscriptionMsg = getSubscriptionMsg(handle);
      return newAVPair((ps_item_header_t*) subscriptionMsg->data, 
          &subscriptionMsg->dataLength, instruction, valueLength, 
          m_subscriptionMsgMaxLength - getSizeSubscriptionMsg(subscriptionMsg));
    }
  }


                      /* PSNotificationAccess */
 
  inline ps_notification_msg_t* getNotificationMsg(const ps_notification_handle_t handle)
  {
    if ((*handle)->flags & MSG_TYPE_TOSMSG)
      return (ps_notification_msg_t*) ((uint8_t*) &(*handle)->tosMsg
                                         + m_notificationMsgOffset);
    else if ((*handle)->flags & MSG_TYPE_NOTIFICATION)
      return &(*handle)->notificationMsg;
    return 0;
  }

  uint16_t getSizeNotificationMsg(ps_notification_msg_t *msg)
  {
    uint16_t size = sizeof(ps_notification_msg_t);
    size += msg->dataLength;
    return size;
  }

  bool notificationMsgLocked(ps_notification_handle_t handle)
  {
    ps_notification_msg_t *notificationMsg;
    notificationMsg = getNotificationMsg(handle);
    if (notificationMsg->flags & MSG_FLAG_LOCK)
      return TRUE;
    else
      return FALSE;
  }
  
  command ps_result_t PSNotificationAccess.create[uint16_t messageAccessID](
      ps_notification_handle_t *handlePtr)
  { 
    if (!getMemAllocLock(messageAccessID))
      return PS_FAIL_BUSY;
    m_requestType = NOTIFICATION_CREATE;
    if (call MemAlloc.allocate((HandlePtr) handlePtr, 
          sizeof(ps_notification_msg_container_t)) == FAIL){
      releaseMemAllocLock();
      return PS_FAIL_ALLOC;
    }
    return SUCCESS; 
  }
  
  command ps_result_t PSNotificationAccess.free[uint16_t messageAccessID](
      ps_notification_handle_t handle)
  {  
    if (notificationMsgLocked(handle))
      return PS_FAIL_MSG_LOCK;
    if (call MemAlloc.free((Handle) handle) != SUCCESS)
      return PS_FAIL_ALLOC;
    else
      return SUCCESS;
  }
  
  command ps_result_t PSNotificationAccess.clone[uint16_t messageAccessID](
      const ps_notification_handle_t originalHandle,
      ps_notification_handle_t *cloneHandlePtr)
  { 
    uint16_t length;
    if (notificationMsgLocked(originalHandle))
      return PS_FAIL_MSG_LOCK;
    if (!getMemAllocLock(messageAccessID))
      return PS_FAIL_BUSY;
    length = sizeof(ps_notification_msg_container_t);
    m_requestType = NOTIFICATION_CLONE_TOSMSG;
    if ((*originalHandle)->flags == MSG_TYPE_NOTIFICATION){
      length = length - sizeof(TOS_Msg) + sizeof(ps_notification_msg_t);
      m_requestType = NOTIFICATION_CLONE_NOTFMSG;
    }
    m_toBeClonedHandle = (const uint8_t*) *originalHandle;
    if (call MemAlloc.allocate((HandlePtr) cloneHandlePtr, length) == FAIL){
      releaseMemAllocLock();
      return PS_FAIL_ALLOC;
    }
    return SUCCESS;
  }
  
  command ps_result_t PSNotificationAccess.reset[uint16_t messageAccessID]
    (ps_notification_handle_t handle)
  {
    ps_notification_msg_t *notificationMsg;
    if (notificationMsgLocked(handle))
      return PS_FAIL_MSG_LOCK;
    else {
      notificationMsg = getNotificationMsg(handle);
      notificationMsg->dataLength = 0;
    }
    return PS_SUCCESS;
  }
  
  command ps_result_t PSNotificationAccess.getAVPairCount[uint16_t messageAccessID](
      const ps_notification_handle_t handle, uint16_t *count)
  { 
    ps_notification_msg_t *notificationMsg;
    if (notificationMsgLocked(handle))
      return PS_FAIL_MSG_LOCK;
    else {
      notificationMsg = getNotificationMsg(handle);
      return getCount((ps_item_header_t*) notificationMsg->data, notificationMsg->dataLength,
         PS_ITEM_TYPE_AVPAIR, count);
    }
  }

  command ps_result_t PSNotificationAccess.getAVPair[uint16_t messageAccessID](
      ps_notification_handle_t handle, 
      ps_avpair_t **avpair,
      uint16_t *valueLength,
      uint16_t num)
  { 
    ps_notification_msg_t *notificationMsg;
    if (notificationMsgLocked(handle))
      return PS_FAIL_MSG_LOCK;
    else {
      notificationMsg = getNotificationMsg(handle);
      return getAVPair((ps_item_header_t*) notificationMsg->data, 
          notificationMsg->dataLength, avpair, valueLength, num);
    }
  }  
  
  command ps_result_t PSNotificationAccess.viewAVPair[uint16_t messageAccessID](
      const ps_notification_handle_t handle, 
      const ps_avpair_t **avpair,
      uint16_t *valueLength,
      uint16_t num)
  { 
    return call PSNotificationAccess.getAVPair[messageAccessID](
      (ps_notification_handle_t) handle, (ps_avpair_t **)avpair, valueLength, num);
  }

  command ps_result_t PSNotificationAccess.newAVPair[uint16_t messageAccessID](
      ps_notification_handle_t handle,
      ps_avpair_t **avpair,
      uint8_t valueLength)
  { 
    ps_notification_msg_t *notificationMsg;
    if (notificationMsgLocked(handle))
      return PS_FAIL_MSG_LOCK;
    else {
      notificationMsg = getNotificationMsg(handle);
      return newAVPair((ps_item_header_t*) notificationMsg->data, 
          &notificationMsg->dataLength, avpair, valueLength, 
          m_notificationMsgMaxLength - getSizeNotificationMsg(notificationMsg));
    }
  }


   
  command ps_result_t PSNotificationAccess.getRequestCount[uint16_t messageAccessID](
      const ps_notification_handle_t handle, 
      uint16_t* count)
  { 
    ps_notification_msg_t *notificationMsg;
    if (notificationMsgLocked(handle))
      return PS_FAIL_MSG_LOCK;
    else {
      notificationMsg = getNotificationMsg(handle);
      return getCount((ps_item_header_t*) notificationMsg->data, notificationMsg->dataLength,
         PS_ITEM_TYPE_CONSTRAINT, count);
    }
  }

  command ps_result_t PSNotificationAccess.getRequest[uint16_t messageAccessID](
      ps_notification_handle_t handle, 
      ps_request_t **request,
      uint16_t *valueLength,
      uint16_t num)
  { 
    ps_notification_msg_t *notificationMsg;
    if (notificationMsgLocked(handle))
      return PS_FAIL_MSG_LOCK;
    else {
      notificationMsg = getNotificationMsg(handle);
      return getConstraint((ps_item_header_t*) notificationMsg->data, 
          notificationMsg->dataLength, request, valueLength, num);
    }
  }

  command ps_result_t PSNotificationAccess.viewRequest[uint16_t messageAccessID](
      const ps_notification_handle_t handle, 
      const ps_request_t **request,
      uint16_t *valueLength,
      uint16_t num)
  { 
    return call PSNotificationAccess.getRequest[messageAccessID](
      (ps_notification_handle_t) handle, (ps_request_t **)request, valueLength, num);
  }

  command ps_result_t PSNotificationAccess.newRequest[uint16_t messageAccessID](
      ps_notification_handle_t handle,
      ps_request_t **request,
      uint16_t valueLength)
  { 
    ps_notification_msg_t *notificationMsg;
    if (notificationMsgLocked(handle))
      return PS_FAIL_MSG_LOCK;
    else {
      notificationMsg = getNotificationMsg(handle);
      return newConstraint((ps_item_header_t*) notificationMsg->data, 
          &notificationMsg->dataLength, request, valueLength, 
          m_notificationMsgMaxLength - getSizeNotificationMsg(notificationMsg));
    }
  }


                      /* PSMessageAccess */

  command void PSMessageAccess.setLockSubscription(ps_subscription_handle_t handle)
  {
    ps_subscription_msg_t *subscriptionMsg;
    subscriptionMsg = getSubscriptionMsg(handle);
    subscriptionMsg->flags |= MSG_FLAG_LOCK;
  }
  
  command void PSMessageAccess.clearLockSubscription(
      ps_subscription_handle_t handle)
  {
    ps_subscription_msg_t *subscriptionMsg;
    subscriptionMsg = getSubscriptionMsg(handle);
    subscriptionMsg->flags &= ~MSG_FLAG_LOCK;
  }
    
  command bool PSMessageAccess.isLockedSubscription(ps_subscription_handle_t handle)
  {
    return subscriptionMsgLocked(handle);
  }
  
  command void PSMessageAccess.setLockNotification(ps_notification_handle_t handle)
  {
    ps_notification_msg_t *notificationMsg;
    notificationMsg = getNotificationMsg(handle);
    notificationMsg->flags |= MSG_FLAG_LOCK;
  }

  command void PSMessageAccess.clearLockNotification(
      ps_notification_handle_t handle)
  {
    ps_notification_msg_t *notificationMsg;
    notificationMsg = getNotificationMsg(handle);
    notificationMsg->flags &= ~MSG_FLAG_LOCK;
  }

  command bool PSMessageAccess.isLockedNotification(ps_notification_handle_t handle)
  {
    return notificationMsgLocked(handle);
  }

  command ps_subscription_msg_t* PSMessageAccess.getSubscriptionMsg(
      const ps_subscription_handle_t handle)
  {
    return getSubscriptionMsg(handle);
  }
  
  command uint16_t PSMessageAccess.getSizeSubscriptionMsg(ps_subscription_msg_t *submsg)
  {
    return getSizeSubscriptionMsg(submsg);
  }
  
  command ps_notification_msg_t* PSMessageAccess.getNotificationMsg(
      const ps_notification_handle_t handle)
  {
    return getNotificationMsg(handle);
  }
  
  command uint16_t PSMessageAccess.getSizeNotificationMsg(ps_notification_msg_t *submsg)
  {
    return getSizeNotificationMsg(submsg);
  }
}
