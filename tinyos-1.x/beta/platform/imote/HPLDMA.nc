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
 * The HPLDMA interface is intended to provide the functionality of a DMA 
 * controller on both the send and receive sides of a transaction. In order
 * to provide this functionality, the interface provide 2 commands and 2 
 * events.  Because the DMA interface is intended to supplement a standard
 * byte based interface, there is no init, start, or stop.  Instead
 * either of the 2 commands may return fail if for some reason there is
 * something wrong with port when the command is issued
 */ 

interface HPLDMA {

  /*
   * Begin a DMAGet (receive).  The parameters should be the initial buffer
   * to place data into and the inital number of bytes.  DMA receive chaining
   * may be accomplished by returning a new buffer in the associated DMAGetDone
   * event
   */
  async command result_t DMAGet(uint8 *RxBuffer, uint16 NumBytes) ;
  
  /*
   * This command informs the FlexUart component to send NumBytes to the
   * Uart using the TxBuffer parameter as the source.  
   */
  async command result_t DMAPut(uint8 *TxBuffer, uint16 NumBytes) ;

  /*
   * This event is signaled to inform the application that NumBytes
   * have been received.  No assumptions can be made about the
   * contents of the RxBuffer once this event returns.  If the caller
   * wants to hold onto these bytes, it should save a copy of it.  To
   * chain receives OF THE SAME LENGTH together, return a new buffer from this 
   * event. If a new transaction of a different length is required or if
   * the application is done receiving data, return NULL and trigger the new
   * transaction from outside this event.  If for some reason
   * the hardware was unable to capture NumBytes of contiguous data without
   * an overrun condition occuring, the event will be signaled with NumBytes 0.
   * In this case, the data pointer will be valid so as to allow the application
   * to free the memory associated with the original get request.
   * 
   */
  async event uint8 *DMAGetDone(uint8 *data, uint16 NumBytes);

  /*
   * This event is signaled by the UART driver to indicate to the application
   * that the bytes have been sent out. 
   */
  async event result_t DMAPutDone(uint8 *data);
}
