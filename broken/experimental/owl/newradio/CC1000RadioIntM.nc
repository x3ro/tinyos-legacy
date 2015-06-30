// $Id: CC1000RadioIntM.nc,v 1.4 2007/04/12 22:30:43 idgay Exp $

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
 * Authors: Philip Buonadonna, Jaein Jeong, Joe Polastre, David Gay.
 * A rewrite of the low-power-listening CC1000 radio stack.
 */

/**
 * @author Philip Buonadonna
 * @author Jaein Jeong
 * @author Joe Polastre
 * @author David Gay
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
implementation 
{
  enum {
    DISABLED_STATE,
    IDLE_STATE,
    SYNC_STATE,
    RX_STATE,
    RECEIVED_STATE,
    SENDING_ACK,
    PRETX_STATE,
    TXPREAMBLE_STATE,
    TXSYNC_STATE,
    TXDATA_STATE,
    TXCRC_STATE,
    TXFLUSH_STATE,
    TXWAITFORACK_STATE,
    TXREADACK_STATE,
    TXDONE_STATE,
    POWERDOWN_STATE,
    PULSECHECK_STATE
  };

  enum {
    SYNC_BYTE1 =	0x33,
    SYNC_BYTE2 =	0xcc,
    SYNC_WORD =		SYNC_BYTE1 << 8 | SYNC_BYTE2,
    ACK_BYTE1 =		0xba,
    ACK_BYTE2 =		0x83,
    ACK_WORD = 		ACK_BYTE1 << 8 | ACK_BYTE2,
    ACK_LENGTH =	16,
    MAX_ACK_WAIT =	18,
    TIME_AFTER_CHECK =  30,
  };

  uint8_t radioState = DISABLED_STATE;
  struct {
    uint8_t ack : 1;
    uint8_t ccaOff : 1;
    uint8_t invert : 1;
    uint8_t txPending : 1;
    uint8_t txBusy : 1;
  } f; // f for flags
  uint16_t count;
  uint8_t clearCount;
  uint16_t runningCrc;

  uint16_t rxShiftBuf;
  uint8_t rxBitOffset;
  TOS_Msg rxBuf;
  TOS_MsgPtr rxBufPtr = &rxBuf;

  uint16_t preambleLength;
  int16_t macDelay;
  TOS_MsgPtr txBufPtr;
  uint8_t nextTxByte;

  uint8_t lplTxPower, lplRxPower;
  uint16_t sleepTime;
  uint8_t newPower;

  uint16_t clearThreshold = CC1K_SquelchInit;
  uint16_t rssiForSquelch;
  uint16_t squelchTable[CC1K_SquelchTableSize];
  uint8_t squelchIndex, squelchCount;

  uint8_t ackCode[5] = { 0xab, ACK_BYTE1, ACK_BYTE2, 0xaa, 0xaa };

  void cancelRssi();
  void adjustSquelch(uint16_t data);
  void startSquelchTimer();
  void checkChannel(uint16_t data);
  void pulseCheck(uint16_t data);
  void pulseFail(uint16_t data);
  void noiseFloor(uint16_t data);

#ifdef UNREACHABLE
  /* We only call this from signalPacketReceived, and a successful post
     of that enters the received state, which cancels RSSI */
#define enterIdleStateRssi enterIdleState
#else
  void enterIdleStateRssi() {
    radioState = IDLE_STATE;
    count = 0;
  }
