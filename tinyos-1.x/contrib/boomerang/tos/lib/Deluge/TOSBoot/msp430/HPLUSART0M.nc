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
 * $Date: 2007/11/05 19:11:27 $
 * @author: Jan Hauer (hauer@tkn.tu-berlin.de)
 * @author: Joe Polastre
 * ========================================================================
 */

module HPLUSART0M {
  provides interface StdControl;
  provides interface HPLUSARTControl as USARTControl;
}
implementation
{
  MSP430REG_NORACE(IE1);
  MSP430REG_NORACE(ME1);
  MSP430REG_NORACE(IFG1);
  MSP430REG_NORACE(U0TCTL);
  MSP430REG_NORACE(U0TXBUF);
  MSP430REG_NORACE(U1TXBUF);

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {

    TOSH_MAKE_SIMO0_INPUT();
    TOSH_MAKE_UCLK0_INPUT();

    TOSH_SEL_SIMO0_MODFUNC();
    TOSH_SEL_SOMI0_MODFUNC();
    TOSH_SEL_UCLK0_MODFUNC();

    return SUCCESS;
  }

  command result_t StdControl.stop() {

    TOSH_SEL_SIMO0_IOFUNC();
    TOSH_SEL_SOMI0_IOFUNC();
    TOSH_SEL_UCLK0_IOFUNC();

    return SUCCESS;
  }

  bool isSPI() {
    // SPI mode is TRUE if ...
    //   ME1.USPIE0 == 1
    //   U0CTL.I2C == 0
    //   U0CTL.SYNC == 1
    //   U0CTL.SWRST == 0
    return (ME1 & USPIE0)
      && ((U0CTL & (I2C|SYNC|SWRST)) == SYNC);
  }
  
  bool isI2C() {
#ifdef __msp430_have_usart0_with_i2c
    return ((U0CTL & (I2C|SYNC|I2CEN)) == (I2C|SYNC|I2CEN));
#else
    return FALSE;
#endif
  }

  command void USARTControl.disableSPI() {
    ME1 &= ~USPIE0;   // USART0 SPI module disable

    // set to PUC values
    //ME1 = 0;
    //U0CTL = 1;
    //U0TCTL = 1;
    //U0RCTL = 0;
  }

  command void USARTControl.disableI2C() {
#ifdef __msp430_have_usart0_with_i2c
    if (isI2C())
      U0CTL &= ~(I2C | I2CEN | SYNC);
#endif
  }

  command void USARTControl.setModeSPI() {
    // CSS, 27 Oct 2005:
    // Precisely follow the initialization procedure or we get observably
    // unpredictable behavior: first disable I2C if necessary then set SWRST.
    call USARTControl.disableI2C();
    U0CTL = SWRST;
      
    //call USARTControl.disableUART();

    //IE1 &= ~(UTXIE0 | URXIE0);  // interrupt disable    

    U0CTL |= CHAR | SYNC | MM;  // 8-bit char, SPI-mode, USART as master
    //U0CTL &= ~(0x20); 

    U0TCTL |= STC | CKPH | SSEL_SMCLK; // 3-pin, half-cycle delayed UCLK

    U0BR0 = 0x02;   // as fast as possible
    U0BR1 = 0x00;

    U0MCTL = 0;

    //ME1 &= ~(UTXE0 | URXE0); //USART UART module disable
    ME1 |= USPIE0;   // USART SPI module enable
    U0CTL &= ~SWRST;  

    //IFG1 = 0; //XXX
  }
  
  // i2c enable bit is not set by default
  command void USARTControl.setModeI2C() {
#ifdef __msp430_have_usart0_with_i2c
    {
      // CSS, 27 Oct 2005:
      // Precisely follow the initialization procedure or we get observably
      // unpredictable behavior: first disable I2C if necessary, then set SWRST,
      // then set SYNC and I2C, then clear I2CEN (which is the SWRST bit).
      call USARTControl.disableI2C();
      U0CTL = SWRST;
      U0CTL |= SYNC | I2C;  // 7-bit addr, I2C-mode, USART as master
      U0CTL &= ~I2CEN; //configure I2C with the module disabled

      //call USARTControl.disableUART();
      //call USARTControl.disableSPI();

      //IE1 &= ~(UTXIE0 | URXIE0);  // interrupt disable    

      U0CTL |= MST;

      I2CTCTL = I2CSSEL_2 | I2CTRX; // use 1MHz SMCLK as the I2C reference

      //I2CPSC = 0x00;              // I2C CLK runs at 1MHz/10 = 100kHz
      //I2CSCLH = 0x03;
      //I2CSCLL = 0x03;
      
      //I2CIE = 0;                 // clear all I2C interrupt enables
      //I2CIFG = 0;                // clear all I2C interrupt flags

      U0CTL |= I2CEN; //enable I2C now that it is configured
    }
#endif
  }
 
  command result_t USARTControl.isTxIntrPending(){
    if (IFG1 & UTXIFG0){
      IFG1 &= ~UTXIFG0;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t USARTControl.isTxEmpty(){
    if (U0TCTL & TXEPT) {
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t USARTControl.isRxIntrPending(){
    if (IFG1 & URXIFG0){
      IFG1 &= ~URXIFG0;
      return SUCCESS;
    }
    return FAIL;
  }

  command void USARTControl.tx(uint8_t data){
    U0TXBUF = data;
  }
  
  command uint8_t USARTControl.rx(){
    return U0RXBUF;
  }
}

