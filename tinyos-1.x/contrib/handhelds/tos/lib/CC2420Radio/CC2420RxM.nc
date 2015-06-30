/**
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
 *
 *  Handle the receive queue of the CC2420 radio.  The receive queue
 *  has the following properties:
 *
 *   Upon receiving a FIFO indication from the chip, we have a 
 *   limited amount of time to read out enough header bytes from
 *   the radio to decide if:
 * 
 *     a. The message is for us
 *     b. We need to ACK the message
 *     c. We need to set the DATA_PENDING flag in the ACK.
 *
 *   All of this processing must occur before the final byte of the
 *   message is received.  If we need to ACK, we must write to the
 *   SPI bus an appropriate command before SFD goes low.
 *
 *   Hence the FIFO interrupt handling routine is quite complex and
 *   usually needs to spin and wait on the FIFO queue (waiting for
 *   each byte to arrive).  Unfortunately, this disrupts other interrupt 
 *   such as timers, UARTs, and the like.  Hence we RE-ENABLE interrupts 
 *   during the FIFO handler.
 *
 *   Once the message header has been ACK/not-ACK'd we defer other
 *   processing until FIFOP has been received and then spawn a task to
 *   read in the remaining bytes.
 *
 *  The result of this system is that you must NOT use the SPI bus in any
 *  way while the receive queue is enabled.  Moreover, calling "disable()"
 *  on the queue takes an indeterminate amount of time (hence the 
 *  "disableDone()" event).
 *
 *  Andrew Christian <andrew.christian@hp.com>
 *  May 2005
 */

#include "IEEE802154.h"

includes IEEEUtility;
includes CC2420Rx;

