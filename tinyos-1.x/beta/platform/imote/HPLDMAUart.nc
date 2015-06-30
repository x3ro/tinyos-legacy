/*
 * Copyright (c) 2004, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
/*
 * The FlexUART interface is used to transmit and receive multiple bytes
 * at once.  This is more efficient that HPLUart when transfering larger 
 * data chunks.  Currently, the maximum allowed chunk is 32 bytes.
 * Note, this interface assumes that the bytes to be transmitted are 
 * stored in the TOSBuffer->UARTTxBuffer, and the received bytes are
 * stored in the TOSBuffer->UARTRxBuffer.
 */ 

interface HPLDMAUart {

  /*
   * Initialize the FlexUart component.
   * The baudrateClkDiv : this should be set to (921600 / baud rate).
   * RxBytes : set to the size of the receive fragment.  The receive
   * callback will be triggered once every RxBytes received.  The maximum
   * value for this parameter is currently set to 32
   */
  async command result_t init(uint8 baudrateClkDiv);

  async command result_t start(uint8 *newRxBuffer, uint16 newRxSize) ;
  
  async command result_t stop();

  /*
   * This command informs the FlexUart component to send NumBytes to the
   * Uart using the TxBuffer parameter as the source.  
   */
  async command result_t put(uint8 *TxBuffer, uint16 NumBytes) ;

  /*
   * This event is signaled to inform the application that NumBytes
   * have been received.  No assumptions can be made about the
   * contents of the RxBuffer once this event returns.  If the caller
   * wants to hold onto these bytes, it should save a copy of it
   */
  event uint8 *get(uint8 *data, uint16 NumBytes);

  /*
   * This event is signaled by the UART driver to indicate to the application
   * that the bytes have been sent out. 
   */
  event result_t putDone(uint8 *data);
}
