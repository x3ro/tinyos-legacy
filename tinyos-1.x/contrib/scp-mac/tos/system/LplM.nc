/* (C) 2005 the University of Southern California.
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
 * This module implements CSMA with low power listening (LPL)
 */


module LplM
{
  provides {
    interface StdControl;
    interface MacMsg;
    interface LplControl;
    interface MacActivity as LplActivity;
    interface LplPollTimer;
  }
  uses {
    interface StdControl as CsmaStdControl;
    interface MacMsg as CsmaMacMsg;
    interface CsmaControl;
    interface MacActivity as CsmaActivity;
    interface RadioState;
    interface CarrierSense;
    interface PhyNotify;
    interface GetSetU32 as LocalTime;
    interface TimerAsync as PollTimer;
    interface Timer as WaitTimer;
    interface Leds;
    interface UartDebug;
  }
}

implementation
{

#include "StdReturn.h"
#include "LplConst.h"
#include "lplEvents.h"

// LPL constants
// maximum pkt transmission time, used for receive timer
#define MAX_BASE_PKT_LEN (PHY_BASE_PRE_BYTES + PHY_MAX_PKT_LEN)
// maximum radio active time -- for wait/protection timer
#define MAX_BASE_PKT_TIME ((uint32_t)MAX_BASE_PKT_LEN * PHY_TX_BYTE_TIME / 1000 + 1)
#define MAX_PKT_EXCHANGE_TIME (CSMA_RTS_DURATION + CSMA_CTS_DURATION \
        + MAX_BASE_PKT_TIME + CSMA_ACK_DURATION + CSMA_PROCESSING_DELAY * 4 + 3)

  // LPL states
  enum {
//    SLEEP,
    IDLE,
    POLL_CHANNEL
  };

  // state variables
  uint8_t state;  // LPL state

  // Variables for Tx
  bool pollEnabled;  // if channel polling is enabled
  bool sleepEnabled;  // if radio sleeping is enabled
  bool autoReTx;   // automatically re-send a buffered packet
  bool virtualCsIdle; // if virtual carrier sense indicates idle
  bool txBuffered;  // if I have buffered a msg to send
  bool txStarted;  // if I have started Tx (i.e., pass it to CSMA)
  bool backoffRepeat;   // if repeated backoff is enabled
  uint8_t txPktLen;
  uint16_t sendAddr;
  uint32_t backoffTime;  // wait for start symbol
  uint8_t contWinSize;  // contention window size
  uint16_t maxWaitTime; // time to wait between packets
  void* dataPkt;  // pointer to data packet to be sent
  uint8_t togglePin;

  // function prototypes
  result_t tryToSleep();
  task void startWaitTimer();


  command result_t StdControl.init()
  {
    // initialize LPL and lower level components

    state = IDLE;
    pollEnabled = TRUE;
    sleepEnabled = TRUE;
    autoReTx = TRUE;
    virtualCsIdle = TRUE;
    txBuffered = FALSE;
    txStarted = FALSE;
    backoffRepeat = TRUE;
    contWinSize = CSMA_CONT_WIN;  // CSMA contention window size
    maxWaitTime = ((PHY_CS_SAMPLE_INTERVAL * (contWinSize + 1)) / 1000) + 2;

    // maximum time needed to wait for a start symbol
    // also used to set CSMA backoff time
    backoffTime = (uint32_t)PHY_BASE_PRE_BYTES * PHY_TX_BYTE_TIME / 1000 + 1
                 + LPL_POLL_PERIOD + 3;
    togglePin = 1;

    call CsmaStdControl.init();  // initialize physical layer
    call Leds.init();  // initialize LEDs

    // Mica2 radio seems sensitive to power supply. With 3V DC power adapter
    // and the old programming board, the radio sometimes can't be correctly
    // initialized (most of time, it can receive but can't transmit).
    // initialize UART debugging
    call UartDebug.init();  // initialize UART debugging

    return SUCCESS;
  }


  command result_t StdControl.start()
  {
    // start MAC and lower-level components

    uint16_t preamble;  // used to wake up a sleeping node

    call CsmaStdControl.start();  // start CSMA
    // start LPL from fully active mode
    preamble = (uint16_t)((uint32_t)LPL_POLL_PERIOD * 1000 /
              PHY_TX_BYTE_TIME) + 1;
    call CsmaControl.addPreamble(preamble);  // set CSMA's preamble
    call CsmaControl.setBackoffTime(backoffTime); // set CSMA backoff time
  
    call PollTimer.start(TIMER_REPEAT, LPL_POLL_PERIOD);
     // wait for clock to stablize before sleep
  
    call WaitTimer.start(TIMER_ONE_SHOT, 10);
    call UartDebug.txEvent(WAIT_TIMER_STARTED);
    return SUCCESS;
  }


  command result_t StdControl.stop()
  {
    // stop clock and PHY, but states are cleared when start again
    call CsmaStdControl.stop();  // stop physical layer
    call PollTimer.stop(); // stop timer
    state = IDLE;
    call UartDebug.txState(state);
    return SUCCESS;
  }


  command result_t MacMsg.send(void* msg, uint8_t length, uint16_t toAddr)
  {
    // standard command to send a message

    uint8_t result;

   
    // sanity check
    if (msg == 0 || length == 0 || length > PHY_MAX_PKT_LEN) {
      call UartDebug.txEvent(TX_REQUEST_REJECTED_MSG_ERROR);
      return FAIL;
    }
    // Don't accept Tx request if I have already accepted a request
    atomic {
      if (txBuffered == FALSE) {
        txBuffered = TRUE;
        result = 1;
      } else {
        result = 0;
      }
    }
    if (result == 0) {
      call UartDebug.txEvent(TX_REQUEST_REJECTED_NO_BUFFER);
      return FAIL;
    }

    call UartDebug.txEvent(TX_REQUEST_ACCEPTED);
    dataPkt = msg;
    txPktLen = length;
    sendAddr = toAddr;
    txStarted = FALSE;

    if (state == IDLE) {
      // pass to CSMA directly
      if (call CsmaMacMsg.send(msg, length, toAddr)) {
        txStarted = TRUE;
      }
    }

    return SUCCESS;
  }


  command result_t MacMsg.sendCancel(void* msg)
  {
    // cancel a message to be sent (i.e., previously called MacMsg.send)

    result_t result;
    if (msg != dataPkt) return FAIL;
    atomic {
      if (txBuffered && !txStarted) {
        txBuffered = FALSE;
        result = SUCCESS;
      } else {
        result = FAIL;
      }
    }
    if (result == SUCCESS) {
      return result;
    } else {
      return call CsmaMacMsg.sendCancel(msg);
    }
  }


  event void CsmaMacMsg.sendDone(void* msg, result_t result)
  {
    // message transmission is done by CSMA

    txStarted = FALSE;
    txBuffered = FALSE;
    call Leds.redToggle();
    call UartDebug.txEvent(TX_MSG_DONE);
    signal MacMsg.sendDone(msg, result);
  }


  event void* CsmaMacMsg.receiveDone(void* msg)
  {
    // CSMA received a message

    void* tmp;
//    call WaitTimer.stop();  // stop receive timer
    call Leds.greenToggle();
    call UartDebug.txEvent(RX_MSG_DONE);
    tmp = signal MacMsg.receiveDone(msg);
    return tmp;
  }


  command void LplControl.enablePolling()
  {
    // enable regular, periodic channel polling

    pollEnabled = TRUE;
    call UartDebug.txEvent(POLL_CHANNEL_ENABLED);
  }


  command void LplControl.disablePolling()
  {
    // temporarily disable channel polling; will not stop poll timer

    pollEnabled = FALSE;
    call UartDebug.txEvent(POLL_CHANNEL_DISABLED);
  }


  command result_t LplControl.pollChannel()
  {
    // poll channel for possible activity now

    uint8_t result;
     
    if ((call RadioState.get() != RADIO_SLEEP) && sleepEnabled) { // radio is busy
      call UartDebug.txEvent(POLL_CHANNEL_FAIL_NOT_SLEEP);
      if (call WaitTimer.getRemainingTime() == 0) {
     
        call WaitTimer.start(TIMER_ONE_SHOT, backoffTime + MAX_PKT_EXCHANGE_TIME);
        call UartDebug.txEvent(WAIT_TIMER_STARTED);
      }
      return FAIL;
    }
    // turn on radio
    result = call RadioState.idle();
    if (result == FAILURE) {
      call UartDebug.txEvent(POLL_CHANNEL_FAIL_WAKEUP_RADIO);
      return FAIL;
    }
    // turn on radio successful, but may not be stable now
    state = POLL_CHANNEL;
    call Leds.yellowOn();
    call UartDebug.txState(state);
    if (result == SUCCESS_DONE) {  // radio is stable now
      call UartDebug.txEvent(START_CARRIER_SENSE);
      if (!call CarrierSense.start(1)) {
        state = IDLE;
        call UartDebug.txState(state);
      }
    }
    return SUCCESS;
  }


  command void LplControl.addPreamble(uint16_t length)
  {
    // set preamble length to wake up a node (not including base preamble)

    call CsmaControl.addPreamble(length);  // set CSMA's preamble
  }


  command void LplControl.setContWin(uint8_t numSlots)
  {
    // set CSMA contention window

    contWinSize = numSlots;
    maxWaitTime = ((PHY_CS_SAMPLE_INTERVAL * (contWinSize + 1)) / 1000) + 2;
    call CsmaControl.setContWin(contWinSize);
  }


  command void LplControl.setBackoffTime(uint32_t time, bool repeat)
  {
    // set backoff time when carrier sense fails

    backoffTime = time;
    backoffRepeat = repeat;
    call CsmaControl.setBackoffTime(backoffTime);
  }


  command void LplControl.disableAutoReTx()
  {
    // disable automatic re-send after previous attempt fails

    autoReTx = FALSE;
    call CsmaControl.disableAutoReTx();
  }

  command void LplControl.enableAutoReTx()
  {
    // enable automatic re-send after previous attempt fails

    autoReTx = TRUE;
    call CsmaControl.enableAutoReTx();
  }




  command void LplControl.disableSleeping()
  {
    // disable periodic radio sleeping
    // in this mode, node will do idle listening, 
    // but Tx still uses long preambles
    sleepEnabled = FALSE;
  }

  command void LplControl.enableSleeping()
  {
    // enable periodic radio sleeping
    // this is normal LPL mode
    sleepEnabled = TRUE;
  }

  command result_t LplPollTimer.start(uint16_t period)
  {
    // start the channel polling timer
   
    return call PollTimer.start(TIMER_REPEAT, (uint32_t)period);
  }


  command result_t LplPollTimer.stop()
  {
    // stop the channel polling timer

    return call PollTimer.stop();
  }


  command uint16_t LplPollTimer.get()
  {
    // get current poll timer value
    volatile uint16_t time;
    time = (uint16_t)call PollTimer.getRemainingTime();
    //call UartDebug.txByte((uint8_t)(time & 0xff));
    //call UartDebug.txByte((uint8_t)((time >> 8) & 0xff));
    return time;

//    return call PollTimer.getRemainingTime();
  }


  command result_t LplPollTimer.set(uint16_t time)
  {
    // set the remaining time of poll timer
    return call PollTimer.setRemainingTime((uint32_t)time);
  }


  default async event result_t LplPollTimer.fired()
  {
    // default do-nothing handler
    return SUCCESS;
  }


  event void CsmaActivity.radioDone(result_t result)
  {
    // CSMA is done with radio for packet Tx or Rx
    // if result is SUCCESS, can start adaptive listen; otherwise sleep

    call UartDebug.txEvent(CSMA_RADIO_DONE);
#ifdef LPL_EXTEND_RECEIVE_TIME
    if (call WaitTimer.getRemainingTime() == 0){
    
      call WaitTimer.start(TIMER_ONE_SHOT, maxWaitTime);
    } else {
     
      call WaitTimer.setRemainingTime(maxWaitTime);
    }
#else
    
    tryToSleep();  // sleep if I have nothing to send
    signal LplActivity.radioDone(result);
#endif
  }


  event void CsmaActivity.virtualCSBusy()
  {
    // virtual carrier sense is busy now (NAV timer started)

    virtualCsIdle = FALSE;
//    call WaitTimer.stop();  // will wait for idle signal
    call UartDebug.txEvent(VIRTUAL_CS_BUSY);
    signal LplActivity.virtualCSBusy();
  }


  event void CsmaActivity.virtualCSIdle()
  {
    // virtual carrier sense is idle now (NAV timer fired)

    virtualCsIdle = TRUE;
    
    tryToSleep();  // sleep if I have nothing to send
    call UartDebug.txEvent(VIRTUAL_CS_IDLE);
    signal LplActivity.virtualCSIdle();
  }


  result_t tryToSleep()
  {
    // check Tx status and change state accordingly

    state = IDLE;  // LPL goes back to idle
    call UartDebug.txState(state);
    if (txBuffered && autoReTx) {  // can't turn off radio
      call UartDebug.txEvent(TRY_TO_SLEEP_FAILED);
      if (!txStarted) {  // start sending now
        call CsmaMacMsg.send(dataPkt, txPktLen, sendAddr);
        txStarted = TRUE;
      }
      return FAIL;  // failed to sleep
    } else {
      if (!sleepEnabled) return FAIL;  // sleeping is disabled
      // now actually put radio into sleep state
      call WaitTimer.stop();
      call RadioState.sleep();
      call Leds.yellowOff();
      call UartDebug.txEvent(SET_RADIO_SLEEP);
      return SUCCESS;  // successfully sleep
    }
  }


  async event result_t PollTimer.fired()
  {
    // time to wake up and poll channel activity
    call UartDebug.txEvent(POLL_TIMER_FIRED);
    if (pollEnabled && virtualCsIdle) {
      call LplControl.pollChannel();
    } else {
      if (!pollEnabled)
        call UartDebug.txEvent(POLL_CHANNEL_FAIL_NOT_ENABLED);
      if (!virtualCsIdle)
        call UartDebug.txEvent(POLL_CHANNEL_FAIL_VIRTUAL_CS);
    }
    // relay timer event
    signal LplPollTimer.fired();
    return SUCCESS;
  }


  async event result_t RadioState.wakeupDone()
  {
    // radio wakeup is done -- it becomes stable now

    // only wake up radio for polling channel
    if (state == POLL_CHANNEL) {
      call UartDebug.txEvent(START_CARRIER_SENSE);
      if (!call CarrierSense.start(1)) {  // check channel activity
        state = IDLE;
        call UartDebug.txState(state);
      }
    }
    return SUCCESS;
  }


  async event result_t CarrierSense.channelIdle()
  {
    // physical carrier sense indicate channel idle

    if (state != POLL_CHANNEL) return FAIL;
    call UartDebug.txEvent(CHANNEL_IDLE_DETECTED);
    // poll channle didn't find activity
    
    tryToSleep();  // check Tx status before sleep
    return SUCCESS;
  }


  async event result_t CarrierSense.channelBusy()
  {
    // physical carrier sense indicate channel busy

    //    if (state != POLL_CHANNEL) return FAIL;
    call UartDebug.txEvent(CHANNEL_BUSY_DETECTED);
    // poll channel found activity, stay awake to receive
    state = IDLE;  // don't turn off radio
    call UartDebug.txState(state);
    // set timer to wait for start symbol
//    call WaitTimer.start(TIMER_ONE_SHOT, backoffTime);
    if (call WaitTimer.getRemainingTime() == 0) {
     
      call WaitTimer.start(TIMER_ONE_SHOT, backoffTime);
    } else {
     
      call WaitTimer.setRemainingTime(backoffTime);
    }
    call UartDebug.txEvent(WAIT_TIMER_STARTED);
    return SUCCESS;
  }


  async event result_t PhyNotify.startSymSent(void* packet)
  {
    // just sent out start symbol of a packet

    return SUCCESS;
  }


  async event result_t PhyNotify.startSymDetected(void* packet, uint8_t bitOffset)
  {
    // just received a start symbol, must be in idle state

    call UartDebug.txEvent(START_SYMBOL_DETECTED);
    if (call WaitTimer.getRemainingTime() == 0) {
     
      call WaitTimer.start(TIMER_ONE_SHOT, MAX_PKT_EXCHANGE_TIME);
    } else {
     
      call WaitTimer.setRemainingTime(MAX_PKT_EXCHANGE_TIME);
    }
    call UartDebug.txEvent(WAIT_TIMER_STARTED);
    return SUCCESS;
  }

  event result_t WaitTimer.fired()
  {
    // can't receive start symbol or packet after waiting

    call UartDebug.txEvent(WAIT_TIMER_FIRED);
    if (state != IDLE) return FAIL;
    
    tryToSleep();
/*
    if (backoffRepeat) {  // repeated backoff is enabled
      // confirm channel idle before go to sleep
      state = POLL_CHANNEL;
      call UartDebug.txState(state);
      call CarrierSense.start(1);
    } else {
      tryToSleep();
    }
*/
    return SUCCESS;
  }


  command result_t LplActivity.reSend()
  {
    // resend a previously buffered packet

    if (!txBuffered) return FAIL;
    if (state == POLL_CHANNEL) return FAIL;
    call UartDebug.txEvent(RESEND_REQUESTED);
    if (!txStarted) {  // start sending now
      call CsmaMacMsg.send(dataPkt, txPktLen, sendAddr);
      txStarted = TRUE;
      return SUCCESS;
    } else {
      return call CsmaActivity.reSend();
    }
  }


  default event void LplActivity.virtualCSBusy()
  {
    // default do-nothing handler
  }


  default event void LplActivity.virtualCSIdle()
  {
    // default do-nothing handler
  }


  default event void LplActivity.radioDone(result_t result)
  {
    // default do-nothing handler
  }

}  // end of implementation
