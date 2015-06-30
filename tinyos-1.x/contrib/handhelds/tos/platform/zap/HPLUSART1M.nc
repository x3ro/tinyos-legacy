/*
 * Copyright (c) 2004, Technische Universitat Berlin
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
 * - Neither the name of the Technische Universitat Berlin nor the names 
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
 * - Description ----------------------------------------------------------
 * Implementation of USART0 lowlevel functionality - stateless.
 * Setting a mode will by default disable USART-Interrupts.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2005/07/29 18:29:30 $
 * @author: Jan Hauer (hauer@tkn.tu-berlin.de)
 * @author: Joe Polastre
 * ========================================================================
 */

module HPLUSART1M {
  provides interface HPLUSARTControl as USARTControl;
  provides interface HPLUSARTFeedback as USARTData;
}
implementation
{
  C55xxREG_NORACE(ME2);
  C55xxREG_NORACE(IFG2);
  C55xxREG_NORACE(U1TCTL);

  uint16_t l_br;
  uint8_t l_mctl;
  uint8_t l_ssel;

//  TOSH_SIGNAL(UART1RX_VECTOR) {
    // signal USARTData.rxDone(temp);
//  }
  
//  TOSH_SIGNAL(UART1TX_VECTOR) {
//    signal USARTData.txDone();
//  }
 
  async command void USARTControl.enableUART() {
  }
  
  async command void USARTControl.disableUART() {
  }
  
  async command void USARTControl.enableUARTTx() {
  }

  async command void USARTControl.disableUARTTx() {
  }

  async command void USARTControl.enableUARTRx() {
  }

  async command void USARTControl.disableUARTRx() {
  }
  
  async command void USARTControl.enableSPI() {
  }
  
  async command void USARTControl.disableSPI() {
  }
 
  async command void USARTControl.setModeSPI() {
    atomic {
    }
    return;
  }
  
  void setUARTModeCommon() {
    atomic {
    }
    return;
  }
  
  async command void USARTControl.setModeUART_TX() {
    atomic {
    }
    setUARTModeCommon();
    return;
  }
  
  async command void USARTControl.setModeUART_RX() {
    atomic {
    }
    setUARTModeCommon();
    return;
  }
 
  async command void USARTControl.setModeUART() {
    atomic {
      setUARTModeCommon();
    }
    return;
  }

  async command void USARTControl.setClockSource(uint8_t source) {
      atomic {
        l_ssel = source | 0x80;
      }
  }

  async command void USARTControl.setClockRate(uint16_t baudrate, uint8_t mctl) {
    atomic {
      l_br = baudrate;
      l_mctl = mctl;
    }
  }

  async command result_t USARTControl.isTxIntrPending(){
    return FAIL;
  }

  async command result_t USARTControl.isTxEmpty(){
    return FAIL;
  }

  async command result_t USARTControl.isRxIntrPending(){
    return FAIL;
  }

  async command result_t USARTControl.disableRxIntr(){
    return SUCCESS;
  }

  async command result_t USARTControl.disableTxIntr(){
    return SUCCESS;
  }

  async command result_t USARTControl.enableRxIntr(){
    return SUCCESS;
  }

  async command result_t USARTControl.enableTxIntr(){
    return SUCCESS;
  }
  
  async command result_t USARTControl.tx(uint8_t data){
    return SUCCESS;
  }
  
  async command uint8_t USARTControl.rx(){
    uint8_t value = 0;
    return value;
  }

  default async event result_t USARTData.txDone() { return SUCCESS; }

  default async event result_t USARTData.rxDone(uint8_t data) { return SUCCESS; }
}
