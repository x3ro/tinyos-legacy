// $Id: CC1000RadioIntM.nc,v 1.2 2007/04/12 22:30:42 idgay Exp $

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
 *  Date last modified: $Revision: 1.2 $
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
    interface RadioCoordinator as RadioSendCoordinator;
    interface RadioCoordinator as RadioReceiveCoordinator;
    interface MacControl;
    interface MacBackoff;
    interface LowPowerListening;
    // legacy commands supported, but should now use the
    // Low Power Listening interface
    async command result_t SetListeningMode(uint8_t power);
    async command uint8_t GetListeningMode();
    async command result_t SetTransmitMode(uint8_t power);
    async command uint8_t GetTransmitMode();
    // Used for debugging the noise floor (gets the current squelch value)
    async command uint16_t GetSquelch();
    // Used for debugging; gets an estimate of the power consumed by the radio
    async command uint16_t GetPower();
  }
  uses {
    interface PowerManagement;
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
  }
}
implementation {
  enum {
    NULL_STATE,
    TX_STATE,
    DISABLED_STATE,
    IDLE_STATE,
    PRETX_STATE,
    SYNC_STATE,
    RX_STATE,
    SENDING_ACK,
    POWER_DOWN_STATE,
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
    TIME_AFTER_CHECK = 30,
    CHECK_MA_COUNT =	8888,
    SEND_MA_COUNT =	7200,
    PREAMBLE_LENGTH_TO_BASE =	8,
    RECEIVE_MA_COUNT = 9600

  };

  uint8_t ack_code[5] = {0xab, 0xba, 0x83, 0xaa, 0xaa};

  uint8_t RadioState;
  uint8_t RadioTxState;
  norace uint8_t iRSSIcount, clearCount;
  uint8_t RSSIInitState;
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
  uint16_t sleeptime;       //  current check interval (sleep time)
 
  uint16_t PreambleCount;   //  found a valid preamble
  uint8_t SOFCount;

  uint16_t search_word;

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
  bool bAckEnable;
  bool bCCAEnable;
  bool bTxBusy;
  bool bRSSIValid;
  uint16_t CC1K_PulseLevel;
  uint16_t usRunningCRC; // Running CRC variable
  uint16_t usRSSIVal;
  uint16_t usSquelchVal;
  uint16_t usTempSquelch;
  uint8_t usSquelchIndex;
  norace uint8_t pulse_check_count;
  norace uint16_t pulse_check_sum;
  norace uint16_t send_sum;
  norace uint16_t receive_sum;
  norace uint16_t power_sum;

  uint16_t usSquelchTable[CC1K_SquelchTableSize];

  int16_t sMacDelay;    // MAC delay for the next transmission
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
    uint32_t tempsquelch;

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
//    for (j = 0; j < ((CC1K_SquelchTableSize) >> 1); j++) {
    for (j = 0; j < 3; j++) {
      for (i = 1; i < CC1K_SquelchTableSize; i++) {
        if ((tempArray[(int)i] != 0xFFFF) && 
           ((tempArray[(int)i] > tempArray[(int)min]) ||
             (tempArray[(int)min] == 0xFFFF))) {
          min = i;
        }
      }
      min_value = tempArray[(int)min];
      tempArray[(int)min] = 0xFFFF;
    }

    tempsquelch = ((uint32_t)(usSquelchVal << 5) + (uint32_t)(min_value << 1));
    atomic usSquelchVal = (uint16_t)((tempsquelch / 34) & 0x0FFFF);

    /*
    // XXX: qsort actually causes ~600bits/sec lower bandwidth... why???
    //
    qsort (tempArray,CC1K_SquelchTableSize, sizeof(uint16_t),sortByShort);
    min_value = tempArray[CC1K_SquelchTableSize >> 1];
    atomic usSquelchVal = ((usSquelchVal << 5) + (min_value << 1)) / 34;
    */


  }

  task void PacketRcvd() {
    TOS_MsgPtr pBuf;

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
  }
  
  task void PacketSent() {
    TOS_MsgPtr pBuf; //store buf on stack 
    atomic {
      txbufptr->time = 0;
      pBuf = txbufptr;
    }
    signal Send.sendDone((TOS_MsgPtr)pBuf,SUCCESS);
    atomic bTxBusy = FALSE;
  }

  ///**********************************************************
  //* Exported interface functions
  //**********************************************************/
  
  command result_t StdControl.init() {
    char i;

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
      bAckEnable = FALSE;
      bCCAEnable = TRUE;
      CC1K_PulseLevel = 300;
      sMacDelay = -1;
      usRSSIVal = -1;
      usSquelchIndex = 0;
      pulse_check_count = 0;
      lplpower =  0;//0x87;
      RSSIInitState = NULL_STATE;
      //      if(TOS_LOCAL_ADDRESS == 0) lplpower = 0;
      //      lplpowertx = 7;
      usSquelchVal = CC1K_SquelchInit;
    }

    for (i = 0; i < CC1K_SquelchTableSize; i++)
      usSquelchTable[(int)i] = CC1K_SquelchInit;

    call SpiByteFifo.initSlave(); // set spi bus to slave mode
    call CC1000StdControl.init();
    call CC1000Control.SelectLock(0x9);		// Select MANCHESTER VIOLATION
    bInvertRxData = call CC1000Control.GetLOStatus();

    call ADCControl.bindPort(TOS_ADC_CC_RSSI_PORT,TOSH_ACTUAL_CC_RSSI_PORT);
    call ADCControl.init();

    call Random.init();
    call TimerControl.init();

    LocalAddr = TOS_LOCAL_ADDRESS;

    return SUCCESS;
  }
  
  /**
   * Get the current Low Power Listening transmit mode
   * @return mode number (see SetListeningMode)
   */
  async command uint8_t LowPowerListening.GetTransmitMode() {
    return lplpowertx;
  }
  // legacy support
  async command uint8_t GetTransmitMode() {
    return call LowPowerListening.GetTransmitMode();
  }

  /**
   * Set the transmit mode.  This allows for hybrid schemes where
   * the transmit mode is different than the receive mode.
   * Use SetListeningMode first, then change the mode with SetTransmitMode.
   *
   * @param mode mode number (see SetListeningMode)
   * @return SUCCESS if the mode was successfully changed
   */
  async command result_t LowPowerListening.SetTransmitMode(uint8_t power) {
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
  // legacy support
  async command result_t SetTransmitMode(uint8_t power) {
    return call LowPowerListening.SetTransmitMode(power);
  }

  /**
   * Set the current Low Power Listening mode.
   * Setting the LPL mode sets both the check interval and preamble length.
   *
   * Modes include:
   *  0 = Radio full on
   *  1 = 10ms check interval
   *  2 = 25ms check interval
   *  3 = 50ms check interval
   *  4 = 100ms check interval (recommended)
   *  5 = 200ms check interval
   *  6 = 400ms check interval
   *  7 = 800ms check interval
   *  8 = 1600ms check interval
   *
   * @param mode the mode number
   * @return SUCCESS if the mode was successfully changed
   */
  async command result_t LowPowerListening.SetListeningMode(uint8_t power) {
    // valid low power listening values are 0 to 8
    // 0 is "always on" and 8 is lowest duty cycle
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
  // legacy support
  async command result_t SetListeningMode(uint8_t power) {
    return call SetListeningMode(power);
  }

  /**
   * Gets the state of low power listening on the chipcon radio.
   * @return Current low power listening state value
   */
  async command uint8_t LowPowerListening.GetListeningMode() {
    return lplpower;
  }
  // legacy support
  async command uint8_t GetListeningMode() {
    return call LowPowerListening.GetListeningMode();
  } 

  /**
   * Set the preamble length of outgoing packets
   *
   * @param bytes length of the preamble in bytes
   * @return SUCCESS if the preamble length was successfully changed
   */
  async command result_t LowPowerListening.SetPreambleLength(uint16_t bytes) {
    result_t result = FAIL;
    atomic {
      if (RadioState != TX_STATE) {
	preamblelen = bytes;
	result = SUCCESS;
      }
    }
    return result;
  }

  /**
   * Get the preamble length of outgoing packets
   *
   * @return length of the preamble in bytes
   */
  async command uint16_t LowPowerListening.GetPreambleLength() {
    return preamblelen;
  }

  /**
   * Set the check interval (time between waking up and sampling
   * the radio for activity in low power listening)
   *
   * @param ms check interval in milliseconds
   * @return SUCCESS if the check interval was successfully changed
   */
  async command result_t LowPowerListening.SetCheckInterval(uint16_t ms) {
    // sleep time will go into effect after the next wakeup time
    atomic sleeptime = ms;
    return SUCCESS;
  }

  /**
   * Get the check interval currently used by low power listening
   *
   * @return length of the check interval in milliseconds
   */
  async command uint16_t LowPowerListening.GetCheckInterval() {
    return sleeptime;
  }


  void sendWakeup() {
    // disable wakeup timer
    atomic RadioState = IDLE_STATE;
    call WakeupTimer.stop();
    call CC1000StdControl.start();
    //TOSH_uwait(2000);
    call CC1000Control.BIASOn();
    TOSH_uwait(200);
    call CC1000Control.RxMode();
    call SpiByteFifo.rxMode();		// SPI to miso
    call SpiByteFifo.enableIntr(); // enable spi interrupt
    if (iSquelchCount > CC1K_SquelchCount)
      call SquelchTimer.start(TIMER_REPEAT, CC1K_SquelchIntervalSlow);
    else
      call SquelchTimer.start(TIMER_REPEAT, CC1K_SquelchIntervalFast);
    call WakeupTimer.start(TIMER_ONE_SHOT, CC1K_LPL_PACKET_TIME*2);
  }

  event result_t SquelchTimer.fired() {
    char currentRadioState;
    atomic currentRadioState = RadioState;

    if (currentRadioState == IDLE_STATE) {
      atomic RSSIInitState = currentRadioState;
      call RSSIADC.getData();
    }
    return SUCCESS;
  }

  event result_t WakeupTimer.fired() {
    uint8_t currentRadioState;

    if (lplpower == 0)
      return SUCCESS;

    atomic currentRadioState = RadioState;
    switch(currentRadioState) {

    case IDLE_STATE:
      if (!bTxPending || sMacDelay > 12) {
        atomic {
	  RadioState = POWER_DOWN_STATE;
	  call SpiByteFifo.disableIntr();
	}
	if (bTxPending)
	  {
	    // divide by 2.4, we know sMacDelay < 128
	    int16_t delay = (sMacDelay * 53) >> 7;
	    call WakeupTimer.start(TIMER_ONE_SHOT, delay);
	    sMacDelay = 1;
	  }
	else
	  call WakeupTimer.start(TIMER_ONE_SHOT, sleeptime);
        call SquelchTimer.stop();
        call CC1000StdControl.stop();
      } else {
        call WakeupTimer.start(TIMER_ONE_SHOT, sleeptime);
      }
      break;

    case POWER_DOWN_STATE:
      if (bTxPending)
	sendWakeup();
      else
	{
	  atomic RadioState = PULSE_CHECK_STATE;
	  pulse_check_count = 0;
	  //call CC1000StdControl.start();
	  //TOSH_uwait(2000);
	  call CC1000Control.BIASOn();
	  call WakeupTimer.start(TIMER_ONE_SHOT, 1);
	}
      break;

    case PULSE_CHECK_STATE:
      {
	bool restart = FALSE;

        call CC1000Control.RxMode();
	TOSH_uwait(35);
	atomic 
	  {
	    if (call RSSIADC.getData())
	      {
		RSSIInitState = PULSE_CHECK_STATE;
		TOSH_uwait(80);
		call CC1000Control.BIASOn();
	      }
	    else
	      {
		RadioState = POWER_DOWN_STATE;
		restart = TRUE;
	      }
	  }
	if (restart)
	  {
	    call WakeupTimer.start(TIMER_ONE_SHOT, TIME_BETWEEN_CHECKS);
	    call CC1000StdControl.stop();
	  }
	pulse_check_sum ++;
        break;
      }
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
    if (currentRadioState == DISABLED_STATE) {
      atomic {
        rxbufptr->length = 0;
        RadioState  = IDLE_STATE;
        bTxPending = bTxBusy = FALSE;
        sMacDelay = -1;
        sleeptime = ((PRG_RDB(&CC1K_LPL_SleepTime[lplpower*2]) << 8) |
                     PRG_RDB(&CC1K_LPL_SleepTime[(lplpower*2)+1]));
        preamblelen = ((PRG_RDB(&CC1K_LPL_PreambleLength[lplpowertx*2]) << 8) |
		     PRG_RDB(&CC1K_LPL_PreambleLength[(lplpowertx*2)+1]));
      }
      // all power on, captain!
      rxbufptr->length = 0;
      atomic RadioState = IDLE_STATE;
      call CC1000StdControl.start();
      //TOSH_uwait(2000);
      call CC1000Control.BIASOn();
      TOSH_uwait(200);
      call SpiByteFifo.rxMode();		// SPI to miso
      call CC1000Control.RxMode();
      if (iSquelchCount > CC1K_SquelchCount)
	call SquelchTimer.start(TIMER_REPEAT, CC1K_SquelchIntervalSlow);
      else
	call SquelchTimer.start(TIMER_REPEAT, CC1K_SquelchIntervalFast);
      call SpiByteFifo.enableIntr(); // enable spi interrupt
      if (lplpower > 0) {
	// set a time to start sleeping after measuring the noise floor
	call WakeupTimer.start(TIMER_ONE_SHOT, CC1K_SquelchIntervalSlow);
      }
    }
    return SUCCESS;
  }

  command result_t Send.send(TOS_MsgPtr pMsg) {
    result_t Result = SUCCESS;
    uint8_t currentRadioState = 0;
    atomic {
      if (bTxBusy) {
	Result = FAIL;
      }
      else {
	bTxBusy = TRUE;
	txbufptr = pMsg;
	txlength = pMsg->length + (MSG_DATA_SIZE - DATA_LENGTH - 2); 

        // initially back off [1,32] bytes (approx 2/3 packet)
	if (bCCAEnable)
	  sMacDelay = signal MacBackoff.initialBackoff(pMsg);
	else
	  sMacDelay = 0;
	bTxPending = TRUE;
      }
      currentRadioState = RadioState;
    }

    if (Result) {

      // if we're off, start the radio
      if (currentRadioState == POWER_DOWN_STATE)
	sendWakeup();
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
  	      (txbufptr->strength == 0xffff && TxByteCnt >= PREAMBLE_LENGTH_TO_BASE)) {
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
            if (bAckEnable) {
              RadioTxState = TXSTATE_WAIT_FOR_ACK;
            }
            else {
              call SpiByteFifo.rxMode();
              call CC1000Control.RxMode();
              RadioTxState = TXSTATE_DONE;
            }
	  }
	  break;

        case TXSTATE_WAIT_FOR_ACK:
	  if(TxByteCnt == 1){
	  	send_sum ++;
		call SpiByteFifo.rxMode();
	        call CC1000Control.RxMode();
#if 0
	  	if(txbufptr->addr == TOS_BCAST_ADDR){
			txbufptr->ack = 0;
			RadioTxState = TXSTATE_DONE;
		}
#endif
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
	  bTxPending = FALSE;
	  if (post PacketSent()) {
	    // If the post operation succeeds, goto Idle
	    // otherwise, we'll try again.
	    RadioState = IDLE_STATE;
            RSSIInitState = RadioState;
            call RSSIADC.getData();
	  }
	  break;
	}
      }
      break;

    case DISABLED_STATE:
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
	else if (bTxPending && (--sMacDelay <= 0)) {
	  RadioState = PRETX_STATE;
          RSSIInitState = PRETX_STATE;
	  bRSSIValid = FALSE;
          iRSSIcount = 0;
	  clearCount = 0;
	  PreambleCount = 0;
	  call RSSIADC.getData();
	}
      }
      break;

    case PRETX_STATE:
      {
	receive_sum ++;
	if (((data_in == (0xaa)) || (data_in == (0x55)))) {
	  // Back to the penalty box.
          sMacDelay = signal MacBackoff.congestionBackoff(txbufptr);
	  RadioState = IDLE_STATE;
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
                  RSSIInitState = RX_STATE;
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

	    if(bAckEnable && (rxbufptr->addr == TOS_LOCAL_ADDRESS)){

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
	  
	  RadioState = IDLE_STATE; //DISABLED_STATE;
	  rxbufptr->strength = usRSSIVal;
	  if (!(post PacketRcvd())) {
	    // If there are insufficient resources to process the incoming packet
	    // we drop it
            rxbufptr->length = 0;
	    RadioState = IDLE_STATE;
	    call SpiByteFifo.enableIntr();
	  }
          RSSIInitState = RadioState;
          call RSSIADC.getData();
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
      break;
    }

	if(pulse_check_sum > CHECK_MA_COUNT){
		power_sum ++;
		pulse_check_sum -= CHECK_MA_COUNT;
	}
	if(send_sum > SEND_MA_COUNT){
		power_sum ++;
		send_sum -= SEND_MA_COUNT;
	}
	if(receive_sum > RECEIVE_MA_COUNT){
		power_sum ++;
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
	/*if(pulse_check_sum > CHECK_MA_COUNT){
		power_sum ++;
		pulse_check_sum -= CHECK_MA_COUNT;
	}
	if(send_sum > SEND_MA_COUNT){
		power_sum ++;
		send_sum -= SEND_MA_COUNT;
	}
	if(receive_sum > RECEIVE_MA_COUNT){
		power_sum ++;
		receive_sum -= RECEIVE_MA_COUNT;
	}*/
}

  task void SleepTimerTask(){
    call WakeupTimer.start(TIMER_ONE_SHOT, sleeptime);
  }

  task void timeoutTask() {
    call WakeupTimer.stop();
    call WakeupTimer.start(TIMER_ONE_SHOT, 5);
  }

  async event result_t RSSIADC.dataReady(uint16_t data) { 
    atomic
      {
	uint8_t currentRadioState;

	//	TOSH_CLR_PW3_PIN();

	currentRadioState = RadioState;
	// find the maximum RSSI value over CC1K_MAX_RSSI_SAMPLES
	switch(currentRadioState) {
	case IDLE_STATE:
	  if (RSSIInitState == IDLE_STATE) {
	    atomic usTempSquelch = data;
	    post adjustSquelch();
	  }
	  RSSIInitState = NULL_STATE;
	  break;

	case RX_STATE:
	  if (RSSIInitState == RX_STATE) {
	    atomic usRSSIVal = data;
	  }
	  RSSIInitState = NULL_STATE;
	  break;

	case PRETX_STATE:
	  iRSSIcount++;

	  // if the channel is clear or CCA is disabled, GO GO GO!
	  if (data > usSquelchVal + CC1K_SquelchBuffer && RSSIInitState == PRETX_STATE)
	    clearCount++;
	  else
	    clearCount = 0;

	  if (clearCount >= 2 || !bCCAEnable) { 
	    call SpiByteFifo.writeByte(0xaa);
	    call CC1000Control.TxMode();
	    call SpiByteFifo.txMode();

	      usRSSIVal = data;
	      iRSSIcount = CC1K_MaxRSSISamples;
	      bRSSIValid = TRUE;
	      TxByteCnt = 0;
	      usRunningCRC = 0;
	      RadioState = TX_STATE;
	      RadioTxState = TXSTATE_PREAMBLE;
	      NextTxByte = 0xaa;
	      RSSIInitState = NULL_STATE;
	  }
	  else {
	    RSSIInitState = NULL_STATE;
	    if (iRSSIcount == CC1K_MaxRSSISamples) {
		sMacDelay = signal MacBackoff.congestionBackoff(txbufptr);
		RadioState = IDLE_STATE;
		post timeoutTask();
	    }
	    else {
	      RSSIInitState = currentRadioState;
	      call RSSIADC.getData();
	    }
	  }
	  break;

	case PULSE_CHECK_STATE:
	  atomic{
	    uint8_t done = 0;
	    uint16_t threshold = call GetSquelch() - CC1K_SquelchBuffer;
            if(data > threshold){
	      // adjust the noise floor level
	      atomic usTempSquelch = data;
	      post adjustSquelch();

	    }else if(pulse_check_count > 5){
	      //go to the idle state since no outliers were found
	      call CC1000Control.RxMode();
	      RadioState = IDLE_STATE;
	      call SpiByteFifo.rxMode();     // SPI to miso
	      call SpiByteFifo.enableIntr(); // enable spi interrupt
	      post IdleTimerTask();
	      done = 1;

	    }else {
	      call CC1000Control.RxMode();
	      TOSH_uwait(35);
	      if(call RSSIADC.getData()){
		TOSH_uwait(80);
		call CC1000Control.BIASOn();
		pulse_check_count ++;
		done = 1;
	      }
	      pulse_check_sum ++;
	    }

	    if(done == 0){
	      call CC1000StdControl.stop();
	      post SleepTimerTask();
	      RadioState = POWER_DOWN_STATE;
	      call SpiByteFifo.disableIntr();
	    }
	  }
	  //go to the power down state
	  break;

	default:
	}
      }
  return SUCCESS;
    }

 // XXX:JP- for testing the mac layer squlech value
 async command uint16_t GetSquelch() {
   return usSquelchVal;
 }
 // XXX:JP- for testing the mac layer power consumption
 async command uint16_t GetPower() {
   return power_sum;
 }

  async command result_t MacControl.enableAck() {
    atomic bAckEnable = TRUE;
    return SUCCESS;
  }

  async command result_t MacControl.disableAck() {
    atomic bAckEnable = FALSE;
    return SUCCESS;
  }

  async command result_t MacControl.enableCCA() {
    atomic bCCAEnable = TRUE;
    return SUCCESS;
  }

  async command result_t MacControl.disableCCA() {
    atomic bCCAEnable = FALSE; 
    return SUCCESS;
  }

  // ***Not yet implemented
  async command TOS_MsgPtr MacControl.HaltTx() {
    return 0;
  }

// Default events for radio send/receive coordinators do nothing.
// Be very careful using these, you'll break the stack.
default async event void RadioSendCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff) { }
default async event void RadioSendCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) { }
default async event void RadioSendCoordinator.blockTimer() { }

default async event void RadioReceiveCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff) { }
default async event void RadioReceiveCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) { }
default async event void RadioReceiveCoordinator.blockTimer() { }

default async event int16_t MacBackoff.initialBackoff(TOS_MsgPtr m) { 
  return (call Random.rand() & 0x1F) + 1;
}

default async event int16_t MacBackoff.congestionBackoff(TOS_MsgPtr m) { 
  return (((call Random.rand() & 0x3)) + 1) << 10;
}

}
