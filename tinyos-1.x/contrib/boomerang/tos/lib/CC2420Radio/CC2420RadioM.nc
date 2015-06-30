// $Id: CC2420RadioM.nc,v 1.1.1.1 2007/11/05 19:11:24 jpolastre Exp $
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
 *
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * This module provides the layer2 functionality for the CC2420 transceiver.
 *
 * @author Joe Polastre
 * @author Alan Broad, Crossbow
 */

#include "byteorder.h"
#include "circularQueue.h"

module CC2420RadioM {
  provides {
    interface StdControl;
    interface SplitControl;
    interface CC2420BareSendMsg as Send;
    interface ReceiveMsg as Receive;
    interface RadioCoordinator as RadioSendCoordinator;
    interface RadioCoordinator as RadioReceiveCoordinator;
    interface MacControl;
    interface MacBackoff;

    interface Counter<T32khz,uint32_t> as RadioActiveTime;
  }
  uses {
    interface SplitControl as CC2420SplitControl;
    interface CC2420Control;
    interface HPLCC2420 as HPLChipcon;
    interface HPLCC2420FIFO as HPLChipconFIFO; 
    interface HPLCC2420Interrupt as FIFOP;
    interface HPLCC2420Capture as SFD;
    interface StdControl as TimerControl;
    interface Alarm<T32khz,uint16_t> as BackoffAlarm32khz;
    interface Counter<T32khz,uint32_t> as Counter32khz;
    interface Counter<T32khz,uint16_t> as Counter32khz16;
    interface Random;

    interface ResourceCmdAsync as CmdFlushRXFIFO;
    interface ResourceCmd as CmdReceive;
    interface ResourceCmd as CmdTransmit;
    interface ResourceCmd as CmdTryToSend;
  }
}

