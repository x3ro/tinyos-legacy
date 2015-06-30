/*
 * Copyright (C) 2003-2006 the University of Southern California.
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * In addition to releasing this program under the LGPL, the authors are
 * willing to dual-license it under other terms. You may contact the authors
 * of this project by writing to Wei Ye, USC/ISI, 4676 Admirality Way, Suite 
 * 1001, Marina del Rey, CA 90292, USA.
 */

/* Authors: Wei Ye and Fabio Silva
 *
 * Passes received packets to the UART.
 * Support different packet length. The first byte must be packet length.
 * Even though we do double-buffering, loss if possible if 3 or 4
 * packets arrive shortly after each other as the UART is much slower
 * than the CC2420 radio.
 * The contents of each packet can be displayed by snoop.c at tools/snoop.c
 *
 */

module SnooperZM
{
  provides interface StdControl;
  uses {
    interface StdControl as PhyControl;
    interface PhyNotify;
    interface PhyPkt;
    interface StdControl as UARTControl;
    interface ByteComm as UARTComm;
    interface Leds;
  }
}

implementation
{
// Included for PKY_MAX_PKT_LEN
#include "PhyRadioMsg.h"

#ifndef PLATFORM_MICAZ
#error "This snooper is only for the MicaZ platform."
#endif

#ifndef TOS_UART_ADDR
#define TOS_UART_ADDR 0x7e
#endif

  // Buffer states
  enum {
    FREE,
    BUSY
  };

  uint8_t pos;
  uint8_t recvBufState;
  uint8_t procBufState;
  char buffer1[PHY_MAX_PKT_LEN];
  char buffer2[PHY_MAX_PKT_LEN];
  uint8_t *recvPtr;
  uint8_t *procPtr;

  command result_t StdControl.init()
  {
    // Initialize buffers and components
    recvBufState = FREE;
    procBufState = FREE;
    recvPtr = (uint8_t *) &buffer1[0];
    procPtr = (uint8_t *) &buffer2[0];
    call Leds.init();
    call UARTControl.init();
    call PhyControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call UARTControl.start();
    call PhyControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call UARTControl.stop();
    call PhyControl.stop();
    return SUCCESS;
  }

  async event result_t PhyNotify.startSymSent(void* pkt)
  {
    return SUCCESS;
  }

  async event result_t PhyNotify.startSymDetected(void* pkt, uint8_t bitOffset)
  {
    // Nothing to do here
    return SUCCESS;
  }

  async event result_t UARTComm.txByteReady(bool success)
  {
    uint8_t len;
    uint8_t *buf;
    bool done, send;
    char *byte;

    atomic{
      len = *(uint8_t *) procPtr;

      // One more byte to send
      if (pos < len){
	send = TRUE;
	done = FALSE;
	pos++;
      }
      else{
	// Finished with this packet
	if (recvBufState == BUSY){
	  // Swap buffers again
	  buf = procPtr;
	  procPtr = recvPtr;
	  recvPtr = buf;
	  recvBufState = FREE;
	  procBufState = BUSY; // Should not be needed, but...
	  send = TRUE;
	  done = TRUE;
	  pos = 0;
	}
	else{
	  procBufState = FREE;
	  send = FALSE;
	  done = TRUE;
	}
      }
    }

    if (done == FALSE){
      byte = (char *)procPtr;
      call UARTComm.txByte(*(byte + (pos - 1)));
      return SUCCESS;
    }

    if (send == TRUE){
      // Send first byte
      call UARTComm.txByte(TOS_UART_ADDR);
      return SUCCESS;
    }

    return SUCCESS;
  }

  async event result_t UARTComm.rxByteReady(uint8_t data, bool error, uint16_t strength)
  {
    return SUCCESS;
  }

  async event result_t UARTComm.txDone()
  {
    return SUCCESS;
  }
   
  event void* PhyPkt.receiveDone(void* packet, uint8_t error)
  {
    uint8_t *data, *buf;
    uint8_t len, c;
    bool busy = TRUE;

    // Return if error in packet
    if (packet == 0)
      return packet;

    // Get packet length
    len = *(uint8_t *) packet;

    // If length greater than PHY_MAX_PKT_LEN (should not happen !!!),
    // we don't send this packet up and signal with a red led change
    if (len > PHY_MAX_PKT_LEN){
      call Leds.redToggle();
      return packet;
    }

    atomic{
      // Check if we have a buffer to receive this packet
      if (recvBufState == FREE){
	busy = FALSE;
	recvBufState = BUSY;
      }
    }

    if (busy == TRUE)
      return packet;
    
    // Copy packet to the receive buffer
    atomic{
      buf = recvPtr;
      data = (uint8_t *) packet;
      c = 0;
    
      while (c < len){
	*(buf) = *(data);
	c++;
	buf++;
	data++;
      }

      // Switch buffers if we can
      if (procBufState == FREE){
	buf = recvPtr;
	recvPtr = procPtr;
	procPtr = buf;
	procBufState = BUSY;
	recvBufState = FREE;
	pos = 0;
      }
    }

    // Send first byte
    call UARTComm.txByte(TOS_UART_ADDR);
    
    return packet;
  }

  event result_t PhyPkt.sendDone(void* packet)
  {
    return SUCCESS;
  }

}  // end of implementation

