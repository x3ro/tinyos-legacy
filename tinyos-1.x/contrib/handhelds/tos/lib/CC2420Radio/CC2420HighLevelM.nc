/**
 * Copyright (c) 2004,2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 * General purpose CC2420 routines for sending and receiving messages
 *
 * A couple of assumptions are important:
 *
 *   1.  The SPI bus is in use when the radio is turned on.  If you wish
 *       to use the SPI bus for some other purpose, turn the radio off
 *       first.
 * 
 *   2.  TimerJiffyAsync uses the 32 kHz crystal to drive comparators
 *       on TimerB.  A 'jiffy' is 30.5 microseconds.   We use one of 
 *       those comparators to generate backoff interrupts.  The 802.15.4 
 *       specification defines aUnitBackoffPeriod = 20 symbols where
 *       each symbol is 16 microseconds (for 2.4 GHz operation).  Hence
 *       one backoff period is 10.5 'jiffies'
 *
 *       However!!!   Sometimes we want to set very short timer intervals (on the
 *       order of 1 jiffy.  But TimerJiffyAsync.setOneShot doesn't allow
 *       intervals under 2 jiffies.  Be warned!
 *
 *   3.  We are currently assuming non-beacon operation.  All packet
 *       transmission is done using non-slotted CSMA-CA.
 *
 *   4.  We take advantage of the TI MSP processor being little-endian 
 *       when we write our PanID and Short address.   This should be
 *       fixed for the general case.
 * 
 *  This code is derived from the CC2420RadioM by Joe Polastre and Alan Broad,
 *  and hence should have their copyrights copied here.
 * 
 *  Andrew Christian <andrew.christian@hp.com>
 *
 *  First written:           December 2004
 *  Substantially upgraded:  May 2005
 */

#include "IEEE802154.h"

includes byteorder;
includes Message;
includes CC2420Control;
includes CC2420Rx;
includes ParamView;
includes CC2420Const;
includes InfoMem;
includes IEEEUtility;

module CC2420HighLevelM {
  provides { 
    interface StdControl;
    interface Message2;
    interface CC2420Control;
    interface ParamView;
  }

  uses {
    /* CC2420LowLevel */
    interface StdControl as CC2420LowLevelControl;
    interface CC2420LowLevel;
    interface CC2420Rx;
    /* TimerJiffyAsync */
    interface TimerJiffyAsync;
    interface StdControl as TimerJiffyAsyncControl;
    /* Other */
    interface Leds;
    interface MessagePool;
    interface Random;
#ifdef ID_CHIP
    interface IDChip;
#endif
  }
}
implementation
{
  extern int snprintf(char *str, size_t len, const char *format, ...) __attribute__ ((C));

#ifndef CC2420_DEF_CHANNEL
#define CC2420_DEF_CHANNEL	11  //channel select
#endif

#define INIT_MDMCTRL0 ((2 << CC2420_MDMCTRL0_CCAHIST) | (3 << CC2420_MDMCTRL0_CCAMODE) | \
                       (1 << CC2420_MDMCTRL0_AUTOCRC) | (2 << CC2420_MDMCTRL0_PREAMBL))

#define INIT_MDMCTRL1 (20 << CC2420_MDMCTRL1_CORRTHRESH)
#define INIT_TXCTRL   ((1 << CC2420_TXCTRL_BUFCUR) | (1 << CC2420_TXCTRL_TURNARND) | (3 << CC2420_TXCTRL_PACUR) | \
				     (1 << CC2420_TXCTRL_PADIFF) | (0x1f << CC2420_TXCTRL_PAPWR))

#define INIT_SECCTRL0 ((1 << CC2420_SECCTRL0_CBCHEAD) | (1 << CC2420_SECCTRL0_SAKEYSEL)  | \
                       (1 << CC2420_SECCTRL0_TXKEYSEL) | (1 << CC2420_SECCTRL0_SECM))

