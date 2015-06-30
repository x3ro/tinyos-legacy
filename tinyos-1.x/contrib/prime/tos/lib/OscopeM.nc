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
 * Authors:   Jason Hill, Kamin Whitehouse, Nelson Lee
 * History:   Jun 28, 2002
 *	     
 *
 *
 *
 *
 *
 * This applicaton periodically samples the ADC and sends a packet 
 * full of data out over the UART.  There are 10 readings per packet.
 * 
 * It has been expanded to let the user specify the following parameters:
 * 1.  Start and Stop
 * 2.  Data channel
 * 3.  Clock Speed
 * 4.  Max Number of Bytes
 * 5.  Number of bytes per reading
 * 6.  Whether to send the data as a packet or just as raw data
 */
includes OscopeMsg;
module OscopeM {
  provides {
    interface Oscope;
    interface StdControl;
  }
  
  uses {
    interface Clock;
    interface Leds;
    interface ADC[uint8_t port];
    interface ADCControl;
    interface StdControl as StdControlPhoto;
    interface StdControl as StdControlGenericComm;
    interface SendMsg as SendMsgGenericComm;
    interface SendVarLenPacket as UARTSendRawBytes;
  }
}


implementation {
  enum {
    AM_TYPE = 10, 
    INITIAL_DATA_CHANNEL = 1,
    START_SYMBOL = 0x7e, //this will be used in raw data mode
    SEND_PACKET_TO_UART = 0,
    SEND_RAW_DATA_TO_UART = 1,
    SEND_PACKET_TO_BCAST = 2
  };
  
  uint8_t active;                   //whether this component is sensing or not
  uint8_t bytesPerSample;
  uint8_t maxSamples;
  volatile uint8_t bufferIndex;	       
  uint16_t sampleCount;
  struct OscopeMsg* currentPkt;
  uint8_t currentBufferNumber;
  TOS_Msg msgBuffer[2];
  volatile uint8_t sendPending;
  uint8_t dataChannel;
  uint8_t  sendType; //0=raw UART data, 1=packet to UART, 2=packet to BCAST



  /* OSCOPE_INIT:  
     flash the LEDs
     initialize lower components.
     initialize component bufferIndex, including constant portion of msgs.
  */
  
  command result_t StdControl.init() {
    active = 0;
    bytesPerSample = 1;
    maxSamples = 0; //zero means collect indefinitly
    bufferIndex = 0;
    sampleCount = 0;
    currentPkt = (struct OscopeMsg*)msgBuffer[(int)currentBufferNumber].data;
    currentBufferNumber = 0;
    sendPending = 0;
    dataChannel = INITIAL_DATA_CHANNEL;
    sendType = SEND_PACKET_TO_UART;


    call Leds.init();
    call StdControlPhoto.init();
    call StdControlGenericComm.init();
    
    dbg(DBG_BOOT, ("OSCOPE initialized\n"));
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call StdControlPhoto.start();
    call StdControlGenericComm.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call StdControlPhoto.stop();
    call StdControlGenericComm.stop();
    return SUCCESS;
  }

  command result_t Oscope.setDataChannel(uint8_t channel) {
    dataChannel = channel;
    return SUCCESS;
  }

  command result_t Oscope.setBytesPerSample(uint8_t numBytes) {
    bytesPerSample = numBytes;
    return SUCCESS;
  }
 
  command result_t Oscope.setMaxSamples(uint8_t fmaxSamples) {
    maxSamples = fmaxSamples;
    return SUCCESS;
  }

  //indicates if the data is to be sent over the UART or broadcasted
  command result_t Oscope.setSendType(uint8_t fsendType) {
    sendType = fsendType;
    return SUCCESS;
  }
  
  command result_t Oscope.activate() {
    active = 1;
    call Clock.setRate(32, 3);
    return SUCCESS;
  }
  
  command result_t Oscope.deactivate() {
    active = 0;
    return SUCCESS;
  }
  
  command result_t Oscope.resetSampleCount() {
    sampleCount = 0;
    return SUCCESS;
  }
  
  event result_t ADC.dataReady[uint8_t port](uint16_t data) {
    TOS_MsgPtr msg;
    uint16_t  sendAddress = 0;
    dbg(DBG_USR1, "data_event\n");
    
    //store the data sample
    currentPkt->data[(int)bufferIndex] = data; 
    bufferIndex++;
    sampleCount++; 
    
    //if the buffer is full, send the data in one of three ways
    if (bufferIndex == BUFFER_SIZE) {
      if (sendPending == 0) {
	
	//if we want to send raw data, add a start symbol before data and send
	if(sendType == SEND_RAW_DATA_TO_UART) {
	  currentPkt->channel = START_SYMBOL;
	  if (call UARTSendRawBytes.send((uint8_t*)&(currentPkt->channel), BUFFER_SIZE*2+2)) {
	    sendPending++;
	  }
	}
	
	//otherwise prepare the packet and send
	else {
	  currentPkt->channel = dataChannel;
	  currentPkt->lastSampleNumber =  sampleCount;
	  currentPkt->sourceMoteID = TOS_LOCAL_ADDRESS;
	  
	  if(sendType == SEND_PACKET_TO_UART) {
	    sendAddress = TOS_UART_ADDR;
	  }else if(sendType == SEND_PACKET_TO_BCAST){
	    sendAddress=TOS_BCAST_ADDR;
	  }
	  
	  msg = &msgBuffer[(int)currentBufferNumber];
	  
	  if (call SendMsgGenericComm.send(sendAddress, sizeof(struct OscopeMsg), msg)) {
	    sendPending++;
	  }
	}
	
	//switch to the other buffer while this one is being sent
	bufferIndex = 0;
	currentBufferNumber ^= 0x1;
	currentPkt = (struct OscopeMsg*) msgBuffer[(int)currentBufferNumber].data;
      }
      
      //but if the old buffer is not finished being sent yet, wait a minute.
      else{
	bufferIndex--;
	sampleCount--;
      }
    } 
    return SUCCESS;
  }
  
  event result_t UARTSendRawBytes.sendDone(uint8_t* bytes, result_t success) {
    if ((uint8_t*)bytes == (uint8_t*)&(((struct OscopeMsg*)((msgBuffer[(int)currentBufferNumber^0x1]).data))->channel)){
      sendPending--;
      return SUCCESS;
    }
    return FAIL;
  }
  
  
  event result_t SendMsgGenericComm.sendDone(TOS_MsgPtr msg, result_t success) {
    if(msg == &msgBuffer[(int)currentBufferNumber^0x1]){
      sendPending--;
      return SUCCESS;
    }
    return FAIL;
  }
  
  event result_t Clock.fire() {
    if((active == 1) && ((maxSamples == 0) || (maxSamples > sampleCount) || (bufferIndex != 0)))
      call ADC.getData[dataChannel]();
    return SUCCESS;
  }
  
  
}
  
  
  
  
  

  
  




