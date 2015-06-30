/*
 * Copyright (c) 2004-2005, Technische Universitaet Berlin
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
 */

/**
 * Byte-level interface to control a USART.
 * <p>The USART can be switched to SPI- or UART-mode. The interface follows
 * the convention of being stateless, thus a higher layer has to maintain
 * state information. I.e. calling <code>tx</done> will transmit a byte of
 * data in the mode (SPI or UART) the USART has been set to before.
 *
 * @author Vlado Handziski (handzisk@tkn.tu-berlin.de)
 * @author Jan Hauer (hauer@tkn.tu-berlin.de)
 * @author Joe Polastre
 * @version $Revision: 1.1 $ $Date: 2009/10/13 10:19:26 $
 */

#include "msp430usart.h"

interface HplMsp430UsciSpi {
  
  async command void resetUsart(bool reset);
  
  /**
   * Switches USART to Spi mode.
   */
  async command void setModeSpi(msp430_spi_union_config_t* config);
  
  async command void disableSpi();
  async command void enableSpi();
  
  /* Dis/enabling of UTXIFG / URXIFG */
  async command void disableRxIntr();
  async command void disableTxIntr();
  async command void disableIntr();
  async command void enableRxIntr();
  async command void enableTxIntr();
  async command void enableIntr();
  
  /**
   * TRUE if TX interrupt pending, flag must be cleared explicitly
   */
  async command bool isTxIntrPending();
  
  /**
   * TRUE if RX interrupt pending, flag must be cleared explicitly
   */
  async command bool isRxIntrPending();
  
  /**
   * Clears RX interrupt pending flag
   */
  async command void clrRxIntr();
  
  /**
   * Clears TX interrupt pending flag
   */
  async command void clrTxIntr();

  /**
   * Clears both TX and RX interrupt pending flags
   */
  async command void clrIntr();

  /**
   * SUCCESS if the TX buffer is empty and all of the bits have been
   * shifted out
   */
  async command bool isTxEmpty();
  
  /**
   * Transmit a byte of data. When the transmission is completed,
   * <code>txDone</done> is generated. Only then a new byte may be
   * transmitted, otherwise the previous byte will be overwritten.
   * The mode of transmission (Uart or Spi) depends on the current
   * state of the USART, which must be managed by a higher layer.
   *
   * @return SUCCESS always.
   */
  async command void tx(uint8_t data);
  
  /**
   * Get current value from RX-buffer.
   *
   * @return SUCCESS always.
   */
  async command uint8_t rx();

}
