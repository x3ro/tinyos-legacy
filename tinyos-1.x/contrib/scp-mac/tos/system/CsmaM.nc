/*
 * Copyright (C) 2005 the University of Southern California.
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * In addition to releasing this program under the LGPL, the authors are
 * willing to dual-license it under other terms. You may contact the authors
 * of this project by writing to Wei Ye, USC/ISI, 4676 Admirality Way, Suite 
 * 1001, Marina del Rey, CA 90292, USA.
 */
/*
 * Authors: Wei Ye
 *
 * This module implements the basic CSMA
 */

module CsmaM
{
  provides {
    interface StdControl;
    interface CsmaControl;
    interface MacMsg;
    interface MacActivity;
  }
  uses {
    interface StdControl as PhyControl;
    interface StdControl as TimerControl;
    interface RadioState;
    interface CarrierSense;
    interface CsThreshold;
    interface PhyPkt;
    interface PhyNotify;
    interface PhyStreamByte;
    interface Random;
    interface Timer as NavTimer;
    interface Timer as NeighbNavTimer;
    interface Timer as BackoffTimer;
    interface Leds;
    interface UartDebug;
  }
}

implementation
{
#include "StdReturn.h"
#include "CsmaConst.h"
#include "csmaEvents.h"

// MAC constants, used internally

// additional delay before timeout when waiting for a packet
#define TIMEOUT_DELAY 2

#define TIME_WAIT_ACK (CSMA_PROCESSING_DELAY + CSMA_ACK_DURATION + \
        CSMA_PROCESSING_DELAY + TIMEOUT_DELAY)

  /* MAC states
  *-------------
  * IDLE - no activity going on, radio can be in sleep state
  * SLEEP -- the only sleep time is overhearing avoidance
  * PRE_TX - will transmit pkt once radio wakeup is done
  * CARR_SENSE - carrier sense. Do it before initiate a Tx
  * TX_PKT: transmitting packet
  * BACKOFF - medium is busy, and cannot Tx
  * RECEIVE - receving packet
  * WAIT_CTS - just sent RTS, and is waiting for CTS
  * WAIT_DATA - just sent CTS, and is waiting for DATA
  * WAIT_ACK - just sent DATA, and is waiting for ACK
  */
  enum {
    SLEEP,
    IDLE,
    PRE_TX,
    CARR_SENSE,
    TX_PKT,
    BACKOFF,
    RECEIVE,
    WAIT_CTS,
    WAIT_DATA,
    WAIT_ACK,
  };

  // CSMA packet types -- will move to CsmaMsg.h
  enum { BCAST_DATA_PKT, UCAST_DATA_PKT, RTS_PKT, CTS_PKT, ACK_PKT };

  // state variables
  uint8_t state;  // MAC state
  uint8_t numCsFailures; // number of consecutive failures on carrier sense

  // timing variables
  uint16_t durInRts;  // duration (tx time needed) of data packet 
  uint16_t backoffTime; // backoff time when carrier sense fails
   
  // Variables for Tx
  uint8_t txPktState; // state of the pkt to be transmitted, as below
  enum {
    NOT_BUFFERED,   // no pkt buffered, ready to accept a new one
    BUFFERED,       // pkt buffered, but sending has not started
    SENDING         // pkt buffered and is being sent
  };
  bool autoReTx;      // automatic re-send if previous attemp fails
  uint16_t sendAddr;   // node that I'm sending data to
  uint8_t txPktLen;   // length of data pkt to be transmitted
  uint16_t addPreambleLen;  // additional preamble to be added
  uint8_t howToSend;     // what action to take for tx
  uint8_t contWinSize;  // contention window size
  uint8_t numBackoff;   // number of continuous backoff
  uint8_t numReTx;      // number unicast re-tx when ACK is not received
  CsmaHeader* dataPkt; // pointer to tx data pkt, only access MAC header
  uint8_t ctrlPkt[CSMA_CTRL_PKT_BUF]; // buffer for control pkts
  
  // Variables for Rx
  uint16_t recvAddr;     // node that I'm receiving data from
  
  // function prototypes
  void handleRTS(void* packet);
  void handleCTS(void* packet);
  void* handleBcastData(void* pkt);
  void* handleUcastData(void* pkt);
  void handleACK(void* packet);
  void handleErrPkt();
  void sendBcast();
  void sendRTS();
  void sendCTS();
  void sendUcast(uint16_t addPreamble);
  void sendACK();
  result_t tryToSend();
  result_t startCarrSense();
  void txMsgDone(result_t result);
  void updateNav(uint32_t time);
  void updNeighbNav(uint32_t time);
  result_t checkActivity(result_t lastResult);
  task void reportStarvation();
  
  
  command result_t StdControl.init()
  {
    // initialize CSMA and related components
    
    state = IDLE;
    numCsFailures = 0;
    txPktState = NOT_BUFFERED;
    autoReTx = TRUE;
    addPreambleLen = 0;  // no additional preamble
    contWinSize = CSMA_CONT_WIN;
    backoffTime = CSMA_BACKOFF_TIME;

    // initialized lower-level components
    call Random.init();  // initialize random number generator
    call TimerControl.init();  // initialize timer
    call PhyControl.init();  //initialize physical layer
    call Leds.init();  // initialize LEDs
    
    // Mica2 radio seems sensitive to power supply. With 3V DC power adapter
    // and the old programming board, the radio sometimes can't be correctly
    // initialized (most of time, it can receive but can't transmit).
    call UartDebug.init();  // initialize UART debugging
    
    return SUCCESS;
  }


  command result_t StdControl.start()
  {
    // start MAC and lower-level components
    
    call TimerControl.start();  // initialize timer
    call PhyControl.start();  //initialize physical layer
    call Leds.yellowOn();  // yellow LED indicate radio active or sleep
    return SUCCESS;
  }
  
  
  command result_t StdControl.stop()
  {
    // stop CSMA
    
    call PhyControl.stop();  // stop physical layer
    return SUCCESS;
  }
  
  
  command void CsmaControl.addPreamble(uint16_t length)
  {
    // set the length of additional preamble
    addPreambleLen = length;
  }
    
  
  command void CsmaControl.setContWin(uint8_t numSlots)
  {
    // set contention window size in terms of number of slots
    
    contWinSize = numSlots;
  }
  
  
  command void CsmaControl.setBackoffTime(uint32_t time)
  {
    // set backoff time when carrier sense fails
    // should be longer than start symbol transmission time
    
    backoffTime = time;
  }
  
  
  command void CsmaControl.disableAutoReTx()
  {
    // disable automatic re-send after previous attempt fails
    
    autoReTx = FALSE;
  }


  command void CsmaControl.enableAutoReTx()
  {
    // enable automatic re-send after previous attemp fails

    autoReTx = TRUE;
  }
  
  
  async event result_t RadioState.wakeupDone()
  {
    // radio wakeup is done -- it becomes stable now

    if (state == PRE_TX) {  // transmission pending
      state = IDLE;
      call UartDebug.txState(state);
      startCarrSense();  // start carrier sense now
    } else if (state == SLEEP) {  // overhearing avoidance
      // resend if have buffered pkt
      state = IDLE;
      call UartDebug.txState(state);
      if (txPktState == BUFFERED && autoReTx) tryToSend();
      // virtual carrier sense is idle now
      signal MacActivity.virtualCSIdle();
    }
    return SUCCESS;
  }
  
  
  command result_t MacMsg.send(void* msg, uint8_t length, uint16_t toAddr)
  {
    // send a message
    
    uint8_t result;
    uint32_t txTimeTmp;
    // sanity check
    
    if (msg == 0 || length == 0 || length > PHY_MAX_PKT_LEN) {
      call UartDebug.txEvent(TX_MSG_REJECTED_ERROR);
      return FAIL;
    }
    // Don't accept Tx request if I have already accepted a request
    atomic {
      if (txPktState == NOT_BUFFERED) {
        txPktState = BUFFERED;
        result = 1;
      } else {     
        result = 0;
      }
    }
    if (result == 0) {
      call UartDebug.txEvent(TX_MSG_REJECTED_BUFFERED);
      return FAIL;
    }
    call UartDebug.txEvent(TX_MSG_ACCEPTED);

    dataPkt = (CsmaHeader*)msg;
    txPktLen = length;
    sendAddr = toAddr;

    if (sendAddr == TOS_BCAST_ADDR) {  // broadcast packet
      dataPkt->type = (BCAST_DATA_PKT << 4) + (dataPkt->type & 0x0f);  // higher 4 bits
      howToSend = BCAST_DATA_PKT;
    } else {  // unicast packet
      dataPkt->type = (UCAST_DATA_PKT << 4) + (dataPkt->type & 0x0f);  // higher 4 bits
      numBackoff = 0;
      numReTx = 0;
      if (txPktLen < CSMA_RTS_THRESHOLD) {
        howToSend = UCAST_DATA_PKT;
      } else {
        howToSend = RTS_PKT;
        // calculate duration of data packet
        txTimeTmp = (uint32_t)(PHY_BASE_PRE_BYTES + txPktLen) *
                  PHY_TX_BYTE_TIME / 1000 + 1;
        durInRts =  CSMA_CTS_DURATION + (uint16_t)txTimeTmp + CSMA_ACK_DURATION
                 + CSMA_PROCESSING_DELAY * 4 + TIMEOUT_DELAY;
      }
    }
    
    // fill in other header fields
    dataPkt->fromAddr = TOS_LOCAL_ADDRESS;
    dataPkt->toAddr = sendAddr;
    
    tryToSend(); // try to send now
    return SUCCESS;
  }


  command result_t MacMsg.sendCancel(void* msg)
  {
    // cancel a message to be sent (i.e., previously called MacMsg.send)
    
    result_t result;
    if (msg != dataPkt) return FAIL;
    atomic {
      if (txPktState == BUFFERED) {
        txPktState = NOT_BUFFERED;
        result = SUCCESS;
      } else {
        result = FAIL;
      }
    }
    if (result == SUCCESS) {  // send cancelled
      signal MacMsg.sendDone(dataPkt, FAIL);  // signal upper layer
    }
    return result;
  }
  
  
  result_t tryToSend()
  {
    // try to send a buffered packet
    
    int8_t result;
    if (state != IDLE || 
        call NavTimer.getRemainingTime() > 0 ||
        call NeighbNavTimer.getRemainingTime() > 0) {
      call UartDebug.txEvent(TRYTOSEND_FAILURE);
      return FAIL;
    }
    call UartDebug.txEvent(TRYTOSEND_SUCCESS);
    
    // wakeup radio if in sleep
    if (call RadioState.get() == RADIO_SLEEP) {
      result = call RadioState.idle();
      if (result == FAILURE) {
        return FAIL;  // can't wake up radio
      } else if (result == SUCCESS_DONE) {
        return startCarrSense();  // start carrier sense now
      } else if (result == SUCCESS_WAIT) {  // wait for wakeupDone signal
        state = PRE_TX;
      }
    } else {
      return startCarrSense();
    }
    return SUCCESS;
  }
  
  
  result_t startCarrSense()
  {
    // start carrier sense
    
    uint16_t backoffSlots;
    result_t result;
    
    if (contWinSize == 0) {  // bypass the carrier sense process
      state = CARR_SENSE;
      signal CarrierSense.channelIdle();
      return SUCCESS;
    }
    // normal carrier sense 
    backoffSlots = DIFS + (call Random.rand() % contWinSize);
    // start carrier sense and change state needs to be atomic
    // to prevent start symbol is detected between them
    atomic {
      if (call CarrierSense.start(backoffSlots) == SUCCESS) {
        state = CARR_SENSE;
        result = SUCCESS;
      } else {
        result = FAIL;
      }
    }
    call UartDebug.txState(state);
    return result;
  }
  
  
  void sendBcast()
  {
    // broadcast data directly; don't use RTS/CTS
/*
#ifdef CSMA_SNOOPER_DEBUG
    *((uint8_t*)dataPkt + sizeof(AppHeader) + 11) = 
      (uint16_t)call NavTimer.getRemainingTime();
    *((uint8_t*)dataPkt + sizeof(AppHeader) + 13) = 
      (uint16_t)call NeighbNavTimer.getRemainingTime();
#endif
*/
    call PhyPkt.send(dataPkt, txPktLen, addPreambleLen);
    state = TX_PKT;
    call UartDebug.txState(state);
  }

   
    void sendRTS()
  {
    // construct and send RTS packet
    
    RTSPkt *rtsPkt = (RTSPkt *)ctrlPkt;
    rtsPkt->type = RTS_PKT << 4;
    rtsPkt->fromAddr = TOS_LOCAL_ADDRESS;
    rtsPkt->toAddr = sendAddr;
    // reserve time for CTS + data + ACK
    rtsPkt->duration =  durInRts;
    // send RTS
    call PhyPkt.send(rtsPkt, sizeof(RTSPkt), addPreambleLen);
    state = TX_PKT;
    call UartDebug.txState(state);
  }


  void sendCTS()
  {
    // construct and send CTS
    
    CTSPkt *ctsPkt = (CTSPkt *)ctrlPkt;
    ctsPkt->type = CTS_PKT << 4;
    ctsPkt->toAddr = recvAddr;
    // should track neighbors' NAV as soon as RTS is received
    ctsPkt->duration = (uint16_t)(call NeighbNavTimer.getRemainingTime())
                       - CSMA_CTS_DURATION - CSMA_PROCESSING_DELAY;
    // send CTS
    call PhyPkt.send(ctsPkt, sizeof(CTSPkt), 0);
    state = TX_PKT;
    call UartDebug.txState(state);
  }


  void sendUcast(uint16_t addPreamble)
  {
    // send a unicast data packet
    // assume all MAC header fields have been filled

/*
#ifdef CSMA_SNOOPER_DEBUG
    *((uint8_t*)dataPkt + sizeof(AppHeader) + 11) = 
      (uint16_t)call NavTimer.getRemainingTime();
    *((uint8_t*)dataPkt + sizeof(AppHeader) + 13) = 
      (uint16_t)call NeighbNavTimer.getRemainingTime();
#endif
*/
    
    call PhyPkt.send(dataPkt, txPktLen, addPreamble);
    state = TX_PKT;
    call UartDebug.txState(state);
  }
  
  
  void sendACK()
  {
    // construct and send ACK
    
    ACKPkt *ackPkt = (ACKPkt *)ctrlPkt;
    ackPkt->type = ACK_PKT << 4;
    ackPkt->toAddr = recvAddr;
//    ackPkt->duration = (uint16_t)call NeighbNavTimer.getRemainingTime(); //debugging
    call PhyPkt.send(ackPkt, sizeof(ACKPkt), 0);
    state = TX_PKT;
    call UartDebug.txState(state);
  }
  
  
  void txMsgDone(result_t result)
  {
    // unicast is done
    
    // prepare to tx next msg
    call UartDebug.txEvent(TX_MSG_DONE);
    call Leds.redToggle();
    txPktState = NOT_BUFFERED;
    signal MacMsg.sendDone(dataPkt, result);
  }
  
  
  task void radioDoneSuccess()
  {
    signal MacActivity.radioDone(SUCCESS);
  }
  
  
  event result_t PhyPkt.sendDone(void* packet)
  {
    // transmit packet is done by physical layer

    char pktType;
    if (packet == 0 || state != TX_PKT) {
      return FAIL;
    }
    pktType = (*((char*)packet + sizeof(PhyHeader))) >> 4;
    switch (pktType) {  // the type field
    case BCAST_DATA_PKT:  // just sent a broadcast data
      state = IDLE;
      call UartDebug.txEvent(TX_BCAST_DONE);
      call UartDebug.txState(state);
      txMsgDone(SUCCESS);
      post radioDoneSuccess();
      break;
    case RTS_PKT:  // just sent RTS
      state = WAIT_CTS;
      updNeighbNav(((RTSPkt*)packet)->duration);  // track neighbors' NAV
      // no data timeout, just use NeighbNAVTimer
      // they update NAV and go to sleep after recv RTS
      call UartDebug.txEvent(TX_RTS_DONE);
      call UartDebug.txState(state);
      break;
    case CTS_PKT:  // just sent CTS
      state = WAIT_DATA;
      // no data timeout, just use neighbors' NAV
      // they update NAV and go to sleep after recv CTS
      call UartDebug.txEvent(TX_CTS_DONE);
      call UartDebug.txState(state);
      break;
    case UCAST_DATA_PKT:  // just sent unicast data
      state = WAIT_ACK;  // waiting for ACK
      updNeighbNav(TIME_WAIT_ACK);  // track neighbors' NAV
      // no data timeout, just use neighbors' NAV
      // they update NAV and go to sleep after recv CTS
      call UartDebug.txEvent(TX_UCAST_DONE);
      call UartDebug.txState(state);
      break;
    case ACK_PKT:
      state = IDLE;
      call UartDebug.txEvent(TX_ACK_DONE);
      call UartDebug.txState(state);
      break;
    }
    return SUCCESS;
  }
  
  
  void updateNav(uint32_t time)
  {
    // update NAV timer
    
#ifdef CSMA_ENABLE_OVERHEARING
    uint32_t timerVal;
    timerVal = call NavTimer.getRemainingTime();
    if (timerVal == 0) {
     
      call NavTimer.start(TIMER_ONE_SHOT, updTime);
      call UartDebug.txEvent(TIMER_STARTED_NAV);
      signal MacActivity.virtualCSBusy();  // virtual carrier sense busy
    } else if (time > timerVal) {
      call NavTimer.setRemainingTime(updTime);
      call UartDebug.txEvent(TIMER_UPDATED_NAV);
    }
#else  // overhearing disabled
    if (time <= PHY_WAKEUP_DELAY) return;  // don't bother to start timer
   
    call NavTimer.start(TIMER_ONE_SHOT, time - PHY_WAKEUP_DELAY);
    call UartDebug.txEvent(TIMER_STARTED_NAV);
    state = SLEEP;
    call UartDebug.txState(state);
    call RadioState.sleep();
    call Leds.yellowOff();
    signal MacActivity.virtualCSBusy();  // virtual carrier sense busy
#endif
    
  }
  
  
  void updNeighbNav(uint32_t time)
  {
    // update NAV timer
    
    uint32_t timerVal;
    if (time == 0) return;
    timerVal = call NeighbNavTimer.getRemainingTime();
    if (timerVal == 0) {
     
      call NeighbNavTimer.start(TIMER_ONE_SHOT, time);
      call UartDebug.txEvent(TIMER_STARTED_NEIGHB_NAV);
    } else if (time > timerVal) {
      call NeighbNavTimer.setRemainingTime(time);
      call UartDebug.txEvent(TIMER_UPDATED_NEIGHB_NAV);
    }
  }
  
  
  event result_t NavTimer.fired()
  {
    // Network allocation vector (NAV) timer fires in a task
    
    call UartDebug.txEvent(TIMER_FIRE_NAV);
    if (state == SLEEP) {  // overhearing avoidance is done
      if (call RadioState.idle() == SUCCESS_DONE) {
        state = IDLE;
        call UartDebug.txState(state);
        if (txPktState == BUFFERED && autoReTx) tryToSend();
        // virtual carrier sense is idle now
        signal MacActivity.virtualCSIdle();
      }
      call Leds.yellowOn();
    } else {  // radio is on
      // resend if have buffered pkt
      if (txPktState == BUFFERED && autoReTx) tryToSend();
      // virtual carrier sense is idle now
      signal MacActivity.virtualCSIdle();
    }
    return SUCCESS;
  }
  
    
  event result_t NeighbNavTimer.fired()
  {
    // this timer keeps track of neighbor's NAV; it fires in a task
    
    call UartDebug.txEvent(TIMER_FIRE_NEIGHB_NAV);
    if (state == WAIT_CTS || state == WAIT_ACK) {  // Tx failed
      state = IDLE;
      call UartDebug.txState(state);
      if (numReTx >= CSMA_RETX_LIMIT) {  // reached re-tx limit
        txMsgDone(FAIL);  // give up Tx
        signal MacActivity.radioDone(FAIL);
      } else {  // can still retry
        numReTx++;
        txPktState = BUFFERED;  // upper layer can cancel Tx now if it wants
        // check if I should resend now
        checkActivity(FAIL);
      }
    } else if (state == WAIT_DATA) { // got RTS but no data
      state = IDLE;
      call UartDebug.txState(state);
      checkActivity(FAIL);  // try to send if buffered tx data
    } else {  // in idle state, successfully sent or received data
//      state = IDLE;
//      call UartDebug.txState(state);
      checkActivity(SUCCESS);
    }
    return SUCCESS;
  }
  
  
  result_t checkActivity(result_t lastResult)
  {
    // check if I should resend my buffered packet now
    
    if (txPktState == BUFFERED && autoReTx) {
      tryToSend();
    } else {
      signal MacActivity.radioDone(lastResult);
    }
    return SUCCESS;
  }
  
  
  event result_t BackoffTimer.fired()
  {
    // previously detected channel busy but didn't find the start symbol
    // time to resend a packet that previously failed
    
    call UartDebug.txEvent(TIMER_FIRE_BACKOFF);
    if (state != BACKOFF) return FAIL;
    state = IDLE;
    call UartDebug.txState(state);
    numBackoff++;
    if (numBackoff > CSMA_BACKOFF_LIMIT) {
      txMsgDone(FAIL);  // signal Tx fail
      signal MacActivity.radioDone(FAIL);
    } else {  // can still retry
      checkActivity(FAIL);  // check if I can resend now
    }
    return SUCCESS;
  }
  
  
  async event result_t CarrierSense.channelIdle()
  {
    // physical carrier sense indicate channel idle, send now
    
    result_t result;
    if (state != CARR_SENSE) return FAIL;
    call UartDebug.txEvent(CHANNEL_IDLE_DETECTED);
    numCsFailures = 0;  // clear CS failure count
    atomic {
      if (txPktState == BUFFERED) {
        txPktState = SENDING;
        result = SUCCESS;
      } else {
        result = FAIL;  // Tx is cancelled after carrier sense starts
      }
    }
    if (result == FAIL) {
      state = IDLE;
      return result;
    }
    // now continue sending
    if (howToSend == BCAST_DATA_PKT) {
      sendBcast();
    } else if (howToSend == RTS_PKT) {
      sendRTS();
    } else if (howToSend == UCAST_DATA_PKT) {
      sendUcast(addPreambleLen);
    }
    return SUCCESS;
  }
  
  
  async event result_t CarrierSense.channelBusy()
  {
    // physical carrier sense indicate channel busy
    
    if (state != CARR_SENSE) return FAIL;
    call UartDebug.txEvent(CHANNEL_BUSY_DETECTED);
    state = BACKOFF;  // try to detect start symbol
   
    call BackoffTimer.start(TIMER_ONE_SHOT, backoffTime);
    call UartDebug.txState(state);
    numCsFailures++;  // increment CS failure count
    if (numCsFailures > (contWinSize << 2)) {
      post reportStarvation();  // ask radio be more aggressive
    }
    return SUCCESS;
  }


  task void reportStarvation()
  {
    // report starvation on Tx, so that radio will become more aggressive
    call CsThreshold.starved();
    numCsFailures = 0;  // clear CS failure count to try new threshold
  }
  
  
  async event result_t PhyNotify.startSymSent(void* pkt)
  {
    // can be used to put timestamp on outgoing pkt
    call UartDebug.txEvent(START_SYMBOL_SENT);
    return SUCCESS;
  }
  
  
  async event result_t PhyNotify.startSymDetected(void* pkt, uint8_t bitOffset)
  {
    // start symbol is detected
    // this event is signalled asynchronously within interrupt handler
    
    call UartDebug.txEvent(START_SYMBOL_DETECTED);
    if (state == BACKOFF) {
      call BackoffTimer.stop();  // stop backoff timer
    }
    if (state == IDLE || state == CARR_SENSE || state == BACKOFF) {       
      state = RECEIVE;
      call UartDebug.txState(state);
    }
    return SUCCESS;
  }


  event void* PhyPkt.receiveDone(void* packet, uint8_t error)
  {
    uint8_t pktType;
    
    if (packet == NULL || error) {  // received an erroneous pkt, a sign of collision
/*
#ifdef CSMA_SNOOPER_DEBUG
      if (packet == NULL) numLenErr++;
      else numCrcErr++;
#endif
*/    if (error == PKT_ERROR_TONE_RECV) {
        // ignore the tone packet so as to avoid affecting state machine at the upper layers. 
        // MicaZ radio reports receiveDone event for each tone (packet) received. 
        return packet;
      }
      handleErrPkt();
      return packet;
    }
    pktType = (*((uint8_t*)packet + sizeof(PhyHeader))) >> 4;
    // dispatch to actual packet handlers
    if (pktType == BCAST_DATA_PKT) {
      return handleBcastData(packet);
    } else if (pktType == UCAST_DATA_PKT) {
      return handleUcastData(packet);
    } else if (pktType == RTS_PKT) {
      handleRTS(packet);
    } else if (pktType == CTS_PKT) {
      handleCTS(packet);
    } else if (pktType == ACK_PKT) {
      handleACK(packet);
    } else {  // unknown packet
      call UartDebug.txEvent(RX_UNKNOWN_PKT);
      handleErrPkt();
    }
    return packet;
  }
  
  
  void handleErrPkt()
  {
    // an erronous packet is received
    
    call UartDebug.txEvent(RX_MSG_ERROR);
    if (state == RECEIVE) {
      state = IDLE;
      call UartDebug.txState(state);
      checkActivity(FAIL);  // check if upper layer want me to send now
    }
  }
  
   
  void* handleBcastData(void* pkt)
  {
    // internal handler for broadcast data packet
    void* tmp;
    CsmaHeader* packet = (CsmaHeader*)pkt;
    call UartDebug.txByte(RX_BCAST_DONE); 
    call UartDebug.txEvent(RX_BCAST_DONE);
    call Leds.greenToggle();
    state = IDLE;
    call UartDebug.txState(state);
    tmp = signal MacMsg.receiveDone(packet);
    checkActivity(SUCCESS);  // check if upper layer want me to send now
    return tmp;
  }
  
  
  void handleRTS(void* pkt)
  {
    // internal handler for RTS
    
    RTSPkt* packet;
    if (state != RECEIVE) return; // ignore pkt if not in receive state
    packet = (RTSPkt*)pkt;
    if (packet->toAddr == TOS_LOCAL_ADDRESS) {
      call UartDebug.txByte(RX_RTS_DONE);
      call UartDebug.txEvent(RX_RTS_DONE);
      recvAddr = packet->fromAddr;  // remember sender's address
      updNeighbNav(packet->duration); // track neighbors' NAV
      // reply with CTS
      sendCTS();
    } else { // packet destined to another node
      call UartDebug.txEvent(RX_RTS_OTHERS);
      state = IDLE;
      call UartDebug.txState(state);
      updateNav(packet->duration);
    }
  }
		

  void handleCTS(void* pkt)
  {
    // internal handler for CTS
    
    CTSPkt* packet;
    packet = (CTSPkt*)pkt;

    if (packet->toAddr == TOS_LOCAL_ADDRESS) {
      call UartDebug.txByte(RX_CTS_DONE);
      call UartDebug.txEvent(RX_CTS_DONE);
      if (state == WAIT_CTS) {
        // send DATA now
        sendUcast(0);  // use base preamble if RTS/CTS is used
//        state = TX_PKT;
//        call UartDebug.txState(state);
      } else {
        handleErrPkt();
      }
    } else { // packet destined to another node
      call UartDebug.txEvent(RX_CTS_OTHERS);
//      if (state == RECEIVE) {
        state = IDLE;
        call UartDebug.txState(state);
        updateNav(packet->duration);
//      }
    }
  }
  
  
  void* handleUcastData(void* pkt)
  {
    // internal handler for unicast data packet
    
    void* tmp;
    CsmaHeader* packet = (CsmaHeader*)pkt;
    
    if (packet->toAddr == TOS_LOCAL_ADDRESS) {  // unicast to me
      // could receive data in receive and wait_data state
      
      call UartDebug.txEvent(RX_UCAST_DONE);
      if (state == RECEIVE || state == WAIT_DATA) {
        // track neighbors' NAV, for the following ACK
        updNeighbNav(TIME_WAIT_ACK);
        recvAddr = packet->fromAddr;  // remember sender's address
        // reply with ACK
        sendACK();
//        state = TX_PKT;
//       call UartDebug.txState(state);
        call Leds.greenToggle();
        tmp = signal MacMsg.receiveDone(packet);
        return tmp;
      }
    } else { // unicast packet destined to another node
      call UartDebug.txEvent(RX_UCAST_OTHERS);
//      if (state == RECEIVE) {
        state = IDLE;
        call UartDebug.txState(state);
        updateNav(TIME_WAIT_ACK);
//      }
    }
    return pkt;
  }
  
  
  void handleACK(void* pkt)
  {
    // internal handler for ACK packet
    
    ACKPkt* packet;
    packet = (ACKPkt*)pkt;
    if (packet->toAddr == TOS_LOCAL_ADDRESS) {  // ACK to me
      call UartDebug.txByte(RX_ACK_DONE);
      call UartDebug.txEvent(RX_ACK_DONE);
      if (state == WAIT_ACK) {
        state = IDLE;
        call UartDebug.txState(state);
        txMsgDone(SUCCESS);
      } else {
        handleErrPkt();
      }
    } else { // packet destined to another node
      call UartDebug.txEvent(RX_ACK_OTHERS);
      handleErrPkt();  //CHECK later
    }
  }
  
  
  event void PhyStreamByte.rxDone(uint8_t* buffer, uint8_t byteIdx)
  {
    // PHY streams each byte before the whole packet is received

#ifndef CSMA_ENABLE_OVERHEARING
    // overhearing avoidance after receiving headers of unicast pkt
    uint8_t tmp;
    uint32_t txTimeTmp;
    CsmaHeader* recvHdr;
    if (byteIdx == sizeof(CsmaHeader) - 1) {
      // the whole header is received
      recvHdr = (CsmaHeader*)buffer;
      tmp = (*(buffer + sizeof(PhyHeader))) >> 4;  // pkt type
      if (tmp == UCAST_DATA_PKT && 
         recvHdr->toAddr != TOS_LOCAL_ADDRESS) { // unicast destined to others
        call UartDebug.txEvent(RX_UCAST_OTHERS);
        if (state == RECEIVE) {
          state = IDLE;
          call UartDebug.txState(state);
          tmp = recvHdr->phyHdr.length;  // pkt length
          txTimeTmp = (uint32_t)(tmp - sizeof(CsmaHeader)) * 
              PHY_TX_BYTE_TIME / 1000 + 1;
          // update NAV and sleep
          updateNav(txTimeTmp + TIME_WAIT_ACK);
        }
      }
    }
#endif
  }
    
  
  command result_t MacActivity.reSend()
  {
    // resend a previously buffered packet
    
    if (txPktState != BUFFERED) return FAIL;
    return tryToSend();
  }
  
  
  default event void MacActivity.radioDone(result_t result)
  {
    // default do-nothing handler
  }
  
  
  default event void MacActivity.virtualCSBusy()
  {
    // default do-nothing handler
  }
  
  
  default event void MacActivity.virtualCSIdle()
  {
    // default do-nothing handler
  }
  
}  // end of implementation
