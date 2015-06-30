// $Id: NoCRCPacket.nc,v 1.9 2003/10/07 21:46:37 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Jason Hill, Alec Woo, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 */

/* This component handles the packet abstraction on the network stack 
*/

/**
 * @author Jason Hill
 * @author Alec Woo
 * @author David Gay
 * @author Philip Levis
 */

module NoCRCPacket {
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
  TOS_Msg buffers[2];
  TOS_Msg* bufferPtrs[2];
  uint8_t bufferIndex;
  uint8_t *recPtr;
  uint8_t *sendPtr;
  
  enum {
    IDLE,
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
    atomic {
      recPtr = (uint8_t *)&buffers[0];
      bufferIndex = 0;
      bufferPtrs[0] = &buffers[0];
      bufferPtrs[1] = &buffers[1];
      
      state = IDLE;
      txCount = rxCount = 0;
      // make sure we always read up to the type (which determines length)
      rxLength = offsetof(TOS_Msg, type) + 1;
      dbg(DBG_BOOT, "Packet handler initialized.\n");
    }
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
    bool sending = FALSE;
    atomic {
      if (txCount == 0)
	{
	  txCount = 1;
	  txLength = numBytes;
	  sendPtr = bytes;
	  byteToSend = sendPtr[0];
	  sending = TRUE;
	}
    }
    if (sending) {
      /* send the first byte */
      if (call ByteComm.txByte(byteToSend))
	return SUCCESS;
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
    uint8_t* packet;
    uint8_t sendNum;
    result_t rval = FAIL;
    atomic {
      oldState = state;
      if (state == IDLE) {
	state = PACKET;
      }
      packet = (uint8_t*)msg;
      sendNum = TOS_MsgLength(msg->type);
    }
    if (oldState == IDLE) {
      atomic {
	msg->crc = 1; /* Fake out the CRC as passed. */
	rval = call txBytes(packet, sendNum);
      }
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
  
  void sendComplete(result_t success) {
    uint8_t stateCopy;
    atomic {
      stateCopy = state;
    }

    if (stateCopy == PACKET) {

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
      //fake out crc
      tmp->crc = 1;
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





