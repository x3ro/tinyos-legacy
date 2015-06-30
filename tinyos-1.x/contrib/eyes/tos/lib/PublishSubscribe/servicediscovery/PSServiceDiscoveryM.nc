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
 * $Date: 2005/10/19 14:02:45 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
module PSServiceDiscoveryM
{
  provides {
    interface PSServiceDiscovery;
  }
  uses {
    interface PSSubscriptionListener as Listener;
    interface PSSubscriptionAccess;
  }
} 
implementation {
  ps_subscription_handle_t subscriptionHandleSD;
  
  enum {
    ATTRIBUTE_ID_ATTRIBUTE_LIST = 18, // see attributes.xml
  };
  
  event void Listener.receivedNew(const ps_subscription_handle_t handle)
  {
    uint16_t count = 0, i, valueLength;
    const ps_instruction_t *instruction;
    if (call PSSubscriptionAccess.getInstructionCount(handle, &count) == PS_SUCCESS && count)
      for (i=0; i<count; i++)
        if (call PSSubscriptionAccess.viewInstruction(
              handle, &instruction, &valueLength, i) == PS_SUCCESS && 
            instruction->attributeID == ATTRIBUTE_ID_ATTRIBUTE_LIST){
          subscriptionHandleSD = handle;
          signal PSServiceDiscovery.updated();
          break;
        }
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
    if (handle == subscriptionHandleSD)
      subscriptionHandleSD = 0;
  }

  command uint8_t PSServiceDiscovery.getAttributeList(ps_attr_ID_t **buffer)
  {
    uint16_t i, count = 0, valueLength = 0;
    const ps_instruction_t *instruction = 0;
     
    if (subscriptionHandleSD &&
        call PSSubscriptionAccess.getInstructionCount(subscriptionHandleSD, &count)
            == PS_SUCCESS && count)
      for (i=0; i<count; i++)
        if (call PSSubscriptionAccess.viewInstruction(
            subscriptionHandleSD, &instruction, &valueLength, i) == PS_SUCCESS && 
          instruction->attributeID == ATTRIBUTE_ID_ATTRIBUTE_LIST)
          break;
    if (instruction && instruction->attributeID == ATTRIBUTE_ID_ATTRIBUTE_LIST){
      *buffer = (ps_attr_ID_t *) instruction->value;
      return valueLength / sizeof(ps_attr_ID_t);
    } else { 
      *buffer = 0;
      return 0;
    }
  }
  
  event void PSSubscriptionAccess.createDone(ps_subscription_handle_t *handlePtr,
                        ps_result_t result){}
  event void PSSubscriptionAccess.cloneDone(
      const ps_subscription_handle_t originalHandle, 
      ps_subscription_handle_t *cloneHandlePtr, 
      ps_result_t result){}
}

