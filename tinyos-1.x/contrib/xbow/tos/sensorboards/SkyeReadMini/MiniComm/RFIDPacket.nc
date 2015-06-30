/*									Tab:4
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
/************************************************
Copyright © 2003, University of Washington, Department of Computer Science and Engineering. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. 

3. Neither name of the University of Washington, Department of Computer Science and Engineering nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Modified By: Waylon Brunette

*************************************************/

includes AM;


// needed by skyetek mini protocol as start/stop bytes
#define CR 0x0d  // carriage return
#define LF 0x0a  // line feed

#define MAX_RCV_SIZE 29 // receive buffer limited to 29 bytes  (1 TOS packet data size)

/* This component handles the packet abstraction on the network stack 
*/
module RFIDPacket {
  provides {
    interface StdControl as Control;
    interface ReceiveVarLenPacket as Receive;
    interface SendVarLenPacket;

  }
  uses {
    interface ByteComm;
    interface StdControl as ByteControl;
    interface Leds;
  }
}
implementation
{
  norace uint8_t rxCount;
  norace uint8_t txCount;
  uint8_t rxLength;
  norace uint8_t txLength;
  uint8_t buffer[MAX_RCV_SIZE];
  norace uint8_t *recPtr;
  norace uint8_t *sendPtr;
  norace uint8_t RXstate;
  norace result_t TXstate;

  enum {
    WAITING = 1,
    PACKET_RECEIVE = 2,
    END = 3
  };

  /* Initialization of this component */
  command result_t Control.init() {
    recPtr = (uint8_t *)&buffer;
    RXstate = WAITING;
    TXstate = SUCCESS;
    txCount = rxCount = 0;
    // make sure we always read up to the type (which determines length)
    rxLength = offsetof(TOS_Msg, type) + 1;
    dbg(DBG_BOOT, "Packet handler initialized.\n");

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


  /* Command to transfer a variable length packet */
  command result_t SendVarLenPacket.send(uint8_t* packet, uint8_t numBytes) {
      if (txCount == 0)
      {
        txCount = 1;
	txLength = numBytes + 1;
	sendPtr = packet;
	/* send the first byte */
	if (call ByteComm.txByte(CR))
	  return SUCCESS;
	else
	  txCount = 0;
      }
    return FAIL;
  }

  
  
  task void sendComplete() {
    signal SendVarLenPacket.sendDone((uint8_t*)sendPtr, TXstate);
    txCount = 0;
  }


  task void PacketRcvd()
   {
     uint8_t* tmp;

     dbg(DBG_PACKET, "got packet\n");  

     tmp = signal Receive.receive(recPtr, rxCount);
     if (tmp)
       recPtr = (uint8_t *)tmp;

     RXstate = WAITING;
     rxCount = 0;
   }


  
  /* Byte level component signals it is ready to accept the next byte.
     Send the next byte if there are data pending to be sent */
  async event result_t ByteComm.txByteReady(bool success) {
    if (txCount > 0)
      {
	if (!success)
	  {
	    dbg(DBG_ERROR, "TX_packet failed, TX_byte_failed");
	    TXstate = FAIL;
	    post sendComplete();
	  }
	else if (txCount < txLength)
	  {
	    dbg(DBG_PACKET, "PACKET: byte sent: %x, COUNT: %d\n",
		sendPtr[txCount-1], txCount);

            // txCount is one ahead because it sent a CR as its first message 
	    if (!call ByteComm.txByte(sendPtr[txCount-1]))
	      {  
	        TXstate = FAIL;
	        post sendComplete();
	      } 
	    else
	      txCount++;
	  }
        else if(txCount == txLength)
          {
	    if (!call ByteComm.txByte(CR))
              {
                TXstate = FAIL;
	        post sendComplete();
	      } 
	    else
	      txCount++;
          }
      }
    return SUCCESS;
  }

  async event result_t ByteComm.txDone() {
    if (txCount == txLength + 1)
    {
      TXstate = SUCCESS;
      post sendComplete();
    }
    return SUCCESS;
  }


  
  /* The handles the latest decoded byte propagated by the Byte Level
     component*/
  async event result_t ByteComm.rxByteReady(uint8_t data, bool error,
				      uint16_t strength) {
    dbg(DBG_PACKET, "PACKET: byte arrived: %x, COUNT: %d\n", data, rxCount);
    
    // look for the sync symbol, adjust state and discard symbol
    if (data == LF && RXstate == WAITING)
	  {
	    rxCount = 0;
	    RXstate = PACKET_RECEIVE;
	  }
    else if(RXstate == PACKET_RECEIVE)
      {
	// check to see if ending packet has arrived
	if(data == CR)
	  {
	    RXstate = END;
	    return SUCCESS;
	  }
	
	// Check to ensure you don't overflow the buffer
	if(rxCount < MAX_RCV_SIZE)
	  {
	    recPtr[rxCount++] = data;
	  }
	else
	  {
	    // there has been a problem
	    RXstate = WAITING;
	    rxCount = 0;
	  }
      }
    else if(RXstate == END && data == LF)
      {
        post PacketRcvd();
      }
	
    
    return SUCCESS;
  }
}