#endif

  void enterIdleState() {
    cancelRssi();
    enterIdleStateRssi();
  }

  void enterDisabledState() {
    cancelRssi();
    radioState = DISABLED_STATE;
  }

  void enterPowerDownState() {
    cancelRssi();
    radioState = POWERDOWN_STATE;
  }

  void enterPulseCheckState() {
    radioState = PULSECHECK_STATE;
    count = 0;
  }

  void enterSyncState() {
    cancelRssi();
    radioState = SYNC_STATE;
    count = 0;
  }

  void enterRxState() {
    cancelRssi();
    radioState = RX_STATE;
    rxBufPtr->length = DATA_LENGTH;
    count = 0;
    runningCrc = 0;
  }

  void enterReceivedState() {
    cancelRssi();
    radioState = RECEIVED_STATE;
  }

  void enterAckState() {
    cancelRssi();
    radioState = SENDING_ACK;
    count = 0;
  }

  void enterPreTxState() {
    cancelRssi();
    radioState = PRETX_STATE;
    count = clearCount = 0;
  }

  void enterTxPreambleState() {
    radioState = TXPREAMBLE_STATE;
    count = 0;
    runningCrc = 0;
    nextTxByte = 0xaa;
  }

  void enterTxSyncState() {
    radioState = TXSYNC_STATE;
  }

  void enterTxDataState() {
    radioState = TXDATA_STATE;
    // The count increment happens before the first byte is read from the
    // packet, so we initialise count to -1 to compensate.
    count = -1; 
  }

  void enterTxCrcState() {
    radioState = TXCRC_STATE;
  }
    
  void enterTxFlushState() {
    radioState = TXFLUSH_STATE;
    count = 0;
  }
    
  void enterTxWaitForAckState() {
    radioState = TXWAITFORACK_STATE;
    count = 0;
  }
    
  void enterTxReadAckState() {
    radioState = TXREADACK_STATE;
    rxShiftBuf = 0;
    count = 0;
  }
    
  void enterTxDoneState() {
    radioState = TXDONE_STATE;
  }

  /* RSSI fun. It's used for lots of things, and a request to read it
     for one purpose may have to be discarded if conditions change. For
     example, if we've initiated a noise-floor measure, but start 
     receiving a packet, we have to:
     - cancel the noise-floor measure (we don't know if the value will
       reflect the received packet or the previous idle state)
     - start an RSSI measurement so that we can report signal strength
       to the application
  */

  enum { /* The reasons for requesting RSSI */
    RSSI_IDLE, // no current measurement
    RSSI_CANCELLED, // an abandoned measurement
    RSSI_RX, // RSSI indication in received packets
    RSSI_NOISE_FLOOR, // RSSI for noise-floor estimation
    RSSI_CHECK_CHANNEL, // for checking whether the channel is clear
    RSSI_PULSE_CHECK, // low-power-listening channel check
    RSSI_PULSE_FAIL, // we misjudged packet presence. adjust noise floor before
     		     // going back to sleep.
  };
  uint8_t currentRssiOp;
  uint8_t nextRssiOp;

  void cancelRssi() {
    if (currentRssiOp != RSSI_IDLE)
      currentRssiOp = RSSI_CANCELLED;
  }

  void startRssi() {
    if (!call RSSIADC.getData())
      // XXX. we have a problem
      ;
  }

  void requestRssi(uint8_t request) {
    if (currentRssiOp == RSSI_IDLE)
      {
	currentRssiOp = request;
	startRssi();
      }
    else // We should only come here with currentRssiOp = RSSI_CANCELLED
      nextRssiOp = request;
  }

#if 0
  struct {
    uint8_t radioState;
    uint16_t rssi;
  } fun[64];
  uint8_t pos;
  uint16_t waited;
