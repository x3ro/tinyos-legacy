// $Id: CC1000RadioIntM.nc,v 1.1 2004/09/13 17:24:41 jdprabhu Exp $

/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
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
 *  Authors: Philip Buonadonna, Jaein Jeong, Joe Polastre
 *  Date last modified: $Revision: 1.1 $
 *
 * This module provides the layer2 functionality for the mica2 radio.
 * While the internal architecture of this module is not CC1000 specific,
 * It does make some CC1000 specific calls via CC1000Control.
 * 
 */

/**
 * @author Philip Buonadonna
 * @author Jaein Jeong
 * @author Joe Polastre
 */
  
includes crc;
includes CC1000Const;

module CC1000RadioIntM {
  provides {
    interface StdControl;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
    command result_t EnableRSSI();
    command result_t DisableRSSI();
    command result_t SetListeningMode(uint8_t power);
    command uint8_t GetListeningMode();
    command result_t SetTransmitMode(uint8_t power);
    command uint8_t GetTransmitMode();
    command uint16_t GetSquelch();
    command uint16_t GetRxCount();
    command uint16_t GetSendCount();
    command uint16_t GetPower();
    command uint16_t GetPower_check();
    command uint16_t GetPower_send();
    command uint16_t GetPower_receive();
    command uint16_t GetPower_total_sum();
    interface RadioCoordinator as RadioSendCoordinator;
    interface RadioCoordinator as RadioReceiveCoordinator;
  }
  uses {
    interface PowerManagement;
    interface StdControl as TimeStart;
    interface StdControl as CC1000StdControl;
    interface CC1000Control;
    interface Random;
    interface ADCControl;
    interface ADC as RSSIADC;
    interface SpiByteFifo;
    interface StdControl as TimerControl;
    interface Timer as WakeupTimer;
    interface Timer as SquelchTimer;
    interface Leds;
    interface Time;
    command uint8_t EnableLowPower();
  }
}
implementation {
  enum {
    TX_STATE,
    DISABLED_STATE,
    IDLE_STATE,
    SYNC_STATE,
    RX_STATE,
    SENDING_ACK,
    POWER_DOWN_STATE,
    WAKE_UP_AND_SEND,
    PULSE_CHECK_STATE,
  };

  enum {
    TXSTATE_WAIT,
    TXSTATE_START,
    TXSTATE_PREAMBLE,
    TXSTATE_SYNC,
    TXSTATE_DATA,
    TXSTATE_CRC,
    TXSTATE_FLUSH,
    TXSTATE_WAIT_FOR_ACK,
    TXSTATE_READ_ACK,
    TXSTATE_DONE
  };

  enum {
    SYNC_BYTE =		0x33,
    NSYNC_BYTE =	0xcc,
    SYNC_WORD =		0x33cc,
    NSYNC_WORD =	0xcc33,
    ACK_LENGTH =	16,
    MAX_ACK_WAIT =	18,
    TIME_BETWEEN_CHECKS = 50,
    TIME_AFTER_CHECK = 5,
    CHECK_MA_COUNT =	7792,
    SEND_MA_COUNT =	5333,
    PREAMBLE_LENGTH_SHORT = 58,
    RECEIVE_MA_COUNT = 8471

  };

  uint8_t ack_code[5] = {0xab, 0xba, 0x83, 0xaa, 0xaa};

  uint8_t RadioState;
  uint8_t RadioTxState;
  norace uint8_t iRSSIcount;
  uint8_t iSquelchCount;
  uint16_t txlength;
  uint16_t rxlength;
  TOS_MsgPtr txbufptr;  // pointer to transmit buffer
  TOS_MsgPtr rxbufptr;  // pointer to receive buffer
  TOS_Msg RxBuf;	// save received messages
  uint8_t NextTxByte;

  uint8_t lplpower;        //  low power listening mode
  uint8_t lplpowertx;      //  low power listening transmit mode

  uint16_t preamblelen;    //  current length of the preamble
 
  uint16_t PreambleCount;   //  found a valid preamble
  uint8_t SOFCount;

  uint16_t search_word;
  uint8_t slot_delay;

  union {
    uint16_t W;
    struct {
      uint8_t LSB;
      uint8_t MSB;
    };
  } RxShiftBuf;

  uint8_t RxBitOffset;	// bit offset for spibus
  uint16_t RxByteCnt;	// received byte counter
  uint16_t TxByteCnt;
  uint16_t RSSISampleFreq; // in Bytes rcvd per sample
  norace bool bInvertRxData;	// data inverted
  norace bool bTxPending;
  bool bTxBusy;
  bool bRSSIValid;
  uint16_t usRunningCRC; // Running CRC variable
  uint16_t usRSSIVal;
  uint16_t usSquelchVal;
  uint16_t usTempSquelch;
  uint8_t usSquelchIndex;
  norace uint8_t pulse_check_count;
  norace uint16_t CC1K_PulseLevel;
  norace uint16_t pulse_check_sum;
  norace int32_t total_sum;
  norace uint16_t unknown_sum;
  norace uint16_t send_sum;
  norace uint16_t receive_sum;
  norace uint16_t pulse_check_mam;
  norace uint16_t send_mam;
  norace uint16_t receive_mam;
  norace uint16_t power_sum;
  norace uint16_t rx_count;
  norace uint16_t send_count;

  uint16_t usSquelchTable[CC1K_SquelchTableSize];

  // XXX-PB:
  // Here's the deal, the mica (RFM) radio stacks used TOS_LOCAL_ADDRESS
  // to determine if an L2 ack was reqd.  This stack doesn't do L2 acks
  // and, thus doesn't need it.  HOWEVER, some set-mote-id versions
  // break if this symbol is missing from the binary.
  // Thus, I put this LocalAddr here and set it to TOS_LOCAL_ADDRESS
  // to keep things happy for now.
  volatile uint16_t LocalAddr;

  ///**********************************************************
  //* local function definitions
  //**********************************************************/

/*
  int sortByShort(const void *x, const void *y) {
    uint16_t* x1 = (uint16_t*)x;
    uint16_t* y1 = (uint16_t*)y;
    if (x1[0] > y1[0]) return -1;
    if (x1[0] == y1[0]) return 0;
    if (x1[0] < y1[0]) return 1;
    return 0; // shouldn't reach here becasue it covers all the cases
  }
*/

  task void adjustSquelch() {
    uint16_t tempArray[CC1K_SquelchTableSize];
    char i,j,min; 
    uint16_t min_value;

    atomic {
      usSquelchTable[usSquelchIndex] = usTempSquelch;
      usSquelchIndex++;
      if (usSquelchIndex >= CC1K_SquelchTableSize)
        usSquelchIndex = 0;
      if (iSquelchCount <= CC1K_SquelchCount)
        iSquelchCount++;  
    }

    for (i=0; i<CC1K_SquelchTableSize; i++) {
      tempArray[(int)i] = usSquelchTable[(int)i];
    }

    min = 0;
    for (j = 0; j < ((CC1K_SquelchTableSize) >> 1); j++) {
      for (i = 1; i < CC1K_SquelchTableSize; i++) {
        if ((tempArray[(int)i] != 0xFFFF) && 
            (tempArray[(int)i] < tempArray[(int)min])) {
          min = i;
        }
      }
      min_value = tempArray[(int)min];
      tempArray[(int)min] = 0xFFFF;
    }

    atomic usSquelchVal = ((usSquelchVal << 4) + (min_value << 1)) / 18;

    /*
    // XXX: qsort actually causes ~600bits/sec lower bandwidth... why???
    //
    qsort (tempArray,CC1K_SquelchTableSize, sizeof(uint16_t),sortByShort);
    min_value = tempArray[CC1K_SquelchTableSize >> 1];
    atomic usSquelchVal = ((usSquelchVal << 4) + (min_value << 1)) / 18;
    */


  }

  task void PacketRcvd() {
    TOS_MsgPtr pBuf;
    rx_count ++;
 
    atomic {
      rxbufptr->time = 0;
      pBuf = rxbufptr;
    }
    pBuf = signal Receive.receive((TOS_MsgPtr)pBuf);
    atomic {
      if (pBuf) 
	rxbufptr = pBuf;
      rxbufptr->length = 0;
    }
    call SpiByteFifo.enableIntr();
    call WakeupTimer.start(TIMER_ONE_SHOT, 1);
  }
  
  task void PacketSent() {
    TOS_MsgPtr pBuf; //store buf on stack 
    atomic {
      txbufptr->time = 0;
      pBuf = txbufptr;
    }
    signal Send.sendDone((TOS_MsgPtr)pBuf,SUCCESS);
    atomic bTxBusy = FALSE;
    call WakeupTimer.start(TIMER_ONE_SHOT, 1);
  }

  ///**********************************************************
  //* Exported interface functions
  //**********************************************************/
  
  command result_t StdControl.init() {

    char i;

    rx_count = 0;
    send_count = 0;
    pulse_check_mam = 0;
    power_sum = 0;
    receive_mam = 0;
    send_mam = 0;

    atomic {
      RadioState = DISABLED_STATE;
      RadioTxState = TXSTATE_PREAMBLE;
      rxbufptr = &RxBuf;
      rxbufptr->length = 0;
      rxlength = MSG_DATA_SIZE-2;
      RxBitOffset = 0;
      iSquelchCount = 0;
      
      PreambleCount = 0;
      RSSISampleFreq = 0;
      RxShiftBuf.W = 0;
      iRSSIcount = 0;
      bTxPending = FALSE;
      bTxBusy = FALSE;
      bRSSIValid = FALSE;
      usRSSIVal = -1;
      usSquelchIndex = 0;
      pulse_check_count = 0;
      lplpower =  0x87;
      if(TOS_LOCAL_ADDRESS == 0) lplpower = 0;
      lplpowertx = 7;
      usSquelchVal = CC1K_SquelchInit;
      CC1K_PulseLevel = 300;
    }

    for (i = 0; i < CC1K_SquelchTableSize; i++)
      usSquelchTable[(int)i] = CC1K_SquelchInit;

    call SpiByteFifo.initSlave(); // set spi bus to slave mode
    call TimeStart.init();
    call CC1000StdControl.init();
    call CC1000Control.SelectLock(0x9);		// Select MANCHESTER VIOLATION
    bInvertRxData = call CC1000Control.GetLOStatus();

    call ADCControl.bindPort(TOS_ADC_CC_RSSI_PORT,TOSH_ACTUAL_CC_RSSI_PORT);
    call ADCControl.init();

    call Random.init();
    call TimerControl.init();
    if(TOS_LOCAL_ADDRESS != 0) call EnableLowPower();

    LocalAddr = TOS_LOCAL_ADDRESS;

    return SUCCESS;
  }
  

  command result_t EnableRSSI() {

    return SUCCESS;
  }

  command result_t DisableRSSI() {

    return SUCCESS;
  }

  command uint8_t GetTransmitMode() {
    return lplpowertx;
  }

  /**
   * Set the state of low power transmit on the chipcon radio.
   * The transmit mode of the sender *must* match the receiver in
   * order for the receiver to successfully get the packet.
   * <p>
   * The default power up state is 0 (radio always on).
   * See CC1000Const.h for low power duty cycles and bandwidth
   */
  command result_t SetTransmitMode(uint8_t power) {
    if ((power >= CC1K_LPL_STATES) || (power == lplpowertx))
      return FAIL;

    // check if the radio is currently doing something
    if ((!bTxPending) && ((RadioState == POWER_DOWN_STATE) || 
			  (RadioState == IDLE_STATE) ||
			  (RadioState == DISABLED_STATE))) {

      atomic {
	lplpowertx = power;
	preamblelen = ((PRG_RDB(&CC1K_LPL_PreambleLength[lplpowertx*2]) << 8)
                       | PRG_RDB(&CC1K_LPL_PreambleLength[(lplpowertx*2)+1]));
      }
      return SUCCESS;
    }
    return FAIL;
  }

  /**
   * Set the state of low power listening on the chipcon radio.
   * <p>
   * The default power up state is 0 (radio always on).
   * See CC1000Const.h for low power duty cycles and bandwidth
   */
  command result_t SetListeningMode(uint8_t power) {
    // valid low power listening values are 0 to 3
    // 0 is "always on" and 3 is lowest duty cycle
    // 1 and 2 are in the middle
    if ((power >= CC1K_LPL_STATES) || (power == lplpower))
      return FAIL;

    // check if the radio is currently doing something
    if ((!bTxPending) && ((RadioState == POWER_DOWN_STATE) || 
			  (RadioState == IDLE_STATE) ||
			  (RadioState == DISABLED_STATE))) {

      // change receiving function in CC1000Radio
      call WakeupTimer.stop();
      atomic {
	if (lplpower == lplpowertx) {
	  lplpowertx = power;
	}
	lplpower = power;
      }

      // if successful, change power here
      if (RadioState == IDLE_STATE) {
	RadioState = DISABLED_STATE;
	call StdControl.stop();
	call StdControl.start();
      }
      if (RadioState == POWER_DOWN_STATE) {
	RadioState = DISABLED_STATE;
	call StdControl.start();
	call PowerManagement.adjustPower();
      }
    }
    else {
      return FAIL;
    }
    return SUCCESS;
  }

  /**
   * Gets the state of low power listening on the chipcon radio.
   * <p>
   * @return Current low power listening state value
   */
  command uint8_t GetListeningMode() {
    return lplpower;
  } 

  event result_t SquelchTimer.fired() {
    char currentRadioState;
    atomic currentRadioState = RadioState;

    if (currentRadioState == IDLE_STATE)
      call RSSIADC.getData();
    return SUCCESS;
  }

void set_sleep_time(){
	uint16_t curtime;
      uint16_t sleeptime;
      curtime = (uint16_t) call Time.getLow32();
      curtime &= 0x7f;
      sleeptime = 128 - curtime;
      if(sleeptime < 15) sleeptime += 128;
      call WakeupTimer.start(TIMER_ONE_SHOT, sleeptime);
}

void set_send_time(){
      uint16_t sleeptime;
      sleeptime = 130;
      if(txbufptr->strength == 0xffff){
		sleeptime -= 15;
      }else{
		sleeptime += 6;
      }
      call WakeupTimer.start(TIMER_ONE_SHOT, sleeptime);
      atomic RadioState = WAKE_UP_AND_SEND;
}

  void clr_power(){
	uint8_t  mcu;
 	mcu = inp(MCUCR);
	mcu &= 0xe3;
	outp(mcu, MCUCR);
	sbi(MCUCR, SE);
  }

task void SleepTimerTask(){
	set_sleep_time();
	call PowerManagement.adjustPower();
}


void start_send(){
	call SpiByteFifo.disableIntr(); // enable spi interrupt
	call CC1000StdControl.start();
	call CC1000Control.BIASOn();
	bRSSIValid = FALSE;
      	call SpiByteFifo.writeByte(0xaa);
      	call CC1000Control.TxMode();
      	call SpiByteFifo.txMode();
  	rxbufptr->length = 0;
      	atomic {
        	TxByteCnt = 0;
        	usRunningCRC = 0;
        	RadioTxState = TXSTATE_PREAMBLE;
        	NextTxByte = 0xaa;
        	RadioState = TX_STATE;
      	}
	call SpiByteFifo.enableIntr(); // enable spi interrupt
	call WakeupTimer.start(TIMER_ONE_SHOT, 10);
	call PowerManagement.adjustPower();
}

task void QuickSleepTimerTask(){
	set_sleep_time();
#ifdef FREQ_433_MHZ
        	TOSH_uwait(90);
#endif
		pulse_check_sum ++;
        	if(!(call RSSIADC.getData())){
        		atomic RadioState = POWER_DOWN_STATE;
		}
  		clr_power();
        	TOSH_uwait(15);
        	call CC1000Control.BIASOn();
}

  event result_t WakeupTimer.fired() {
  
    uint8_t currentRadioState;


    if (lplpower == 0)
      return SUCCESS;

    atomic currentRadioState = RadioState;
    switch(currentRadioState) {
    case IDLE_STATE:
        atomic RadioState = POWER_DOWN_STATE;
        call SquelchTimer.stop();
        call CC1000StdControl.stop();
	call SpiByteFifo.disableIntr();
	post SleepTimerTask();
      break;

    case WAKE_UP_AND_SEND:
	start_send();
	break;

    case POWER_DOWN_STATE:
	if(bTxPending){
		if(slot_delay > 0){
			 slot_delay --;
		}else {
			set_send_time();
			break;
		}
	}
      	atomic RadioState = PULSE_CHECK_STATE;
      	call CC1000Control.BIASOn();
      	call WakeupTimer.start(TIMER_ONE_SHOT, 1);
      break;

    case PULSE_CHECK_STATE:
	atomic{
        	call CC1000Control.LPL_rx();
		//delay here...
		post QuickSleepTimerTask();
      		pulse_check_count = 0;
		//set_sleep_time();
		
        	/*TOSH_uwait(90);
		pulse_check_sum ++;
        	if(!(call RSSIADC.getData())){
        		atomic RadioState = POWER_DOWN_STATE;
		}
  		clr_power();
        	TOSH_uwait(15);
        	call CC1000Control.BIASOn();*/
	}
        break;

    default:
      call WakeupTimer.start(TIMER_ONE_SHOT, 5);
    }
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    atomic RadioState = DISABLED_STATE;

    call SquelchTimer.stop();
    call WakeupTimer.stop();
    call CC1000StdControl.stop();
    call SpiByteFifo.disableIntr(); // disable spi interrupt
    return SUCCESS;
  }

  command result_t StdControl.start() {
    uint8_t currentRadioState;
    atomic currentRadioState = RadioState;
    call TimeStart.start();
    if (currentRadioState == DISABLED_STATE) {
      atomic {
        rxbufptr->length = 0;
        RadioState  = IDLE_STATE;
        bTxPending = bTxBusy = FALSE;
        preamblelen = ((PRG_RDB(&CC1K_LPL_PreambleLength[lplpowertx*2]) << 8) |
		     PRG_RDB(&CC1K_LPL_PreambleLength[(lplpowertx*2)+1]));
      }
      if (lplpower == 0) {
        // all power on, captain!
        rxbufptr->length = 0;
        atomic RadioState = IDLE_STATE;
        call CC1000StdControl.start();
        call CC1000Control.BIASOn();
	TOSH_uwait(200);
        call SpiByteFifo.rxMode();		// SPI to miso
        call CC1000Control.RxMode();
        if (iSquelchCount > CC1K_SquelchCount)
          call SquelchTimer.start(TIMER_REPEAT, CC1K_SquelchIntervalSlow);
        else
          call SquelchTimer.start(TIMER_REPEAT, CC1K_SquelchIntervalFast);
        call SpiByteFifo.enableIntr(); // enable spi interrupt
      }
      else {
        uint16_t sleeptime = 200; //this time doesn't really matter.
        atomic RadioState = POWER_DOWN_STATE;
        call TimerControl.start();
        call SquelchTimer.stop();
	call SpiByteFifo.disableIntr();
        call WakeupTimer.start(TIMER_ONE_SHOT, sleeptime);
      }
    }
    return SUCCESS;
  }

  command result_t Send.send(TOS_MsgPtr pMsg) {
    result_t Result = SUCCESS;
    atomic {
      if (bTxBusy) {
	Result = FAIL;
      }
      else {
	send_count ++;
	bTxBusy = TRUE;
	txbufptr = pMsg;
#if 0
	pMsg->length = 0x1C;
#endif
	txlength = pMsg->length + (MSG_DATA_SIZE - DATA_LENGTH - 2); 
        slot_delay = (call Random.rand() & 0x7) + 3;
	bTxPending = TRUE;
	txbufptr->ack = 0;
    	if (lplpower == 0) {
		start_send();
		pMsg->strength = 0;
	}
      }
    }
    return Result;
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

  async event result_t SpiByteFifo.dataReady(uint8_t data_in) {
    
    signal RadioSendCoordinator.blockTimer();
    signal RadioReceiveCoordinator.blockTimer();
    total_sum ++;
    if (bInvertRxData) 
      data_in = ~data_in;
#ifdef ENABLE_UART_DEBUG
    UARTPutChar(RadioState);
#endif
    switch (RadioState) {

    case TX_STATE:
      {
	call SpiByteFifo.writeByte(NextTxByte);
	TxByteCnt++;
	switch (RadioTxState) {

	case TXSTATE_PREAMBLE:
	  send_sum ++;
	  if (!(TxByteCnt < preamblelen)||
  	      (txbufptr->strength == 0xffff && 
		TxByteCnt >= PREAMBLE_LENGTH_SHORT) || 
  	      (txbufptr->strength == 0x7fff && 
	        TxByteCnt >= 8)) {
	    NextTxByte = SYNC_BYTE;
	    RadioTxState = TXSTATE_SYNC;
	  }
	  break;

	case TXSTATE_SYNC:
	  send_sum ++;
	  NextTxByte = NSYNC_BYTE;
	  RadioTxState = TXSTATE_DATA;
	  TxByteCnt = -1;
          // for Time Sync services
	  signal RadioSendCoordinator.startSymbol(8, 0, txbufptr); 
	  break;

	case TXSTATE_DATA:
	  send_sum ++;
	  if ((uint8_t)(TxByteCnt) < txlength) {
	    NextTxByte = ((uint8_t *)txbufptr)[(TxByteCnt)];
	    usRunningCRC = crcByte(usRunningCRC,NextTxByte);
	    signal RadioSendCoordinator.byte(txbufptr, (uint8_t)TxByteCnt); // Time Sync
	  }
	  else {
	    NextTxByte = (uint8_t)(usRunningCRC);
	    RadioTxState = TXSTATE_CRC;
	  }
	  break;

	case TXSTATE_CRC:
	  send_sum ++;
	  NextTxByte = (uint8_t)(usRunningCRC>>8);
	  RadioTxState = TXSTATE_FLUSH;
	  TxByteCnt = 0;
	  break;

	case TXSTATE_FLUSH:
	  send_sum ++;
	  if (TxByteCnt > 3) {
	    TxByteCnt = 0;
	    RadioTxState = TXSTATE_WAIT_FOR_ACK;
	  }
	  break;


        case TXSTATE_WAIT_FOR_ACK:
	  if(TxByteCnt == 1){
	  	send_sum ++;
		call SpiByteFifo.rxMode();
	        call CC1000Control.RxMode();
	  	if(txbufptr->addr == TOS_BCAST_ADDR){
			txbufptr->ack = 0;
			RadioTxState = TXSTATE_DONE;
		}
		break;
	  }
	  receive_sum ++;
	  if (TxByteCnt > 3) {
	    RadioTxState = TXSTATE_READ_ACK;
	    TxByteCnt = 0;
	    search_word = 0;
	  }
	  break;

        case TXSTATE_READ_ACK:
	  {
	     uint8_t i;
	     receive_sum ++;
	     for(i = 0; i < 8; i ++){
		search_word <<= 1;
        	if(data_in & 0x80) search_word |=  0x1;
        	data_in <<= 1;
        	if (search_word == 0xba83){
                	txbufptr->ack = 1;
	    		RadioTxState = TXSTATE_DONE;
                	return SUCCESS;
	
        	}
             }
  	  }
	  if(TxByteCnt >= MAX_ACK_WAIT){
		txbufptr->ack = 0;
	    	RadioTxState = TXSTATE_DONE;
	
	  }
	  break;

	case TXSTATE_DONE:
	default:
          call RSSIADC.getData();
	  bTxPending = FALSE;
	  if (post PacketSent()) {
	    // If the post operation succeeds, goto Idle
	    // otherwise, we'll try again.
	    RadioState = IDLE_STATE;
	  }
	  break;
	}
      }
      break;

    case DISABLED_STATE:
      unknown_sum ++;
      break;

    case IDLE_STATE: 
      {
	receive_sum ++;
	if (((data_in == (0xaa)) || (data_in == (0x55)))) {
	  PreambleCount++;
	  if (PreambleCount > CC1K_ValidPrecursor) {
	    PreambleCount = SOFCount = 0;
	    RxBitOffset = RxByteCnt = 0;
	    usRunningCRC = 0;
	    rxlength = MSG_DATA_SIZE-2;
	    RadioState = SYNC_STATE;
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
	// check for data inversion, and restore proper polarity 
        // XXX-PB: Don't do this.
	uint8_t i;

	receive_sum ++;
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
	  case 3: 
	  case 4: 
	  case 5: 
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
                if (rxbufptr->length !=0) {
                  call Leds.redToggle();
                  RadioState = IDLE_STATE;
                }
                else {
                  RadioState = RX_STATE;
                  call RSSIADC.getData();
                  RxBitOffset = 7-i;
                  // For time sync services
                  signal RadioReceiveCoordinator.startSymbol(8, RxBitOffset, rxbufptr); 
                }
		break;
	      }
	    }
	    break;

	  default:
	    // We didn't find it after a reasonable number of tries, so....
	    RadioState = IDLE_STATE;  // Ensures we wait till the end of the transmission
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
	receive_sum ++;

	RxShiftBuf.W <<=8;
	RxShiftBuf.LSB = data_in;

	Byte = (RxShiftBuf.W >> RxBitOffset);
	((char*)rxbufptr)[(int)RxByteCnt] = Byte;
	RxByteCnt++;

	signal RadioReceiveCoordinator.byte(rxbufptr, (uint8_t)RxByteCnt);
	
	if (RxByteCnt < rxlength) {
	  usRunningCRC = crcByte(usRunningCRC,Byte);

	  if (RxByteCnt == (offsetof(struct TOS_Msg,length) + 
			    sizeof(((struct TOS_Msg *)0)->length))) {
	    rxlength = rxbufptr->length;
	    if (rxlength > TOSH_DATA_LENGTH) {
	      // The packet's screwed up, so just dump it
              rxbufptr->length = 0;
	      RadioState = IDLE_STATE;  // Waits till end of transmission
	      return SUCCESS;
	    }
	    //Add in the header size
	    rxlength += offsetof(struct TOS_Msg,data);
	  }
	}
	else if (RxByteCnt == rxlength) {
	  usRunningCRC = crcByte(usRunningCRC,Byte);
	  // Shift index ahead to the crc field.
	  RxByteCnt = offsetof(struct TOS_Msg,crc);
	}
	else if (RxByteCnt >= MSG_DATA_SIZE) { 

	  // Packet filtering based on bad CRC's is done at higher layers.
	  // So sayeth the TOS weenies.
	  if (rxbufptr->crc == usRunningCRC) {
	    rxbufptr->crc = 1;
	    if(rxbufptr->addr == TOS_LOCAL_ADDRESS
		&& rxbufptr->group == TOS_AM_GROUP){

	    	RadioState = SENDING_ACK; 
	    	call CC1000Control.TxMode();
	    	call SpiByteFifo.txMode();
	    	call SpiByteFifo.writeByte(0xaa);
	    	RxByteCnt = 0;
	    	return SUCCESS; 
	       }
	  } else {
	    rxbufptr->crc = 0;
	  }

	  call SpiByteFifo.disableIntr();
	  
	  RadioState = IDLE_STATE; 
	  rxbufptr->strength = usRSSIVal;
	  if (!(post PacketRcvd())) {
	    // If there are insufficient resources to process the incoming packet
	    // we drop it
            rxbufptr->length = 0;
	    RadioState = IDLE_STATE;
	    call SpiByteFifo.enableIntr();
	  }

	}
      }
      break;
    case SENDING_ACK:
      {
	send_sum ++;
	RxByteCnt++;
	if (RxByteCnt >= ACK_LENGTH) { 
	    call CC1000Control.RxMode();
	    call SpiByteFifo.rxMode();
	    call SpiByteFifo.disableIntr();
	    RadioState = IDLE_STATE; //DISABLED_STATE;
	    rxbufptr->strength = usRSSIVal;
	    if (!(post PacketRcvd())) {
  		rxbufptr->length = 0;
  		RadioState = IDLE_STATE;
  		call SpiByteFifo.enableIntr();
	    }
	}else if(RxByteCnt >= ACK_LENGTH - sizeof(ack_code)){
	    call SpiByteFifo.writeByte(ack_code[RxByteCnt + sizeof(ack_code) - ACK_LENGTH]);
        }
      }
      break;
	  
    default:
      unknown_sum ++;
      break;
    }

	if(pulse_check_sum > CHECK_MA_COUNT){
		power_sum ++;
		pulse_check_mam ++;
		pulse_check_sum -= CHECK_MA_COUNT;
	}
	if(send_sum > SEND_MA_COUNT){
		power_sum ++;
		send_mam ++;
		send_sum -= SEND_MA_COUNT;
	}
	if(receive_sum > RECEIVE_MA_COUNT){
		power_sum ++;
		receive_mam ++;
		receive_sum -= RECEIVE_MA_COUNT;
	}
  return SUCCESS;
}

task void IdleTimerTask(){
      	if (iSquelchCount > CC1K_SquelchCount)
       		call SquelchTimer.start(TIMER_REPEAT, CC1K_SquelchIntervalSlow);
      	else
       		call SquelchTimer.start(TIMER_REPEAT, CC1K_SquelchIntervalFast);
      	call WakeupTimer.start(TIMER_ONE_SHOT, TIME_AFTER_CHECK);
}





async event result_t RSSIADC.dataReady(uint16_t data) {
  uint8_t currentRadioState;
  atomic currentRadioState = RadioState;
  // find the maximum RSSI value over CC1K_MAX_RSSI_SAMPLES
  switch(currentRadioState) {

  case IDLE_STATE:
    atomic usTempSquelch = data;
    post adjustSquelch();
    break;

  case RX_STATE:
    atomic usRSSIVal = data;
    break;
 
  case PULSE_CHECK_STATE:
	atomic{
		uint8_t done = 0;
		uint16_t threshold = CC1K_PulseLevel >> 8;
		data >>= 2;
		if(pulse_check_count == 0){
			CC1K_PulseLevel -= threshold;
			CC1K_PulseLevel += data;
	
		}
		threshold -= threshold >> 3;
		if(data > threshold){
			//go to the power down state
			//see below;
			;
		}else if(pulse_check_count > 3){
			//go to the idle state.
        	   	call CC1000Control.RxMode();
      			RadioState = IDLE_STATE;
      			call SpiByteFifo.rxMode();     // SPI to miso
      			call SpiByteFifo.enableIntr(); // enable spi interrupt
			post IdleTimerTask();
			done = 1;
		}else {
        	   call CC1000Control.RxMode();
#ifdef FREQ_433_MHZ
        	TOSH_uwait(90);
#endif
        	   TOSH_uwait(70);
		   if(call RSSIADC.getData()){
			pulse_check_count ++;
			done = 1;
		   }
        	   TOSH_uwait(17);
		   pulse_check_sum ++;
        	   call CC1000Control.BIASOn();
		}
		
		if(done == 0){
			call CC1000Control.BIASOff();
	  		call SpiByteFifo.disableIntr();
        		RadioState = POWER_DOWN_STATE;
		}
	}
	//go to the power down state
    break;
 
  default:
  }

  return SUCCESS;
}

 // XXX:JP- for testing the mac layer squlech value
 command uint16_t GetSquelch() {
   return usSquelchVal;
 }
 command uint16_t GetSendCount() {
   return send_count;
 }
 command uint16_t GetRxCount() {
   return rx_count;
 }
 command uint16_t GetPower() {
   return power_sum;
 }
 command uint16_t GetPower_total_sum() {
   return total_sum >> 10;
 }
command uint16_t GetPower_check() {
   return pulse_check_mam;
 }

command uint16_t GetPower_send() {
   return send_mam;
}

command uint16_t GetPower_receive() {
   return receive_mam;
}
// Default events for radio send/receive coordinators do nothing.
// Be very careful using these, you'll break the stack.
default async event void RadioSendCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff) { }
default async event void RadioSendCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) { }
default async event void RadioSendCoordinator.blockTimer() { }

default async event void RadioReceiveCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff) { }
default async event void RadioReceiveCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) { }
default async event void RadioReceiveCoordinator.blockTimer() { }
}