implementation {
  enum {
    DISABLED_STATE = 0,
    DISABLED_STATE_STARTTASK,
    IDLE_STATE,
    TX_STATE,
    TX_WAIT,
    PRE_TX_STATE,
    POST_TX_STATE,
    POST_TX_ACK_STATE,
    WARMUP_STATE,

    TIMER_INITIAL = 0,
    TIMER_BACKOFF,
    TIMER_ACK,
    TIMER_SFD,
  };

#define MAX_SEND_TRIES 8

  enum { NUM_TIMESTAMPS = 10 };

  norace uint8_t countRetry;
  uint8_t stateRadio;
  norace uint8_t stateTimer;
  norace uint8_t currentDSN;
  bool bPacketReceiving;
  uint8_t txlength;
  norace TOS_MsgPtr txbufptr;  // pointer to transmit buffer
  norace TOS_MsgPtr rxbufptr;  // pointer to receive buffer
  TOS_Msg RxBuf;	       // save received messages
  uint8_t rh_transmit;
  uint8_t rh_receive;
  bool m_sfdReceiving;
  uint8_t m_rxFifoCount;
  norace bool bShutdownRequest;

  uint32_t m_timestamps[NUM_TIMESTAMPS];
  CircularQueue_t m_timestampQueue;

  volatile uint16_t LocalAddr;

  uint32_t cc2420_laston;
  uint32_t cc2420_waketime;

  
  async command uint32_t RadioActiveTime.get() {
    return cc2420_waketime;
  }

  async command bool RadioActiveTime.isOverflowPending() {
    return FALSE;
  }

  async command void RadioActiveTime.clearOverflow() {
  }

  default async event void RadioActiveTime.overflow() {
  }

  ///**********************************************************
  //* local function definitions
  //**********************************************************/

   void sendFailedSync() {
     cc2420_error_t _error = CC2420_E_UNKNOWN;
     atomic stateRadio = IDLE_STATE;
     txbufptr->length = txbufptr->length - MSG_HEADER_SIZE - MSG_FOOTER_SIZE;
     if (bShutdownRequest)
       _error = CC2420_E_SHUTDOWN;
     signal Send.sendDone(txbufptr, _error);
   }

#ifdef TOS2_TASKS
   task void sendFailedTask() {
     sendFailedSync();
   }

   void sendFailedAsync() {
     post sendFailedTask();
   }
#else
   void sendFailedAsync() {
     sendFailedSync();
   }
#endif

   async event void CmdFlushRXFIFO.granted( uint8_t rh ) {
     // 28 Nov 2005 CSS: make the complete internal/external flush operation
     // atomic to prevent any chance of mismatched and/or corrupted state.
     atomic {
       call FIFOP.disable();
       call HPLChipcon.read(rh, CC2420_RXFIFO); //flush Rx fifo
       call HPLChipcon.cmd(rh, CC2420_SFLUSHRX);
       call HPLChipcon.cmd(rh, CC2420_SFLUSHRX);
       bPacketReceiving = FALSE;
       m_rxFifoCount = 0;
       cqueue_init( &m_timestampQueue, NUM_TIMESTAMPS );
       if( m_sfdReceiving ) {
         m_sfdReceiving = FALSE;
         call SFD.enableCapture(TRUE);
       }
       call FIFOP.startWait(FALSE);
     }
     call CmdFlushRXFIFO.release();
   }

   void flushRXFIFO( uint8_t rh ) {
     call CmdFlushRXFIFO.urgentRequest( rh );
   }

   inline result_t setInitialTimer( uint16_t jiffy ) {
     stateTimer = TIMER_INITIAL;
     call BackoffAlarm32khz.start( jiffy );
     return SUCCESS;
   }

   inline result_t setBackoffTimer( uint16_t jiffy ) {
     stateTimer = TIMER_BACKOFF;
     call BackoffAlarm32khz.start(jiffy);
     return SUCCESS;
   }

   inline result_t setAckTimer( uint16_t jiffy ) {
     stateTimer = TIMER_ACK;
     call BackoffAlarm32khz.start(jiffy);
     return SUCCESS;
   }

   inline result_t setSFDTimeoutTimer( uint16_t jiffy ) {
     stateTimer = TIMER_SFD;
     call BackoffAlarm32khz.start(jiffy);
     return SUCCESS;
   }

  /***************************************************************************
   * PacketRcvd
   * - Radio packet rcvd, signal 
   ***************************************************************************/
   task void PacketRcvd() {
     TOS_MsgPtr pBuf;

     atomic {
       pBuf = rxbufptr;
     }
     if (rxbufptr->crc)
       pBuf = signal Receive.receive((TOS_MsgPtr)pBuf);
     atomic {
       if (pBuf) rxbufptr = pBuf;
       rxbufptr->length = 0;
       bPacketReceiving = FALSE;
       if( (m_rxFifoCount > 0) && (--m_rxFifoCount > 0) )
         call CmdReceive.deferRequest();
     }
   }

  
  task void PacketSent() {
    TOS_MsgPtr pBuf; //store buf on stack 

    atomic {
      stateRadio = IDLE_STATE;
      pBuf = txbufptr;
      pBuf->length = pBuf->length - MSG_HEADER_SIZE - MSG_FOOTER_SIZE;
    }

    signal Send.sendDone(pBuf,CC2420_SUCCESS);
  }

  task void taskShutdownRequest() {
    bool bShutdown = FALSE;
    atomic {
      if ((stateRadio != IDLE_STATE) || 
	  (bPacketReceiving) || 
	  (m_rxFifoCount > 0)) {
	// don't shut down yet
	post taskShutdownRequest();
      }
      else {
	bShutdown = TRUE;
      }
    }

    if (bShutdown) {
      atomic stateRadio = DISABLED_STATE;

      call SFD.disable();
      call FIFOP.disable();
      call TimerControl.stop();
      call CC2420SplitControl.stop();
    }
  }

  //**********************************************************
  //* Exported interface functions for Std/SplitControl
  //* StdControl is deprecated, use SplitControl
  //**********************************************************/
  
  // This interface is depricated, please use SplitControl instead
  command result_t StdControl.init() {
    return call SplitControl.init();
  }

  // Split-phase initialization of the radio
  command result_t SplitControl.init() {

    atomic {
      stateRadio = DISABLED_STATE;
      currentDSN = 0;
      bPacketReceiving = FALSE;
      rxbufptr = &RxBuf;
      rxbufptr->length = 0;
      m_sfdReceiving = FALSE;
      m_rxFifoCount = 0;
      cqueue_init( &m_timestampQueue, NUM_TIMESTAMPS );
    }

    call TimerControl.init();
    call Random.init();
    LocalAddr = TOS_LOCAL_ADDRESS;
    return call CC2420SplitControl.init();
  }

  event result_t CC2420SplitControl.initDone() {
    return signal SplitControl.initDone();
  }

  default event result_t SplitControl.initDone() {
    return SUCCESS;
  }
  
  // This interface is depricated, please use SplitControl instead
  command result_t StdControl.stop() {
    return call SplitControl.stop();
  }

  // split phase stop of the radio stack
  command result_t SplitControl.stop() {
    result_t result = FAIL;
    atomic {
      if ((stateRadio != DISABLED_STATE) &&
	  (stateRadio != WARMUP_STATE)) {
	if (post taskShutdownRequest() == SUCCESS) {
	  bShutdownRequest = TRUE;
	  result = SUCCESS;
	}
      }
    }
    return result;
  }

  event result_t CC2420SplitControl.stopDone() {
    bShutdownRequest = FALSE; //atomic
    atomic {
      uint32_t oldtime = cc2420_waketime;
      cc2420_waketime += (call Counter32khz.get() - cc2420_laston);
      if( cc2420_waketime < oldtime )
        signal RadioActiveTime.overflow();
    }
    return signal SplitControl.stopDone();
  }

  default event result_t SplitControl.stopDone() {
    return SUCCESS;
  }

  task void startRadio() {
    result_t success = FAIL;
    atomic {
      if (stateRadio == DISABLED_STATE_STARTTASK) {
	stateRadio = DISABLED_STATE;
	success = SUCCESS;
      }
    }

    if (success == SUCCESS) 
      call SplitControl.start();
  }

  // This interface is depricated, please use SplitControl instead
  command result_t StdControl.start() {
    // if we put starting the radio from StdControl in a task, then it
    // delays executing until the other "start" functions are done.
    // the bug occurs when other components use the underlying bus in their
    // start() functions.  since the radio is split phase, it acquires
    // the bus during SplitControl.start() but doesn't release it until
    // SplitControl.startDone().  Ideally, Main would be changed to
    // understand SplitControl and run each SplitControl serially.
    result_t success = FAIL;

    atomic {
      if (stateRadio == DISABLED_STATE) {
	// only allow the task to be posted once.
	if (post startRadio()) {
	  success = SUCCESS;
	  stateRadio = DISABLED_STATE_STARTTASK;
	}
      }
    }

    return success;
  }

  // split phase start of the radio stack (wait for oscillator to start)
  command result_t SplitControl.start() {
    uint8_t chkstateRadio;

    atomic chkstateRadio = stateRadio;

    if (chkstateRadio == DISABLED_STATE) {
      atomic {
	stateRadio = WARMUP_STATE;
        countRetry = 0;
        rxbufptr->length = 0;
      }
      call TimerControl.start();
      return call CC2420SplitControl.start();
    }
    return FAIL;
  }

  event result_t CC2420SplitControl.startDone() {
    uint8_t chkstateRadio;

    atomic chkstateRadio = stateRadio;

    if (chkstateRadio == WARMUP_STATE) {

      cc2420_laston = call Counter32khz.get();

      call CC2420Control.RxMode( RESOURCE_NONE );
      //enable interrupt when pkt rcvd
      call FIFOP.startWait(FALSE);
      // enable start of frame delimiter timer capture (timestamping)
      call SFD.enableCapture(TRUE);
      
      atomic stateRadio  = IDLE_STATE;
    }
    signal SplitControl.startDone();
    return SUCCESS;
  }

  default event result_t SplitControl.startDone() {
    return SUCCESS;
  }

  /************* END OF STDCONTROL/SPLITCONTROL INIT FUNCITONS **********/

  /**
   * Try to send a packet.  If unsuccessful, backoff again
   **/
  void sendPacket( uint8_t rh ) {
    uint8_t status;

    call HPLChipcon.cmd(rh, CC2420_STXONCCA);
    status = call HPLChipcon.cmd(rh, CC2420_SNOP);
    if ((status >> CC2420_TX_ACTIVE) & 0x01) {

      // wait for the SFD to go high for the transmit SFD
      call SFD.enableCapture(TRUE);
      // JP: Sep 12 2005: set a timeout in case the SFD pin hangs
      setSFDTimeoutTimer(CC2420_MAX_SFD_TIME);
    }
    else {
      // try again to send the packet
      atomic stateRadio = PRE_TX_STATE;
      if (!(setBackoffTimer(signal MacBackoff.congestionBackoff(txbufptr) * CC2420_SYMBOL_UNIT))) {
        sendFailedAsync();
      }
    }
  }

  /**
   * Captured an edge transition on the SFD pin
   * Useful for time synchronization as well as determining
   * when a packet has finished transmission
   */
  async event result_t SFD.captured(uint16_t time) {
    switch (stateRadio) {
    case TX_STATE:
      // wait for SFD to fall--indicates end of packet
      call SFD.enableCapture(FALSE);

      txbufptr->time = time;
      signal RadioSendCoordinator.startSymbol(8,0,txbufptr);

      // if the pin already fell, disable the capture and let the next
      // state enable the cpature (bug fix from Phil Buonadonna)
      // fire TX SFD event
      if (!TOSH_READ_CC_SFD_PIN()) {
	call SFD.disable();
      }
      else {
	// if the pin hasn't fallen, break out and wait for the interrupt
	// if it fell, continue on the to the TX_WAIT state
	stateRadio = TX_WAIT;
	break;
      }
    case TX_WAIT:
      // end of packet reached
      stateRadio = POST_TX_STATE;
      call SFD.disable();
      // revert to receive SFD capture
      call SFD.enableCapture(TRUE);
      /* JP: Sep 12 2005: Stop the backoff timer from going off after
       * an SFD timeout
       */
      call BackoffAlarm32khz.stop();

      TOSH_CLR_UTXD0_PIN();

      // if acks are enabled and it is a unicast packet, wait for the ack
      if ((txbufptr->fcfhi == CC2420_DEF_FCF_HI_ACK) && 
	  (txbufptr->addr != TOS_BCAST_ADDR)) {
        if (!(setAckTimer(CC2420_ACK_DELAY)))
          sendFailedAsync();
      }
      // if no acks or broadcast, post packet send done event
      else {
        if (!post PacketSent())
          sendFailedAsync();
      }
      break;
    default:
      if( m_sfdReceiving ) {
        m_sfdReceiving = FALSE;
        call SFD.enableCapture(TRUE); //capture rising edge SFD for rx/tx start of packet
        if( TOSH_READ_CC_FIFO_PIN() ) {
          // SFD fell and FIFO high means valid packet, receive bytes
          m_rxFifoCount++;
          call CmdReceive.deferRequest();
        } else {
          // SFD fell and FIFO low means invalid packet, flush bytes
          flushRXFIFO( RESOURCE_NONE );
        }
      } else {
        uint32_t when = call Counter32khz.get();
        if((when & 0xFFFF) < time )
          when -= 0x10000L;
        when = (when & 0xffff0000L) | time;

        // fire RX SFD handler
        m_sfdReceiving = TRUE;
        call SFD.enableCapture(FALSE); //capture falling edge SFD for rx end of packet

        // if we're trying to send a message and a FIFOP interrupt occurs
        // and acks are enabled, we need to backoff longer so that we don't
        // interfere with the ACK
        if ((stateRadio == PRE_TX_STATE) && (call BackoffAlarm32khz.isRunning())) {
          call BackoffAlarm32khz.stop();
          call BackoffAlarm32khz.start((signal MacBackoff.congestionBackoff(txbufptr) * CC2420_SYMBOL_UNIT) + CC2420_MIN_ACK_DELAY);
        }

        if( cqueue_pushBack(&m_timestampQueue) )
          m_timestamps[m_timestampQueue.back] = when;
	//        rxbufptr->time = when;
        signal RadioReceiveCoordinator.startSymbol(8,0,rxbufptr);
      }
    }
    return SUCCESS;
  }

  /**
   * Start sending the packet data to the TXFIFO of the CC2420
   */
  bool startSendBody( uint8_t rh ) {
    if (bShutdownRequest) {
      sendFailedSync();
      return FALSE;
    }
    // flush the tx fifo of stale data
    if (!(call HPLChipcon.cmd(rh, CC2420_SFLUSHTX))) {
      sendFailedSync();
      return FALSE;
    }
    // write the txbuf data to the TXFIFO
    atomic rh_transmit = rh;
    if (!(call HPLChipconFIFO.writeTXFIFO(rh, txlength+1,(uint8_t*)txbufptr))) {
      sendFailedSync();
      return FALSE;
    }
    return TRUE;
  }

  event void CmdTransmit.granted( uint8_t rh ) {
    if( startSendBody(rh) == FALSE )
      call CmdTransmit.release();
  }

  /**
   * Check for a clear channel and try to send the packet if a clear
   * channel exists using the sendPacket() function
   */
  void tryToSend( uint8_t rh ) {
     uint8_t currentstate;
     atomic currentstate = stateRadio;

     // and the CCA check is good
     if (currentstate == PRE_TX_STATE) {

       if (bShutdownRequest) {
	 sendFailedAsync();
	 return;
       }

       // if a FIFO overflow occurs or if the data length is invalid, flush
       // the RXFIFO to get back to a normal state.
       if ((!TOSH_READ_CC_FIFO_PIN() && !TOSH_READ_CC_FIFOP_PIN())) {
         flushRXFIFO( rh );
       }

       if (TOSH_READ_RADIO_CCA_PIN()) {
         atomic stateRadio = TX_STATE;
         sendPacket( rh );
       }
       else {
	 // if we tried a bunch of times, the radio may be in a bad state
	 // flushing the RXFIFO returns the radio to a non-overflow state
	 // and it continue normal operation (and thus send our packet)
         if (countRetry-- <= 0) {
	   flushRXFIFO( rh );
	   countRetry = MAX_SEND_TRIES;
           call CmdTransmit.deferRequest();
           return;
         }
         if (!(setBackoffTimer(signal MacBackoff.congestionBackoff(txbufptr) * CC2420_SYMBOL_UNIT))) {
           sendFailedAsync();
         }
       }
     }
  }

  event void CmdTryToSend.granted( uint8_t rh ) {
    tryToSend( rh );
    call CmdTryToSend.release();
  }

  /**
   * Multiplexed timer to control initial backoff, 
   * congestion backoff, and delay while waiting for an ACK
   */
  async event void BackoffAlarm32khz.fired() {
    uint8_t currentstate;
    atomic currentstate = stateRadio;

    switch (stateTimer) {
    case TIMER_INITIAL:
      call CmdTransmit.deferRequest();
      break;
    case TIMER_BACKOFF:
      call CmdTryToSend.deferRequest();
      break;
    case TIMER_ACK:
      if (currentstate == POST_TX_STATE) {
	/* MDW 12-July-05: Race condition here: If ACK comes in before
	 * PacketSent() runs, the task can be posted twice (duplicate
	 * sendDone events). Fix: set the state to a different value to
	 * suppress the later task.
	 */
	atomic {
	  txbufptr->ack = 0;
	  stateRadio = POST_TX_ACK_STATE;
	}
        if (!post PacketSent())
	  sendFailedAsync();
      }
      break;
    case TIMER_SFD:
      /* JP Sep 12 2005: Allow the radio stack to break out of the SFD
       * wait process if the radio has stalled (or the capture effect occurs)
       * This occurs in an interrupt handler, so no need to put atomic 
       * around the statements below.
       */
      // disable the SFD 
      call SFD.disable();
      // revert to receive SFD capture
      call SFD.enableCapture(TRUE);
      // signal the failed event
      sendFailedAsync();
      break;
    }
  }

  async command void MacControl.requestAck(TOS_MsgPtr pMsg) {
    atomic {
      if (pMsg == txbufptr) {
	txbufptr->fcfhi = CC2420_DEF_FCF_HI_ACK;
      }
    }
  }

 /**********************************************************
   * Send
   * - Xmit a packet
   *    USE SFD FALLING FOR END OF XMIT !!!!!!!!!!!!!!!!!! interrupt???
   * - If in power-down state start timer ? !!!!!!!!!!!!!!!!!!!!!!!!!s
   * - If !TxBusy then 
   *   a) Flush the tx fifo 
   *   b) Write Txfifo address
   *    
   **********************************************************/
  command result_t Send.send(TOS_MsgPtr pMsg) {
    uint8_t currentstate;
    atomic currentstate = stateRadio;

    if ((currentstate == IDLE_STATE) && (!bShutdownRequest)) {
      // put default FCF values in to get address checking to pass
      pMsg->fcflo = CC2420_DEF_FCF_LO;
      pMsg->fcfhi = CC2420_DEF_FCF_HI;
      // destination PAN is broadcast
      pMsg->destpan = TOS_BCAST_ADDR;
      // adjust the destination address to be in the right byte order
      pMsg->addr = toLSB16(pMsg->addr);
      // adjust the data length to now include the full packet length
      pMsg->length = pMsg->length + MSG_HEADER_SIZE + MSG_FOOTER_SIZE;
      // keep the DSN increasing for ACK recognition
      pMsg->dsn = ++currentDSN;
      // reset the time field
      pMsg->time = 0;
      // FCS bytes generated by CC2420
      txlength = pMsg->length - MSG_FOOTER_SIZE;  
      txbufptr = pMsg;
      countRetry = MAX_SEND_TRIES;

      if (setInitialTimer(signal MacBackoff.initialBackoff(txbufptr) * CC2420_SYMBOL_UNIT)) {
        atomic stateRadio = PRE_TX_STATE;
        return SUCCESS;
      }
    }
    return FAIL;

  }
  
  /**
   * Delayed RXFIFO is used to read the receive FIFO of the CC2420
   * in task context after the uC receives an interrupt that a packet
   * is in the RXFIFO.  Task context is necessary since reading from
   * the FIFO may take a while and we'd like to get other interrupts
   * during that time, or notifications of additional packets received
   * and stored in the CC2420 RXFIFO.
   */
  bool delayedRXFIFOBody( uint8_t rh ) {
    bool doReadRXFIFO;

    atomic {
      if ((!TOSH_READ_CC_FIFO_PIN()) && (!TOSH_READ_CC_FIFOP_PIN())) {
        flushRXFIFO( rh );
        return FALSE;
      }

      // JP NOTE: TODO: move readRXFIFO out of atomic context to permit
      // high frequency sampling applications and remove delays on
      // interrupts being processed.  There is a race condition
      // that has not yet been diagnosed when RXFIFO may be interrupted.
      if( bPacketReceiving == FALSE ) {
        bPacketReceiving = TRUE;
        rh_receive = rh;
        doReadRXFIFO = TRUE;
      }
      else {
        doReadRXFIFO = FALSE;
      }
    }

    if( doReadRXFIFO ) {
      if( call HPLChipconFIFO.readRXFIFO(rh, MSG_DATA_SIZE, (uint8_t*)rxbufptr) ) {
        return TRUE;
      }
      else {
        // 28 Nov 2005 CSS: If HPLChipconFIFO.readRXFIFO failed, it will likely
        // fail again for this packet, so flush RXFIFO and start over.
        flushRXFIFO( rh );
        return FALSE;
      }
    }
    else {
      // 20 Dec 2005 CSS: if doReadRXFIFO is false, then bPacketReceiving was
      // alreeady true, so wait for RXFIFODone to post PacketRcvd to request
      // the another CmdReceive.  This is to keep track of exactly how many
      // packets there are witing to be received in the RX FIFO.
      return FALSE;
    }
  }

  event void CmdReceive.granted( uint8_t rh ) {
    if( delayedRXFIFOBody(rh) == FALSE )
      call CmdReceive.release();
  }


  
  /**********************************************************
   * FIFOP lo Interrupt: Rx data avail in CC2420 fifo
   * Radio must have been in Rx mode to get this interrupt
   * If FIFO pin =lo then fifo overflow=> flush fifo & exit
   * 
   *
   * Things ToDo:
   *
   * -Disable FIFOP interrupt until PacketRcvd task complete 
   * until send.done complete
   *
   * -Fix mixup: on return
   *  rxbufptr->rssi is CRC + Correlation value
   *  rxbufptr->strength is RSSI
   **********************************************************/
   async event result_t FIFOP.fired() {
     // Check for RXFIFO overflow
     if (!TOSH_READ_CC_FIFO_PIN()) {
       flushRXFIFO( RESOURCE_NONE );
     }
     return SUCCESS;
   }



  /**
   * After the buffer is received from the RXFIFO,
   * process it, then post a task to signal it to the higher layers
   */
  result_t doRXFIFODoneBody( uint8_t rh, uint8_t length, uint8_t *data ) {
    // JP NOTE: rare known bug in high contention:
    // radio stack will receive a valid packet, but for some reason the
    // length field will be longer than normal.  The packet data will
    // be valid up to the correct length, and then will contain garbage
    // after the correct length.  There is no currently known fix.
    uint8_t currentstate;
    atomic { 
      currentstate = stateRadio;
    }

    // if a FIFO overflow occurs or if the data length is invalid, flush
    // the RXFIFO to get back to a normal state.
    if ((!TOSH_READ_CC_FIFO_PIN() && !TOSH_READ_CC_FIFOP_PIN()) 
        || (length == 0) || (length > MSG_DATA_SIZE)) {
      flushRXFIFO( rh );
      return SUCCESS;
    }

    rxbufptr = (TOS_MsgPtr)data;

    // check for an acknowledgement that passes the CRC check
    if ((currentstate == POST_TX_STATE) &&
         ((rxbufptr->fcfhi & 0x07) == CC2420_DEF_FCF_TYPE_ACK) &&
         (rxbufptr->dsn == currentDSN) &&
         ((data[length-1] >> 7) == 1)) {
      atomic {
        txbufptr->ack = 1;
        txbufptr->strength = data[length-2];
        txbufptr->lqi = data[length-1] & 0x7F;
	/* MDW 12-Jul-05: Need to set the real radio state here... */
        stateRadio = POST_TX_ACK_STATE;
        bPacketReceiving = FALSE;
      }
      if (!post PacketSent())
	sendFailedAsync();

      /* HN/Intel: Sep 13 2005: Post delayedRXFIFIOtask if there's
       * more data to be read ELSE flushRXFIFO to enable FIFOP
       * interrupts from future packets. Without either of these
       * actions, no further packets will be received after the first
       * ack packet.
       */
      if (TOSH_READ_CC_FIFO_PIN()) {
        call CmdReceive.deferRequest();
        return SUCCESS;
      }

      flushRXFIFO( rh );
      return SUCCESS;
    }

    // check for invalid packets
    // an invalid packet is a non-data packet with the wrong
    // addressing mode (FCFLO byte)
    if (((rxbufptr->fcfhi & 0x07) != CC2420_DEF_FCF_TYPE_DATA) ||
         (rxbufptr->fcflo != CC2420_DEF_FCF_LO)) {
      flushRXFIFO( rh );
      return SUCCESS;
    }
    rxbufptr->length = rxbufptr->length - MSG_HEADER_SIZE - MSG_FOOTER_SIZE;

    if (rxbufptr->length > TOSH_DATA_LENGTH) {
      flushRXFIFO( rh );
      return SUCCESS;
    }

    // adjust destination to the right byte order
    rxbufptr->addr = fromLSB16(rxbufptr->addr);
 

    // if the length is shorter, we have to move the CRC bytes
    rxbufptr->crc = data[length-1] >> 7;
    // put in RSSI
    rxbufptr->strength = data[length-2];
    // put in LQI
    rxbufptr->lqi = data[length-1] & 0x7F;

    // transfer the timestamp from the queue to rxbufptr
    atomic {
      if( !cqueue_isEmpty( &m_timestampQueue ) )
        rxbufptr->time = m_timestamps[ m_timestampQueue.front ];
      cqueue_popFront( &m_timestampQueue );
    }

    // if ack is requested, must pass CRC and match our address
    if ((rxbufptr->fcfhi & (1 << CC2420_DEF_FCF_BIT_ACK)) && 
	(rxbufptr->crc) && 
	(rxbufptr->group == TOS_AM_GROUP) &&
	(rxbufptr->addr == TOS_LOCAL_ADDRESS)) {
      call HPLChipcon.cmd(rh, CC2420_SACK);
    }

    post PacketRcvd();

    // 28 Nov 2005 CSS: "Check for more data in RXFIFO" code has been removed.
    // A complete packet reception is handled by the SFD pin, and RXFIFO
    // overflow is handled by the FIFOP interrupt or in the absolute worst case
    // by Counter32khz.overflow().

    return SUCCESS;
  }

  async event result_t HPLChipconFIFO.RXFIFODone(uint8_t length, uint8_t *data) {
    doRXFIFODoneBody( rh_receive, length, data );
    call CmdReceive.release();
    return SUCCESS;
  }

  async event void Counter32khz.overflow() {
  }

  async event void Counter32khz16.overflow() {
    atomic {
      if( (!TOSH_READ_CC_FIFO_PIN()) && (!TOSH_READ_CC_FIFOP_PIN()) ) {
        flushRXFIFO( RESOURCE_NONE );
      }
    }
  }

  /**
   * Notification that the TXFIFO has been filled with the data from the packet
   * Next step is to try to send the packet
   */
  async event result_t HPLChipconFIFO.TXFIFODone(uint8_t length, uint8_t *data) { 
    if (bShutdownRequest) {
      sendFailedAsync();
    }
    else {
      tryToSend( rh_transmit );
    }
    call CmdTransmit.release();
    return SUCCESS;
  }

  /**
   * Enable link layer hardware acknowledgements.
   * Deprecated; use requestAck()
   */
  async command void MacControl.enableAck() {
  }

  /**
   * Disable link layer hardware acknowledgements.
   * Deprecated; use requestAck()
   */
  async command void MacControl.disableAck() {
  }

  async command cc2420_linkstate_t MacControl.getState() {
    cc2420_linkstate_t retval = CC2420_LINKSTATE_ON;
    atomic {
      switch (stateRadio) {
      case DISABLED_STATE:
      case DISABLED_STATE_STARTTASK:
	retval = CC2420_LINKSTATE_OFF;
	break;
      case WARMUP_STATE:
	retval = CC2420_LINKSTATE_WARMUP;
	break;
      default:
	break;
      }
    }
    return retval;
  }

  default event TOS_MsgPtr Receive.receive( TOS_MsgPtr msg ) {
    return msg;
  }

  default event result_t Send.sendDone(TOS_MsgPtr msg, cc2420_error_t success) {
    return SUCCESS;
  }

  /**
   * How many basic time periods to back off.
   * Each basic time period consists of 20 symbols (16uS per symbol)
   */
  default async event int16_t MacBackoff.initialBackoff(TOS_MsgPtr m) {
    return (call Random.rand() & 0xF) + 1;
  }
  /**
   * How many symbols to back off when there is congestion 
   * (16uS per symbol * 20 symbols/block)
   */
  default async event int16_t MacBackoff.congestionBackoff(TOS_MsgPtr m) {
    return (call Random.rand() & 0x3F) + 1;
  }

// Default events for radio send/receive coordinators do nothing.
// Be very careful using these, you'll break the stack.
// The "byte()" event is never signalled because the CC2420 is a packet
// based radio.
default async event void RadioSendCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff) { }
default async event void RadioSendCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) { }
default async event void RadioReceiveCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff) { }
default async event void RadioReceiveCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) { }

}