#endif

  async event result_t RSSIADC.dataReady(uint16_t data) {
    atomic
      {
	uint8_t op = currentRssiOp;

	if (nextRssiOp != RSSI_IDLE)
	  {
	    currentRssiOp = nextRssiOp;
	    nextRssiOp = RSSI_IDLE;
	    startRssi();
	  }
	else
	  currentRssiOp = RSSI_IDLE;

	switch (op)
	  {
	  case RSSI_CHECK_CHANNEL: checkChannel(data); break;
	  case RSSI_PULSE_CHECK: pulseCheck(data); break;
	  case RSSI_RX: rxBufPtr->strength = data; break;
	  case RSSI_NOISE_FLOOR: noiseFloor(data); break;
	  case RSSI_PULSE_FAIL: pulseFail(data); break;
	  }
      }
    return SUCCESS;
  }

  /* Low-power listening stuff */
  /*---------------------------*/
  void setPreambleLength() {
    preambleLength = PRG_RDB(&CC1K_LPL_PreambleLength[lplTxPower * 2]) << 8
      | PRG_RDB(&CC1K_LPL_PreambleLength[lplTxPower * 2 + 1]);
  }

  void setSleepTime() {
    sleepTime = PRG_RDB(&CC1K_LPL_SleepTime[lplRxPower *2 ]) << 8 |
      PRG_RDB(&CC1K_LPL_SleepTime[lplRxPower * 2 + 1]);
  }

  task void sendWakeupTask() {
    atomic
      if (radioState != IDLE_STATE)
	return;

    call CC1000StdControl.start();
    //TOSH_uwait(2000);
    call CC1000Control.BIASOn();
    TOSH_uwait(200);
    call CC1000Control.RxMode();
    call SpiByteFifo.rxMode();
    startSquelchTimer();
    call SpiByteFifo.enableIntr();
  }

  /* Prepare to send when currently in low-power listen mode (i.e., 
     PULSECHECK or POWERDOWN) */
  void sendWakeup() {
    enterIdleState();
    call WakeupTimer.stop();
    if (!post sendWakeupTask())
      ; // XXX. Hmm
  }

  event result_t WakeupTimer.fired() {
    atomic 
      {
	if (lplRxPower == 0)
	  return SUCCESS;

	switch (radioState)
	  {
	  case IDLE_STATE:
	    if (!f.txPending)
	      requestRssi(RSSI_PULSE_FAIL);
	    call WakeupTimer.start(TIMER_ONE_SHOT, sleepTime);
	    break;

	  case POWERDOWN_STATE:
#ifndef UNREACHABLE
	    if (f.txPending)
	      sendWakeup();
	    else
#endif
	      {
		enterPulseCheckState();
		call CC1000Control.BIASOn();
		call WakeupTimer.start(TIMER_ONE_SHOT, 1);
	      }
	    break;

	  case PULSECHECK_STATE:
	    call CC1000Control.RxMode();
	    TOSH_uwait(35);
	    requestRssi(RSSI_PULSE_CHECK);
	    TOSH_uwait(80);
	    //call CC1000Control.BIASOn();
	    //call CC1000StdControl.stop();
	    break;

	  default:
	    call WakeupTimer.start(TIMER_ONE_SHOT, 5);
	    break;
	  }
      }
    
    return SUCCESS;
  }

  task void idleTimerTask() {
    startSquelchTimer();
    call WakeupTimer.start(TIMER_ONE_SHOT, TIME_AFTER_CHECK);
  }

  task void adjustSquelchAndStop() {
    uint16_t squelchData;

    atomic
      {
	squelchData = rssiForSquelch;
	if (f.txPending)
	  {
	    if (radioState == PULSECHECK_STATE)
	      sendWakeup();
	  }
	else if ((radioState == IDLE_STATE && lplRxPower > 0) ||
		 radioState == PULSECHECK_STATE)
	  {
	    enterPowerDownState();
	    call SpiByteFifo.disableIntr();
	    call CC1000StdControl.stop();
	    call WakeupTimer.start(TIMER_ONE_SHOT, sleepTime);
	  }
      }
    adjustSquelch(squelchData);
  }

  task void justStop() {
    atomic
      {
	if (f.txPending)
	  {
	    if (radioState == PULSECHECK_STATE)
	      sendWakeup();
	  }
	else if ((radioState == IDLE_STATE && lplRxPower > 0) ||
		 radioState == PULSECHECK_STATE)
	  {
	    enterPowerDownState();
	    call SpiByteFifo.disableIntr();
	    call CC1000StdControl.stop();
	    call WakeupTimer.start(TIMER_ONE_SHOT, sleepTime);
	  }
      }
  }

  void pulseCheck(uint16_t data) {
    //if(data > clearThreshold - CC1K_SquelchBuffer)
    if (data > clearThreshold - (clearThreshold >> 2))
      {
	// don't be too agressive (ignore really quiet thresholds).
	if (data < clearThreshold + (clearThreshold >> 3))
	  {
	    // adjust the noise floor level, go back to sleep.
	    rssiForSquelch = data;
	    if (!post adjustSquelchAndStop())
	      ; // XXX.
	  }
	else
	  post justStop();
	
      }
    else if (count++ > 5)
      {
	//go to the idle state since no outliers were found
	enterIdleState();
	call CC1000Control.RxMode();
	call SpiByteFifo.rxMode();     // SPI to miso
	call SpiByteFifo.enableIntr(); // enable spi interrupt
	post idleTimerTask();
      }
    else
      {
	//call CC1000Control.RxMode();
	//TOSH_uwait(35);
	requestRssi(RSSI_PULSE_CHECK);
	TOSH_uwait(80);
	//call CC1000Control.BIASOn();
	//call CC1000StdControl.stop();
      }
  }

  void pulseFail(uint16_t data) {
    rssiForSquelch = data;
    if (!post adjustSquelchAndStop())
      ; // XXX.
  }
  


  command result_t StdControl.init() {
    uint8_t i;

    call SpiByteFifo.initSlave(); // set spi bus to slave mode
    call CC1000StdControl.init();
    call CC1000Control.SelectLock(0x9);		// Select MANCHESTER VIOLATION
    if (call CC1000Control.GetLOStatus())
      atomic f.invert = TRUE;

    for (i = 0; i < CC1K_SquelchTableSize; i++)
      squelchTable[i] = CC1K_SquelchInit;

    call ADCControl.bindPort(TOS_ADC_CC_RSSI_PORT, TOSH_ACTUAL_CC_RSSI_PORT);
    call ADCControl.init();
    call Random.init();
    call TimerControl.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    atomic 
      if (radioState == DISABLED_STATE)
	{
	  enterIdleState();
	  f.txPending = f.txBusy = FALSE;
	  setPreambleLength();
	  setSleepTime();
	  // set a time to start sleeping after measuring the noise floor
	  if (lplRxPower > 0)
	    call WakeupTimer.start(TIMER_ONE_SHOT, CC1K_SquelchIntervalSlow);
	}
      else
	return SUCCESS;

    call CC1000StdControl.start();
    //TOSH_uwait(2000);
    call CC1000Control.BIASOn();
    TOSH_uwait(200);
    call SpiByteFifo.rxMode();
    call CC1000Control.RxMode();
    startSquelchTimer();
    call SpiByteFifo.enableIntr();

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    atomic 
      {
	enterDisabledState();
	call CC1000StdControl.stop();
	call SpiByteFifo.disableIntr();
      }
    call SquelchTimer.stop();
    call WakeupTimer.stop();
    return SUCCESS;
  }

  command result_t Send.send(TOS_MsgPtr msg) {
    atomic
      {
	if (f.txBusy)
	  return FAIL;

	f.txBusy = TRUE;
	txBufPtr = msg;

	if (!f.ccaOff)
	  macDelay = signal MacBackoff.initialBackoff(msg);
	else
	  macDelay = 0;
	f.txPending = TRUE;

	if (radioState == POWERDOWN_STATE)
	  sendWakeup();

#if 0
	waited = 0;
	call Leds.redOn();
#endif
      }

    return SUCCESS;
  }

  task void signalPacketSent() {
    TOS_MsgPtr pBuf;

    atomic
      {
	if (radioState == DISABLED_STATE)
	  return;

	txBufPtr->time = 0;
	pBuf = txBufPtr;
	if (lplRxPower > 0)
	  call WakeupTimer.start(TIMER_ONE_SHOT, CC1K_LPL_PACKET_TIME);
      }
    atomic f.txBusy = FALSE;
    signal Send.sendDone(pBuf, SUCCESS);
  }

  task void signalPacketReceived() {
    TOS_MsgPtr pBuf;

    atomic
      {
	if (radioState != RECEIVED_STATE)
	  return;

	rxBufPtr->time = 0;
	pBuf = rxBufPtr;
      }
    pBuf = signal Receive.receive(pBuf);
    atomic
      {
	if (pBuf) 
	  rxBufPtr = pBuf;
	/* We don't cancel any pending noise floor measurement */
	enterIdleStateRssi();
      }
  }

  void packetReceiveDone() {
    // We just drop packets which we could not send to the upper layers
    if (post signalPacketReceived())
      enterReceivedState();
    else
      enterIdleState();
    //requestRssi(RSSI_NOISE_FLOOR);
  }

  void packetReceived() {
    // Packet filtering based on bad CRC's is done at higher layers.
    // So sayeth the TOS weenies.
    rxBufPtr->crc = rxBufPtr->crc == runningCrc;

    if (f.ack &&
	rxBufPtr->crc && rxBufPtr->addr == TOS_LOCAL_ADDRESS)
      {
	enterAckState();
	call CC1000Control.TxMode();
	call SpiByteFifo.txMode();
	call SpiByteFifo.writeByte(0xaa);
      }
    else
      packetReceiveDone();
  }

  /* Basic SPI functions */

  void idleData(uint8_t in) {
    // Look for enough preamble bytes
    if (in == 0xaa || in == 0x55)
      {
	/* XXX: reset macDelay if txPending? */
	count++;
	if (count > CC1K_ValidPrecursor)
	  enterSyncState();
      }
    else if (f.txPending)
      if (macDelay <= 1)
	{
	  enterPreTxState();
	  requestRssi(RSSI_CHECK_CHANNEL);
	}
      else
	--macDelay;
  }

  void preTxData(uint8_t in) {
    // If we detect a preamble when we're trying to send, abort.
    if (in == 0xaa || in == 0x55)
      {
	macDelay = signal MacBackoff.congestionBackoff(txBufPtr);
	enterIdleState();
	// we could set count to 1 here (one preamble byte seen).
	// count = 1;
      }
  }

  void syncData(uint8_t in) {
    // draw in the preamble bytes and look for a sync byte
    // save the data in a short with last byte received as msbyte
    //    and current byte received as the lsbyte.
    // use a bit shift compare to find the byte boundary for the sync byte
    // retain the shift value and use it to collect all of the packet data
    // check for data inversion, and restore proper polarity 
    // XXX-PB: Don't do this.

    if (in == 0xaa || in == 0x55)
      // It is actually possible to have the LAST BIT of the incoming
      // data be part of the Sync Byte.  SO, we need to store that
      // However, the next byte should definitely not have this pattern.
      // XXX-PB: Do we need to check for excessive preamble?
      rxShiftBuf = in << 8;
    else if (count++ == 0)
      rxShiftBuf |= in;
    else if (count <= 6)
      {
	// TODO: Modify to be tolerant of bad bits in the preamble...
	uint16_t tmp;
	uint8_t i;

	// bit shift the data in with previous sample to find sync
	tmp = rxShiftBuf;
	rxShiftBuf = rxShiftBuf << 8 | in;

	for(i = 0; i < 8; i++)
	  {
	    tmp <<= 1;
	    if (in & 0x80)
	      tmp  |=  0x1;
	    in <<= 1;
	    // check for sync bytes
	    if (tmp == SYNC_WORD)
	      {
		enterRxState();
		rxBitOffset = 7 - i;
		signal RadioReceiveCoordinator.startSymbol(8, rxBitOffset, rxBufPtr);
		requestRssi(RSSI_RX);
	      }
	  }
      }
    else // We didn't find it after a reasonable number of tries, so....
      enterIdleState();
  }

  void rxData(uint8_t in) {
    uint8_t nextByte;
    uint8_t rxLength = rxBufPtr->length + offsetof(struct TOS_Msg,data);

    // Reject invalid length packets
    if (rxLength > DATA_LENGTH + offsetof(struct TOS_Msg,data))
      {
	// The packet's screwed up, so just dump it
	enterIdleState();
	return;
      }

    rxShiftBuf = rxShiftBuf << 8 | in;
    nextByte = rxShiftBuf >> rxBitOffset;
    ((uint8_t *)rxBufPtr)[count++] = nextByte;
    signal RadioReceiveCoordinator.byte(rxBufPtr, count);

    if (count <= rxLength)
      runningCrc = crcByte(runningCrc, nextByte);

    // Jump to CRC when we reach the end of data
    if (count == rxLength)
      count = offsetof(struct TOS_Msg, crc);

    if (count == MSG_DATA_SIZE)
      packetReceived();
  }

  void ackData(uint8_t in) {
    if (++count >= ACK_LENGTH)
      { 
	call CC1000Control.RxMode();
	call SpiByteFifo.rxMode();
	packetReceiveDone();
      }
    else if (count >= ACK_LENGTH - sizeof ackCode)
      call SpiByteFifo.writeByte(ackCode[count + sizeof ackCode - ACK_LENGTH]);
  }

  void sendNextByte() {
    call SpiByteFifo.writeByte(nextTxByte);
    count++;
  }

  void txPreamble() {
    sendNextByte();
    if (count >= preambleLength)
      {
	nextTxByte = SYNC_BYTE1;
	enterTxSyncState();
      }
  }

  void txSync() {
    sendNextByte();
    nextTxByte = SYNC_BYTE2;
    enterTxDataState();
    // for Time Sync services
    signal RadioSendCoordinator.startSymbol(8, 0, txBufPtr); 
  }

  void txData() {
    sendNextByte();
    if (count < txBufPtr->length + (MSG_DATA_SIZE - DATA_LENGTH - 2))
      {
	nextTxByte = ((uint8_t *)txBufPtr)[count];
	runningCrc = crcByte(runningCrc, nextTxByte);
	signal RadioSendCoordinator.byte(txBufPtr, count);
      }
    else
      {
	nextTxByte = runningCrc;
	enterTxCrcState();
      }
  }

  void txCrc() {
    sendNextByte();
    nextTxByte = runningCrc >> 8;
    enterTxFlushState();
  }

  void txFlush() {
    sendNextByte();
    if (count > 3)
      if (f.ack)
	enterTxWaitForAckState();
      else
	{
	  call SpiByteFifo.rxMode();
	  call CC1000Control.RxMode();
	  enterTxDoneState();
	}
  }

  void txWaitForAck() {
    sendNextByte();
    if (count == 1)
      {
	call SpiByteFifo.rxMode();
	call CC1000Control.RxMode();
      }
    else if (count > 3)
      enterTxReadAckState();
  }

  void txReadAck(uint8_t in) {
    uint8_t i;

    sendNextByte();

    for (i = 0; i < 8; i ++)
      {
	rxShiftBuf <<= 1;
	if (in & 0x80)
	  rxShiftBuf |=  0x1;
	in <<= 1;

	if (rxShiftBuf == ACK_WORD)
	  {
	    txBufPtr->ack = 1;
	    enterTxDoneState();
	    return;
	  }
      }
    if (count >= MAX_ACK_WAIT)
      {
	txBufPtr->ack = 0;
	enterTxDoneState();
      }
  }

  void txDone() {
    if (post signalPacketSent())
      {
	// If the post operation succeeds, goto Idle. Otherwise, we'll just
	// try the post again on the next SPI interrupt
	f.txPending = FALSE;
	enterIdleState();
	//requestRssi(RSSI_NOISE_FLOOR);
      }
  }

  async event result_t SpiByteFifo.dataReady(uint8_t data) {
    signal RadioSendCoordinator.blockTimer();
    signal RadioReceiveCoordinator.blockTimer();

    //waited++;

    if (f.invert)
      data = ~data;

    switch (radioState)
      {
      default: break;
      case IDLE_STATE: idleData(data); break;
      case SYNC_STATE: syncData(data); break;
      case RX_STATE: rxData(data); break;
      case SENDING_ACK: ackData(data); break;
      case PRETX_STATE: preTxData(data); break;
      case TXPREAMBLE_STATE: txPreamble(); break;
      case TXSYNC_STATE: txSync(); break;
      case TXDATA_STATE: txData(); break;
      case TXCRC_STATE: txCrc(); break;
      case TXFLUSH_STATE: txFlush(); break;
      case TXWAITFORACK_STATE: txWaitForAck(); break;
      case TXREADACK_STATE: txReadAck(data); break;
      case TXDONE_STATE: txDone(); break;
      }
    
    return SUCCESS;
  }

  /* Noise floor stuff */
  /*-------------------*/

  void adjustSquelch(uint16_t data) {
    uint16_t squelchTab[CC1K_SquelchTableSize];
    uint8_t i, j, min; 
    uint32_t newThreshold;
    uint16_t min_value;

    squelchTable[squelchIndex++] = data;
    if (squelchIndex >= CC1K_SquelchTableSize)
      squelchIndex = 0;
    if (squelchCount <= CC1K_SquelchCount)
      squelchCount++;  

#if 0
    // Find 3rd highest (aka lowest signal strength) value
    memcpy(squelchTab, squelchTable, sizeof squelchTable);
    min = 0;
    for (j = 0; ; j++)
      {
	for (i = 1; i < CC1K_SquelchTableSize; i++)
	  if (squelchTab[i] > squelchTab[min])
	    min = i;
	if (j == 3)
	  break;
	squelchTab[min] = 0;
      }

    newThreshold = ((uint32_t)clearThreshold << 5) +
      ((uint32_t)squelchTab[min] << 1);
    atomic clearThreshold = newThreshold / 34;
#else
    for (i=0; i<CC1K_SquelchTableSize; i++) {
      squelchTab[(int)i] = squelchTable[(int)i];
    }

    min = 0;
//    for (j = 0; j < ((CC1K_SquelchTableSize) >> 1); j++) {
    for (j = 0; j < 3; j++) {
      for (i = 1; i < CC1K_SquelchTableSize; i++) {
        if ((squelchTab[(int)i] != 0xFFFF) && 
           ((squelchTab[(int)i] > squelchTab[(int)min]) ||
             (squelchTab[(int)min] == 0xFFFF))) {
          min = i;
        }
      }
      min_value = squelchTab[(int)min];
      squelchTab[(int)min] = 0xFFFF;
    }

    newThreshold = ((uint32_t)(clearThreshold << 5) + (uint32_t)(min_value << 1));
    atomic clearThreshold = (uint16_t)((newThreshold / 34) & 0x0FFFF);
#endif
  }

  task void adjustSquelchTask() {
    uint16_t squelchData;

    atomic squelchData = rssiForSquelch;
    adjustSquelch(squelchData);
  }

  void noiseFloor(uint16_t data) {
    rssiForSquelch = data;
    post adjustSquelchTask();
  }