#define INIT_IOCFG0   ((127 << CC2420_IOCFG0_FIFOTHR)) 
  // I can't think of any reason to use the reversed polarity on FIFOP

  enum {
    RADIO_STATE_VREG_OFF    = POWER_STATE_VREG_OFF, // Fully shut off
    RADIO_STATE_POWER_DOWN  = POWER_STATE_POWER_DOWN,
    RADIO_STATE_IDLE        = POWER_STATE_IDLE,
    RADIO_STATE_RX_MODE     = POWER_STATE_ACTIVE,   // Normal mode
    RADIO_STATE_RX_DISABLE,   // Waiting for the radio to switch to TX mode
    RADIO_STATE_TX_WAIT_IFS,  // Waiting for an IFS to pass before starting a message
    RADIO_STATE_TX_ACTIVE,    // Actively trying transmissions
    RADIO_STATE_TX_WAIT_ACK,  // Message sent; waiting for ACK
    RADIO_STATE_TX_WAIT_DISABLE,  // ACK failed, disabling radio for another try
    RADIO_STATE_TX_FINISH    
  };

  enum {
    RADIO_INIT_OK          = 0,
    RADIO_ERROR_OSCILLATOR,
    RADIO_ERROR_SET_REGS,
    RADIO_ERROR_SET_ADDRESS,
    RADIO_ERROR_TUNE_PRESET
  };

  enum {
    TX_ATTEMPTS_GOT_ACK  = 255
  };

  struct TxStats {
    uint32_t tx_total;     // Total packets successfully sent
    uint32_t tx_dropped;   // TX packets dropped (due to timeout)
    uint16_t tx_last_delay;
  };

  norace struct TxStats g_stats;
  struct Message       *g_TxQueue;

  norace uint8_t g_RadioState   = RADIO_STATE_VREG_OFF;
  uint8_t        g_DesiredState = POWER_STATE_VREG_OFF;

  norace uint8_t  g_NB;   // Used for transmission
  norace uint8_t  g_BE;
  norace uint8_t  g_TxAttempts;    // Used for ACK checking
  norace result_t g_TxResult;
  norace int      g_TxFlags;

  // These parameters are used to configure state on power up/down
  uint8_t  g_LongAddress[8];

  norace uint16_t g_MDMCTRL0     = INIT_MDMCTRL0; 
  norace uint16_t g_ShortAddress = 0xffff;
  norace uint16_t g_PanID        = 0xffff;
  norace uint8_t  g_Channel      = CC2420_DEF_CHANNEL;

  /************************************************************************
   * radioSetRegisters
   *  - Configure CC2420 registers with current values
   *  - Readback 1st register written to make sure electrical connection OK
   *************************************************************************/

  /*
   *  TASK context
   */

  bool radioSetAndVerify( uint8_t addr, uint16_t value )
  {
    uint16_t v;
    uint8_t count = 0;

    do {
      call CC2420LowLevel.write( addr, value );
      v = call CC2420LowLevel.read( addr );
    } while ( v != value && ++count < 4 );
    
    return v == value;
  }

  /*
   *  TASK context
   */

  bool radioSetAndVerifyMask( uint8_t addr, uint16_t value, uint16_t mask )
  {
    uint16_t v;
    uint8_t count = 0;

    do {
      call CC2420LowLevel.write( addr, value );
      v = call CC2420LowLevel.read( addr );
    } while ( (v & mask) != (value & mask) && ++count < 4 );
    
    return v == value;
  }

  /*
   *  TASK context
   */

  bool radioSetRegisters() {
    uint16_t io = INIT_IOCFG0;

    if ( !radioSetAndVerify( CC2420_MDMCTRL0,    g_MDMCTRL0 )
	 || !radioSetAndVerify( CC2420_MDMCTRL1, INIT_MDMCTRL1)  // Why do I set this one?  Looks like default
	 || !radioSetAndVerify( CC2420_TXCTRL,   INIT_TXCTRL)    // This one sets TX mixer buffer bias current
	 || !radioSetAndVerify( CC2420_SECCTRL0, INIT_SECCTRL0))
      return FALSE;

    if ( g_PanID == 0xffff )
      io |= (1 << CC2420_IOCFG0_BCN_ACCEPT);
    
    if ( !radioSetAndVerify( CC2420_IOCFG0, io ))
      return FALSE;

    call CC2420LowLevel.cmd(CC2420_SFLUSHTX);    //flush Tx fifo
    call CC2420LowLevel.cmd(CC2420_SFLUSHRX);
 
    return TRUE;
  }

  /*
   *  TASK context
   */

