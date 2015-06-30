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
 * Authors:		
 * Date last modified:  6/25/02
 *
 */

/* This component handles the gps control and packet abstraction */
includes sensorboard;
module GpsPacket {
    provides {
    interface StdControl as Control;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
    interface SendVarLenPacket;
    interface GpsCmd;

    command result_t txBytes(uint8_t *bytes, uint8_t numBytes);
    /* Effects: start sending 'numBytes' bytes from 'bytes' */
 //      command result_t GpsPower(uint8_t PowerState); 
 //      /* 0 => gps power off; 1 => gps power on */   
  }
  uses {
    interface ByteComm;
    interface StdControl as ByteControl;
    interface Leds;
    interface StdControl as SwitchControl;
    interface Switch as Switch1;
    interface Switch as SwitchI2W;
  }
}
implementation
{
#include "SODebug.h"
#include "gps.h"
 GPS_Msg buffer;
 //GPS_Msg* bufferPtr;
 TOS_MsgPtr bufferPtr;         //really a GPS_Msg pointer
 enum {GPS_SWITCH_IDLE,                      //GPS I2C switches are not using the I2C bus
	   GPS_PWR_SWITCH_WAIT,                  //Waiting for GPS I2C power switch to set
       GPS_EN_SWITCH_WAIT,                   //Waiting for GPS I2C enable switch to set
       GPS_TX_SWITCH_WAIT,                   //Waiting for GPS I2C tx switch to set
       GPS_RX_SWITCH_WAIT,                   //Waiting for GPS I2C rx switch to set
   	};

  uint8_t state_gps;            //state of I2C switches
  uint8_t power_gps;            //gps on off
  norace uint8_t state_gps_pkt;        //detect gps pckt

  uint16_t rxCount, rxLength, txCount, txLength;

  
  uint8_t bufferIndex;
  uint8_t *recPtr;
  uint8_t *sendPtr;
  
  enum {
    IDLE,
    PACKET,
    BYTES,
	   NO_GPS_START_BYTE = 0,
	   GPS_START_BYTE = 1,
	   GPS_BUF_NOT_AVAIL = 2
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
    atomic recPtr = (uint8_t *)&buffer;
    bufferIndex = 0;
    (GPS_Msg*) bufferPtr = &buffer;
    atomic{
      state_gps = GPS_SWITCH_IDLE;    
      state_gps_pkt = NO_GPS_START_BYTE;
      state = IDLE;
      txCount = rxCount = 0;
      rxLength = GPS_DATA_LENGTH;
    }
    return call ByteControl.init();
  }

 
  command result_t Control.start() {
    // apply your power management algorithm
        call SwitchControl.start();
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
    atomic state = PACKET;
    msg->crc = 1; /* Fake out the CRC as passed. */
    return call txBytes((uint8_t *)msg, TOS_MsgLength(msg->type));
  }

  /* Command to transfer a variable length packet */
  command result_t SendVarLenPacket.send(uint8_t* packet, uint8_t numBytes) {
    atomic state = BYTES;
    return call txBytes(packet, numBytes);
  }

  
  task void sendDoneFailTask() {
    atomic{
	  txCount = 0;
      state = IDLE;
    }
    signal Send.sendDone((TOS_MsgPtr)sendPtr, FAIL);
  }
  
  task void sendDoneSuccessTask() {
    atomic{
	  txCount = 0;
      state = IDLE;
    }
    signal Send.sendDone((TOS_MsgPtr)sendPtr, SUCCESS);
  }

  task void sendVarLenFailTask() {
    atomic{
	  txCount = 0;
      state = IDLE;
    }
    signal SendVarLenPacket.sendDone((uint8_t*)sendPtr, FAIL);
  }

  task void sendVarLenSuccessTask() {
    atomic {
      txCount = 0;
      state = IDLE;
    }
    signal SendVarLenPacket.sendDone((uint8_t*)sendPtr, SUCCESS);
  }
  
  void sendComplete(result_t success) {
   atomic{ 
    if (state == PACKET){
	       TOS_MsgPtr msg = (TOS_MsgPtr)sendPtr;
       	if (success) {           /* This is a non-ack based layer */
	       msg->ack = TRUE;
	       post sendDoneSuccessTask();
	   }
	   else {
	       post sendDoneFailTask();
	   }
      }
    else if (state == BYTES) {
      if (success) {
	        post sendVarLenSuccessTask();
      }
      else {
	        post sendVarLenFailTask();
      }
    }
    else {
      txCount = 0;
      state = IDLE;
    }
   } //atomic
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
   atomic{
    if (txCount > 0){
	     if (!success){
	        dbg(DBG_ERROR, "TX_packet failed, TX_byte_failed");
	        sendComplete(FAIL);
	     }
	     else if (txCount < txLength){
	        dbg(DBG_PACKET, "PACKET: byte sent: %x, COUNT: %d\n",
	       	sendPtr[txCount], txCount);
	        if (!call ByteComm.txByte(sendPtr[txCount++])) sendComplete(FAIL);
	     }
    }
   } //atomic
    return SUCCESS;
  }

 async  event result_t ByteComm.txDone() {
   atomic{
    if (txCount == txLength)
      sendComplete(TRUE);
    }
    return SUCCESS;
  }

/******************************************************************************
 * Signal gps buffer avail
 * Only one buffer
 *****************************************************************************/
  task void receiveTask() {
     bufferPtr = signal Receive.receive(bufferPtr);   //no pointer change on return
     atomic state_gps_pkt = NO_GPS_START_BYTE;
   }
/******************************************************************************
 * Byte received from GPS
 * First byte in gps packet is reserved to count number of bytes rcvd.
 * Gps messages start with '$' (0x24) and end with <cr><lf> (0x0D, 0x0A)
 *****************************************************************************/
  async event result_t ByteComm.rxByteReady(uint8_t data, bool error,
				      uint16_t strength) {
 //   SODbg(DBG_USR2, "PACKET: byte arrived: %x, COUNT: %i\n", data, rxCount);

	if (error){
	    rxCount = 0;
	    return FAIL;
      }
//if gps buffer not avail
    if (state_gps_pkt == GPS_BUF_NOT_AVAIL) return SUCCESS;

	if ((state_gps_pkt == NO_GPS_START_BYTE) && (data != GPS_PACKET_START)){
	    rxCount = 1;
	    return SUCCESS;
    }
    else{
        state_gps_pkt = GPS_START_BYTE;
    }
	
    recPtr[rxCount++] = data;
    recPtr[0] = rxCount;
    
	if (rxCount == GPS_DATA_LENGTH ){
	  SODbg(DBG_USR2, "gps packet too large- flushed \n");  
      state_gps_pkt = NO_GPS_START_BYTE;
	  return SUCCESS;
    }

	if (data == GPS_PACKET_END2 ){
	  state_gps_pkt = GPS_BUF_NOT_AVAIL;
      rxCount = 1;
	  post receiveTask(); 
	  return SUCCESS;
    }


//	    bufferIndex = bufferIndex ^ 1;
//        recPtr = (uint8_t*)bufferPtr;           ping pong buffers !!!!!!!!!!!!!!!!!!
	  //  SODbg(DBG_USR2, "got gps packet; # of bytes =  %i  \n", rxCount);  
	  //  rxCount = 0;
	  //  post receiveTask();
	  //  return FAIL;
    //}

    return SUCCESS;
  }

/******************************************************************************
 * Turn Gps  on/off
 * PowerState = 0 then GPS power off, GPS enable off
 *            = 1 then GPS power on,  GPS enable on
 * NOTE - GPS switching power supply is enabled by a lo, disabled by a hi
 *****************************************************************************/
command result_t GpsCmd.PowerSwitch(uint8_t PowerState){
    if (state_gps == GPS_SWITCH_IDLE){
	  power_gps = PowerState;
      if (power_gps){
        if (call Switch1.set(MICAWB_GPS_POWER,0) == SUCCESS) state_gps = GPS_PWR_SWITCH_WAIT;
      }
      else{
        if (call Switch1.set(MICAWB_GPS_POWER,1) == SUCCESS) state_gps = GPS_PWR_SWITCH_WAIT;
      }
      return SUCCESS;
    }
    return FAIL;
} 


// Power or Enabled switch set
  event result_t Switch1.setDone(bool local_result) {
    if (state_gps == GPS_PWR_SWITCH_WAIT) {
       if (call Switch1.set(MICAWB_GPS_ENABLE ,power_gps) == SUCCESS) {
       state_gps = GPS_EN_SWITCH_WAIT;
      }
    }
    else if (state_gps == GPS_EN_SWITCH_WAIT) {
       signal GpsCmd.PowerSet(power_gps);
       state_gps = GPS_SWITCH_IDLE;
    }
    
    
    return SUCCESS;
  }

 event result_t Switch1.getDone(char value) {
    return SUCCESS;
  }


/******************************************************************************
 * Turn Gps  Rx,Tx signals on/off
 * state = 0 then tx and rx disabled
 *       = 1 then tx and rx enabled
 * NOTE - rx,tx share pressure lines.
 *****************************************************************************/
command result_t GpsCmd.TxRxSwitch(uint8_t rtstate){
    power_gps = rtstate;   
    if (state_gps == GPS_SWITCH_IDLE){
      if (call SwitchI2W.set( MICAWB_GPS_TX_SELECT ,power_gps) == SUCCESS) {
	    state_gps = GPS_TX_SWITCH_WAIT;
        return SUCCESS;
      }
    }
	return FAIL;
}


// Tx or Rx switch set
  event result_t SwitchI2W.setDone(bool local_result) {
    if (state_gps == GPS_TX_SWITCH_WAIT) {
      if (call SwitchI2W.set( MICAWB_GPS_RX_SELECT ,power_gps) == SUCCESS) {
	  state_gps = GPS_RX_SWITCH_WAIT;
      }
    }
    else if (state_gps == GPS_RX_SWITCH_WAIT) {
	   SODbg(DBG_USR2, "GpsPacket: all switches set \n"); 
       state_gps = GPS_SWITCH_IDLE;
       signal GpsCmd.TxRxSet(power_gps);
    }
    
    return SUCCESS;
  }

  event result_t SwitchI2W.setAllDone(bool local_result) {
    return SUCCESS;
  }


  event result_t Switch1.setAllDone(bool local_result) {
    return SUCCESS;
  }

  event result_t SwitchI2W.getDone(char value) {
    return SUCCESS;
  }



}





