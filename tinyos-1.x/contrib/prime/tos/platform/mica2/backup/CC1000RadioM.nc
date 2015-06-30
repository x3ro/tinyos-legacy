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
 *  Authors: Philip Buonadonna, Jaein Jeong
 *  Date last modified: $Revision: 1.1.1.1 $
 *
 * This module provides the layer2 functionality for the mica2 radio.
 * While the internal architecture of this module is not CC1000 specific,
 * It does make some CC1000 specific calls via CC1000Control.
 * 
 */

module CC1000RadioM {
  provides {
    interface StdControl;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
    command result_t EnableRSSI();
    command result_t DisableRSSI();
  }
  uses {
    interface StdControl as CC1000StdControl;
    interface CC1000Control;
    interface Random;
    interface ADCControl;
    interface ADC as RSSIADC;
    interface SpiByteFifo;
  }
}
implementation {
  enum {
    DISABLED_STATE,
    IDLE_STATE,
    TXPEND_STATE,
    SYNC_STATE,
    RX_STATE,
    TX_STATE
  };

  enum {
    SYNC_BYTE =		0x33,
    NSYNC_BYTE =	0xcc,
    SYNC_WORD =		0x33cc,
    NSYNC_WORD =	0xcc33
  };

  enum {
    PREAMBLE_LEN =	18,
    VALID_PRECURSOR =	5
  };

  
  uint8_t RadioState;
  uint16_t txlength;
  uint16_t rxlength;
  TOS_MsgPtr txbufptr;  // pointer to transmit buffer
  TOS_MsgPtr rxbufptr;  // pointer to receive buffer
  TOS_Msg RxBuf;	// save received messages

  uint8_t PreambleCount;  //  found a valid preamble
  uint8_t SOFCount;
  union {
    uint16_t W;
    struct {
      uint8_t LSB;
      uint8_t MSB;
    };
  } RxShiftBuf;
  uint8_t RxBitOffset;	// bit offset for spibus
  uint8_t RxByteCnt;	// received byte counter
  bool bInvertRxData;	// data inverted
  bool bRSSIEnable;	// RSSI flag
  uint16_t usRunningCRC; // Running CRC variable
  int16_t sMacDelay;    // MAC delay for the next transmission
  // XXX-PB:
  // Here's the deal, the mica (RFM) radio stacks used TOS_LOCAL_ADDRESS
  // to determine if an L2 ack was reqd.  This stack doesn't do L2 acks
  // and, thus doesn't need it.  HOWEVER, set-mote-id breaks if it 
  // compiles a program that doesn't have the symbol TOS_LOCAL_ADDRESS in
  // the binary.  This occurs in programs such as GenericBase.
  // Thus, I put this LocalAddr here and set it to TOS_LOCAL_ADDRESS
  // to keep things happy for now.
  volatile uint16_t LocalAddr;

  ///**********************************************************
  //* local function definitions
  //**********************************************************/
  
  short add_crc_byte(char new_byte, short crc){
    uint8_t i;
    crc = crc ^ (int) new_byte << 8;
    i = 8;
    do
      {
	if (crc & 0x8000)
	  crc = crc << 1 ^ 0x1021;
	else
	  crc = crc << 1;
      } while(--i);
    return crc;
  }
  

  void TransmitPkt() {
    uint16_t i;
    char byte;
	  
    usRunningCRC = 0;
    // time to transmit a packet
    cli(); // XXX-PB We're already in interrupt state, aren't we??

    call CC1000Control.TxMode();	// radio to tx mode
    call SpiByteFifo.txMode();		// SPI to miso
	  
    for (i=0;i<PREAMBLE_LEN;i++) {
      call SpiByteFifo.writeByte(0xaa);
    }
    call SpiByteFifo.writeByte(SYNC_BYTE);
    call SpiByteFifo.writeByte(NSYNC_BYTE);
	  
    for (i=0;i<txlength;i++) {
      byte = ((char*)txbufptr)[i];
      usRunningCRC = add_crc_byte(byte,usRunningCRC);
      call SpiByteFifo.writeByte(byte);
    }
    byte = (char)(usRunningCRC);
    call SpiByteFifo.writeByte(byte);
    byte = (char)(usRunningCRC>>8);
    call SpiByteFifo.writeByte(byte);

    // wait for byte buffer to empty
    while(call SpiByteFifo.isBufBusy()) ;
	  
    call SpiByteFifo.rxMode();		// SPI to miso
    call CC1000Control.RxMode();	// radio to rx mode
	  
    RadioState = IDLE_STATE;
    sMacDelay = -1;
    signal Send.sendDone((TOS_MsgPtr)txbufptr, SUCCESS);	// signal rfcomm
    call SpiByteFifo.enableIntr();	// enable spi interrupts
    sei();  // enable interrupts
  
  }
  ///**********************************************************
  //* Exported interface functions
  //**********************************************************/
  
  command result_t StdControl.init() {
    RadioState = IDLE_STATE;
    rxbufptr = &RxBuf;
    rxlength = MSG_DATA_SIZE-2;
    RxBitOffset = 0;

    PreambleCount = 0;
    RxShiftBuf.W = 0;
    sMacDelay = -1;

    call SpiByteFifo.initSlave(); // set spi bus to slave mode
    call CC1000StdControl.init();
    call CC1000Control.SelectLock(0x9);		// Select MANCHESTER VIOLATION
    bInvertRxData = call CC1000Control.GetLOStatus();  //Do we need to invert Rcvd Data?

    call ADCControl.bindPort(TOS_ADC_CC_RSSI_PORT,TOSH_ACTUAL_CC_RSSI_PORT);
    call ADCControl.init();

    call Random.init();

    call SpiByteFifo.enableIntr(); // enable spi and spi interrupt
    LocalAddr = TOS_LOCAL_ADDRESS;
    bRSSIEnable = TRUE;	   // rssi disabled

    return SUCCESS;
  }
  

  command result_t EnableRSSI() {
    bRSSIEnable = TRUE;

    return SUCCESS;
  }

  command result_t DisableRSSI() {
    bRSSIEnable = FALSE;

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    RadioState = DISABLED_STATE;

    call CC1000StdControl.stop();
    call SpiByteFifo.disableIntr(); // disable spi interrupt

    return SUCCESS;
  }

  command result_t StdControl.start() {
    RadioState  = IDLE_STATE;
    sMacDelay = -1;
    //call Chipcon.rf_pwup();
    call CC1000StdControl.start();
    call SpiByteFifo.enableIntr(); // enable spi interrupt

    return SUCCESS;
  }

  command result_t Send.send(TOS_MsgPtr pMsg) {
    // msg is pointer to new transmit packet
    if (sMacDelay != -1) {
      return FAIL;
    }
    txbufptr = pMsg;
    txlength = pMsg->length + (MSG_DATA_SIZE - DATA_LENGTH - 2); 
    sMacDelay = ((call Random.rand() & 0x3f) + 100) >> 3;
    return SUCCESS;
  }
  
  /**********************************************************
   * make a spibus interrupt handler
   * needs to handle interrupts for transmit delay
   * and then go into byte transmit mode with
   *   timer1 baudrate delay as interrupt handler
   * else
   * needs to handle interrupts for byte read and detect preamble
   *  then handle reading a packet
   * PB - We can use this interrupt handler as a transmit scheduler
   * because the CC1000 continuously clocks in data, regarless
   * of whether it's good or not.  Thus, this routine will be called
   * on every 8 ticks of DCLK. 
   **********************************************************/

  event result_t SpiByteFifo.dataReady(uint8_t data_in) {

    if (bInvertRxData) 
      data_in = ~data_in;

    switch (RadioState) {

    case DISABLED_STATE:
      break;

    case IDLE_STATE:
      {
	bool bManchesterBad;
	bManchesterBad = call CC1000Control.GetLock();
	if ((!bManchesterBad) && ((data_in == (0xaa)) || (data_in == (0x55)))) {
	  PreambleCount++;
	  if (PreambleCount > VALID_PRECURSOR) {
	    PreambleCount = SOFCount = 0;
	    RxBitOffset = RxByteCnt = 0;
	    usRunningCRC = 0;
	    rxlength = MSG_DATA_SIZE-2;
	    RadioState = SYNC_STATE;
	    if (bRSSIEnable) {
	      // Sample signal strength for this packet.
	      call RSSIADC.getData();
	    }
	  }
	  else if (sMacDelay != -1) {
	    sMacDelay = ((call Random.rand() & 0x3f) + 100) >> 3;
	  }
	}
	else {
	  PreambleCount = 0;

	  if ((sMacDelay != -1) && (--sMacDelay == 0)) { // tx timeout go to tx mode
	    TransmitPkt();
	  }
	}
      }
      break;
      
    case SYNC_STATE:
      {
	// draw in the preamble bytes and look for a sync byte
	// save the data in a short with last byte received as msbyte
	//    and current byte received as the lsbyte.
	// use a bit shift compare to find the byte boundary for the sync byte
	// retain the shift value and use it to collect all of the packet data
	// check for data inversion, and restore proper polarity XXX-PB: Don't do this.
	uint8_t i;
      
	if ((data_in == 0xaa) || (data_in == 0x55)) {
	  // It is actually possible to have the LAST BIT of the incoming
	  // data be part of the Sync Byte.  SO, we need to store that
	  // However, the next byte should definitely not have this pattern.
	  // XXX-PB: Do we need to check for excessive preamble?
	  RxShiftBuf.MSB = data_in;
	
	}
	else {
	  // TODO: Modify to be tolerant of bad bits in the preamble...
	  uint16_t usTmp;
	  switch (SOFCount) {
	  case 0:
	    RxShiftBuf.LSB = data_in;
	    break;
	  
	  case 1:
	  case 2: 
	    // bit shift the data in with previous sample to find sync
	    usTmp = RxShiftBuf.W;
	    RxShiftBuf.W <<= 8;
	    RxShiftBuf.LSB = data_in;

	    for(i=0;i<8;i++) {
	      usTmp <<= 1;
	      if(data_in & 0x80)
		usTmp  |=  0x1;
	      data_in <<= 1;
	      // check for sync bytes
	      if (usTmp == SYNC_WORD) {
		RadioState = RX_STATE;
		RxBitOffset = 7-i;
		break;
	      }
#if 0
	      else if (usTmp == NSYNC_WORD) {
		RadioState = RX_STATE;
		RxBitOffset = 7-i;
		bInvertRxData = TRUE;
		break;
	      }
#endif
	    }
	    break;

	  default:
	    // We didn't find it after a reasonable number of tries, so....
	    RadioState = IDLE_STATE;
	    break;
	  }
	  SOFCount++;
	}

      }
      break;
      //  collect the data and shift into double buffer
      //  shift out data by correct offset
      //  invert the data if necessary
      //  stop after the correct packet length is read
      //  return notification to upper levels
      //  go back to idle state
    case RX_STATE:
      {
	char Byte;

	RxShiftBuf.W <<=8;
	RxShiftBuf.LSB = data_in;

#if 0
	if (bInvertRxData) {
	  Byte= ~(RxShiftBuf.W >> RxBitOffset);
	}
	else {
	  Byte = (RxShiftBuf.W >> RxBitOffset);
	}
#endif
	Byte = (RxShiftBuf.W >> RxBitOffset);
	((char*)rxbufptr)[(int)RxByteCnt] = Byte;
	RxByteCnt++;

	if (RxByteCnt < rxlength) {
	  usRunningCRC = add_crc_byte(Byte,usRunningCRC);

	  if (RxByteCnt == (offsetof(struct TOS_Msg,length) + 
			    sizeof(((struct TOS_Msg *)0)->length))) {
	    rxlength = rxbufptr->length;
	    if (rxlength > TOSH_DATA_LENGTH) {
	      // The packet's screwed up, so just dump it
	      RadioState = IDLE_STATE;
	      return SUCCESS;
	    }
	    //Add in the header size
	    rxlength += offsetof(struct TOS_Msg,data);
	  }
	}
	else if (RxByteCnt == rxlength) {
	  // We've reached the end of the header/payload stream. Next two
	  // rcvd bytes should be CRC. Advanced counter to 'crc' field.
	  usRunningCRC = add_crc_byte(Byte,usRunningCRC);
	  // Shift index ahead to the crc field.
	  RxByteCnt = offsetof(struct TOS_Msg,crc);
	}
	else if (RxByteCnt >= MSG_DATA_SIZE) { 
	  RadioState = IDLE_STATE;
	  if (rxbufptr->crc == usRunningCRC) {
	    rxbufptr = signal Receive.receive((TOS_Msg*)rxbufptr); // signal rfcomm
	  }
	  if (sMacDelay != -1) {
	    sMacDelay = ((call Random.rand() & 0x3f) + 100) >> 3;
	  }
	}
      }

      break;

    default:
      break;
    }

    return SUCCESS;
  }

  event result_t RSSIADC.dataReady(uint16_t data) {
    rxbufptr->strength = data;
    return SUCCESS;
  }
}




