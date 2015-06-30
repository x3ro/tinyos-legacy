/* 
 * Copyright (c) 2005, Ecole Polytechnique Federale de Lausanne (EPFL)
 * and Shockfish SA, Switzerland.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   and Shockfish SA, nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ========================================================================
 */
/*
 * Main XE1205 radio driver module.
 *
 * @author Henri Dubois-Ferriere
 * @author Remy Blank
 */

includes crc;
includes XE1205Const;

module XE1205RadioM {
  provides {
    interface StdControl;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
    interface RadioCoordinator as RadioReceiveCoordinator;
    interface RadioCoordinator as RadioSendCoordinator;
    interface XE1205Stats as Stats;
    interface XE1205LPL as LPL;

    interface CSMAControl;
    interface MacBackoff;

    // Fine-grained control functions, intended for testing/debugging/measurement purposes.
    async command result_t enableInitialBackoff(); // Enable initial pre-transmit backoff. 
    async command result_t disableInitialBackoff(); // Disable initial pre-transmit backoff (it is enabled by default). 

  }
  uses {
    interface StdControl as ConfigControl;
    interface StdControl as TimerJiffyControl;
    interface StdControl as HPLControl;
    interface XE1205Control;
    interface CCAThresh;
    interface HPLXE1205;
    interface HPLXE1205Interrupt as IRQ0;
    interface HPLXE1205Interrupt as IRQ1;
    interface Leds;
    interface TimerJiffyAsync as TimerJiffy;
    interface Random;

  }
}