#define MASK_FSCTRL      0xcbff

  bool radioTunePreset() {
    bool     result;
    uint16_t fsctrl;
    
    call CC2420LowLevel.cmd(CC2420_SRFOFF);
    
    fsctrl = 357 + 5*(g_Channel-11) + 0x4000;
    result = radioSetAndVerifyMask( CC2420_FSCTRL, fsctrl, MASK_FSCTRL );
    call CC2420LowLevel.cmd(CC2420_SRXON);

    return result;
  }

  /*
   *  TASK context
   */

  result_t radioOscillatorOn() {
    uint16_t i;
    uint8_t status;
    bool bXoscOn = FALSE;

    i = 0;

    call CC2420LowLevel.cmd(CC2420_SXOSCON);   //turn-on crystal

    while ((i < CC2420_XOSC_TIMEOUT) && (bXoscOn == FALSE)) {
      status = call CC2420LowLevel.cmd(CC2420_SNOP);      //read status
      status = status & ( 1 << CC2420_XOSC16M_STABLE);
      if (status) bXoscOn = TRUE;
      i++;
    }

    if (!bXoscOn) return FAIL;
    return SUCCESS;
  }

  result_t radioOscillatorOff() {
    return call CC2420LowLevel.cmd(CC2420_SXOSCOFF);   //turn-off crystal
  }

  /**
   *  TASK context
   */

  result_t radioInitAddress() {
    return ((call CC2420LowLevel.writeRAM( CC2420_RAM_SHORTADR, 2, (uint8_t*)&g_ShortAddress)) &&
	    (call CC2420LowLevel.writeRAM( CC2420_RAM_PANID,    2, (uint8_t*)&g_PanID)) &&
	    (call CC2420LowLevel.writeRAM( CC2420_RAM_IEEEADR,  8, g_LongAddress)));
  }

  /**
   *  Bring the radio from full halt to powered up
   *
   *  TASK context
   */ 

  result_t radioStart() {
    // turn on crystal, takes about 860 usec, 
    // chk CC2420 status reg for stablize
    //set freq, load regs

    if (!radioOscillatorOn()) 
      return FAIL;

    if (!radioSetRegisters())
      return FAIL;
 
    if (!radioInitAddress()) 
      return FAIL;

    if (!radioTunePreset())
      return FAIL;

    return SUCCESS;
  }

  /**
   *  Inform CC2420Control that we have changed the power level
   */

  task void powerLevelChange()
  {
    enum POWER_STATE state = g_RadioState;

    if ( state > POWER_STATE_ACTIVE )
      state = POWER_STATE_ACTIVE;

    signal CC2420Control.power_state_change( state );
  }

  /**
   *  Raise the power level from the current level to the desired state.
   *
   *  TASK context, but only when g_RadioState < POWER_STATE_RX_MODE
   */

  bool raisePowerLevel()
  {
    // Use these on a TelosB for duty cycle measurement
    //    if ( g_DesiredState ) TOSH_SET_ADC0_PIN();
    //    else                  TOSH_CLR_ADC0_PIN();

    if ( g_RadioState == POWER_STATE_VREG_OFF && g_DesiredState > POWER_STATE_VREG_OFF ) {
      call CC2420LowLevelControl.start();
      //turn on power
      TOSH_SET_RADIO_VREF_PIN();                    //turn-on  
      TOSH_uwait(600);  // CC2420 spec: 600us max turn on time

      // toggle reset
      TOSH_CLR_RADIO_RESET_PIN();
      TOSH_wait();
      TOSH_SET_RADIO_RESET_PIN();
      TOSH_wait();

      g_RadioState = POWER_STATE_POWER_DOWN;
    }

    if ( g_RadioState == POWER_STATE_POWER_DOWN && g_DesiredState > POWER_STATE_POWER_DOWN ) {
      if ( radioStart() == SUCCESS )
	g_RadioState = POWER_STATE_IDLE;
    }

    if ( g_RadioState == POWER_STATE_IDLE && g_DesiredState > POWER_STATE_IDLE ) {
      g_RadioState = RADIO_STATE_RX_MODE;
      call CC2420LowLevel.cmd(CC2420_SRXON);
      call CC2420Rx.enable();
    }

    post powerLevelChange();
    return (g_RadioState == g_DesiredState);
  }

  /**
   *  Set g_DesiredState before calling this routine.
   *  It lowers the power level until it hits desired state
   *
   *  TASK context, but only called when RX has been disabled
   */

  void lowerPowerLevel() 
  {
    if ( g_RadioState >= POWER_STATE_ACTIVE && g_DesiredState < POWER_STATE_ACTIVE ) {
      call CC2420LowLevel.cmd( CC2420_SRFOFF );  // Go to IDLE state
      g_RadioState = POWER_STATE_IDLE;
    }

    if ( g_RadioState == POWER_STATE_IDLE && g_DesiredState < POWER_STATE_IDLE ) {
      call CC2420LowLevel.cmd( CC2420_SXOSCOFF );
      g_RadioState = POWER_STATE_POWER_DOWN;
    }

    if ( g_RadioState == POWER_STATE_POWER_DOWN && g_DesiredState < POWER_STATE_POWER_DOWN ) {
      TOSH_CLR_RADIO_RESET_PIN();
      TOSH_CLR_RADIO_VREF_PIN();                    //turn-off  
      TOSH_SET_RADIO_RESET_PIN();
      call CC2420LowLevelControl.stop();
      g_RadioState = POWER_STATE_VREG_OFF;
    }

    // Use these on a TelosB for duty cycle measurement
    // if ( g_RadioState )   TOSH_SET_ADC0_PIN();
    // else                  TOSH_CLR_ADC0_PIN();

    post powerLevelChange();
  }

  /**********************************************************
   * StdControl interface functions
   **********************************************************/

  command result_t StdControl.init() {
    memcpy( g_LongAddress, infomem->mac, 8 );
#ifdef ID_CHIP
    call IDChip.read( g_LongAddress + 2 );  // Fill in the last 6 bytes
#endif

    call MessagePool.init();
    call Random.init();
    call TimerJiffyAsyncControl.init();
    call CC2420LowLevelControl.init();

    return SUCCESS;
  }
  
  command result_t StdControl.stop() {  // Notice that this doesn't terminate immediately
    call TimerJiffyAsyncControl.stop();
    call CC2420Control.set_power_state( POWER_STATE_VREG_OFF );
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call TimerJiffyAsyncControl.start();
    call CC2420Control.set_power_state( POWER_STATE_ACTIVE );
    
    return SUCCESS;
  }
  
  /********************************************
   *  Message interface - send message using
   *  CSMA-CA and backoffs.  This is inappropriate
   *  for Beacon frames, ACK frames and the CFP.
   *
   *  Rules:  First, we must wait at least LIFS/SIFS
   *    from the last frame.  Then we must run the
   *    CSMA-CA algorithm (pg. 144 of the spec)
   *
   *  A question.....the Chipcon radio takes 8 to 12 symbols
   *    to begin transmitting.  Can this be counted as part 
   *    of the LIFS/SIFS backoff?  If so, then SIFS is
   *    pretty meaningless.
   ********************************************/
  
  // Current defines which could be user settable
