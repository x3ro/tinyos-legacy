/*
 * Copyright (c) 2004-2005, Technische Universitat Berlin
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
 * $Revision: 1.1.1.1 $
 * $Date: 2007/11/05 19:11:30 $
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
  MSP430REG_NORACE(ME2);
  MSP430REG_NORACE(IFG2);
  MSP430REG_NORACE(U1TCTL);
  MSP430REG_NORACE(U1TXBUF);

  uint16_t l_br;
  uint8_t l_mctl;
  uint8_t l_ssel;

  TOSH_SIGNAL(UART1RX_VECTOR) {
    uint8_t temp = U1RXBUF;
    signal USARTData.rxDone(temp);
  }
  
  TOSH_SIGNAL(UART1TX_VECTOR) {
    signal USARTData.txDone();
  }
 
  async command bool USARTControl.isSPI() {
    // SPI mode is TRUE if ...
    //   ME1.USPIE0 == 1
    //   U0CTL.I2C == 0
    //   U0CTL.SYNC == 1
    //   U0CTL.SWRST == 0
    atomic return (ME2 & USPIE1)
      && ((U1CTL & (I2C|SYNC|SWRST)) == SYNC);
  }
  
  async command bool USARTControl.isUART() {
    atomic return (ME2 & UTXE1) && (ME2 & URXE1)
      && TOSH_IS_URXD1_MODFUNC()
      && TOSH_IS_UTXD1_MODFUNC();
  }

  async command bool USARTControl.isUARTtx() {
    atomic return (ME2 & UTXE1)
      && TOSH_IS_UTXD1_MODFUNC()
      && TOSH_IS_URXD1_IOFUNC();
  }

  async command bool USARTControl.isUARTrx() {
    atomic return (ME2 & URXE1)
      && TOSH_IS_URXD1_MODFUNC()
      && TOSH_IS_UTXD1_IOFUNC();
  }  
    
  // i2c not supported on USART1
  async command bool USARTControl.isI2C() {
    return FALSE;
  }

  async command msp430_usartmode_t USARTControl.getMode() {
    if (call USARTControl.isUART())
      return USART_UART;
    else if (call USARTControl.isUARTrx())
      return USART_UART_RX;
    else if (call USARTControl.isUARTtx())
      return USART_UART_TX;
    else if (call USARTControl.isSPI())
      return USART_SPI;
    else if (call USARTControl.isI2C())
      return USART_I2C;
    else
      return USART_NONE;
  }

  /**
   * Sets the USART mode to one of the options from msp430_usartmode_t
   * defined in MSP430USART.h
   */
  async command void USARTControl.setMode(msp430_usartmode_t _mode) {
    switch (_mode) {
    case USART_UART:
      call USARTControl.setModeUART();
      break;
    case USART_UART_RX:
      call USARTControl.setModeUART_RX();
      break;
    case USART_UART_TX:
      call USARTControl.setModeUART_TX();
      break;
    case USART_SPI:
      call USARTControl.setModeSPI();
      break;
    default:
      break;
    }
  }

  // i2c is not available on USART1
  async command void USARTControl.setModeI2C() { }
    
  async command void USARTControl.enableUART() {
      TOSH_SEL_UTXD1_MODFUNC();
      TOSH_SEL_URXD1_MODFUNC();
      ME2 |= (UTXE1 | URXE1);   // USART1 UART module enable
  }
  
  async command void USARTControl.disableUART() {
      ME2 &= ~(UTXE1 | URXE1);   // USART1 UART module enable
      TOSH_SEL_UTXD1_IOFUNC();
      TOSH_SEL_URXD1_IOFUNC();
  }
  
  async command void USARTControl.enableUARTTx() {
      TOSH_SEL_UTXD1_MODFUNC();
      ME2 |= UTXE1;   // USART1 UART Tx module enable
  }

  async command void USARTControl.disableUARTTx() {
      ME2 &= ~UTXE1;   // USART1 UART Tx module enable
      TOSH_SEL_UTXD1_IOFUNC();
  }

  async command void USARTControl.enableUARTRx() {
      TOSH_SEL_URXD1_MODFUNC();
      ME2 |= URXE1;   // USART1 UART Rx module enable
  }

  async command void USARTControl.disableUARTRx() {
      ME2 &= ~URXE1;  // USART1 UART Rx module disable
      TOSH_SEL_URXD1_IOFUNC();
  }
  
  async command void USARTControl.enableSPI() {
      TOSH_SEL_SIMO1_MODFUNC();
      TOSH_SEL_SOMI1_MODFUNC();
      TOSH_SEL_UCLK1_MODFUNC();
      ME2 |= USPIE1;   // USART1 SPI module enable
  }
  
  async command void USARTControl.disableSPI() {
      ME2 &= ~USPIE1;   // USART1 SPI module disable
      TOSH_SEL_SIMO1_IOFUNC();
      TOSH_SEL_SOMI1_IOFUNC();
      TOSH_SEL_UCLK1_IOFUNC();
  }

  async command void USARTControl.enableI2C() { }
  async command void USARTControl.disableI2C() { }
 
  async command void USARTControl.setModeSPI() {
    atomic {
      // CSS, 27 Oct 2005:
      // Precisely follow the initialization procedure or we get observably
      // unpredictable behavior: first disable I2C if necessary then set SWRST.
      call USARTControl.disableI2C();
      U1CTL = SWRST;
      
      call USARTControl.disableUART();

      TOSH_SEL_SIMO1_MODFUNC();
      TOSH_SEL_SOMI1_MODFUNC();
      TOSH_SEL_UCLK1_MODFUNC();

      IE2 &= ~(UTXIE1 | URXIE1);  // interrupt disable    

      U1CTL |= SWRST;  
      U1CTL |= CHAR | SYNC | MM;  // 8-bit char, spi-mode, USART as master
      U1CTL &= ~(0x20); 

      U1TCTL = STC ;     // 3-pin
      U1TCTL |= CKPH;    // half-cycle delayed UCLK

      if (l_ssel & 0x80) {
        U1TCTL &= ~(SSEL_0 | SSEL_1 | SSEL_2 | SSEL_3);
        U1TCTL |= (l_ssel & 0x7F); 
      }
      else {
        U1TCTL &= ~(SSEL_0 | SSEL_1 | SSEL_2 | SSEL_3);
        U1TCTL |= SSEL_SMCLK; // use SMCLK, assuming 1MHz
      }

      if (l_br != 0) {
        U1BR0 = l_br & 0x0FF;
        U1BR1 = (l_br >> 8) & 0x0FF;
      }
      else {
        U1BR0 = 0x02;   // as fast as possible
        U1BR1 = 0x00;
      }
      U1MCTL = 0;

      ME2 &= ~(UTXE1 | URXE1); //USART UART module disable
      ME2 |= USPIE1;  // USART SPI module enable
      U1CTL &= ~SWRST;  

      IFG2 &= ~(UTXIFG1 | URXIFG1);
      IE2 &= ~(UTXIE1 | URXIE1);  // interrupt disabled    
    }
  }
  
  void setUARTModeCommon() {
    atomic {
      U1CTL = SWRST;  
      U1CTL |= CHAR;  // 8-bit char, UART-mode

      U1RCTL &= ~URXEIE;  // even erroneous characters trigger interrupts

      U1CTL = SWRST;
      U1CTL |= CHAR;  // 8-bit char, UART-mode

      if (l_ssel & 0x80) {
        U1TCTL &= ~(SSEL_0 | SSEL_1 | SSEL_2 | SSEL_3);
        U1TCTL |= (l_ssel & 0x7F); 
      }
      else {
        U1TCTL &= ~(SSEL_0 | SSEL_1 | SSEL_2 | SSEL_3);
        U1TCTL |= SSEL_ACLK; // use ACLK, assuming 32khz
      }

      if ((l_mctl != 0) || (l_br != 0)) {
        U1BR0 = l_br & 0x0FF;
        U1BR1 = (l_br >> 8) & 0x0FF;
        U1MCTL = l_mctl;
      }
      else {
        U1BR0 = 0x03;   // 9600 baud
        U1BR1 = 0x00;
        U1MCTL = 0x4A;
      }
      
      ME2 &= ~USPIE1;   // USART1 SPI module disable
      ME2 |= (UTXE1 | URXE1);   // USART1 UART module enable
      
      U1CTL &= ~SWRST;

      IFG2 &= ~(UTXIFG1 | URXIFG1);
      IE2 &= ~(UTXIE1 | URXIE1);  // interrupt disabled
    }
  }
  
  async command void USARTControl.setModeUART_TX() {
    atomic {   
      // CSS, 27 Oct 2005:
      // Precisely follow the initialization procedure or we get observably
      // unpredictable behavior: first disable I2C if necessary then set SWRST.
      call USARTControl.disableI2C();
      U1CTL = SWRST;

      call USARTControl.disableSPI();
      call USARTControl.disableUART();

      TOSH_SEL_UTXD1_MODFUNC();     
      TOSH_SEL_URXD1_IOFUNC();        

      setUARTModeCommon();
    }
  }
  
  async command void USARTControl.setModeUART_RX() {
    atomic {
      // CSS, 27 Oct 2005:
      // Precisely follow the initialization procedure or we get observably
      // unpredictable behavior: first disable I2C if necessary then set SWRST.
      call USARTControl.disableI2C();
      U1CTL = SWRST;

      call USARTControl.disableSPI();
      call USARTControl.disableUART();

      TOSH_SEL_URXD1_MODFUNC();     
      TOSH_SEL_UTXD1_IOFUNC();        

      setUARTModeCommon();
    }
  }
 
  async command void USARTControl.setModeUART() {
    atomic {
      // CSS, 27 Oct 2005:
      // Precisely follow the initialization procedure or we get observably
      // unpredictable behavior: first disable I2C if necessary then set SWRST.
      call USARTControl.disableI2C();
      U1CTL = SWRST;

      call USARTControl.disableSPI();
      call USARTControl.disableUART();

      TOSH_SEL_UTXD1_MODFUNC();     
      TOSH_SEL_URXD1_MODFUNC();        

      setUARTModeCommon();
    }
  }

  async command void USARTControl.setClockSource(uint8_t source) {
      atomic {
        l_ssel = source | 0x80;
        U1TCTL &= ~(SSEL_0 | SSEL_1 | SSEL_2 | SSEL_3);
        U1TCTL |= (l_ssel & 0x7F); 
      }
  }

  async command void USARTControl.setClockRate(uint16_t baudrate, uint8_t mctl) {
    atomic {
      l_br = baudrate;
      l_mctl = mctl;
      U1BR0 = baudrate & 0x0FF;
      U1BR1 = (baudrate >> 8) & 0x0FF;
      U1MCTL = mctl;
    }
  }

  async command result_t USARTControl.isTxIntrPending(){
    if (IFG2 & UTXIFG1){
      IFG2 &= ~UTXIFG1;
      return SUCCESS;
    }
    return FAIL;
  }

  async command result_t USARTControl.isTxEmpty(){
    if (U1TCTL & TXEPT) {
      return SUCCESS;
    }
    return FAIL;
  }

  async command result_t USARTControl.isRxIntrPending(){
    if (IFG2 & URXIFG1){
      IFG2 &= ~URXIFG1;
      return SUCCESS;
    }
    return FAIL;
  }

  async command result_t USARTControl.disableRxIntr(){
    atomic IE2 &= ~URXIE1;    
    return SUCCESS;
  }

  async command result_t USARTControl.disableTxIntr(){
    atomic IE2 &= ~UTXIE1;  
    return SUCCESS;
  }

  async command result_t USARTControl.enableRxIntr(){
    atomic {
      IFG2 &= ~URXIFG1;
      IE2 |= URXIE1;
    }
    return SUCCESS;
  }

  async command result_t USARTControl.enableTxIntr(){
    atomic {
      IFG2 &= ~UTXIFG1;
      IE2 |= UTXIE1;
    }
    return SUCCESS;
  }
  
  async command result_t USARTControl.tx(uint8_t data){
    atomic {
      U1TXBUF = data;
    }
    return SUCCESS;
  }
  
  async command uint8_t USARTControl.rx(){
    uint8_t value;
    atomic {
      value = U1RXBUF;
    }
    return value;
  }

  default async event result_t USARTData.txDone() { return SUCCESS; }

  default async event result_t USARTData.rxDone(uint8_t data) { return SUCCESS; }
}