implementation {

 
  // Radio driver states
  enum {                     
    RADIO_LPL_LISTEN=0,        // Searching(*) for LPL Pattern 
    RADIO_LISTEN=1,            // Searching for Pkt Pattern
    RADIO_RX=2,              // Receiving Pkt
    RADIO_PRE_TX=3,          // Pre Tx (measuring channel for CCA)
    RADIO_TX_LPLPREAMBLE=4,  // Sending LPL preamble (long)
    RADIO_TX_PKTPREAMBLE=5,  // Sending pkt preamble (short)
    RADIO_TX_DATA=6,         // Sending pkt
    RADIO_TX_ACK=7,          // Sending ACK
    RADIO_RX_ACK=8,          // Searching for ACK
    RADIO_DISABLED=9, 
    RADIO_SLEEP=10,
    RADIO_STANDBY=11,
  };                         // (*) "Searching" means pattern detector armed, RX mode
  

  // Multiple logically distinct functions and states
  // are multiplexed on the same single jiffy timer.
  enum {
    TIMER_IDLE=1,               // Timer inactive
    TIMER_PRE_TX_RSSI_LO=2,     // Timeout for pre-tx RSSI measurement (low range)
    TIMER_PRE_TX_RSSI_HI=3,     // Timeout for pre-tx RSSI measurement (high range)
    TIMER_POST_TX_RSSI=4,       // Timeout for post-tx RSSI measurement 
    TIMER_INITIALBACKOFF=5,     // Timeout for initial backoff
    TIMER_ACK_WAIT=6,           // Timeout while awaiting ACK
    TIMER_WAITBUS_ARMPD=7,      // Timeout when we could not arm pattern detector because bus was busy
    TIMER_WAKE_TX=8,            // Timeout when we are awaking to TX a packet
    TIMER_LPL_SLEEP=9,
    TIMER_LPL_AWAKE=10,
    TIMER_RX                    // Timeout for end of packet reception (safety net to catch FIFO overrun hangups)
  };

  enum {
    flagRxBufBusy = 1 << 0,
    flagTxBufBusy = 1 << 1
  };

  enum {
    flagHaveRssiNone = 0,
    flagHaveRssiLow=1,
    flagHaveRssiHigh=2,
    flagHaveRssiBoth=3
  };

  uint8_t const pktPreamble[] = {
    0x55, 0x55, 0x55,
    (Xe1205_Pattern >> 16) & 0xff, (Xe1205_Pattern >> 8) & 0xff, Xe1205_Pattern & 0xff
  };

  uint8_t const lplPreamble[] = {
    0x55, 0x55, 0x55, 0x55,
    0x55, 0x55, 0x55, 0x55,
    0x55, 0x55, 0x55, 0x55,
    0x55, 0x55, 0x55, 0x55
  };

  uint8_t const ack_code[] = {
    0x55, 0x55, 0x55,
    (Xe1205_Ack_code >> 16) & 0xff, (Xe1205_Ack_code >> 8) & 0xff, Xe1205_Ack_code & 0xff
  };

  uint8_t lplTXState;
  uint8_t lplRXState;
  norace uint16_t nlplPreambles; // only used in send path, so no races

  uint8_t mState;
  uint8_t mFlags;
  norace uint8_t mBufferIndex;// the only async code which touches these 2 vars is IRQX.fired (and only one can happen at a time), 
  norace TOS_MsgPtr mTxPtr;   // and Send.send(), which will touches it *after* having disabled IRQs

  norace TOS_Msg mTxMsgWhite; // there can only be one outstanding message in the send path, so no races here.
                              // note that the 'norace' is not needed to avoid warnings or avoid 'atomics' on this variable --
                              // it's here as a workaround a 'nesc internal error' bug that cropped up in revision 1.16
                              // and which (i am guessing) is happening in the race analysis stage. (nesc 1.1.2 and 1.2beta2)

  norace uint8_t white=0;       // only used in computeCrcandWhiten, so no races

  TOS_MsgPtr mTxWhitePtr = &mTxMsgWhite;
  TOS_MsgPtr mRxPtr;
  TOS_Msg mRxMsg;

  bool enableAck;
  norace bool enableCCA;      
  norace bool enableInitBk;

  uint16_t congestionBackoffs;
  uint8_t timerState;
  uint16_t nextRxlength;
  norace uint16_t nextTxlength; // only accessed via send.send and IRQ0.fired when sending a packet.

  typedef struct rssiInfo {
    uint8_t rssiLow;
    uint8_t rssiHigh;
    uint8_t rssiStatus;
  } rssiInfo;

  
  norace rssiInfo rssiRX;// only async code which touches rssiRX  happens at end of packet RX, so no races
  rssiInfo rssiPostTx;
  uint8_t nPostTxCancels; // number of postTX rssi meas. cancelled because a new send() happens before measurement.
  bool postTxRssiCancellable = TRUE;
  rssiInfo rssiPreTx;

  inline void clearRssiInfo (rssiInfo* rssi) {
    rssi->rssiStatus = flagHaveRssiNone;
    rssi->rssiHigh = 0;
    rssi->rssiLow = 0;
  }

  uint8_t rssi_samples[64];
  uint8_t rssi_index;

  ////////////////////////////////////////////////////////////////////////////////////
  //
  // jiffy/microseconds/bytetime conversion functions.
  //
  ////////////////////////////////////////////////////////////////////////////////////

  // 1 jiffie = 1/32768 = 30.52us; 
  // we approximate to 32us for quicker computation and also to account for interrupt/processing overhead.
  inline uint32_t usecs_to_jiffies(uint32_t usecs) {
    return usecs >> 5;
  }

  // warning -> this is EXTREMELEY expensive to compute - something like 200-400us
  inline uint32_t usecs_to_jiffies_slow(uint32_t usecs) {
    if ((usecs % 31) < 15)  
      return usecs / 31;
    else 
      return 1 + (usecs / 31);
  }

  inline uint32_t usecs_to_jiffies_floor(uint32_t usecs) {
    return usecs / 31;
  }

  inline uint32_t usecs_to_jiffies_ceil(uint32_t usecs) {
    return 1 + (usecs / 31);
  }

  // Time in jiffies to send 1 byte.  
  uint16_t xe1205_byte_jiffies() {
    return usecs_to_jiffies(call XE1205Control.GetByteTime_us());
  }

  // Time in jiffies to send N bytes.  
  uint32_t xe1205_nbyte_jiffies(uint16_t nbytes) {
    return usecs_to_jiffies((uint32_t) nbytes * (uint32_t) call XE1205Control.GetByteTime_us());
  }


  ////////////////////////////////////////////////////////////////////////////////////
  //
  // Forward decls.
  //
  ////////////////////////////////////////////////////////////////////////////////////
  void readRssi(rssiInfo* rssi, bool range);
  bool channelClear();
  result_t sendRadioOn();
  inline void startTX();
  inline void startReceive();
  inline void startReceiveLpl();
  inline void startReceivePkt();
  inline void sleepOrStartReceive();
  void sendFailed();
  task void postTxRssiDone();
  void startPostTxRssiTimer();
  bool radio_busy();
  void radioSleep();


  ////////////////////////////////////////////////////////////////////////////////////
  //
  // XE1205Stats interface.
  //
  ////////////////////////////////////////////////////////////////////////////////////
  typedef struct macStats_t {
    uint32_t bytesTX;
    uint32_t pktsTX;
    uint32_t bytesRX;
    uint32_t pktsRX;
    uint16_t crcErrsRX;
    uint16_t pktsNotAcked;
  }  macStats_t;

  // if i define this in one declaration, pytos doesn't pick it up...
  macStats_t stats;

  command void Stats.resetStats() {
    atomic {
      stats.bytesTX = 0;
      stats.pktsTX = 0;
      stats.bytesRX = 0;
      stats.pktsRX = 0;
      stats.crcErrsRX = 0;
      stats.pktsNotAcked = 0;
    }
  }

  command uint32_t Stats.bytesTX() { 
    uint32_t res; 
    atomic res = stats.bytesTX; 
    return res; 
  }
  command uint32_t Stats.pktsTX()  { 
    uint32_t res; 
    atomic res =  stats.pktsTX; 
    return res;
  }
  command uint32_t Stats.bytesRX() { 
    uint32_t res; 
    atomic res = stats.bytesRX; 
    return res;
  }
  command uint32_t Stats.pktsRX()  { 
    uint32_t res; 
    atomic res = stats.pktsRX;  
    return res;
  }
  command uint16_t Stats.crcErrsRX() { 
    uint16_t res; 
    atomic res = stats.crcErrsRX; 
    return res;
  }
  command uint16_t Stats.pktsNotAcked() {
    uint16_t res; 
    atomic res = stats.pktsNotAcked;
    return res;
  }

  ////////////////////////////////////////////////////////////////////////////////////
  //
  // XE1205LPL interface.
  //
  ////////////////////////////////////////////////////////////////////////////////////
  command result_t LPL.SetListeningMode(uint8_t power) { 
    bool idle = !radio_busy();
    
    if (power < XE1205_LPL_STATES) {
      atomic lplRXState = power; 

      if (lplRXState && idle) // yes we should take into account SLEEP
	sleepOrStartReceive();


      if (!lplRXState)	{
	atomic {
	  if (mState == RADIO_SLEEP) {
	    call XE1205Control.RxMode();
	    call XE1205Control.AntennaRx();
	  }
	  if (mState == RADIO_SLEEP || mState == RADIO_LPL_LISTEN) {
	    sleepOrStartReceive();
	  }
	}
      }
      return SUCCESS;
    } else return FAIL;
  }

  command uint8_t LPL.GetListeningMode() { return lplRXState; }

  command result_t LPL.SetTransmitMode(uint8_t power) { 
    if (lplTXState < XE1205_LPL_STATES) {
      atomic lplTXState = power; 
      return SUCCESS;
    } else return FAIL;
  }

  command uint8_t LPL.GetTransmitMode() { return lplTXState; }
  


  ////////////////////////////////////////////////////////////////////////////////////
  //
  // CSMAControl interface.
  //
  ////////////////////////////////////////////////////////////////////////////////////
  async command result_t CSMAControl.enableAck() {
    atomic enableAck = TRUE;
    return SUCCESS;
  }
  async command result_t CSMAControl.disableAck() {
    atomic enableAck = FALSE;
    return SUCCESS;
  }
  async command result_t CSMAControl.enableCCA() {
    atomic enableCCA = TRUE;
    return SUCCESS;
  }
  async command result_t CSMAControl.disableCCA() {
    atomic enableCCA = FALSE;
    return SUCCESS;
  }
  async command result_t enableInitialBackoff() {
    atomic enableInitBk = TRUE;
    return SUCCESS;
  }
  async command result_t disableInitialBackoff() {
    atomic enableInitBk = FALSE;
    return SUCCESS;
  }





  ////////////////////////////////////////////////////////////////////////////////////
  //
  // TimerJiffy interface.
  //
  ////////////////////////////////////////////////////////////////////////////////////
  result_t setRssiRangeLow();
  result_t setRssiRangeHigh();

  uint16_t rssiMeasurePeriod_jiffies() {
    // assume that it's ok to take 'rounded' jiffies, in worst case we underestimate by 15 microsecs, but that 
    // is most likely to be compensated by processing overhead etc.
    return usecs_to_jiffies(call XE1205Control.GetRssiMeasurePeriod_us());
  }

  void transitionTimerPreTxRssiHi() {
    if (setRssiRangeHigh() && call TimerJiffy.setOneShot(rssiMeasurePeriod_jiffies())) {
      timerState = TIMER_PRE_TX_RSSI_HI;
    } 
    else {
      timerState = TIMER_IDLE;
      sendFailed();
    }
  }


  void transitionTimerPreTxRssiLo(uint32_t jiffies) {
    if ( setRssiRangeLow() && call TimerJiffy.setOneShot(jiffies)) {
      timerState = TIMER_PRE_TX_RSSI_LO;
    } 
    else {
      timerState = TIMER_IDLE;
      sendFailed();
    }
  }
  
  void transmitIfCCA() {
    rssi_samples[rssi_index++] = (rssiPreTx.rssiHigh << 4) | rssiPreTx.rssiLow;
    if (rssi_index == sizeof(rssi_samples)) rssi_index = 0;

    if (!enableCCA || channelClear() || congestionBackoffs >= 6) {
      timerState = TIMER_IDLE;
      startTX();
    } 
    else {
      clearRssiInfo(&rssiPreTx);
      congestionBackoffs++;
      transitionTimerPreTxRssiLo(xe1205_nbyte_jiffies(signal MacBackoff.congestion(mTxPtr)));
    }
  }

  task void frameSentTask();
  
  void postSend() {// async

      if(!post frameSentTask()) {
	// this will signal the sendDone in interrupt context,
	// which is bad, but we have no choice.
	// (until TinyOS 2.0 ?? http://cvs.sourceforge.net/viewcvs.py/tinyos/tinyos-1.x/beta/teps/txt/tep106.txt?view=markup)
	sendFailed();
	return;
      }

      startReceive(); // even if we're in LPL, don't sleep right away because we have to sample RSSI

      if (call HPLXE1205.getBus() == SUCCESS) {
	startPostTxRssiTimer(); 
	call HPLXE1205.releaseBus();
      }

  }

  // returns TRUE if we are sending or receiving a packet
  inline bool radio_busy() {
    uint8_t mState_;
    atomic mState_ = mState;
    return 
      ((mState_ != RADIO_SLEEP) 
       &&
       ((lplRXState && (mState_ != RADIO_LPL_LISTEN))
	|| (!lplRXState && (mState_ != RADIO_LISTEN))));
  }

  async event result_t TimerJiffy.fired() {
    switch (timerState) {

    case TIMER_POST_TX_RSSI:
      timerState = TIMER_IDLE;

      // don't read clear channel RSSI if we are already receiving another packet.
      if (radio_busy()) break; 

      if (call HPLXE1205.getBus() == SUCCESS) {
	readRssi(&rssiPostTx, call XE1205Control.GetRssiRange());
	call HPLXE1205.releaseBus();
	
	if (rssiPostTx.rssiStatus == flagHaveRssiBoth) post postTxRssiDone();
      }
      if (lplRXState) sleepOrStartReceive();
      break;

    case TIMER_INITIALBACKOFF:
      transitionTimerPreTxRssiLo(rssiMeasurePeriod_jiffies());
      break;

    case TIMER_PRE_TX_RSSI_LO:
      readRssi(&rssiPreTx, FALSE); 
      if (rssiPreTx.rssiStatus == flagHaveRssiBoth) 
 	transmitIfCCA();
      else 
	transitionTimerPreTxRssiHi();
      break;

    case TIMER_PRE_TX_RSSI_HI:
      readRssi(&rssiPreTx, TRUE); 
      transmitIfCCA();
      break;

    case TIMER_ACK_WAIT: // Timed out waiting for ACK
      timerState = TIMER_IDLE;
      call XE1205Control.loadDataPattern();
      mTxPtr->ack = 0;
      stats.pktsNotAcked++;
      postSend();
      break;

    case TIMER_WAITBUS_ARMPD: // we are waiting till bus frees up to arm pd
      timerState = TIMER_IDLE;
      if (radio_busy()) break;
      startReceive();
      break;

    case TIMER_WAKE_TX:
      timerState = TIMER_IDLE;
      mState = RADIO_LISTEN;
      if (sendRadioOn() == FAIL) 
	sendFailed();
      break;

    case TIMER_LPL_SLEEP: // awaken from sleep mode and listen (briefly) for a packet
      call XE1205Control.RxMode();
      call XE1205Control.AntennaRx();

      // time to wake up receiver and receive 4 bytes
      call TimerJiffy.setOneShot(usecs_to_jiffies(Xe1205_Sleep_to_RX_Time) + xe1205_nbyte_jiffies(4));

      startReceive();
      if (lplRXState) 
	timerState = TIMER_LPL_AWAKE;
      else
	timerState = TIMER_IDLE;
      break;
      
    case TIMER_LPL_AWAKE: 
      timerState = TIMER_IDLE;

      // if we have received a LPL preamble, then we will be in RADIO_LISTEN mode awaiting the 
      // packet preamble, and so we don't put the radio to sleep.
      // note that we currently don't deal with the case where we missed the packet preamble -- 
      // in this case the radio will stay awake until we get a new packet.
      if (mState == RADIO_LPL_LISTEN) {
	sleepOrStartReceive();
      }
      break;
 
    case TIMER_RX: 
      mFlags &= ~flagRxBufBusy;
      call XE1205Control.ClearFifoOverrun();  
      sleepOrStartReceive();


    case TIMER_IDLE:
      break;
    }

    return SUCCESS;
  }

  task void postTxRssiDone() {
    uint8_t rssi;

    if (rssiPostTx.rssiStatus != flagHaveRssiBoth) return;
                
    atomic rssi = rssiFromPair(rssiPostTx.rssiHigh, rssiPostTx.rssiLow);
    call CCAThresh.newClearSample(rssi);
    atomic clearRssiInfo(&rssiPostTx);
  }

  result_t setRssiRangeLow() {
    if  (! call XE1205Control.GetRssiRange() || call XE1205Control.SetRssiRange(FALSE))
      return SUCCESS;
    else 
      return FAIL;
  }
  
  result_t setRssiRangeHigh() {
    if  (call XE1205Control.GetRssiRange() || call XE1205Control.SetRssiRange(TRUE))
      return SUCCESS;
    else 
      return FAIL;
  }



  command result_t StdControl.init()
  {
    result_t result1 = call HPLControl.init();
    result_t result2 = call ConfigControl.init();
    result_t result3 = call TimerJiffyControl.init();

    call CCAThresh.reset();

    atomic {
      enableCCA = TRUE;
      enableInitBk = TRUE;
      enableAck = FALSE;
    }


    call Random.init();

    call Stats.resetStats();

    atomic {
      lplTXState = 0;
      lplRXState = 0;
      timerState = TIMER_IDLE;
      mState = RADIO_DISABLED;
      mRxPtr = &mRxMsg;
    }
    return rcombine3(result1, result2, result3);
  }

  command result_t StdControl.start()
  {
    result_t result1 = call HPLControl.start();
    result_t result2 = call ConfigControl.start();
    result_t result3 = call TimerJiffyControl.start();

    atomic {
      mState = RADIO_LISTEN;
      timerState = TIMER_IDLE;
      nPostTxCancels = 0;
      postTxRssiCancellable = TRUE;
      mFlags = 0;
    }
    call XE1205Control.RxMode();
    call XE1205Control.AntennaRx();
    if (call HPLXE1205.getBus() != SUCCESS) return FAIL;
    call XE1205Control.SetRssiMode(TRUE);
    call HPLXE1205.releaseBus();
    sleepOrStartReceive();
    return rcombine3(result1, result2, result3);
  }

  command result_t StdControl.stop()
  {
    result_t result1, result2, result3;

    atomic mState = RADIO_DISABLED;

    call IRQ0.disable();
    call IRQ1.disable();
    
    call XE1205Control.AntennaOff();
    call XE1205Control.SleepMode();

    result1 = call ConfigControl.stop();
    result2 = call HPLControl.stop();
    result3 = call TimerJiffyControl.stop();

    if (call HPLXE1205.getBus() != SUCCESS) return FAIL;
    call XE1205Control.SetRssiMode(FALSE);
    call HPLXE1205.releaseBus();

    // This needs to be set to get to 6 uamps sleep power
    // but sensors might depend on it, so not clear at this point where it belongs.
    // TOSH_SET_NREGE_PIN();

    return rcombine3(result1, result2, result3);
  }


  bool channelClear() {
    uint8_t rssi = rssiFromPair(rssiPreTx.rssiHigh, rssiPreTx.rssiLow);
    uint8_t clear_thresh = call CCAThresh.getClearThresh();

    // if we have a very very near neighbor we could catch his LO leakage in which case RSSI is never below -85dbm.
    // in this situation, we can't do any real CSMA to speak of, due to the limited RSSI measurement range of the xemics.
    //if (clear_thresh == RSSI_ABOVE_85 && rssi == RSSI_ABOVE_85)  return (call Random.rand() & 1);

    return (rssi < clear_thresh);
  }


  void checkCrcAndUnWhiten(TOS_MsgPtr msg_) {
    uint16_t crc = 0;
    uint8_t* ptr = (uint8_t*) (&msg_->whitening);
    uint8_t length = msg_->length;
    uint8_t white_ = msg_->whitening;

    crc = crcByte(crc, length);
    for(; ptr < (uint8_t *)&msg_->data[length]; ++ptr) {
      *ptr ^= white_;
      crc = crcByte(crc, *ptr);
    }
                
    if (crc == ( ((uint8_t) msg_->data[length]) | ((uint8_t) msg_->data[length+1]) << 8)) {
      msg_->crc = 1;
      stats.pktsRX++;
    } else {
      msg_->crc = 0;
      stats.crcErrsRX++;
    }
  }


  // Compute the CRC, whiten and copy the message into 
  // temp buffer (mTxWhitePtr)
  void computeCrcAndWhiten(TOS_MsgPtr msg_)
  {
    uint16_t crc = 0;
    uint8_t const* ptr = (uint8_t*)msg_;
    uint8_t length = msg_->length; 
   
    char* destptr = ((char*) mTxWhitePtr);

    msg_->whitening = 0;
    white++;

    for(; ptr < (uint8_t const*)&msg_->data[length]; ++ptr) {
      // crc computation will include whitening byte with value 0
      // (crc check at other end is done over unwhitened packet, at 
      //  which point whitening byte is back to 0).
      crc = crcByte(crc, *ptr); 
      *destptr = *ptr ^ white;      
      destptr++;
    }

    msg_->crc = crc;

    mTxMsgWhite.length = msg_->length;
    mTxMsgWhite.whitening = white;

    ( mTxMsgWhite.data[length]) = crc & 0xff; 
    (mTxMsgWhite.data[length+1]) = crc >> 8;
  }

  void radioSleep() { // async
    atomic mState = RADIO_SLEEP; 
    call XE1205Control.AntennaOff();

    if (call HPLXE1205.getBus() == SUCCESS) {
      // if the bus is taken, we won't be able to turn off the RSSI for this sleep cycle --
      // assuming the other client of the bus is well behaved, it won't be taken forever 
      // and we will get it at the next LPL period
      call XE1205Control.SetRssiMode(FALSE);
      call HPLXE1205.releaseBus();
    }
    call XE1205Control.SleepMode();
  }

  
  result_t sendRadioOn() {
    
    atomic {	  // this can be cleaned up when we move to nesc1.2 which allows return from atomic sections..

      if (enableCCA && !setRssiRangeLow()) 
      	return FAIL;
  
      if (timerState != TIMER_IDLE) {
 	  call TimerJiffy.stop(); 
 	  timerState = TIMER_IDLE;
      }
      
      call IRQ0.disable();
      call IRQ0.clear();
      
      mState = RADIO_PRE_TX;
      congestionBackoffs = 0;
      
      if (enableInitBk)
	timerState = TIMER_INITIALBACKOFF;
      else { 
	if (enableCCA) 
	  timerState = TIMER_PRE_TX_RSSI_LO;
	else
	  timerState = TIMER_IDLE;
      }
    }

    mBufferIndex = 0;
    computeCrcAndWhiten(mTxPtr);


    // if we have CCA disabled, no need to make RSSI measurements, 
    // and we can jump straight into TX transmission
    if (!enableCCA) {
      startTX();
      return SUCCESS;
    }
    

    // could probably move this to after the setOneShot to improve //ism
    atomic clearRssiInfo(&rssiPreTx);

    if (enableInitBk) {
      if (!call TimerJiffy.setOneShot(xe1205_nbyte_jiffies(signal MacBackoff.initial(mTxPtr)))) {
	atomic {
	  timerState = TIMER_IDLE;
	  if (lplRXState) radioSleep(); else mState = RADIO_LISTEN;
	}
	return FAIL;
      }
    }
    else { // Initial backoff disabled, go straight to pre-tx rssi measurement
      if (!(setRssiRangeLow() && call TimerJiffy.setOneShot((rssiMeasurePeriod_jiffies())))) {
	atomic {
	  timerState = TIMER_IDLE;
	  if (lplRXState) radioSleep(); else mState = RADIO_LISTEN;
	}
	return FAIL;
      }
    }
    return SUCCESS;
  }

  command result_t Send.send(TOS_MsgPtr msg_)  {

    atomic {

      if (radio_busy()) return FAIL;

      // reserve the bus for the whole transaction.
      // we could make things finer-grained, but depending on the HPL implementation
      // the overhead of getting/releasing at multiple points throughout a radio frame becomes too much,
      // esp. given the timing sensitivity of this code.
      if (call HPLXE1205.getBus() != SUCCESS) return FAIL;

      if (mFlags & flagTxBufBusy) return FAIL;

      if (timerState == TIMER_POST_TX_RSSI) {
	if (!postTxRssiCancellable) 
	  return FAIL;
	else {
	  call TimerJiffy.stop(); 
	  timerState = TIMER_IDLE;
	}
      }

      if (mState == RADIO_SLEEP) {
	call XE1205Control.AntennaRx();
	call XE1205Control.RxMode();
	call XE1205Control.SetRssiMode(TRUE);

	if (!call TimerJiffy.setOneShot(usecs_to_jiffies(Xe1205_Sleep_to_RX_Time))) 
	  return FAIL;
	timerState = TIMER_WAKE_TX;
	mFlags |= flagTxBufBusy;
	mTxPtr = msg_;
	return SUCCESS;
      }

      mFlags |= flagTxBufBusy;
      mTxPtr = msg_;
    }

    if (sendRadioOn() == SUCCESS) return SUCCESS;
      
    atomic mFlags &= ~flagTxBufBusy;
    return FAIL;
  }

   

  // Compute this *before* the tx interrupt occurs, in order to squeeze out every possible 
  // cycle of latency between interrupt and writing into FIFO.
  void computeNextTxlength() {
    nextTxlength = TOSH_HEADER_SIZE + mTxWhitePtr->length + sizeof(mTxPtr->crc) - mBufferIndex; 
    if (nextTxlength > 16) nextTxlength = 16;
  }

  void computeNextRxlength() {
    uint16_t bytesleft = TOSH_HEADER_SIZE + mRxPtr->length + sizeof(mTxPtr->crc) - mBufferIndex; 

    // for timesync and such, we want the end of the packet to coincide with a fifofull event, 
    // so that we know precisely when last byte was received 
    if (bytesleft > 16) {
      if (bytesleft < 32) nextRxlength = bytesleft - 16; else nextRxlength = 15;
    } 
    else {
      nextRxlength = bytesleft;
    }
  }


  void startTX() {// async

    uint8_t const *preamblePtr;
    uint8_t n;

    nlplPreambles = Xe1205_LPL_NPreambles[lplTXState];

    call XE1205Control.TxMode(); // xxx this should happen before, especially if we did not go through pre_tx_rssi 
    call XE1205Control.AntennaTx(); // now we've decided channel is ours, turn on antenna right away to keep it busy.

    if (nlplPreambles) {
      atomic mState = RADIO_TX_LPLPREAMBLE; 
      preamblePtr = lplPreamble;
      n = sizeof(lplPreamble);
      nlplPreambles--;
    } else {
      atomic mState = RADIO_TX_DATA; 
      preamblePtr = pktPreamble;
      n = sizeof(pktPreamble);
      computeNextTxlength();
    }

    if (call HPLXE1205.writeData(preamblePtr, n) != SUCCESS) 
      sendFailed();

    atomic {
      stats.bytesTX += n;
    }
    
    call IRQ0.enable(FALSE);
  }

  default event result_t Send.sendDone(TOS_MsgPtr msg_, result_t success_)
  {
    return SUCCESS;
  }

  task void frameSentTask()
  {
    TOS_MsgPtr msg;

    atomic {
      msg = mTxPtr;
      mFlags &= ~flagTxBufBusy;
    }

    signal Send.sendDone(msg, SUCCESS);
  }

  void sendFailed() //async
  {
    TOS_MsgPtr msg;

    atomic msg = mTxPtr;

    // Since this is a send failure, reset flagTxBufBusy *after* signalling event, so that we 
    // don't accept a new packet to send before the senddone is complete.
    signal Send.sendDone(msg, FAIL);
    atomic mFlags &= ~flagTxBufBusy;
    sleepOrStartReceive();
  }

  default event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg_)
  {
    return msg_;
  }

        
  task void frameReceived()
  {
    TOS_MsgPtr msg;
    uint8_t rssi;

    msg = mRxPtr;

    if (msg->crc && (rssiRX.rssiStatus == flagHaveRssiBoth)) {
      atomic rssi = rssiFromPair(rssiRX.rssiHigh, rssiRX.rssiLow);
      call CCAThresh.newRXSample(rssi);
    }

    msg = signal Receive.receive(msg);

    atomic {
      if(msg) mRxPtr = msg;
      mFlags &= ~flagRxBufBusy;
    }
  }

  inline void sleepOrStartReceive() {

    if (lplRXState) {
      atomic timerState = TIMER_LPL_SLEEP;  
      call TimerJiffy.setOneShot(xe1205_nbyte_jiffies(16*Xe1205_LPL_SleepTimeNPreambles[lplRXState])); 
      radioSleep();
    }
    else startReceivePkt();
  }

  inline void startReceive() {
    if (lplRXState) startReceiveLpl(); else startReceivePkt();
  }

  /**
   * Arm pattern detector and enable packet detection interrupt.
   * Set RSSI measurement range according to rssiRange flag (TRUE -> high)
   */
  void startReceivePkt()
  {

    atomic mState = RADIO_LISTEN;

    mBufferIndex = 1; // at first interrupt we read length byte into msg[0]

    if (call HPLXE1205.getBus() == SUCCESS) {
      setRssiRangeHigh();
      call XE1205Control.ArmPatternDetector();

      // ClearFifooverrun flag because overruns may happen at 152kbps: after reading the last bytes of a packet, 
      // FIFO continues to fill, and depending on how many bytes we took in the last read, 
      // it could overflow.
      // This call also re-arms the pattern detector
      call XE1205Control.ClearFifoOverrun();  

      // don't release bus if we are in LPL, since we have at this point already heard the LPL preamble and 
      // are waiting for the packet preamble
      if (!lplRXState)	call HPLXE1205.releaseBus();

    } else { // try again later, otherwise whole stack hangs..
      call TimerJiffy.stop();
      atomic timerState = TIMER_WAITBUS_ARMPD;
      call TimerJiffy.setOneShot(15000); 
    }

    call IRQ0.enable(TRUE);
    }
    
  void startReceiveLpl()
  {
    atomic mState = RADIO_LPL_LISTEN;

    if (call HPLXE1205.getBus() == SUCCESS) {
      call XE1205Control.loadLPLPattern();
      call XE1205Control.ArmPatternDetector();
      call HPLXE1205.releaseBus();
    } 
    call IRQ0.enable(TRUE);
  }


  // All the hackery below is due to the fact that the XE1205 RSSI value is over 3 bits, 
  // but can only be read two bits at a time (with a configuration bit indicating if 
  // we want to read in the low or high range). 
  // So we must make a first measure, then, if the measure is at the border of the current 
  // measurement range, switch range and make a second measure.
  // see rssi.txt
  void readRssi(rssiInfo* rssiInfoPtr, bool range) {

    // if the task to push previous values into CCAThresh still hasn't run, no point getting new ones
    if (rssiInfoPtr->rssiStatus == flagHaveRssiBoth) return;

    if (range) {// take high range measurement

      call XE1205Control.GetRssi(&rssiInfoPtr->rssiHigh);

      if (rssiInfoPtr->rssiStatus == flagHaveRssiLow) {
	rssiInfoPtr->rssiStatus = flagHaveRssiBoth;
	return;
      }
      if (rssiInfoPtr->rssiHigh != 0x00) {
	rssiInfoPtr->rssiLow = 0x3;
	rssiInfoPtr->rssiStatus = flagHaveRssiBoth;
	return;
      }
      
      rssiInfoPtr->rssiStatus = flagHaveRssiHigh;

    } else {// take low range measurement

      call XE1205Control.GetRssi(&rssiInfoPtr->rssiLow);

      if (rssiInfoPtr->rssiStatus == flagHaveRssiHigh) {
	rssiInfoPtr->rssiStatus = flagHaveRssiBoth;
	return;
      }
      if ( rssiInfoPtr->rssiLow != 0x03) {
	rssiInfoPtr->rssiHigh = 0;
	rssiInfoPtr->rssiStatus = flagHaveRssiBoth;
	return;
      }
      rssiInfoPtr->rssiStatus = flagHaveRssiLow;
    }
  }

  void startPostTxRssiTimer()  {

    // possible optimization: 
    // if we have ACKs enabled, then we have already switched to RX a while ago and the timer below is not necessary.
    if (call TimerJiffy.setOneShot(usecs_to_jiffies(Xe1205_TX_to_RX_Time) + rssiMeasurePeriod_jiffies())) { 
      timerState = TIMER_POST_TX_RSSI;
      
      if (rssiPostTx.rssiStatus == flagHaveRssiLow) 
 	setRssiRangeHigh();
      else
 	setRssiRangeLow();

      // If a send() comes in before we are done measuring Post-TX RSSI, we usually cancel the measure, 
      // so as not to penalize thruput.
      // But every once in a while, we FAIL the send() and go ahead with the RSSI measure, to avoid starving
      // the CCA estimator.
      if (nPostTxCancels <= 10) { 
	nPostTxCancels++;
	postTxRssiCancellable = TRUE;
      } else {
	nPostTxCancels = 0;
	postTxRssiCancellable = FALSE;
      }
    }
  }
  


  /**
   * Event: IRQ0 asserted.
   *
   * In transmit: nTxFifoEmpty. (ie after the last byte has been *read out of the fifo*)
   * In receive: write_byte. 
   */
  async event void IRQ0.fired()
  {
    switch(mState) {
    case RADIO_LPL_LISTEN:

      if(mFlags & flagTxBufBusy) {
	call IRQ0.disable();
	return;
      }

      // reserve the bus for the whole rx operation. (same rationale as below in RADIO_LISTEN)
      if (call HPLXE1205.getBus() != SUCCESS) {
	startReceive(); 
	// note that if we have a faulty component that hogs the bus forever, then 
	// we will stay in this state and not turn off radio. 
	// the obvious fix is to call sleepOrStartReceive() here instead of startReceive --
	// but we lose the opportunity to catch the packet later in the preamble.
	return;
      }

      mState = RADIO_LISTEN;
      call XE1205Control.loadDataPattern();
      call XE1205Control.SetRssiMode(TRUE);
      startReceivePkt();
      return;

    case RADIO_LISTEN:

      if(mFlags & flagTxBufBusy) {
	call IRQ0.disable();
	return;
      }

      if(mFlags & flagRxBufBusy) {
	sleepOrStartReceive(); 
	return;
      }

      mState = RADIO_RX;

      // reserve the bus for the whole rx operation.
      // we could make things finer-grained, but depending on the HPL implementation
      // the overhead of getting/releasing at multiple points throughout a radio frame becomes too much,
      // esp. given the timing sensitivity of this code.
      if (!lplRXState && // if lplRXState, we already took bus in RADIO_LPL_LISTEN state above
	  call HPLXE1205.getBus() != SUCCESS) {
      	sleepOrStartReceive(); //this will actually fail since the bus is busy, but then will self-repost
      	return;
      }

      // if we have a very high bitrate, then it is impossible to read first byte before second one is pushed into FIFO.
      // so in this case, we purposely let a second byte come in before reading the first one, in order to avoid 
      // tickling the xemics FIFO bug.
      if (call XE1205Control.GetByteTime_us() < 150)
	TOSH_uwait(call XE1205Control.GetByteTime_us());

      mRxPtr->length = call HPLXE1205.readByteFast();

      if (mRxPtr->length > TOSH_DATA_LENGTH) {
	sleepOrStartReceive();
	return;
      }

      mFlags |= flagRxBufBusy;

      signal RadioReceiveCoordinator.startSymbol(8, 0, mRxPtr);

      clearRssiInfo(&rssiRX);
      readRssi(&rssiRX, TRUE);
      if (rssiRX.rssiStatus != flagHaveRssiBoth) setRssiRangeLow();


      computeNextRxlength();

      // In case of high load, and at very high bit rates, it may happen that 
      // a FIFO overrun occurs, in which case the stack hangs. Workaround is to set a (generous) 
      // timeout at the beginning of pkt reception, so that receiver can clear FIFO overrun and recover.
      atomic timerState = TIMER_RX;
      call TimerJiffy.setOneShot(xe1205_byte_jiffies() << 7); 

      call IRQ1.enable(TRUE);
      return;
      
    case RADIO_RX_ACK:
      call TimerJiffy.stop();          // ACK arrived, cancel timeout timer.
      atomic timerState = TIMER_IDLE;

      stats.bytesTX += sizeof(ack_code);
      call XE1205Control.loadDataPattern();
      mTxPtr->ack = 1;
      postSend();
      return;

    case RADIO_TX_LPLPREAMBLE:
      if (call HPLXE1205.writeData(lplPreamble, sizeof(lplPreamble)) != SUCCESS) {
	sendFailed(); 
	return;
      }
      atomic stats.bytesTX += sizeof(lplPreamble);

      if (--nlplPreambles) 
	mState = RADIO_TX_LPLPREAMBLE;
       else 
	mState = RADIO_TX_PKTPREAMBLE;

      call IRQ0.enable(FALSE);
      return;

    case RADIO_TX_PKTPREAMBLE:
      if (call HPLXE1205.writeData(pktPreamble, sizeof(pktPreamble)) != SUCCESS) {
	sendFailed();
	return;
      }
      atomic stats.bytesTX += sizeof(pktPreamble);

      computeNextTxlength();
      mState = RADIO_TX_DATA;
      call IRQ0.enable(FALSE);
      return;

    case RADIO_TX_DATA:
      if(mBufferIndex == 0)
	signal RadioSendCoordinator.startSymbol(8, 0, mTxPtr);

      call HPLXE1205.writeData(&((char *)mTxWhitePtr)[mBufferIndex], nextTxlength);
      stats.bytesTX += nextTxlength;
      mBufferIndex += nextTxlength;
      computeNextTxlength();
      if (nextTxlength == 0) {
	call IRQ1.enable(TRUE);
      }
      else {      
	call IRQ0.enable(FALSE);
      }
      return;
    }
  }

  /**
   * Event: IRQ1 asserted.
   *
   * In transmit: TxStopped. (ie after the last byte has been *sent*)
   * In receive: Fifofull.
   */
  async event void IRQ1.fired()
  {
    switch(mState) {
    case RADIO_RX:

      call IRQ1.clear();
      call HPLXE1205.readData(&((uint8_t*)(mRxPtr))[mBufferIndex], nextRxlength);
      mBufferIndex += nextRxlength;
      computeNextRxlength();
      if (nextRxlength==0) {
	// Re-arm right away to minimize chance of fifo overrun
	// [ The overrun in itself is harmless, since we are at end of packet, but 
	//   reading and/or clearing the fifooverrun flag appears to be buggy ]
	call XE1205Control.ArmPatternDetector();

	call TimerJiffy.stop(); // packet received; cancel RX timeout

 	if (rssiRX.rssiStatus != flagHaveRssiBoth)
 	  readRssi(&rssiRX, FALSE);
	
	checkCrcAndUnWhiten(mRxPtr);

	stats.bytesRX += sizeof(pktPreamble) + TOSH_HEADER_SIZE + mRxPtr->length + TOSH_TRAILER_SIZE;

	if (enableAck && mRxPtr->crc && (mRxPtr->addr == TOS_LOCAL_ADDRESS)) {
	  mState = RADIO_TX_ACK;
	  call XE1205Control.TxMode(); 
	  call XE1205Control.AntennaTx(); // turn on antenna before we send ACK in order to keep channel busy
	  
	  // Wait for TX transition time. 
	  // Short enough (100us) that timerjiffy not worth using here.
	  // '- 20' is for the time it takes to shift first byte over SPI.
	  TOSH_uwait(Xe1205_RX_to_TX_Time - 20); 
	  
	  call HPLXE1205.writeData(ack_code, sizeof(ack_code));
	  call IRQ1.enable(TRUE);

	  return;
	}

	if(!post frameReceived()) {
	  mFlags &= ~flagRxBufBusy;
	}

	sleepOrStartReceive(); 

	return;
      }

      // don't clear pending interrupt, just in case the FIFO has already overflowed.
      // [ such an overflow is rare and only possible at 152kbps, but could cause the whole stack to hang ]
      call IRQ1.reEnable(); 
      return;

    case RADIO_TX_DATA:
      call XE1205Control.AntennaRx();
      call XE1205Control.RxMode();
      mTxPtr->whitening = 0; // erase whitening sequence
      stats.pktsTX++;

      if (enableAck  && (mTxPtr->addr != TOS_BCAST_ADDR)) {
	mState = RADIO_RX_ACK;
	call XE1205Control.loadAckPattern();
	call XE1205Control.ArmPatternDetector();
	call IRQ0.enable(TRUE);
	timerState = TIMER_ACK_WAIT;
	// for long packets, setting the timeout value shorter than this misses the ACK.
	call TimerJiffy.setOneShot(25 * xe1205_byte_jiffies()); 
	return;
      }

      timerState = TIMER_IDLE;
      postSend();

      return;

    case RADIO_TX_ACK:

      call XE1205Control.AntennaRx();
      call XE1205Control.RxMode();

      stats.bytesTX += sizeof(ack_code);

      if(!post frameReceived()) {
	mFlags &= ~flagRxBufBusy;
      }

      sleepOrStartReceive(); 
      
      return;
    }
  }

  default async event uint16_t MacBackoff.initial(TOS_MsgPtr m) {
    return (call Random.rand() & 0xF) + 1;
  }
  default async event uint16_t MacBackoff.congestion(TOS_MsgPtr m) {
    return (call Random.rand() & 0x1F) + 1;
  }

  /*
   * Default coordinator handlers.
   *
   * Only startSymbol() is actually generated, as we have a buffer between the microcontroller and the
   * radio, and therefore no definite timing when clocking in bytes.
   */
  default async event void RadioSendCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff)
  {
  }

  default async event void RadioSendCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount)
  {
  }

  default async event void RadioSendCoordinator.blockTimer()
  {
  }

  default async event void RadioReceiveCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff)
  {
  }

  default async event void RadioReceiveCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount)
  {
  }

  default async event void RadioReceiveCoordinator.blockTimer()
  {
  }

}


