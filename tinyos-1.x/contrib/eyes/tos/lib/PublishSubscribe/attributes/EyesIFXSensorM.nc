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
 * $Date: 2005/11/01 23:35:38 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
generic module EyesIFXSensorM(uint8_t channel)
{
  provides interface StdControl;
  provides interface PSValue;
  provides interface PSOperation;
  //uses interface AcquireData;
  uses interface MSP430ADC12Single;
} 
implementation {
  void *m_buffer;
  bool m_lock;
  norace uint16_t m_adcData;

  enum {
    // as defined in attributes.xml
    PS_OPR_EQUALS = 0,
    PS_OPR_SMALLER = 1,
    PS_OPR_SMALLER_EQUAL = 2,
    PS_OPR_GREATER = 3,
    PS_OPR_GREATER_EQUAL = 4,
    PS_OPR_ANY = 5,
  };

  bool getLock(void *buffer)
  {
    if (m_lock)
      return FALSE;
    else {
      m_buffer = buffer;
      m_lock = TRUE;
      return TRUE;
    }
  }

  void *releaseLock()
  {
    m_lock = FALSE;
    return m_buffer;
  }
  
  command result_t StdControl.init() {
    m_lock = FALSE;
    switch (channel)
    {
      case 0: call MSP430ADC12Single.bind(MSP430ADC12_EXTERNAL_TEMP_SETTINGS); break;
      case 2: call MSP430ADC12Single.bind(MSP430ADC12_PHOTO_SETTINGS); break;
      case 3: call MSP430ADC12Single.bind(MSP430ADC12_RSSI_SETTINGS); break;
      case 10: call MSP430ADC12Single.bind(MSP430ADC12_INTERNAL_TEMPERATURE); break;
      case 11: call MSP430ADC12Single.bind(MSP430ADC12_INTERNAL_VOLTAGE); break;
    }
    return SUCCESS;  
  }
  
  command result_t StdControl.stop() {
    if (channel == 0) {
      TOSH_CLR_TEMP_EN_PIN(); 
    } 
    return SUCCESS; 
  }

  command result_t StdControl.start() {
    if (channel == 0) {
      TOSH_SET_TEMP_EN_PIN(); 
    }
    return SUCCESS;
  }

  command ps_result_t PSValue.getValueSize(uint8_t *valueSize){
    *valueSize = 2; // msp430 adc resolution is 12 bit
    return PS_SUCCESS;
  }
  
  command ps_result_t PSValue.getValue(void *buffer){
    if (getLock(buffer)){
      if (call MSP430ADC12Single.getData() != SUCCESS){
        releaseLock();
        return PS_FAIL_BUSY;
      } else
        return PS_SUCCESS;
    } else
      return PS_FAIL_BUSY;
  }

  void task adcDataReady()
  {
    nx_uint16_t *buffer = (nx_uint16_t *) releaseLock();
    *buffer = m_adcData;
    signal PSValue.valueReady(PS_SUCCESS, (void *) buffer);
  }
    
  async event result_t MSP430ADC12Single.dataReady(uint16_t data)
  {
    m_adcData = data;
    post adcDataReady();
    return SUCCESS;
  }
  
  command bool PSOperation.isMatching(const void *value1, 
      const ps_opr_ID_t *operation, const void *value2)
  {
    switch(*operation)
    {
      case PS_OPR_EQUALS: return *((nx_uint16_t *) value1) == *((nx_uint16_t *) value2);
      case PS_OPR_SMALLER: return *((nx_uint16_t *) value1) < *((nx_uint16_t *) value2);
      case PS_OPR_SMALLER_EQUAL: return *((nx_uint16_t *) value1) <= *((nx_uint16_t *) value2);
      case PS_OPR_GREATER: return *((nx_uint16_t *) value1) > *((nx_uint16_t *) value2);
      case PS_OPR_GREATER_EQUAL: return *((nx_uint16_t *) value1) >= *((nx_uint16_t *) value2);
      case PS_OPR_ANY: return TRUE;
    }
    return FALSE;
  }
}

