/* 
 * Copyright (c) 2005, Ecole Polytechnique Federale de Lausanne (EPFL)
 * and Shockfish SA, Switzerland.
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
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   and Shockfish SA, nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
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
 * ========================================================================
 */
/*
 * Implementation of the HPLXE1205 HPL layer interface for XE1205 driver.
 * 
 * @author Remy Blank
 * @author Henri Dubois-Ferriere
 *
 */

/**
 */

includes XE1205Const;


module HPLXE1205M {
  provides {
    interface StdControl;
    interface HPLXE1205;
  }
  uses {
    interface StdControl as BusStdControl;  
    interface BusArbitration;
    interface HPLUSARTControl as USART;
  }
}


implementation {
  enum {
    byteShiftTime = 22
  };

  bool haveBus;

  async command result_t HPLXE1205.getBus() {
    uint8_t ret=SUCCESS;
    
    atomic {
      if (!haveBus) {
	if (call BusArbitration.getBus() == SUCCESS) {
	  haveBus = TRUE;
	  ret= SUCCESS;
	} 
	else ret=FAIL;
      }
    }

    return ret;
  }

  async command result_t HPLXE1205.releaseBus() {
    atomic {
      if (haveBus) {
	call BusArbitration.releaseBus();
	haveBus = FALSE;
      }
    }

    return SUCCESS;
  }

  event result_t BusArbitration.busFree() {
    return SUCCESS;
  }


  command result_t StdControl.init()
  {
    uint8_t result;
  
    TOSH_SET_NSS_DATA_PIN();
    TOSH_SET_NSS_CONFIG_PIN();
    TOSH_CLR_SW_RX_PIN();
    TOSH_CLR_SW_TX_PIN();
    TOSH_CLR_SW0_PIN();
    TOSH_CLR_SW1_PIN();

    call USART.setModeSPI();
    result = call USART.disableRxIntr();
    result = rcombine(result,call USART.disableTxIntr());
    result = rcombine(result,call BusStdControl.init());
      
    atomic haveBus = FALSE;
      
    return result;
  } 

  command result_t StdControl.start()
  {
    uint8_t result;
  
    TOSH_SET_NSS_DATA_PIN();
    TOSH_SET_NSS_CONFIG_PIN();
    TOSH_CLR_SW_RX_PIN();
    TOSH_CLR_SW_TX_PIN();
    TOSH_CLR_SW0_PIN();
    TOSH_CLR_SW1_PIN();

    call USART.setModeSPI();
    result = call USART.disableRxIntr();
    result = rcombine(result,call USART.disableTxIntr());
    result = rcombine(result,call BusStdControl.start());

    return result;
  }

  command result_t StdControl.stop()
  { 
    call USART.disableSPI();
    return SUCCESS;
  }

  void sendBuffer(uint8_t const* buffer_, int size_)
  {
    call USART.isTxIntrPending();
    call USART.rx();
    while(size_ > 0) {
      call USART.tx(*buffer_);
      ++buffer_;
      --size_;
      TOSH_uwait(byteShiftTime);
      call USART.rx();
    }
  }

  async command result_t HPLXE1205.writeConfig(uint8_t const* buffer_, int size_)
  {
    if (call HPLXE1205.getBus() == SUCCESS) {
      TOSH_CLR_NSS_CONFIG_PIN();
      sendBuffer(buffer_, size_);
      TOSH_SET_NSS_CONFIG_PIN();
      call HPLXE1205.releaseBus();
      return SUCCESS;
    }
    return FAIL;
  }

  async command result_t HPLXE1205.writeConfig_havebus(uint8_t const* buffer_, int size_)
  {
      TOSH_CLR_NSS_CONFIG_PIN();
      sendBuffer(buffer_, size_);
      TOSH_SET_NSS_CONFIG_PIN();
      return SUCCESS;
  }	
  async command result_t HPLXE1205.writeData(uint8_t const* buffer_, int size_)
  {
      TOSH_CLR_NSS_DATA_PIN();
      sendBuffer(buffer_, size_);
      TOSH_SET_NSS_DATA_PIN();
      return SUCCESS;
  }
	
  async command result_t HPLXE1205.readConfig_havebus(uint8_t* buffer_, int size_)
  {
      TOSH_CLR_NSS_CONFIG_PIN();
      call USART.isTxIntrPending();
      call USART.rx();

      call USART.tx(*buffer_);
      TOSH_uwait(byteShiftTime);
      call USART.rx();
      while(size_ > 0) {
	call USART.tx((size_ > 1)? *(buffer_ + 1): 0);
	TOSH_uwait(byteShiftTime);
	*buffer_ = call USART.rx();
	++buffer_;
	--size_;
      }
      TOSH_SET_NSS_CONFIG_PIN();
      return SUCCESS;
  }

  async command result_t HPLXE1205.readConfig(uint8_t* buffer_, int size_)
  {
    if (call HPLXE1205.getBus() == SUCCESS) {

      TOSH_CLR_NSS_CONFIG_PIN();
      call USART.isTxIntrPending();
      call USART.rx();

      call USART.tx(*buffer_);
      TOSH_uwait(byteShiftTime);
      call USART.rx();
      while(size_ > 0) {
	call USART.tx((size_ > 1)? *(buffer_ + 1): 0);
	TOSH_uwait(byteShiftTime);
	*buffer_ = call USART.rx();
	++buffer_;
	--size_;
      }
      TOSH_SET_NSS_CONFIG_PIN();
      call HPLXE1205.releaseBus();
      return SUCCESS;
    }
    return FAIL;
  }

  async command result_t HPLXE1205.readData(uint8_t* buffer_, int size_)
  {
      call USART.isTxIntrPending();
      call USART.rx();
      
      while(size_ > 0) {
	  TOSH_CLR_NSS_DATA_PIN();
	  call USART.tx(0);
	  TOSH_uwait(byteShiftTime);
	  *buffer_ = call USART.rx();
	  TOSH_SET_NSS_DATA_PIN();
	  ++buffer_;
	  --size_;
      }
      
      return SUCCESS;
  }

  async command uint8_t HPLXE1205.readByteFast()
  {
    uint8_t b;

    TOSH_CLR_NSS_DATA_PIN();
    call USART.isTxIntrPending();
    call USART.rx();

    call USART.tx(0);
    TOSH_uwait(byteShiftTime);
    b = call USART.rx();
    TOSH_SET_NSS_DATA_PIN();
    return b;
  }
}
