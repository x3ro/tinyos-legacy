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
 * Date last modified:  6/25/02
 *
 */

/* This component handles the packet abstraction on the network stack 
   - perform CRC calculation and integrity check
*/
includes crc;
module CRCPacket {
  provides {
    interface StdControl as Control;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
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

  /* Initialization of this component */
  command result_t Control.init() {
    recPtr = (uint8_t *)&buffer;
    txCount = rxCount = 0;
    // make sure we always read up to the type (which determines length)
    rxLength = offsetof(TOS_Msg, type) + 1;
    dbg(DBG_BOOT, "CRC Packet handler initialized.\n");

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


  /* Internal function to calculate 16 bit CRC */
  uint16_t calcrc(uint8_t *ptr, uint8_t count) {
    uint16_t crc;
    uint8_t i;
  
    crc = 0;
    while (count-- > 0)
      crc = crcByte(crc, *ptr++);

    return crc;
  }

  /* A Task to calculate CRC for message transmission */
  task void CRCCalc() {
    uint16_t length = txLength;
    uint16_t crc = calcrc(sendPtr, length - 2);
    
    sendPtr[length - 2] = crc & 0xff;
    sendPtr[length - 1] = (crc >> 8) & 0xff;
    
    dbg(DBG_CRC, "CRCPacket: CRC calculated to be %x\n", ((TOS_MsgPtr)sendPtr)->crc);
  }

  /* A Task to calculate CRC for to check for message integrity */
  task void CRCCheck() {
    uint16_t crc, mcrc;
    uint8_t length;

    rxCount = 0;
    length = rxLength;
    crc = calcrc(recPtr, length - 2);
    mcrc = ((recPtr[length - 1] & 0xff)<< 8);
    mcrc |= (recPtr[length - 2] & 0xff);
    if (crc == mcrc)
      {
	TOS_MsgPtr tmp;

	dbg(DBG_PACKET, "got packet\n");  
	tmp = signal Receive.receive((TOS_MsgPtr)recPtr);
	dbg(DBG_CRC, "CRCPacket: check succeeded: %x, %x\n", crc, mcrc);
	if (tmp)
	  recPtr = (uint8_t *)tmp;  
      }
    else
      dbg(DBG_CRC, "CRCPacket: check failed: %x, %x\n", crc, mcrc);
  }

  /* Command to transmit a packet */
  command result_t Send.send(TOS_MsgPtr msg) {
    if (txCount == 0)
      {
	txCount = 1;
	txLength = TOS_MsgLength(msg->type);
	sendPtr = (uint8_t *)msg;
	/* send the first byte */
	if (call ByteComm.txByte(sendPtr[0]))
	  {
	    post CRCCalc();
	    return SUCCESS;
	  }
	else
	  txCount = 0;
      }
    return FAIL;
  }

  void sendComplete(result_t success) {
    TOS_MsgPtr msg = (TOS_MsgPtr)sendPtr;

    /* This is a non-ack based layer */
    if (success)
      msg->ack = TRUE;
    signal Send.sendDone(msg, success);
    txCount = 0;
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
	    
	    if (!call ByteComm.txByte(sendPtr[txCount++]))
	      sendComplete(FALSE);
	  }
      }
    return SUCCESS;
  }

  event result_t ByteComm.txDone() {
    if (txCount == txLength)
      sendComplete(TRUE);
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
      rxLength = TOS_MsgLength(data);

    recPtr[rxCount++] = data;

    if (rxCount == rxLength)
      {
	post CRCCheck();
	return FAIL;
      }

    return SUCCESS;
  }
}

