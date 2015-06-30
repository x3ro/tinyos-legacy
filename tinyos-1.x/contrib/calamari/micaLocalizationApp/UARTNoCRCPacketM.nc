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
 * $Id: UARTNoCRCPacketM.nc,v 1.3 2005/02/21 02:17:47 kaminw Exp $
 *
 */

/* This component handles the packet abstraction on the network stack 
*/
module UARTNoCRCPacketM {
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

  enum {
    SYNC_BYTE  = 0x6E,
    SYNC_LEN   = 10
  };

/*
  typedef struct sync_packet {
    uint8_t sync_bytes[SYNC_LEN];
    TOS_Msg msg;
  } sync_packet;
*/

  uint8_t synccount;
  uint8_t out[SYNC_LEN];

  uint8_t rxCount, rxLength, txCount, txLength;
  TOS_Msg buffers[2];
  TOS_Msg* bufferPtrs[2];
  uint8_t bufferIndex;
  uint8_t *recPtr;
  uint8_t *sendPtr;

  uint8_t sendNum;
  uint8_t* buffered_packet;
  
  enum {
    IDLE,
    SYNC,
    PACKET,
    BYTES
  };
  uint8_t state;

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
    uint8_t i;
    atomic {
      recPtr = (uint8_t *)&buffers[0];
      bufferIndex = 0;
      bufferPtrs[0] = &buffers[0];
      bufferPtrs[1] = &buffers[1];

      synccount = 0;
     
      state = IDLE;
      txCount = rxCount = 0;
      // make sure we always read up to the type (which determines length)
      rxLength = offsetof(TOS_Msg, type) + 1;
      dbg(DBG_BOOT, "Packet handler initialized.\n");
    }
    for (i = 0; i < SYNC_LEN; i++)
      out[i] = SYNC_BYTE;

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
    uint8_t byteToSend = 0;
    bool send = FALSE;
    atomic {
      if (txCount == 0)
	{
	  txCount = 1;
	  txLength = numBytes;
	  sendPtr = bytes;
	  byteToSend = sendPtr[0];
	  send = TRUE;
	}
    }
    if (send) {
      /* send the first byte */
      if (call ByteComm.txByte(byteToSend)) {
	return SUCCESS;
      }
      else {
	atomic {
	  txCount = 0;
	}
      }
    }
    return FAIL;
  }
  
  /* Command to transmit a packet */
  command result_t Send.send(TOS_MsgPtr msg) {
    uint8_t oldState;
    result_t rval = FAIL;
    atomic {
      oldState = state;
      if (state == IDLE) {
	state = SYNC;
      }
    }
    if (oldState == IDLE) {
      msg->crc = 1; /* Fake out the CRC as passed. */
      sendNum = TOS_MsgLength(msg->type);

      // copy the incoming message to a new buffer
      buffered_packet = (uint8_t*)msg;
#ifdef UART_SYNC
      rval = call txBytes(out, SYNC_LEN);
#else
      state = PACKET;
      rval = call txBytes(buffered_packet, sendNum);
#endif
    }
    return rval;
  }

  /* Command to transfer a variable length packet */
  command result_t SendVarLenPacket.send(uint8_t* packet, uint8_t numBytes) {
    uint8_t oldState;
    result_t rval = FAIL;
    atomic {
      oldState = state;
      if (state == IDLE) {
	state = BYTES;
      }
    }
    if (oldState == IDLE) {
      atomic {
	rval = call txBytes(packet, numBytes);
      }
    }
    return rval;
  }

  
  task void sendDoneFailTask() {
    TOS_MsgPtr msg;
    atomic {
      txCount = 0;
      state = IDLE;
      msg = (TOS_MsgPtr)sendPtr;
    }
    signal Send.sendDone(msg, FAIL);
  }
  
  task void sendDoneSuccessTask() {
    TOS_MsgPtr msg;
    atomic {
      txCount = 0;
      state = IDLE;
      msg = (TOS_MsgPtr)sendPtr;
    }
    signal Send.sendDone(msg, SUCCESS);
  }

  task void sendVarLenFailTask() {
    uint8_t* buf;
    atomic {
      txCount = 0;
      state = IDLE;
      buf = sendPtr;
    }
    signal SendVarLenPacket.sendDone(buf, FAIL);
  }

  task void sendVarLenSuccessTask() {
     uint8_t* buf;
    atomic {
      txCount = 0;
      state = IDLE;
      buf = sendPtr;
    }
    signal SendVarLenPacket.sendDone(buf, SUCCESS);
  }
  
  task void sendPacket() {
    call txBytes(buffered_packet, sendNum);
  }

  void sendComplete(result_t success) {
    uint8_t stateCopy;
    atomic {
      stateCopy = state;
    }

    if (stateCopy == SYNC) {
      state = PACKET;
      txCount = 0;
      post sendPacket();
      return;
    }

    else if (stateCopy == PACKET) {

      /* This is a non-ack based layer */
      /* This seems wrong to me -- it assumes this is
	 on top of the UART (a non-ack based layer). What
	 if we want to send a NoCrcPacket over the radio? -pal */
      if (success) {
	TOS_MsgPtr msg;
	atomic {
	  msg = (TOS_MsgPtr)sendPtr;
	  msg->ack = TRUE;
	}
	post sendDoneSuccessTask();
      }
      else {
	post sendDoneFailTask();
      }
    }
    else if (stateCopy == BYTES) {
      if (success) {
	post sendVarLenSuccessTask();
      }
      else {
	post sendVarLenFailTask();
      }
    }
    else {
      atomic {
	txCount = 0;
	state = IDLE;
      }
    }
  }

      
  default event result_t SendVarLenPacket.sendDone(uint8_t* packet, result_t success) {
    return success;
  }

  default event result_t Send.sendDone(TOS_MsgPtr msg, result_t success){
    return success;
  }
  
  
  /* Byte level component signals it is ready to accept the next byte.
     Send the next byte if there are data pending to be sent */
  async event result_t ByteComm.txByteReady(bool success) {
    uint8_t txC;
    uint8_t txL;
    atomic {
      txC = txCount;
      txL = txLength;
    }
    if (txC > 0) {
      if (!success) {
	dbg(DBG_ERROR, "TX_packet failed, TX_byte_failed");
	sendComplete(FAIL);
      }
      else if (txC < txL) {
	uint8_t byteToSend;
	atomic {
	  byteToSend = sendPtr[txC];
	  txCount++;
	}
	dbg(DBG_PACKET, "PACKET: byte sent: %x, COUNT: %d\n",
	    sendPtr[txCount], txCount);
	if (!call ByteComm.txByte(byteToSend))
	  sendComplete(FAIL);
      }
    }
    return SUCCESS;
  }

  async event result_t ByteComm.txDone() {
    bool complete;
    atomic {
      complete = (txCount == txLength);
    }
    if (complete)
      sendComplete(TRUE);
    return SUCCESS;
  }


  task void receiveTask() {
    TOS_MsgPtr tmp;
    atomic {
      tmp = bufferPtrs[bufferIndex ^ 1];
    }
    tmp  = signal Receive.receive(tmp);
    if (tmp) {
      atomic {
	bufferPtrs[bufferIndex ^ 1] = tmp;
      }
    }
  }
  
  /* The handles the latest decoded byte propagated by the Byte Level
     component*/
  async event result_t ByteComm.rxByteReady(uint8_t data, bool error,
				      uint16_t strength) {
    bool rxDone;

    dbg(DBG_PACKET, "PACKET: byte arrived: %x, COUNT: %d\n", data, rxCount);
    if (error)
      {
	atomic {
	  rxCount = 0;
	}
	return FAIL;
      }

#ifdef UART_SYNC
    if (data == SYNC_BYTE) {
      synccount++;
    if (synccount == SYNC_LEN) {
        rxCount = 0;
	return SUCCESS;
      }
    }
    else {
      synccount = 0;
    }
#endif
     
    atomic {
      if (rxCount == 0)
	((TOS_MsgPtr)(recPtr))->strength = strength;
      
      if (rxCount == offsetof(TOS_Msg, type))
	rxLength = TOS_MsgLength(data);
      
      recPtr[rxCount++] = data;

      rxDone = (rxCount == rxLength);
    }
    
    if (rxDone)
      {	
	atomic {
	  bufferIndex = bufferIndex ^ 1;
	  recPtr = (uint8_t*)bufferPtrs[bufferIndex];
	  dbg(DBG_PACKET, "got packet\n");  
	  rxCount = 0;
	}
	post receiveTask();
	return FAIL; 
      }

    return SUCCESS;
  }

}