#define IEEE802154_macMinBE                     3     // Range 0-3 
#define IEEE802154_macMaxCSMABackoffs           4     // Range 0-5 
  /*
   * the IEEE 802.15.4a-2007 spec amendment offers this formula for 250k
   * phy layers (section 7.4.2, equation 14d):
   * macAckWaitDuration250k = aUnitBackoffPeriod + aTurnaroundTime +
   *                          phySHRDuration250k + 3 × ceiling(1/3 × [1.5 + 5]) × phySymbolsPerOctet250k
   * if we plug in the numbers -- a cc2420 sync header has 10 symbols -- we now have 55 symbols (up one!).
   */
#define IEEE802154_macAckWaitDuration           55    

  bool ack_is_required( struct Message *msg )
  {
    return ( msg &&
	     (msg_get_length(msg) >= 7) &&    // FCF (2 bytes), DSN (1 byte), Dest Addr (4 bytes)
	     (msg_get_uint8(msg,0) & ACK_REQUEST));
  }

  bool is_valid_ack( struct Message *msg, struct Message *reply )
  {
    uint8_t dsn = msg_get_uint8(msg,2);

    return ( (msg_get_length(reply) == 5) &&
	     ((msg_get_uint8(reply,0) & FRAME_TYPE_MASK) == FRAME_TYPE_ACK) &&
	     (msg_get_uint8(reply,1) == 0) &&
	     (msg_get_uint8(reply,2) == dsn));
  }

  /**
   *  Signal the completion of a packet transmission.
   */

  task void sendStart();

  task void handleTxComplete() {
    struct Message *msg = pop_queue( &g_TxQueue );

    signal Message2.sendDone( msg, g_TxResult, g_TxFlags );

    if ( g_TxResult == FAIL )
      g_stats.tx_dropped++;

    if ( g_TxQueue ) {
      if ( call CC2420Rx.isEnabled()) {
	g_RadioState = RADIO_STATE_RX_DISABLE;
	call CC2420Rx.disable();
      }
      else
	post sendStart();
    }
    else if ( g_DesiredState < POWER_STATE_ACTIVE ) {
      if ( call CC2420Rx.isEnabled()) {
	g_RadioState = RADIO_STATE_RX_DISABLE;
	call CC2420Rx.disable();
      }
      else
	lowerPowerLevel();
    }
    else {
      g_RadioState = RADIO_STATE_RX_MODE;
      if ( !call CC2420Rx.isEnabled() )
	call CC2420Rx.enable();
    }
  }

  /* 
   * Conversion to jiffies
   * The actual value is 32768 / 62500
   * We use an approximation that fits in 16 bit arithmatic.
   * Note that we NEVER return a number <= 0
   */

  inline uint16_t symbols_to_jiffies( uint16_t symbols )
  {
    return ((symbols * 67) >> 7) + 1;
  }

  /*
   * IEEE 802.15.4 backoff algorithm
   */

  uint16_t calculateBackoff() {
    uint16_t delay;

    delay = ((call Random.rand()) & ((1 << g_BE) - 1)) * IEEE802154_aUnitBackoffPeriod;  // Symbols
    return symbols_to_jiffies( delay );
  }

  /*
   *  Attempt to send the queued message using CC2420_STXONCCA.
   *  
   *  _IF_ the message goes out, we need to calculate how long it takes for the entire
   *  message to get out of the door, plus time for the ACK.   What would make life 
   *  convenient is if we could get an interrupt on SFD when it goes from high to low (thus
   *  marking the end of the transmitted frame.  We'll settle for estimating.
   *
   *  INTERRUPT context (by the TimerJiffyAsync routine)
   */

