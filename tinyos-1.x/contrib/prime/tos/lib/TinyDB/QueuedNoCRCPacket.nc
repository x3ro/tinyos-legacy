/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:		Jason Hill, Alec Woo, David Gay, Philip Levis
 * Date last modified:  5/12/03 -- SRM -- queued UART received
 *
 */

/* This component handles the packet abstraction on the network stack 
   This variant doesn't compute CRC, and follows the simple queued
   receive protocol for use with the QueuedSerialSource.java, which works as follows:

   Messages sent over the uart are of the format:

   <magic code><msg-id><payload>

   Where magic code is currently 0xFE and msg-id is a nonce that can
   be used to eliminate duplicates.

   And a 1-byte syncronous acknowledgement is expected by the sender,
   where a value of 1 indicates the messages was successfully received.
   If this acknowledgement is not sent with 50ms, the sender will assume
   the message was not received and will try again.

*/
module QueuedNoCRCPacket {
  provides {
    interface StdControl as Control;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
    interface SendVarLenPacket;

    command result_t txBytes(uint8_t *bytes, uint8_t numBytes);
    /* Effects: start sending 'numBytes' bytes from 'bytes'
    */
  }
  uses {
    interface ByteComm;
    interface StdControl as ByteControl;
    interface Leds;
  }
}
implementation
{
  uint8_t rxCount, rxLength, txCount, txLength;
  TOS_Msg buffer;
  uint8_t *recPtr;
  uint8_t *sendPtr;
  uint8_t lastMsgId;
  uint8_t msgId;
  bool gotId;
  bool gotMagicCode;
  bool acking;
  enum {
    IDLE,
    PACKET,
    BYTES,
  };
  uint8_t state;

  bool newMsgId(uint8_t testMsgId);

  /*
    state == IDLE, nothing is being sent
    state == PACKET, this level is sending a packet
    state == BYTES, this level is just transferring bytes

    The purpose of adding the new state, to simply transfer bytes, is because
    certain applications may want to just send a sequence of bytes without the
    packet abstraction.  One such example is the UART.

   */
  

  /* Initialization of this component */
  command result_t Control.init() {
    recPtr = (uint8_t *)&buffer;
    state = IDLE;
    txCount = rxCount = 0;
    // make sure we always read up to the type (which determines length)
    rxLength = offsetof(TOS_Msg, type) + 1;
    dbg(DBG_BOOT, "Packet handler initialized.\n");
    lastMsgId = 0xFF;
    gotId = FALSE;
    acking = FALSE;
    gotMagicCode = FALSE;
    return call ByteControl.init();
  }

  /* Command to control the power of the network stack */
  command result_t Control.start() {
    // apply your power management algorithm
    return call ByteControl.start();
  }

    /* Command to control the power of the network stack */
  command result_t Control.stop() {
    // apply your power management algorithm
    return call ByteControl.stop();
  }

  command result_t txBytes(uint8_t *bytes, uint8_t numBytes) {
    if (txCount == 0)
      {
	txCount = 1;
	txLength = numBytes;
	sendPtr = bytes;
	/* send the first byte */
	if (call ByteComm.txByte(sendPtr[0]))
	  return SUCCESS;
	else
	  txCount = 0;
      }
    return FAIL;
  }

  /* Command to transmit a packet */
  command result_t Send.send(TOS_MsgPtr msg) {
    state = PACKET;
    msg->crc = 1; /* Fake out the CRC as passed. */
    if (call txBytes((uint8_t *)msg, TOS_MsgLength(msg->type)) == FAIL) {
      state = IDLE;
      return FAIL;
    }
    return SUCCESS;
  }

  /* Command to transfer a variable length packet */
  command result_t SendVarLenPacket.send(uint8_t* packet, uint8_t numBytes) {
    state = BYTES;
    if (call txBytes(packet, numBytes) == FAIL) {
      state = IDLE;
      return FAIL;
    }
    return SUCCESS;
  }
  
  void sendComplete(result_t success) {
    if (state == PACKET) 
      {
	TOS_MsgPtr msg = (TOS_MsgPtr)sendPtr;

	/* This is a non-ack based layer */
	if (success)
	  msg->ack = TRUE;
	signal Send.sendDone((TOS_MsgPtr)sendPtr, success);
      }
    else if (state == BYTES)
      signal SendVarLenPacket.sendDone((uint8_t*)sendPtr, success);
    state = IDLE;
    txCount = 0;
  }

  default event result_t SendVarLenPacket.sendDone(uint8_t* packet, result_t success) {
    return success;
  }

  default event result_t Send.sendDone(TOS_MsgPtr msg, result_t success){
    return success;
  }
  
  
  /* Byte level component signals it is ready to accept the next byte.
     Send the next byte if there are data pending to be sent */
  event result_t ByteComm.txByteReady(bool success) {
    if (txCount > 0)
      {
	if (!success)
	  {
	    dbg(DBG_ERROR, "TX_packet failed, TX_byte_failed");
	    sendComplete(FAIL);
	  }
	else if (txCount < txLength)
	  {
	    dbg(DBG_PACKET, "PACKET: byte sent: %x, COUNT: %d\n",
		sendPtr[txCount], txCount);

	    if (acking || !call ByteComm.txByte(sendPtr[txCount++]))
	      sendComplete(FALSE);
	  }
      }
    return SUCCESS;
  }

  event result_t ByteComm.txDone() {
    if (acking) {
      acking = FALSE;
    } else {
      if (txCount == txLength)
	sendComplete(TRUE);
    }
    return SUCCESS;
  }

  /* The handles the latest decoded byte propagated by the Byte Level
     component*/
  event result_t ByteComm.rxByteReady(uint8_t data, bool error,
				      uint16_t strength) {
    dbg(DBG_PACKET, "PACKET: byte arrived: %x, COUNT: %d\n", data, rxCount);
    
    if (error)
      {
	rxCount = 0;
	return FAIL;
      }

    if (rxCount == 0)
      ((TOS_MsgPtr)(recPtr))->strength = strength;
  
    if (rxCount == offsetof(TOS_Msg, type))
      rxLength = TOS_MsgLength(data); //for id

    if (!gotMagicCode) {
      if (data == 0xFE) gotMagicCode = TRUE;
    } else if (!gotId) {
      
      msgId = data;
      gotId = TRUE;
    } else {
      recPtr[rxCount++] = data;
    }

    //done receiving
    if (rxCount == rxLength)
      {
	TOS_MsgPtr tmp;

	dbg(DBG_PACKET, "got packet\n");  
	rxCount = 0;
	gotId = FALSE;
	gotMagicCode = FALSE;
	

	
	if (state == IDLE) {
	  acking = TRUE;
	  if (call ByteComm.txByte(1) == FAIL)
	    acking = FALSE;
	}
	

	//check that the packet is new
	if (newMsgId(msgId)) {
	  tmp = signal Receive.receive((TOS_MsgPtr)recPtr);
	  //call Leds.yellowToggle();
	  if (tmp)
	    recPtr = (uint8_t *)tmp;
	}

	return FAIL;
      }

    return SUCCESS;
  }

  bool newMsgId(uint8_t testMsgId) {
    if (testMsgId == lastMsgId) {
      //call Leds.redToggle();
       return FALSE;
    } else 
      lastMsgId = testMsgId;

    return TRUE;
  }

}





