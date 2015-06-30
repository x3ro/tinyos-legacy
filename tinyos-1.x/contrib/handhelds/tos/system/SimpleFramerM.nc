/*
 * Copyright (c) 2004,2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Authors:  Andrew Christian
 *           16 November 2004
 *
 * 
 * SimpleFramerM
 *
 * This module provides framing for UART communications using a simpler
 * framing syntax than that included in "FramerM.nc".
 *
 * Protocol:
 * 
 *  - Each packet has the form:
 *         FRAME
 *         Data (n bytes, where n < 127)
 *         FRAME
 *
 *  - Data packets values of FRAME and CE are escaped by being
 *    replaced by CE, x ^ 0x20.
 * 
 *         FRAME = 0x7e
 *         CE    = 0x7D
 * 
 *  Packets that don't match the protocol are silently dropped.
 * 
 */

/**
 * A simple framing protocol for UART transactions.
 *
 * @author Andrew Christian 
 */

includes Message;

module SimpleFramerM {

  provides {
    interface StdControl;
    interface Message;
  }

  uses {
    interface HPLUART;
    interface MessagePool;
  }
}

implementation {
  
  enum {
    FRAME_BYTE     = 0x7e,
    ESCAPE_BYTE    = 0x7d
  };
  
  enum {
    RXSTATE_INIT,   // Waiting for a FRAME byte to mark an incoming packet
    RXSTATE_FIRST_BYTE,
    RXSTATE_DATA,   // Reading data into RxBuffer
    RXSTATE_TOKEN   // Just past an escape character, reading more data
  };
  
  enum {
    TXSTATE_IDLE,
    TXSTATE_DATA,
    TXSTATE_TOKEN,
    TXSTATE_EOF
  };

  norace struct Message *g_Active;   // Current buffer being filled
  norace struct Message *g_Full;     // Full buffers being processed elsewhere
  norace uint8_t         g_RxState;

  norace struct Message *g_TxQueue;
  norace uint8_t         g_TxState;
  uint8_t                g_TxIndex;


  /****************************************/

  command result_t StdControl.init() {
    g_Active  = NULL;
    g_Full    = NULL;
    g_RxState = RXSTATE_INIT;

    g_TxQueue = NULL;
    g_TxState = TXSTATE_IDLE;


    call MessagePool.init();
    return call HPLUART.init();
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return call HPLUART.stop();
  }

  /**
   * A complete buffer of data has been received from the UART/serial port.
   * Pass this off to other components that are waiting for this data.
   */

  task void PacketReceived() {
    struct Message *msg;
    atomic msg = pop_queue( &g_Full );

    while (msg) {
      signal Message.receive(msg);
      atomic msg = pop_queue( &g_Full );
    }
  }

  /**
   * Process a byte read from the UART or serial port.
   * 
   * We strip the FRAME and ESCAPE bytes and stuff everything
   * into one of two buffers.  Messages that are too long are silently
   * dropped.
   */

  async event result_t HPLUART.get( uint8_t data )  {
    switch (g_RxState) {

    case RXSTATE_INIT:        // Waiting for a FRAME byte
      if (data == FRAME_BYTE) 
	g_RxState = RXSTATE_FIRST_BYTE;
      else 
	dbg(DBG_USR1, "Dropping byte; synchronizing\n");
      break;

    case RXSTATE_FIRST_BYTE:  // No g_Active assigned yet
      if ( data == FRAME_BYTE )
	return SUCCESS;         // Do nothing...

      g_Active = call MessagePool.alloc();
      if ( g_Active == NULL ) {
	dbg(DBG_USR1, "No rx buffer available\n");
	g_RxState = RXSTATE_INIT;
	return SUCCESS;
      }

      g_RxState = RXSTATE_DATA;
      // Deliberate fall through
      
    case RXSTATE_DATA:  // Guaranteed to have a real g_Active
      if (data == FRAME_BYTE) {
	if ( msg_get_length(g_Active) > 0 ) {   // If g_Active.len==0, try filling it again
	  append_queue( &g_Full, g_Active );
	  g_RxState = RXSTATE_FIRST_BYTE;   // Will need new RX buffer
	  g_Active = NULL;
	  post PacketReceived();
	}
      }
      else {
	if ( msg_get_length(g_Active) >= MESSAGE_MAX_LENGTH ) {    // Flush the packet if it is too long
	  dbg(DBG_USR1, "SimpleFrameM rx packet too long\n");
	  call MessagePool.free( g_Active );
	  g_RxState      = RXSTATE_INIT;
	}

	if ( data == ESCAPE_BYTE ) {
	  g_RxState = RXSTATE_TOKEN;
	}
	else {
	  msg_append_uint8( g_Active, data );
	}
      }
      break;

    case RXSTATE_TOKEN:
      // Could check to see if the byte was either FRAME_BYTE or ESCAPE_BYTE
      msg_append_uint8( g_Active, data ^ 0x20 );
      g_RxState = RXSTATE_DATA;
      break;
    }

    return SUCCESS;
  }


  /**
   * Call this to start sending a message.  We put the message on 
   * the transmit queue and start sending data.
   */
  
  command result_t Message.send( struct Message *msg )
  {
    if ( msg_get_length(msg) == 0 ) 
      return FAIL;

    atomic {
      append_queue( &g_TxQueue, msg );

      if ( g_TxState == TXSTATE_IDLE ) {
	g_TxState = TXSTATE_DATA;
	g_TxIndex = 0;
	call HPLUART.put( FRAME_BYTE );  // Ignore the result
      }
    }

    return SUCCESS;
  }

  /**
   * Called when the last byte has been successfully put
   */

  async event result_t HPLUART.putDone()
  {
    result_t result = SUCCESS;
    uint8_t  data;

    if ( g_TxState == TXSTATE_IDLE ) {
      if ( g_TxQueue == NULL ) {
	return SUCCESS;       // Nothing to do
      }

      g_TxState = TXSTATE_DATA;  // Start sending data bytes
      g_TxIndex = 0;
    }

    switch (g_TxState) {
    case TXSTATE_DATA:
      data = msg_get_uint8( g_TxQueue, g_TxIndex );  // Next data byte
      if ( data == FRAME_BYTE || data == ESCAPE_BYTE ) {
	g_TxState = TXSTATE_TOKEN;
	result = call HPLUART.put( ESCAPE_BYTE );
      }
      else {
	g_TxIndex++;
	if ( g_TxIndex >= msg_get_length(g_TxQueue) )
	  g_TxState = TXSTATE_EOF;
	result = call HPLUART.put( data );
      }
      break;

    case TXSTATE_TOKEN:
      data = msg_get_uint8( g_TxQueue, g_TxIndex );
      g_TxIndex++;
      if ( g_TxIndex >= msg_get_length(g_TxQueue) )
	g_TxState = TXSTATE_EOF;
      else
	g_TxState = TXSTATE_DATA;
      result = call HPLUART.put( data ^ 0x20 );
      break;

    case TXSTATE_EOF:
      call MessagePool.free(pop_queue(&g_TxQueue));
      g_TxState = TXSTATE_IDLE;   // Idle will take care of starting the next one
      result = call HPLUART.put( FRAME_BYTE );
      break;
    }

    if ( result != SUCCESS )
      dbg(DBG_USR1,"Dropped Tx frame");

    return result;
  }
}