module CC2420RxM {
  provides {
    interface CC2420Rx;
    interface ParamView;
  }
  uses {
    interface CC2420LowLevel;
    interface CC2420Interrupt as CC2420InterruptFIFO;
    interface CC2420Interrupt as CC2420InterruptFIFOP;
    interface MessagePool;
  }
}
implementation {
  struct RxStats {
    uint32_t rx_total;           // Total packets received (FIFO interrupts)
    uint32_t rx_fifo_fail;       // Lost due to read failure
    uint32_t rx_discard;         // Bad packet or not for us
    uint32_t rx_ack_received;    // ACK received (from our send)
    uint32_t rx_ack_sent;        // ACK send (by use in response to packet)

    uint32_t rx_fifo_overflow;   // FIFO pin low, FIFOP high
    uint32_t rx_fail_alloc;      // No buffer available to receive a packet
    uint32_t rx_bad_crc;   // Bad CRC value
  };

#define IEEE802154_ACK_BACKOFF                  34    // 12 between, 22 for the ack

  /********************************************
   *  CC2420
   *
   *  Processing incoming messages
   ********************************************/

  uint8_t g_rxbuf[24];  
  norace uint8_t g_rxmsglen;   // The length byte read from the 802.15.4
  norace uint8_t g_rxbuflen;   // Number of bytes in the buffer
  norace struct RxStats g_stats;

  enum {
    RX_STATE_DISABLED,
    RX_STATE_WAIT_FIFO,  // Waiting for a FIFO interrupt
    RX_STATE_IN_FIFO,    // Processing a FIFO interrupt
    RX_STATE_WAIT_FIFOP,
    RX_STATE_READ_BODY
  };

  norace uint8_t g_state;       // Default disabled
  norace uint8_t g_desired;     // Default disabled

  task void markDisableDone()
  {
    signal CC2420Rx.disableDone();
  }

  /*
   * Turn on Rx mode
   */

  async command void CC2420Rx.enable()
  {
    if ( g_desired != RX_STATE_DISABLED )
      return;

    g_desired = RX_STATE_WAIT_FIFO;
    g_state   = RX_STATE_WAIT_FIFO;

    call CC2420LowLevel.read(CC2420_RXFIFO);          //flush Rx fifo
    call CC2420LowLevel.cmd(CC2420_SFLUSHRX);
    call CC2420LowLevel.cmd(CC2420_SFLUSHRX);

    atomic {
      call CC2420InterruptFIFO.enable();
    }
  }
  
  command bool CC2420Rx.isEnabled()
  {
    return g_state != RX_STATE_DISABLED;
  }

  /* 
   * Turn off Rx.
   */

  async command void CC2420Rx.disable()
  {
    if ( g_desired == RX_STATE_DISABLED )
      return;

    atomic {
      g_desired = RX_STATE_DISABLED;
      if (call CC2420InterruptFIFO.getEnabled()) {
	g_state = RX_STATE_DISABLED;
	call CC2420InterruptFIFO.disable();
	post markDisableDone();
      }
    }
  }

  /*
   * Set a back off time whenever we receive a packet
   * to avoid transmitting too soon after a reception
   *
   * Runs in INTERRUPT context
   */

  void setIFSTimer()
  {
    uint16_t symbols;

    if ( (g_rxmsglen & 0x7f) > IEEE802154_aMaxSIFSFrameSize )
      symbols = IEEE802154_aMinLIFSPeriod;
    else 
      symbols = IEEE802154_aMinSIFSPeriod;

    if ( g_rxbuflen && g_rxbuf[0] & (1 << CC2420_DEF_FCF_BIT_ACK))
      symbols += IEEE802154_ACK_BACKOFF;
      
    signal CC2420Rx.setIFSTimer( symbols );
  }

  /**
   *  Read the head of the message
   *  Our goal is to read just enough bytes in to determine
   *  if we need to generate a SACK or SACKPEND response.  The rest of the
   *  message processing will be handled in task context by readMessageBody().   
   *
   *  There are three ways to terminate this routine.  
   *    1. Reading from the FIFO gives an error (a 'stuffed' FIFO)
   *       -> Set an error flag and flush the FIFO (later)   g_rxmsglen  = 0x80
   *    2. The frame isn't valid or isn't for us.
   *       -> Set an error flag, read FIFO (later)           g_rxmsglen |= 0x00 | msg_len
   *    3. The frame is good.
   *       -> Store the number of bytes we have read         g_rxmsglen  = msg_len
   *
   *  Return TRUE if we should allow readMessageBody() to process the remainder
   *  of this message.
   *
   *  INTERRUPT context
   */

#define PKT_HEADER_SIZE 3  // FCF + DSN
#define MIN_PKT_SIZE 5     // FCF + DSN + 2 extra bytes (for ACKs)

  bool readMessageHead()
  {
    int      addr_bytes = 0;
    uint8_t  dest_mode;
    uint8_t  src_mode;
    uint8_t  frame_type;
    uint16_t tmp;
    result_t result;
    uint8_t *pan_id   = NULL;
    uint8_t *src_addr = NULL;

    call CC2420LowLevel.openRXFIFO();
    result = call CC2420LowLevel.readRXFIFO( &g_rxmsglen, 1 );  // Length byte

    if ( result != SUCCESS || g_rxmsglen < MIN_PKT_SIZE || g_rxmsglen > 127 ) 
      goto fifo_fail;

    // Read in FCF + DSN
    result = call CC2420LowLevel.readRXFIFO( g_rxbuf, MIN_PKT_SIZE );
    if ( result != SUCCESS ) 
      goto fifo_fail;

    g_rxbuflen = MIN_PKT_SIZE;

    frame_type = g_rxbuf[0] & FRAME_TYPE_MASK;
    if ( frame_type > FRAME_TYPE_CMD )
      goto fifo_discard;

    // Calculate how many address bytes we need to recover
    dest_mode = g_rxbuf[1] & DEST_MODE_MASK;
    src_mode  = g_rxbuf[1] & SRC_MODE_MASK;

    switch ( dest_mode ) {
    case 0: break;
    case DEST_MODE_SHORT: addr_bytes = 4; break;
    case DEST_MODE_LONG: addr_bytes = 10; break;
    default: goto fifo_discard;
    }

    switch ( src_mode ) {
    case 0: break;
    case SRC_MODE_SHORT:  pan_id = g_rxbuf + 3 + addr_bytes; src_addr = pan_id + 2; addr_bytes += 4; break;
    case SRC_MODE_LONG:   pan_id = g_rxbuf + 3 + addr_bytes; src_addr = pan_id + 2; addr_bytes += 10; break;
    default: goto fifo_discard;
    }

    if ( (g_rxbuf[0] & INTRA_PAN) && dest_mode && src_mode ) {
      pan_id      = g_rxbuf + 3;
      src_addr   -= 2;
      addr_bytes -= 2;
    }

    if ( g_rxmsglen < addr_bytes + PKT_HEADER_SIZE )
      goto fifo_discard;

    // Read the address bytes
    if ( addr_bytes > (g_rxbuflen - PKT_HEADER_SIZE)) {
      addr_bytes -= (g_rxbuflen - PKT_HEADER_SIZE);  // Really this is 'bytes to read'
      result = call CC2420LowLevel.readRXFIFO( g_rxbuf + g_rxbuflen, addr_bytes );
      if ( result != SUCCESS ) 
	goto fifo_fail;

      g_rxbuflen += addr_bytes;
    }

    // Address recognition
    // Promiscuous mode is set with call CC2420Rx.panID() = 0xffff

    if ( signal CC2420Rx.panID() != 0xffff ) {
      switch (frame_type) {
      case FRAME_TYPE_BEACON:
	// Beacon frames either must match g_PanID or be broadcast (0xffff)
	if ( signal CC2420Rx.panID() != 0xffff ) {
	  if ( dest_mode || !src_mode )
	    goto fifo_discard;
	  tmp = (((uint16_t) g_rxbuf[4]) << 8) | g_rxbuf[3];
	  if ( tmp != signal CC2420Rx.panID() )
	    goto fifo_discard;
	}
	break;

      case FRAME_TYPE_ACK:
	// We directly handle ACK packets as they have been completely read
	if ( g_rxmsglen != 5 )
	  goto fifo_discard;
	//	setIFSTimer();
	if (g_rxbuf[4] & 0x80)      // CRC
	  //signal CC2420Rx.receiveAck( g_rxbuf[2], g_rxbuf[0] & FRAME_PENDING );
          //BRC: Aug 2 2005, pass up RSSI and LQI
	  signal CC2420Rx.receiveAck( g_rxbuf[2], g_rxbuf[0] & FRAME_PENDING, g_rxbuf[3], g_rxbuf[4] & 0x7f);

	//	//n	if ( g_RadioState == RADIO_STATE_TX_WAIT_ACK 
	//	     && (g_rxbuf[4] & 0x80)      // CRC
	//	     && g_rxbuf[2] == msg_get_uint8(g_TxQueue,2))   // DSN must match
	//	  g_TxAttempts = ( ( g_rxbuf[0] & FRAME_PENDING ) ? TX_ATTEMPTS_GOT_ACK_PEND : TX_ATTEMPTS_GOT_ACK );

	// This isn't quite right
	if ( TOSH_READ_RADIO_FIFO_PIN() || TOSH_READ_RADIO_FIFOP_PIN())
	  goto fifo_fail;

	call CC2420LowLevel.closeRXFIFO();
	g_stats.rx_ack_received++;
	return FALSE;  // No more message to read

      default:  // Command or Data frame
	// If dest PanID exists, it must match g_PanID or broadcast (0xffff)
	if ( dest_mode ) {
	  tmp = (((uint16_t) g_rxbuf[4]) << 8) | g_rxbuf[3];
	  if ( tmp != 0xffff && tmp != signal CC2420Rx.panID() )
	    goto fifo_discard;
	}

	// If short destination address is specified, it must match signal CC2420Rx.shortAddr()
	// or the broadcast address (0xffff)
	if ( dest_mode == DEST_MODE_SHORT ) {
	  tmp = (((uint16_t) g_rxbuf[6]) << 8) | g_rxbuf[5];
	  if ( tmp != 0xffff && tmp != signal CC2420Rx.shortAddr() )
	    goto fifo_discard;
	}

	// If long destination address is specified, it must match g_LongAddress
	if ( dest_mode == DEST_MODE_LONG ) {
	  if ( memcmp( g_rxbuf + 5, signal CC2420Rx.longAddr(), 8 ))
	    goto fifo_discard;
	}

	// If only source addressing modes are in a DATA or COMMAND frame,
	// accept only if we are PAN coordinator and source PanID matches
	// g_PanID.
	if ( dest_mode == 0 ) {
	  if ( src_mode == 0 || !signal CC2420Rx.panCoord())
	    goto fifo_discard;
	  tmp = (((uint16_t) g_rxbuf[4]) << 8) | g_rxbuf[3];
	  if ( tmp != signal CC2420Rx.panID() )
	    goto fifo_discard;
	}
	break;
      }
    }
    
    call CC2420LowLevel.closeRXFIFO();

    // Generate an ACK for the packet
    if ( signal CC2420Rx.panID() != 0xffff && 
	 (g_rxbuf[0] & ACK_REQUEST)) {
      switch (signal CC2420Rx.generateAck( src_mode, pan_id, src_addr )) {
      case ACK_NO_DATA:
	call CC2420LowLevel.cmd( CC2420_SACK );
	g_stats.rx_ack_sent++;
	break;
      case ACK_DATA:
	call CC2420LowLevel.cmd( CC2420_SACKPEND );
	g_stats.rx_ack_sent++;
	break;
      }
    }
    return TRUE;  // Read remainder of message

  fifo_discard:
    // This message isn't for us or is invalid 802.15.4
    // If there are more bytes to read, let that be handled by a task
    g_stats.rx_discard++;

    call CC2420LowLevel.closeRXFIFO();
    if ( g_rxmsglen > g_rxbuflen ) {  // Are bytes remaining?
      g_rxmsglen |= 0x80;
      return TRUE;   // Read the remainder of the invalid message
    }
    return FALSE; 
    
  fifo_fail:    // The queue appears to be messed up
    g_stats.rx_fifo_fail++;
    call CC2420LowLevel.closeRXFIFO();
    // If FIFOP is still active, we assume that our buffer is stuffed
    while (TOSH_READ_RADIO_FIFO_PIN() || TOSH_READ_RADIO_FIFOP_PIN()) {
      g_stats.rx_fifo_overflow++;
      call CC2420LowLevel.read(CC2420_RXFIFO);          //flush Rx fifo
      call CC2420LowLevel.cmd(CC2420_SFLUSHRX);
      call CC2420LowLevel.cmd(CC2420_SFLUSHRX);
    }
    return FALSE;
  }

  /**
   *  Read out the remainder of the message.  If the discard bit is set or we can't allocate
   *  a message buffer, toss the message.
   *
   *  This runs in task context, but we guarantee that neither FIFO or FIFOP interrupt handlers
   *  are active.
   */

  task void readMessageBody()
  {
    struct Message *msg = NULL;
    uint8_t *buf = NULL;

    if (!TOSH_READ_RADIO_FIFO_PIN())
      g_stats.rx_fifo_overflow++;  // In theory, we can still read the message out
    
    if (!(g_rxmsglen & 0x80)) {
      msg = call MessagePool.alloc();
      if (msg) {
	msg_append_buf( msg, g_rxbuf, g_rxbuflen );
	buf = msg_get_pointer( msg, g_rxbuflen );
      }
      else 
	g_stats.rx_fail_alloc++;
    }
    else 
      g_rxmsglen &= 0x7f;

    call CC2420LowLevel.openRXFIFO();
    call CC2420LowLevel.readRXFIFOsafe( buf, g_rxmsglen - g_rxbuflen );
    call CC2420LowLevel.closeRXFIFO();

    msg_set_length( msg, g_rxmsglen );
    
    // If FIFOP is still active, we assume that our buffer is stuffed
    while (!TOSH_READ_RADIO_FIFO_PIN() && TOSH_READ_RADIO_FIFOP_PIN()) {
      g_stats.rx_fifo_overflow++;
      call CC2420LowLevel.read(CC2420_RXFIFO);          //flush Rx fifo
      call CC2420LowLevel.cmd(CC2420_SFLUSHRX);
      call CC2420LowLevel.cmd(CC2420_SFLUSHRX);
    }

    // The last thing we do is process the message (the signal may
    // result in someone else calling into our system)

    if ( msg ) {
      if ( msg_get_uint8( msg, msg_get_length(msg) - 1 ) & 0x80 ) {
	signal CC2420Rx.receive(msg);
      }
      else {
	g_stats.rx_bad_crc++;
	call MessagePool.free(msg);
      }
    }

    // Re-enable the FIFO interrupt OR signal disabled
    if ( !g_desired ) {
      g_state = RX_STATE_DISABLED;
      post markDisableDone();
    }
    else 
      atomic {call CC2420InterruptFIFO.enable(); }
  }

  /**
   * Process the FIFOP interrupt.  FIFOP is active when we've finished receiving
   * the message.  
   */

  async event bool CC2420InterruptFIFOP.fired() {
    setIFSTimer();
    if ( g_state == RX_STATE_WAIT_FIFOP )
      post readMessageBody();
    return FALSE;    // Disable FIFOP
  }

  /**
   * Process the FIFO interrupt. 
   */

  async event bool CC2420InterruptFIFO.fired() {
    bool result;
    g_state = RX_STATE_IN_FIFO;
    
    __nesc_enable_interrupt();
    // We must enable FIFOP _before_ we read out any RXFIFO bits because we
    // can lose the FIFOP interrupt by reading RXFIFO bits
    call CC2420InterruptFIFOP.enable();
    result = readMessageHead();  // Return TRUE if we have a message we'd like to read
    __nesc_disable_interrupt();
    
    if (!result) {      // We're not interested in reading the message body
      call CC2420InterruptFIFOP.disable();
      if ( g_desired == RX_STATE_DISABLED ) {
	g_state = RX_STATE_DISABLED;
	post markDisableDone();
	return FALSE;
      }
      g_state = RX_STATE_WAIT_FIFO;
      return TRUE;
    }

    if (!call CC2420InterruptFIFOP.getEnabled()) {  // Has FIFOP already fired?
      g_state = RX_STATE_READ_BODY;
      post readMessageBody();
    }
    else
      g_state = RX_STATE_WAIT_FIFOP;

    return FALSE;   // Disable FIFO
  }

  /*****************************************************************/

  const struct Param s_RadioRX[] = {
    { "rx_total",         PARAM_TYPE_UINT32, &g_stats.rx_total },
    { "rx_fifo_fail",     PARAM_TYPE_UINT32, &g_stats.rx_fifo_fail },
    { "rx_discard",       PARAM_TYPE_UINT32, &g_stats.rx_discard },
    { "rx_ack_received",  PARAM_TYPE_UINT32, &g_stats.rx_ack_received },
    { "rx_ack_sent",      PARAM_TYPE_UINT32, &g_stats.rx_ack_sent },

    { "rx_fifo_overflow", PARAM_TYPE_UINT32, &g_stats.rx_fifo_overflow },
    { "rx_fail_alloc",    PARAM_TYPE_UINT32, &g_stats.rx_fail_alloc },
    { "rx_bad_crc",       PARAM_TYPE_UINT32, &g_stats.rx_bad_crc },

    { NULL, 0, NULL }
  };

  struct ParamList g_RXList  = { "radiorx",  &s_RadioRX[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_RXList );
    return SUCCESS;
  }

}