#ifndef UNREACHABLE
  task void timeoutTask() {
    call WakeupTimer.stop();
    call WakeupTimer.start(TIMER_ONE_SHOT, 5);
  }
#endif

  void checkChannel(uint16_t data) {
    count++;
    if (data > clearThreshold + CC1K_SquelchBuffer)
      clearCount++;
    else
      clearCount = 0;

    // if the channel is clear or CCA is disabled, GO GO GO!
    if (clearCount >= 1 || f.ccaOff)
      { 
#if 0
	if (txBufPtr->type == 0x2c)
	  *((uint16_t *)txBufPtr->data) = waited;
	call Leds.redOff();
	fun[pos].radioState = 0xfe;
	//fun[pos].rssi = clearThreshold;
#endif
	enterTxPreambleState();
	call SpiByteFifo.writeByte(0xaa);
	call CC1000Control.TxMode();
	call SpiByteFifo.txMode();
      }
    else if (count == CC1K_MaxRSSISamples)
      {
	macDelay = signal MacBackoff.congestionBackoff(txBufPtr);
	enterIdleState();
#ifndef UNREACHABLE
	if (lplRxPower > 0)
	  post timeoutTask();
#endif
      }
    else 
      requestRssi(RSSI_CHECK_CHANNEL);
  }

  void startSquelchTimer() {
    if (squelchCount > CC1K_SquelchCount)
      call SquelchTimer.start(TIMER_REPEAT, CC1K_SquelchIntervalSlow);
    else
      call SquelchTimer.start(TIMER_REPEAT, CC1K_SquelchIntervalFast);
  }

  event result_t SquelchTimer.fired() {
    atomic
      if (radioState == IDLE_STATE)
	requestRssi(RSSI_NOISE_FLOOR);
    return SUCCESS;
  }

  /* Options */
  /*---------*/

  async command result_t MacControl.enableAck() {
    atomic f.ack = TRUE;
    return SUCCESS;
  }

  async command result_t MacControl.disableAck() {
    atomic f.ack = FALSE;
    return SUCCESS;
  }

  async command result_t MacControl.enableCCA() {
    atomic f.ccaOff = FALSE;
    return SUCCESS;
  }

  async command result_t MacControl.disableCCA() {
    atomic f.ccaOff = TRUE;
    return SUCCESS;
  }

  task void adjustLpl() {
    call StdControl.stop();

    atomic 
      {
	if (lplRxPower == lplTxPower)
	  lplTxPower = newPower;
	lplRxPower = newPower;
      }

    call StdControl.start();
    call PowerManagement.adjustPower();
  }

  async command result_t LowPowerListening.SetListeningMode(uint8_t power) {
    if (power >= CC1K_LPL_STATES)
      return FAIL;

    atomic
      {
	newPower = power;
	if (!post adjustLpl())
	  return FAIL;
      }
    return SUCCESS;
  }

  async command uint8_t LowPowerListening.GetListeningMode() {
    atomic return lplRxPower;
  }

  async command result_t LowPowerListening.SetTransmitMode(uint8_t power) {
    if (power >= CC1K_LPL_STATES)
      return FAIL;

    atomic
      {
	lplTxPower = power;
	setPreambleLength();
      }
    return SUCCESS;
  }

  async command uint8_t LowPowerListening.GetTransmitMode() {
    atomic return lplTxPower;
  }

  async command result_t LowPowerListening.SetPreambleLength(uint16_t bytes) {
    atomic
      preambleLength = bytes;
    return SUCCESS;
  }

  async command uint16_t LowPowerListening.GetPreambleLength() {
    atomic return preambleLength;
  }

  async command result_t LowPowerListening.SetCheckInterval(uint16_t ms) {
    atomic sleepTime = ms;
    return SUCCESS;
  }

  async command uint16_t LowPowerListening.GetCheckInterval() {
    atomic return sleepTime;
  }


  // Default MAC backoff parameters
  default async event int16_t MacBackoff.initialBackoff(TOS_MsgPtr m) { 
    // initially back off [1,32] bytes (approx 2/3 packet)
    return (call Random.rand() & 0x1F) + 1;
  }

  default async event int16_t MacBackoff.congestionBackoff(TOS_MsgPtr m) { 
    return (call Random.rand() & 0xF) + 1;
    //return (((call Random.rand() & 0x3)) + 1) << 10;
  }

  // Default events for radio send/receive coordinators do nothing.
  // Be very careful using these, or you'll break the stack.
  default async event void
  RadioSendCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset,
				   TOS_MsgPtr msgBuff) { }
  default async event void RadioSendCoordinator.byte(TOS_MsgPtr msg,
						     uint8_t byteCount) { }
  default async event void RadioSendCoordinator.blockTimer() { }

  default async event void
  RadioReceiveCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset,
				      TOS_MsgPtr msgBuff) { }
  default async event void RadioReceiveCoordinator.byte(TOS_MsgPtr msg,
							uint8_t byteCount) { }
  default async event void RadioReceiveCoordinator.blockTimer() { }

}
