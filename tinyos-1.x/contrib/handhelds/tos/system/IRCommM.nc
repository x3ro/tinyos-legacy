/**
 * Copyright (c) 2005 Hewlett-Packard Company
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
 * Communicate via a MicroChip 2150 and an IrDA transceiver
 *
 * Author:  Andrew Christian <andrew.christian@hp.com>
 *          31 March 2005
 *
 * We assume the following connections:
 *
 *  HPLUART and USARTControl are connected to an MCP2150 chip.
 *  CTS0Interrupt...
 *
 *  TOSH__MCP2150_RESET_L   ->  2150 Reset line
 *  TOSH__MCP2150_EN_H      ->  2150 Enable line
 *  TOSH_IR_LOWPWR_H        ->  SD (shutdown) line of the IrDA transceiver
 */

includes msp430baudrates;

module IRCommM {
  provides {
    interface StdControl;
    interface ParamView;
    interface Message;
    interface IRClient;
  }

  uses {
    interface HPLUSARTFeedback as USARTData;
    interface HPLUSARTControl  as USARTControl;

    interface MSP430Interrupt as CTS0Interrupt;
    interface MSP430Interrupt as RXInterrupt;

    interface Timer;

    interface MessagePool;
    interface MessagePoolFree;
  }
}
implementation {
  enum {
    IR_RXSTATE_FIRST_BYTE,  // Waiting for first byte of len
    IR_RXSTATE_PENDING,     // Waiting on a message buffer
    IR_RXSTATE_DATA,        // Reading data
  };

  enum {
    IR_TXSTATE_IDLE = 0,
    IR_TXSTATE_LENGTH,
    IR_TXSTATE_DATA
  };

  struct Message *g_Active; // Current buffer being filled
  struct Message *g_Full;   // Full buffers being processed elsewhere
  uint8_t         g_RxState;
  uint8_t         g_RxLength;

  struct Message *g_TxQueue;
  uint8_t         g_TxState;
  uint8_t         g_TxBytesSent;

#ifndef IR_BAUDRATE
#define IR_BAUDRATE 115200
#endif

  struct IRStats {
    uint16_t wakeup;       // Number of times we've woken up the MCP2150
    uint16_t conn_time;    // Seconds we've run in connection mode

    uint16_t bytes_tx;           // Bytes transmitted
    uint16_t bytes_rx;           // Bytes received
    uint16_t packets_tx;
    uint16_t packets_rx;

    uint8_t  err_rx_pend;  // Bytes received while pending
    uint8_t  rx_flush;     // Partial packets received and flushed
    uint8_t  tx_flush;     // Partial packets sent and flushed
    uint16_t cts;          // Had to set CTS to pend a send
  };

  norace struct IRStats g_stats;

  void enableCTS0Interrupt();

  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    call USARTControl.setModeUART();

#if IR_BAUDRATE == 9600
    call USARTControl.setClockSource(SSEL_ACLK);
    call USARTControl.setClockRate(UBR_ACLK_9600, UMCTL_ACLK_9600);
#elif IR_BAUDRATE == 19200
    call USARTControl.setClockSource(SSEL_SMCLK);
    call USARTControl.setClockRate(UBR_SMCLK_19200, UMCTL_SMCLK_19200);
#elif IR_BAUDRATE == 57600
    call USARTControl.setClockSource(SSEL_SMCLK);
    call USARTControl.setClockRate(UBR_SMCLK_57600, UMCTL_SMCLK_57600);
#elif IR_BAUDRATE == 115200
    call USARTControl.setClockSource(SSEL_SMCLK);
    call USARTControl.setClockRate(UBR_SMCLK_115200, UMCTL_SMCLK_115200);
#else
#error "Error, unsupported value for IR_BAUDRATE in IRCommM.nc"
#endif
    //    call USARTControl.enableUART_RTSCTS();

    call CTS0Interrupt.disable();
    call CTS0Interrupt.edge(FALSE);    // High to low transition

    call RXInterrupt.disable();
    call RXInterrupt.edge(FALSE);     // High to low transition

    return SUCCESS;
  }

  command result_t StdControl.start() {

    // These are set at device startup....
    //    TOSH_CLR_DTR0_PIN();            // Set MCP2150 to normal mode (dtr=0,rts=1)
    //    TOSH_SET_RTS0_PIN();

    TOSH_CLR_MCP2150_RESET_L_PIN(); // Reset the MCP2150 (2000 ns minimum)
    TOSH_uwait(3);
    TOSH_SET_MCP2150_RESET_L_PIN();

    while ( !TOSH_READ_DSR0_PIN())  // Wait for the MCP2150 to become ready
      ;

    TOSH_CLR_IR_LOWPRW_H_PIN();    // Put the IR transceiver in working mode

    // Finally, enable interrupts
    call RXInterrupt.clear();
    call RXInterrupt.enable();

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call USARTControl.disableRxIntr();
    call USARTControl.disableTxIntr();

    call CTS0Interrupt.disable();

    TOSH_CLR_MCP2150_EN_H_PIN();   // Puts the MCP2150 in low power mode
    TOSH_SET_IR_LOWPRW_H_PIN();    // Puts the IR transceiver in low power mode

    return SUCCESS;
  }

  /*****************************************
   *  Receiving IR data
   *****************************************/

  task void packetReceived()
  {
    struct Message *msg;
    atomic msg = pop_queue( &g_Full );
    
    while (msg) {
      signal Message.receive(msg);
      atomic msg = pop_queue( &g_Full );
    }
  }

  async event void MessagePoolFree.avail() 
  {
    uint8_t state;

    atomic state = g_RxState;

    if ( state == IR_RXSTATE_PENDING ) {
      atomic {
	g_Active = call MessagePool.alloc();
	if ( g_Active ) {
	  g_RxState = IR_RXSTATE_DATA;
	  TOSH_CLR_RTS0_PIN();      // Allow data
	}
      }
    }
  }

  async event result_t USARTData.rxDone(uint8_t data) 
  {
    g_stats.bytes_rx++;

    switch (g_RxState) {
    case IR_RXSTATE_FIRST_BYTE:
      g_Active = call MessagePool.alloc();
      if ( !g_Active ) {
	TOSH_SET_RTS0_PIN();     // Pending on receiving a message pool free
	g_RxState = IR_RXSTATE_PENDING;
      }
      else {
	g_RxLength = data;
	g_RxState = IR_RXSTATE_DATA;
      }
      break;

    case IR_RXSTATE_PENDING:
      g_stats.err_rx_pend++;   // This is really an error state
      break;

    case IR_RXSTATE_DATA:
      msg_append_uint8( g_Active, data );
      if ( msg_get_length( g_Active ) == g_RxLength ) {
	g_stats.packets_rx++;
	append_queue( &g_Full, g_Active );
	g_Active  = NULL;
	g_RxState = IR_RXSTATE_FIRST_BYTE;
	post packetReceived();
      }
      break;
    }
    return SUCCESS;
  }

  /*****************************************
   *  Sending IR Data
   *****************************************/

  uint8_t next_tx_byte()
  {
    uint8_t len = msg_get_length( g_TxQueue );
    uint8_t data;

    g_stats.bytes_tx++;

    switch (g_TxState) {
    case IR_TXSTATE_LENGTH:
      g_TxBytesSent = 0;
      g_TxState = IR_TXSTATE_DATA;
      return len;

    case IR_TXSTATE_DATA:
      data = msg_get_uint8( g_TxQueue, g_TxBytesSent++ );
      if ( g_TxBytesSent == len ) {
	g_stats.packets_tx++;
	call MessagePool.free( pop_queue( &g_TxQueue ));

	if ( g_TxQueue )
	  g_TxState = IR_TXSTATE_LENGTH;
	else
	  g_TxState = IR_TXSTATE_IDLE;
      }
      return data;
    }

    return 0;
  }

  /* This only fires when (a) we have data to send and (b) CTS is low */

  async event void CTS0Interrupt.fired() {
    call CTS0Interrupt.disable();
    call CTS0Interrupt.clear();
    call USARTControl.tx(next_tx_byte());
  }

  // Always call in atomic or interrupt context

  void push_byte()
  {
    if ( call CTS0Interrupt.getValue() ) {  // High = don't send yet
      g_stats.cts++;

      // Set an interrupt for when CTS goes low.
      call CTS0Interrupt.clear();
      call CTS0Interrupt.enable();

      if ( !(call CTS0Interrupt.getValue()) &&
	   !(call CTS0Interrupt.getPending()))
	call CTS0Interrupt.setPending();
    }
    else {
      call USARTControl.tx( next_tx_byte() );
    }
  }

  async event result_t USARTData.txDone() {
    if ( g_TxState != IR_TXSTATE_IDLE )
      push_byte();
    
    return SUCCESS;
  }

  // Only accept packets if we have a Carrier Detect line active.

  command result_t Message.send( struct Message *msg )
  {
    if ( msg_get_length(msg) == 0 || TOSH_READ_CD0_PIN())
      return FAIL;

    atomic {
      append_queue( &g_TxQueue, msg );
      if ( g_TxState == IR_TXSTATE_IDLE ) {
	g_TxState = IR_TXSTATE_LENGTH;
	push_byte();
      }
    }

    return SUCCESS;
  }


  /*****************************************
   *  Main IR mode handling. 
   *
   *  We wake up the MCP2150 when we see IR activity,
   *  and put it back to sleep if we haven't seen any
   *  activity.
   *****************************************/

  task void enableMCP2150()
  {
    g_stats.wakeup++;

    atomic {
      g_RxState = IR_RXSTATE_FIRST_BYTE;
      g_TxState = IR_TXSTATE_IDLE;
    }

    call USARTControl.enableRxIntr();
    call USARTControl.enableTxIntr();

    TOSH_CLR_RTS0_PIN();            // Host controller ready to receive data
    TOSH_SET_MCP2150_EN_H_PIN();    // Enable the MCP2150

    call Timer.start( TIMER_ONE_SHOT, 2048 );
    signal IRClient.connected(TRUE);
  }

  void disableMCP2150()
  {
    signal IRClient.connected(FALSE);

    TOSH_SET_RTS0_PIN();           // Pend all data

    call USARTControl.disableRxIntr();
    call USARTControl.disableTxIntr();
    call CTS0Interrupt.disable();

    TOSH_CLR_MCP2150_EN_H_PIN();    // Put the MCP2150 into low power mode

    // Flush any partial packets
    atomic {
      if (g_Active) {
	call MessagePool.free(g_Active);
	g_Active = NULL;
	g_stats.rx_flush++;
      }
    }

    while (g_TxQueue) {
      call MessagePool.free(pop_queue(&g_TxQueue));
      g_stats.tx_flush++;
    }

    call RXInterrupt.clear();       // Enable interupt processing for the IR
    call RXInterrupt.enable();
  }

  // Something is happening in IR land.  Turn on the MCP2150
  // and spend at least two seconds listening and processing
  // packets.

  async event void RXInterrupt.fired() {
    call RXInterrupt.disable();
    post enableMCP2150();
  }

  // Check for a carrier.  If we don't have one, put the MCP2150 to sleep

  event result_t Timer.fired()
  {
    if ( TOSH_READ_CD0_PIN() )   // True if we don't have an IR link
      disableMCP2150();
    else {
      g_stats.conn_time++;
      call Timer.start( TIMER_ONE_SHOT, 1024 );
    }

    return SUCCESS;
  }

  /*****************************************************************/

  const struct Param s_IRComm[] = {
    { "wakeup",      PARAM_TYPE_UINT16,  &g_stats.wakeup },
    { "conn_time",   PARAM_TYPE_UINT16,  &g_stats.conn_time },
    { "bytes_tx",    PARAM_TYPE_UINT16,  &g_stats.bytes_tx },
    { "bytes_rx",    PARAM_TYPE_UINT16,  &g_stats.bytes_rx },
    { "pkts_tx",     PARAM_TYPE_UINT16,  &g_stats.packets_tx },
    { "pkts_rx",     PARAM_TYPE_UINT16,  &g_stats.packets_rx },
    { "err_rx_pend", PARAM_TYPE_UINT8,   &g_stats.err_rx_pend },
    { "tx_flush",    PARAM_TYPE_UINT8,   &g_stats.tx_flush },
    { "rx_flush",    PARAM_TYPE_UINT8,   &g_stats.rx_flush },
    { "cts",         PARAM_TYPE_UINT16,  &g_stats.cts },
    { NULL, 0, NULL }
  };

  struct ParamList g_IRCommList   = { "irda",   &s_IRComm[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_IRCommList );
    return SUCCESS;
  }
}
