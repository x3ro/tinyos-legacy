/* -*- Mode: C; c-basic-indent: 3; indent-tabs-mode: nil -*- */ 


/**
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

/**
 * Parts of this code were written or modified for FireBug project
 * funded by the NSF Information Technology Research
 * initiative.  Copyright Regents of the University of 
 * of California, 2003.
 *
 * @url http://firebug.sourceforge.net
 * 
 * @author David. M. Doolin
 */


/* This component handles the gps control and packet abstraction */
includes sensorboard;


module GpsPacketM {

  provides {
    interface StdControl as Control;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
    interface SendVarLenPacket;
    interface I2CSwitchCmds;// as GpsCmd;

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
    interface Switch as PowerSwitch;
    interface Switch as IOSwitch;

  }
}


implementation {

#include "SODebug.h"  
#define DBG_USR2 1


   enum {GPS_I2C_SWITCH_IDLE,        //GPS I2C switches are not using the I2C bus 
         GPS_PWR_SWITCH_WAIT,    //Waiting for GPS I2C power switch to set
         GPS_I2C_ENABLE_SWITCH_WAIT,     //Waiting for GPS I2C enable switch to set
         GPS_TX_SWITCH_WAIT,     //Waiting for GPS I2C tx switch to set
         GPS_RX_SWITCH_WAIT,     //Waiting for GPS I2C rx switch to set
   	};

   /** FIXME: Get rid of the norace specification. */
   norace GPS_Msg buffer;
   //GPS_Msg* bufferPtr;
   norace TOS_MsgPtr bufferPtr;         //really a GPS_Msg pointer

   norace uint8_t state_gps;            //state of I2C switches
   norace uint8_t power_gps;            //gps on off
   norace uint8_t state_gps_pkt;        //detect gps pckt
   norace uint8_t bufferIndex;
   norace uint8_t *recPtr;
   norace uint8_t *sendPtr;
   norace uint8_t state;

   norace uint16_t rxLength, txCount, txLength;

   /** This is only used in ByteComm.rxByteReady(), but 
    * apparently needs to maintain its value between
    * successive calls.
    * FIXME: Why isn't rxCount declared static in its
    * function?  Remove if possible.
    */
   norace uint16_t rxCount;

  
   enum {IDLE,
         PACKET,
         BYTES,
	 NO_GPS_START_BYTE = 0,
	 GPS_START_BYTE = 1,
	 GPS_BUF_NOT_AVAIL = 2
        };


  
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
      bufferIndex = 0;
      (GPS_Msg*) bufferPtr = &buffer;
      state_gps = GPS_I2C_SWITCH_IDLE;    
      state_gps_pkt = NO_GPS_START_BYTE;
      state = IDLE;
      txCount = 0;
      rxCount = 0;
      rxLength = GPS_DATA_LENGTH;
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

   /** FIXME: Explain why we would want to transmit bytes, instead
    * of just reading bytes.
    */
   command result_t txBytes(uint8_t *bytes, uint8_t numBytes) {

      if (txCount == 0) {

         txCount = 1;
         txLength = numBytes;
         sendPtr = bytes;
        /* send the first byte */
         if (call ByteComm.txByte(sendPtr[0])) {
            return SUCCESS;
         } else {
            txCount = 0;
         }
      }
      return FAIL;
   }


  /* Command to transmit a packet */
   command result_t Send.send(TOS_MsgPtr msg) {

     //GPS_Msg * gps_msg = (GPS_Msg*)msg;
     //state = PACKET;
      //msg->crc = 1; /* Fake out the CRC as passed. */

     state = PACKET;
      //return call txBytes((uint8_t *)msg, TOS_MsgLength(msg->type));
      //return call txBytes(msg->data, msg->length);
      return call SendVarLenPacket.send(msg->data, msg->length);
   }



  /* Command to transfer a variable length packet */
   command result_t SendVarLenPacket.send(uint8_t* packet, uint8_t numBytes) {

      state = BYTES;
      
      return call txBytes(packet, numBytes);
   }

  
   task void sendDoneFailTask() {

     txCount = 0;
     state = IDLE;
     signal Send.sendDone((TOS_MsgPtr)sendPtr, FAIL);
   }
  

   task void sendDoneSuccessTask() {

     txCount = 0;
     state = IDLE;
     signal Send.sendDone((TOS_MsgPtr)sendPtr, SUCCESS);
   }

   task void sendVarLenFailTask() {

     txCount = 0;
     state = IDLE;
     signal SendVarLenPacket.sendDone((uint8_t*)sendPtr, FAIL);
   }


   task void sendVarLenSuccessTask() {

      txCount = 0;
      state = IDLE;
      signal SendVarLenPacket.sendDone((uint8_t*)sendPtr, SUCCESS);
   }
  


   void sendComplete(result_t success) {

      if (state == PACKET) {

         TOS_MsgPtr msg = (TOS_MsgPtr)sendPtr;
	/* This is a non-ack based layer */
	 if (success) {
	    msg->ack = TRUE;
	    post sendDoneSuccessTask();
	 } else {
	    post sendDoneFailTask();
	 }
      } else if (state == BYTES) {
         if (success) {
	    post sendVarLenSuccessTask();
         } else {
	    post sendVarLenFailTask();
         }
      } else {
         txCount = 0;
         state = IDLE;
      }
   }

      
   default event result_t SendVarLenPacket.sendDone(uint8_t* packet, result_t success) {

      SODbg(DBG_USR2, "$GpsPacketM.SendVarLenPacket.sendDone(): success: %i\r\n", success);
      return success;
   }

   default event result_t Send.sendDone(TOS_MsgPtr msg, result_t success){

      return success;
   }
  
  
  /* Byte level component signals it is ready to accept the next byte.
     Send the next byte if there are data pending to be sent */
   async event result_t ByteComm.txByteReady(bool success) {

      if (txCount > 0) {

         if (!success) {

           //dbg(DBG_ERROR, "TX_packet failed, TX_byte_failed");
	    sendComplete(FAIL);
	 } else if (txCount < txLength) {

           //dbg(DBG_PACKET, "PACKET: byte sent: %x, COUNT: %d\n",sendPtr[txCount], txCount);
	    if (!call ByteComm.txByte(sendPtr[txCount++])) {
	      sendComplete(FAIL);
            }
	 }
      }
      return SUCCESS;
   }

   async event result_t ByteComm.txDone() {

      if (txCount == txLength) {
         sendComplete(TRUE);
      }
      return SUCCESS;
   }


  /**
   * Signal gps buffer avail
   * Only one buffer
   */
   task void receiveTask() {

     /** FIXME: tmp is unused. */
     //TOS_Msg * tmp =
     signal Receive.receive(bufferPtr);
     state_gps_pkt = NO_GPS_START_BYTE;
   }

  /**
   * Byte received from GPS
   * First byte in gps packet is reserved to count number of bytes rcvd.
   * Gps messages start with '$' (0x24) and end with <cr><lf> (0x0D, 0x0A),
   * which are defined in the header file.
   */
   async event result_t ByteComm.rxByteReady(uint8_t data, bool error,
				             uint16_t strength) {

      //GPSDbg(DBG_USR2, "PACKET: byte arrived: %x, COUNT: %i\n", data, rxCount);

      //FIXME: See if this works, remove global if possible.
      //static uint16_t rxCount = 0;

      if (error) {
         rxCount = 0;
	 return FAIL;
      }

      //if gps buffer not avail
      if (state_gps_pkt == GPS_BUF_NOT_AVAIL) {
         return SUCCESS;
      }

      if ((state_gps_pkt == NO_GPS_START_BYTE) && (data != GPS_PACKET_START)) {
         rxCount = 1;
	 return SUCCESS;
      } else {
         state_gps_pkt = GPS_START_BYTE;
      }
	
      recPtr[rxCount++] = data;
      recPtr[0] = rxCount;

      /** Hopefully, rxCount won't ever exceed GPS_DATA_LENGTH */    
      if (rxCount == GPS_DATA_LENGTH ) {

        //GPSDbg(DBG_USR2, "gps packet too large- flushed \n");  
         state_gps_pkt = NO_GPS_START_BYTE;
	 return SUCCESS;
      }

      if (data == GPS_PACKET_END2 ) {
         state_gps_pkt = GPS_BUF_NOT_AVAIL;
         rxCount = 1;
	 post receiveTask();
	 return SUCCESS;
      }

      //  bufferIndex = bufferIndex ^ 1;
      //  recPtr = (uint8_t*)bufferPtr;  ping pong buffers !!!!!!!!!!!!!!!!!!
      //  GPSDbg(DBG_USR2, "got gps packet; # of bytes =  %i  \n", rxCount);  
      //  rxCount = 0;
      //  post receiveTask();
      //  return FAIL;
      //}

      return SUCCESS;
   }


/******************************************************************************
 * Turn Gps  on/off
 * PowerState = 0 then GPS power off, GPS enable off, tx and rx disabled
 *            = 1 then GPS power on,  GPS enable on,  tx and rx enabled
 * NOTE - rx,tx share pressure lines.
 *      - GPS switching power supply is enabled by a lo, disabled by a hi
 *****************************************************************************/

   //command result_t GpsCmd.PowerSwitch(uint8_t PowerState){
   command result_t I2CSwitchCmds.PowerSwitch(uint8_t PowerState){

     //GPSDbg(DBG_USR2, "GpsPacket.PowerSwitch.setDone(): PowerState: %i \n", PowerState); 

      if (state_gps == GPS_I2C_SWITCH_IDLE){

         power_gps = PowerState;

         if (power_gps){
           /** Wired to MicaWBSwitch.set() */
            if (call PowerSwitch.set(MICAWB_GPS_POWER,0) == SUCCESS) {
               state_gps = GPS_PWR_SWITCH_WAIT;
               //GPSDbg(DBG_USR2, "GpsPacket.PowerSwitch.setDone(): 2d arg 0\n"); 
            }
         } else {
            if (call PowerSwitch.set(MICAWB_GPS_POWER,1) == SUCCESS) {
               state_gps = GPS_PWR_SWITCH_WAIT;
               //GPSDbg(DBG_USR2, "GpsPacket.PowerSwitch.setDone(): 2d arg 1\n"); 
            }
         }
         return SUCCESS;
      }
      return FAIL;
   } 



  /** Power or Enabled switch set */
   event result_t PowerSwitch.setDone(bool local_result) {

      if (state_gps == GPS_PWR_SWITCH_WAIT) {
         if (call PowerSwitch.set(MICAWB_GPS_ENABLE ,power_gps) == SUCCESS) {
            state_gps = GPS_I2C_ENABLE_SWITCH_WAIT;
         }
      } else if (state_gps == GPS_I2C_ENABLE_SWITCH_WAIT) {
         if (call IOSwitch.set( MICAWB_GPS_TX_SELECT ,power_gps) == SUCCESS) {
	    state_gps = GPS_TX_SWITCH_WAIT;
         }
      }
    
      return SUCCESS;
   }

   event result_t PowerSwitch.getDone(char value) {
      return SUCCESS;
   }


// Tx or Rx switch set
   event result_t IOSwitch.setDone(bool local_result) {

      if (state_gps == GPS_TX_SWITCH_WAIT) {
         if (call IOSwitch.set( MICAWB_GPS_RX_SELECT ,power_gps) == SUCCESS) {
	    state_gps = GPS_RX_SWITCH_WAIT;
         }
      } else if (state_gps == GPS_RX_SWITCH_WAIT) {
         state_gps = GPS_I2C_SWITCH_IDLE;
         //signal GpsCmd.SwitchesSet(state_gps);
         signal I2CSwitchCmds.SwitchesSet(state_gps);
      }
    
      return SUCCESS;
   }

   event result_t IOSwitch.setAllDone(bool local_result) {
      return SUCCESS;
   }


   event result_t PowerSwitch.setAllDone(bool local_result) {
      return SUCCESS;
   }

   event result_t IOSwitch.getDone(char value) {
      return SUCCESS;
   }
}