#define CHIPCON_TX_CALIBRATE_DELAY 12   // Twelve symbols to calibrate transmitter 
#define CHIPCON_TX_PREAMBLE        10   // Ten symbols in the preamble 
#define SYMBOLS_PER_BYTE            2   // Two symbols per byte transmitted
#define PLATFORM_LATENCY_VARIATION_HACK 25   // see comment below

  void sendMessage() {
    uint8_t status;
    uint16_t delay;

    call CC2420LowLevel.cmd( CC2420_STXONCCA );
    status = call CC2420LowLevel.cmd( CC2420_SNOP );

    if (status & (1<< CC2420_TX_ACTIVE)) {
      delay = symbols_to_jiffies( CHIPCON_TX_CALIBRATE_DELAY + CHIPCON_TX_PREAMBLE
				  + SYMBOLS_PER_BYTE * (msg_get_length(g_TxQueue) + 1));

      if ( ack_is_required(g_TxQueue) ) {
	delay += symbols_to_jiffies( IEEE802154_macAckWaitDuration );
	g_RadioState = RADIO_STATE_TX_WAIT_ACK;

	/*
	 * with a small msg size of (~11 bytes), we should have about 73 jiffies here.
	 * on some platforms, this will cause the radio to timeout awaiting an ack, and be in WAIT_DISABLE 
	 * when an arp request arrives; this breaks an initial association!
	 * scoping the lag between the jiffy timeout and the arrival of the arp request, 
	 * we found it in the 650-900 uS range, or between 22 and 30 jiffies, platform-dependent
	 * all platforms tested comfortably at 25; we add it here
	 */
	call TimerJiffyAsync.setOneShot(delay + PLATFORM_LATENCY_VARIATION_HACK);
	call CC2420Rx.enable();
      }
      else {
	g_RadioState = RADIO_STATE_TX_FINISH;
	g_TxResult = SUCCESS;
	g_TxFlags  = 0;
	post handleTxComplete();
      }
    }
    else {
      // The frame didn't go out.  Try again after a backoff 
      if ( ++g_NB <= IEEE802154_macMaxCSMABackoffs ) {  // Can we try again?
	if ( ++g_BE > IEEE802154_aMaxBE )
	  g_BE = IEEE802154_aMaxBE;

	delay = calculateBackoff();
	g_stats.tx_last_delay += delay;

	call TimerJiffyAsync.setOneShot( delay );
      }
      else {	// Failure! We couldn't send the message out.
	g_RadioState = RADIO_STATE_TX_FINISH;
	g_TxResult = FAIL;
	g_TxFlags  = MESSAGE2_CHANNEL_BUSY;
	post handleTxComplete();
      }
    }
  }

  /**
   *  Initialize clear-channel assessment backoff calculations.
   *
   *  TASK context
   */

  void sendStartBackoffs() {
    uint16_t delay;

    g_RadioState = RADIO_STATE_TX_ACTIVE;
    g_NB = 0;
    g_BE = 3;   // macMinBE
    g_TxAttempts++;
    
    delay = calculateBackoff();
    g_stats.tx_last_delay = delay;

    call TimerJiffyAsync.setOneShot( delay );
  }

  /**
   *  Load the queue with a message and try to send it.
   *  It's very important that this task only run when the RX mode of the
   *  radio is disabled (FIFO, FIFOP disabled, no 'readMessageBody()' task
   *  pending.
   */

  task void sendStart() {
    call CC2420LowLevel.cmd( CC2420_SFLUSHTX );    //flush Tx fifo
    call CC2420LowLevel.writeTXFIFO( g_TxQueue );  // Write the message on the queue top
    g_TxAttempts = 0;                              // How many times we've tried to send this message
    sendStartBackoffs();
  }

  /**
   *  TimerJiffyAsync is used for IFS calculation in receive mode and
   *  backoff calculations in transmit mode.
   *
   *  INTERRUPT context
   */

  async event result_t TimerJiffyAsync.fired() {
    switch (g_RadioState) {
    case RADIO_STATE_TX_WAIT_IFS:  // Waiting for an IFS frame
      post sendStart();
      break;

    case RADIO_STATE_TX_ACTIVE:
      sendMessage();
      break;

    case RADIO_STATE_TX_WAIT_ACK:

      // A successful ACK sets g_TxAttempts to TX_ATTEMPTS_GOT_ACK
      if ( g_TxAttempts <= IEEE802154_aMaxFrameRetries ) {
	g_RadioState = RADIO_STATE_TX_WAIT_DISABLE;
	call CC2420Rx.disable();
      }
      else {
	if ( g_TxAttempts == TX_ATTEMPTS_GOT_ACK ) {
	  g_TxResult = SUCCESS;
	}
	else {
	  g_TxResult = FAIL;
	  g_TxFlags = 0;
	}
	g_RadioState = RADIO_STATE_TX_FINISH;
	post handleTxComplete();
      }
      break;

    default:
      // Do nothing 
      break;
    }
    
    return SUCCESS;      // Meaningless
  }

  /**
   * Add a message to the send queue.  If we are in RX mode,
   * post the 'sendStart' task (unless we are waiting on IFS)
   *
   * TASK context
   */

  command result_t Message2.send( struct Message *msg ) {
    if ( g_RadioState < POWER_STATE_ACTIVE )
      return FAIL;

    append_queue( &g_TxQueue, msg );
    g_stats.tx_total++;
    
    if ( g_RadioState == RADIO_STATE_RX_MODE ) {
      g_RadioState = RADIO_STATE_RX_DISABLE;
      call CC2420Rx.disable();
    }

    return SUCCESS;
  }


  /*****************************************************************
   * Interface to CC2420Rx
   *****************************************************************/

  /* 
   * Fires when RX_MODE has been disabled.  Note that an IFS timer can still fire during this event.
   *
   * TASK context 
   */

  event void CC2420Rx.disableDone()
  {
    switch (g_RadioState) {
    case RADIO_STATE_RX_DISABLE:
      if ( g_TxQueue ) {
	atomic {  // Must be atomic because IFS could fire in the midst of these lines
	  g_RadioState = RADIO_STATE_TX_WAIT_IFS;
	  if (!call TimerJiffyAsync.isSet())
	    post sendStart();
	}
      }
      else if ( g_DesiredState < POWER_STATE_ACTIVE )
	lowerPowerLevel();
      break;
	  
    case RADIO_STATE_TX_WAIT_DISABLE:
      sendStartBackoffs(); 
      break;
    }
  }

  /* INTERRUPT context */
  async event void CC2420Rx.setIFSTimer( uint16_t symbols )
  {
    if ( g_RadioState == RADIO_STATE_RX_MODE )   // Set the Intra-frame backoff timer
      call TimerJiffyAsync.setOneShot( symbols_to_jiffies(symbols) );
  }

  /* INTERRUPT context */
  //async event void CC2420Rx.receiveAck( uint8_t dsn, bool frame_pending )
  //BRC: Aug 2 2005, pass up RSSI value
  async event void CC2420Rx.receiveAck( uint8_t dsn, bool frame_pending, int rssi, uint8_t lqi)
  { 
    if ( g_RadioState == RADIO_STATE_TX_WAIT_ACK &&
	 dsn == msg_get_uint8(g_TxQueue,2) ) {            // DSN must match
      g_TxAttempts = TX_ATTEMPTS_GOT_ACK;
      g_TxFlags    = MESSAGE2_ACK;
      if ( frame_pending )
	g_TxFlags |= MESSAGE2_DATA_PENDING;
      //pass up RSSI value in upper byte of g_TxFlags
      //LQI value is dropped for now
      g_TxFlags |= rssi << 8;
    }
  }

  /* INTERRUPT context */
  async event int CC2420Rx.generateAck( uint8_t src_mode, uint8_t* pan_id, uint8_t *src_addr )
  {
    if ( g_RadioState == RADIO_STATE_RX_MODE ) 
      return (signal CC2420Control.is_data_pending(src_mode, pan_id, src_addr) ? ACK_DATA : ACK_NO_DATA);
    return 0;
  }

  /* TASK context */
  event void CC2420Rx.receive( struct Message *msg )
  {
    if ( g_RadioState == RADIO_STATE_RX_MODE )
      signal Message2.receive(msg);
    else // We discard all messages received in transmission mode, as per 802.15.4 spec.
      call MessagePool.free(msg);
  }

  // Access some useful globals
  async event uint16_t  CC2420Rx.panID()     { return g_PanID; }
  async event uint16_t  CC2420Rx.shortAddr() { return g_ShortAddress; }
  async event uint8_t  *CC2420Rx.longAddr()  { return g_LongAddress; }
  async event bool      CC2420Rx.panCoord()  { return (g_MDMCTRL0 & (1 << CC2420_MDMCTRL0_PANCRD)) != 0; }
  
  /********************************************
   *  CC2420Control
   ********************************************/
  
  command uint16_t CC2420Control.get_frequency()
  {
    uint16_t fsctrl;

    atomic {
      fsctrl  = ((call CC2420LowLevel.read( CC2420_FSCTRL )) & 0x03ff) + 2048;
    }
    return fsctrl;
  }

  command void CC2420Control.set_channel( uint8_t channel )
  {
    g_Channel = channel;
    atomic {
      if (!radioTunePreset())
	;
    }
  }

  command uint16_t CC2420Control.get_state()
  {
    uint16_t result;

    result = call CC2420LowLevel.cmd(CC2420_SNOP);      //read status

    if ( !TOSH_READ_RADIO_FIFOP_PIN())
      result |= 0x8000;

    if ( TOSH_READ_RADIO_FIFO_PIN())
      result |= 0x4000;

    return result;
  }

  command enum POWER_STATE CC2420Control.get_power_state()   { return g_DesiredState;  }
  command enum POWER_STATE CC2420Control.get_actual_state()  { return g_RadioState; }

  /*
   *  Runs in TASK context.  
   *
   *  Note that g_RadioState can only be set to WAIT_ACK, TX_ACTIVE, and TX_FINISH
   *  in interrupt context, so checking levels is safe.
   */

  command void CC2420Control.set_power_state( enum POWER_STATE state )
  {
    g_DesiredState = state;

    if ( g_RadioState >= POWER_STATE_ACTIVE ) {  // We are currently powered up
      if ( g_RadioState == RADIO_STATE_RX_MODE && g_DesiredState < POWER_STATE_ACTIVE ) {
	g_RadioState = RADIO_STATE_RX_DISABLE;
	call CC2420Rx.disable();
      }
    }
    else {
      if ( g_RadioState < g_DesiredState )
	raisePowerLevel();
      else if ( g_RadioState > g_DesiredState ) {
	lowerPowerLevel();
      }
    }
  }

  command result_t CC2420Control.set_short_address( uint16_t addr )
  {
    g_ShortAddress = addr;
    if ( g_RadioState > RADIO_STATE_POWER_DOWN ) {
      call CC2420LowLevel.cmd(CC2420_SRFOFF);  // Does this flush the QUEUE?

      radioSetRegisters();
      radioInitAddress();

      call CC2420LowLevel.cmd(CC2420_SRXON);
    }

    return SUCCESS;
  }

  command result_t CC2420Control.set_pan_id( uint16_t panid )
  {
    uint16_t io = INIT_IOCFG0;

    g_PanID = panid;

    if ( g_RadioState > RADIO_STATE_POWER_DOWN ) {
      if ( g_PanID == 0xffff )
	io |= (1 << CC2420_IOCFG0_BCN_ACCEPT);

      call CC2420LowLevel.cmd(CC2420_SRFOFF);

      radioSetRegisters();
      radioInitAddress();

      call CC2420LowLevel.cmd(CC2420_SRXON);
    }

    return SUCCESS;
  }

  command result_t CC2420Control.set_pan_coord( bool isSet )
  {
    if (isSet)
      g_MDMCTRL0 |= (1 << CC2420_MDMCTRL0_PANCRD);
    else
      g_MDMCTRL0 &= ~(1 << CC2420_MDMCTRL0_PANCRD);

    if ( g_RadioState > RADIO_STATE_VREG_OFF )
      call CC2420LowLevel.write( CC2420_MDMCTRL0, g_MDMCTRL0 );

    return SUCCESS;
  }

  command uint16_t CC2420Control.get_short_address()                                  { return g_ShortAddress; }
  command uint16_t CC2420Control.get_pan_id()                                         { return g_PanID; }
  command void     CC2420Control.get_long_address( uint8_t *buf )                     { memcpy( buf, g_LongAddress, 8 ); }
  command void     CC2420Control.append_pan_id( struct Message *msg )                 { msg_append_saddr( msg, g_PanID ); }
  command void     CC2420Control.append_saddr( struct Message *msg )                  { msg_append_saddr( msg, g_ShortAddress ); }
  command void     CC2420Control.append_laddr( struct Message *msg )                  { msg_append_buf( msg, g_LongAddress, 8 ); }
  command void     CC2420Control.insert_pan_id( struct Message *msg, uint8_t offset ) { msg_set_saddr( msg, offset, g_PanID ); }
  command void     CC2420Control.insert_saddr( struct Message *msg, uint8_t offset )  { msg_set_saddr( msg, offset, g_ShortAddress ); }
  command void     CC2420Control.insert_laddr( struct Message *msg, uint8_t offset )  { msg_set_buf( msg, offset, g_LongAddress, 8 ); }

  default async event bool CC2420Control.is_data_pending( uint8_t src_mode, uint8_t *pan_id, uint8_t *src_addr )
  {
    return FALSE;
  }

  /*****************************************************************/

  const struct Param s_Radio[] = {
    { "tx_total",         PARAM_TYPE_UINT32, &g_stats.tx_total },
    { "tx_dropped",       PARAM_TYPE_UINT32, &g_stats.tx_dropped },
    { "tx_last_delay",    PARAM_TYPE_UINT16, &g_stats.tx_last_delay },
    { NULL, 0, NULL }
  };

  struct ParamList g_RXList  = { "radiotx",  &s_Radio[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_RXList );
    return SUCCESS;
  }

  /*****************************************
   *  Telnet
   *****************************************/

  command char * CC2420Control.telnet( char *in, char *out, char *outmax )
  {
    out += snprintf(out, outmax - out, "Pan ID: 0x%04x\r\n", g_PanID );
    out += snprintf(out, outmax - out, "S_Addr: 0x%04x\r\n", g_ShortAddress );
    out += snprintf(out, outmax - out, "L_Addr: %02x:%02x:%02x:%02x:%02x:%02x:%02x:%02x\r\n",
		    g_LongAddress[0], g_LongAddress[1], g_LongAddress[2], g_LongAddress[3], 
		    g_LongAddress[4], g_LongAddress[5], g_LongAddress[6], g_LongAddress[7] );
    
    return out;
  }
}


