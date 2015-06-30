/*									tab:0
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

/* Modified by Xbow:
 * -Use only for UART xmit/rcv
 * -Rcv msgs from RS232:
 *   -Looks for preamble on incoming uart packet.
 *   -Rejects bytes until correct hdr found
 * -Xmit msgs to RS232:
 *   -adds two bytes ofpreamble to pkt
 */

/* This component handles the packet abstraction on the network stack 
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
  TOS_Msg buffer;
  uint8_t *recPtr;
  uint8_t *sendPtr;
  bool    bHdr1Found;                //true if 1st uart pkt hdr found
  bool    bHdr2Found;                //true if 2nd uart pkt hdr found
  bool    bXmiting;                  //true if packet xmitting
  bool    bHdr2Xmit;                 //true if 2nd preamble xmitted
  enum {
    IDLE,
    PACKET,
    BYTES,
	HDR1 = 0xaa,                    //Uart packet preamble
	HDR2 = 0x55                     //Uart packet preamable  
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
  
/* ----------------------------------------------------------------------------
 * Initialization of this component   
 * --------------------------------------------------------------------------*/
  command result_t Control.init() {
    recPtr = (uint8_t *)&buffer;
    state = IDLE;
    txCount = rxCount = 0;
    bHdr1Found = FALSE;
    bHdr2Found = FALSE;
    //bHdr1Xmit =  FALSE;
    bHdr2Xmit =  FALSE;
	   	   
// make sure we always read up to the type (which determines length)
    rxLength = offsetof(TOS_Msg, type) + 1;
    dbg(DBG_BOOT, "Packet handler initialized.\n");

    return call ByteControl.init();
  }
/* ----------------------------------------------------------------------------
 * Command to control the power of the network stack   
 * --------------------------------------------------------------------------*/
  command result_t Control.start() {
    // apply your power management algorithm
    return call ByteControl.start();
  }
/* ----------------------------------------------------------------------------
 * Command to control the power of the network stack   
 * --------------------------------------------------------------------------*/
  command result_t Control.stop() {
    // apply your power management algorithm
    return call ByteControl.stop();
  }
/* ----------------------------------------------------------------------------
 * Xmit bytes to RS232
 * Add preamble before xmitting pckt    
 * --------------------------------------------------------------------------*/
  command result_t txBytes(uint8_t *bytes, uint8_t numBytes) {
    uint8_t cHdr;
	
	if (bXmiting) return FAIL;
    txCount = 0;
	bHdr2Xmit = TRUE;
    bXmiting = TRUE;
	txLength = numBytes;            //# of pckt byte to xmit
    sendPtr = bytes;                //pointer to packet
	if (call ByteComm.txByte(HDR1)) return SUCCESS;  //xmit 1st preamble byte
	return FAIL;
  }
/* ----------------------------------------------------------------------------
 * Command to xmit a packet to RS232      
 * --------------------------------------------------------------------------*/
  command result_t Send.send(TOS_MsgPtr msg) {
    state = PACKET;
    msg->crc = 1; /* Fake out the CRC as passed. */
    return call txBytes((uint8_t *)msg, TOS_MsgLength(msg->type));
  }
/* ----------------------------------------------------------------------------
 * Command to xmit a variable length pkt to RS232      
 * --------------------------------------------------------------------------*/
  command result_t SendVarLenPacket.send(uint8_t* packet, uint8_t numBytes) {
    state = BYTES;
    return call txBytes(packet, numBytes);
  }
/* ----------------------------------------------------------------------------
 * sendComplete      
 * --------------------------------------------------------------------------*/
  void sendComplete(result_t success) {
    if (state == PACKET){
        TOS_MsgPtr msg = (TOS_MsgPtr)sendPtr;
		if (success) msg->ack = TRUE;    /* This is a non-ack based layer */
	    signal Send.sendDone((TOS_MsgPtr)sendPtr, success);
    }
    else if (state == BYTES) signal SendVarLenPacket.sendDone((uint8_t*)sendPtr, success);
    
	state = IDLE;
    txCount = 0;
    bHdr2Xmit = FALSE;
	bXmiting = FALSE;    
  }
/* ----------------------------------------------------------------------------
 * SendVarLenPacket.sendDone      
 * --------------------------------------------------------------------------*/
 	default event result_t SendVarLenPacket.sendDone(uint8_t* packet, result_t success) {
    return success;
  }
/* ----------------------------------------------------------------------------
 * txByteReady:
 * Transmit next byte to RSR232.
 * Send the next byte if there are data pending to be sent
 * --------------------------------------------------------------------------*/
  event result_t ByteComm.txByteReady(bool success) {

   if (!success){
      dbg(DBG_ERROR, "TX_packet failed, TX_byte_failed");
      sendComplete(FAIL);
      return(SUCCESS);
   }
   
   if (!bXmiting) return SUCCESS;

// if bHdr2Xmit = true then xmit the 2nd hdr
    if (bHdr2Xmit){
	   bHdr2Xmit = FALSE;               //finished sending preamble
       if (!call ByteComm.txByte(HDR2)) sendComplete(FALSE);  //xmit preamble byte
	   return (SUCCESS);
	}   

	if (txCount < txLength){
	       dbg(DBG_PACKET, "PACKET: byte sent: %x, COUNT: %d\n", sendPtr[txCount], txCount);
	       if (!call ByteComm.txByte(sendPtr[txCount++])) sendComplete(FALSE);
    }
    return SUCCESS;
  }
/* ----------------------------------------------------------------------------
 * txDone:
 * Transmit of byte complete.
 * Check for end of pckt xmit
 * --------------------------------------------------------------------------*/
  event result_t ByteComm.txDone() {
    if (txCount == txLength) sendComplete(TRUE);
    return SUCCESS;
  }
/* ----------------------------------------------------------------------------
 * rxByteReady:
 * Receive next byte from RSR232.
 * Send the next byte if there are data pending to be sent
 * --------------------------------------------------------------------------*/
  event result_t ByteComm.rxByteReady(uint8_t data, bool error, uint16_t strength) {
    dbg(DBG_PACKET, "PACKET: byte arrived: %x, COUNT: %d\n", data, rxCount);
    
    if (error){
	   rxCount = 0;
	   return FAIL;
    }
//1st header of preamble found?
    if (!bHdr1Found)
	  if (data == HDR1){
		 bHdr1Found = TRUE;
		 return SUCCESS;
         rxCount = 0;
      }
	  else return TRUE;
//2nd header of preamble found?
	if (!bHdr2Found){
	  if (data == HDR2) {
	       bHdr2Found = TRUE;
		   return SUCCESS;
      }
	  else{                                  //1st preamble bytes found
	     bHdr1Found = FALSE;
		 rxCount = 0;
		 return TRUE;
	  }
    }
// Locked onto packet at this point
	if (rxCount == 0)
      ((TOS_MsgPtr)(recPtr))->strength = strength;

    if (rxCount == offsetof(TOS_Msg, type))
      rxLength = TOS_MsgLength(data);

    recPtr[rxCount++] = data;
    
    if (rxCount == rxLength){
	     TOS_MsgPtr tmp;
	     dbg(DBG_PACKET, "got packet\n");  
	     rxCount = 0;
         bHdr1Found = FALSE;
		 bHdr2Found = FALSE;
	     tmp = signal Receive.receive((TOS_MsgPtr)recPtr);
	     if (tmp)  recPtr = (uint8_t *)tmp;
	     return FAIL;
      }
    return SUCCESS;
  }
}





