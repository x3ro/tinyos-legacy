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
generic module PSLocalAttributesM(uint8_t numAttrib, uint16_t lastID)
{
  provides {
    interface StdControl;
    interface PSValue;
    interface PSOperation;
  }
  uses {
    interface PSValue as PSValueQuery[uint16_t attrID];
  }
} 
implementation {
  enum {
    // must be >= biggest possible attribute ID (check attributes.xml)
    MAX_VALID_ATTRIB_ID = lastID,  
    ATTRIBUTE_ID_ATTRIBUTE_LIST = 18, // see attributes.xml
    REGISTERED_ATTR_CACHE_SIZE = numAttrib,  
  };
  
  uint8_t m_numRegisteredAttributes;
  ps_attr_ID_t m_registeredAttributes[REGISTERED_ATTR_CACHE_SIZE];
  
  command result_t StdControl.init() {
    return SUCCESS;  
  }
  
  command result_t StdControl.stop() { 
    return SUCCESS; 
  }

  command result_t StdControl.start() {
    uint16_t i;
    uint8_t dummy;
    m_numRegisteredAttributes = 0;
    for (i=0; i<=MAX_VALID_ATTRIB_ID; i++) 
      if (call PSValueQuery.getValueSize[i](&dummy) == PS_SUCCESS){
        if (m_numRegisteredAttributes < REGISTERED_ATTR_CACHE_SIZE)
          m_registeredAttributes[m_numRegisteredAttributes] = i;
        m_numRegisteredAttributes++;
      }
    return SUCCESS;
  }
  
  command ps_result_t PSValue.getValueSize(uint8_t *valueSize)
  {
    *valueSize = m_numRegisteredAttributes * sizeof(ps_attr_ID_t);
    return PS_SUCCESS;
  }

  command ps_result_t PSValue.getValue(void *buffer)
  {
    memcpy(buffer, m_registeredAttributes, m_numRegisteredAttributes * sizeof(ps_attr_ID_t));
    signal PSValue.valueReady(PS_SUCCESS, buffer);
    return PS_SUCCESS;
  }
  
  command bool PSOperation.isMatching(const void *value1, 
      const ps_opr_ID_t *operation, const void *value2)
  {
    return TRUE;
  }
  
  default command ps_result_t PSValueQuery.getValueSize[uint16_t attrID](uint8_t *valueSize)
  {
    *valueSize = 0;
    return PS_FAIL;
  }

  event void PSValueQuery.valueReady[uint16_t attrID](
    ps_result_t result, void *buffer) { }
}

