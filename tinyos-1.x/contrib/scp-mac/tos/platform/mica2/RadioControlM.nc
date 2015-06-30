/*
 * Copyright (C) 2003-2005 the University of Southern California.
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
/* Authors: Wei Ye, Honghui Chen
 *
 * This module implements the radio control functions:
 *   1) Put radio into different states:
 *   	a) idle; b) sleep; c) receive; d) transmit
 *   2) Start symbol detection in idle state
 *      (Partially based on CC1000RadioM.nc)
 *   3) Physical carrier sense
 */

module RadioControlM
{
   provides {
      interface StdControl as RadControl;
      interface RadioState;
      interface CarrierSense;
      interface CsThreshold;
      interface RadioByte;
      interface TxPreamble;
      interface GetSetU8 as RadioTxPower;
      interface RSSISample;
      interface RadioEnergy;
   }
   uses {
      interface StdControl as CC1000StdControl;
      interface CC1000Control;
      interface ADCControl;
      interface ADC as RSSIADC;
      interface TimerAsync as WakeupTimer;
      interface PowerManagement;
      interface GetSetU32 as LocalTime;
   }
}

implementation
{
#include "PhyConst.h"
#include "StdReturn.h"

// carrier sense threshold that determines a busy channel

  enum {
    RADIO_BUSY_THRESHOLD = 0xb0,  // definitely busy above this level
    RADIO_NOISE_LEVEL = 0x160  // initial noise level before any Rx
  };

  uint8_t start[2] __attribute((C)) = {0x33, 0xcc};

  // radio control states. INIT is a temperary state only at start up
  // these states are used internally by this component
  enum { INIT, SLEEP, IDLE, SYNC_START, RECEIVE, TRANSMIT };
  
  // Tx type
  enum { PREAMBLE_ONLY, PACKET };
  
  uint8_t state;        // state of radio control componet, used internally
  uint8_t radioState;   // radio hardware state, for use by other components
  uint8_t stateLock;    // lock for state transition
  uint16_t carrSenTime; // carrier sense time
  uint8_t extFlag;      // carrier sense extension flag
  uint8_t nextByte;     // tx buffer
  uint16_t preambleLen; // preamble length for current tx packet
  uint16_t txCount;      // for start symbol tx
  uint8_t txType;       // tx packet or just preamble
  uint16_t minSignal;   // measured minimum signal strength
  uint16_t avgSignal;   // measured average signal strength
  uint16_t noiseLevel;  // measured average noise level
  uint8_t measureRSSI;  // flag indicating RSSI measurement
  uint16_t valueRSSI;   // RSSI value
  uint16_t extCsVal;    // extended carrier sense sample
  bool updThreshEnabled; // if updating carrier sense threshold is enabled

  bool bManchesterBad;
  bool bInvertRxData;	// data inverted
  
  enum {
    //SYNC_BYTE = 0x33,
    //NSYNC_BYTE = 0xcc,
    SYNC_WORD = 0x33cc,
    NSYNC_WORD = 0xcc33
  };

  uint8_t PreambleCount;  //  found a valid preamble
  uint8_t SOFCount;
  union {
    uint16_t W;
    struct {
      uint8_t LSB;
      uint8_t MSB;
    };
  } RxShiftBuf;
  uint8_t RxBitOffset;	// bit offset for SPI bus
  uint16_t preambleLen;
  uint16_t LocalAddr;
   
#ifdef RADIO_MEASURE_ENERGY
  bool measureEnergy;  // energy measurement flag
  uint8_t lastRadioState;  // last radio state
  uint32_t lastUpdateTime;  // last time to update energy
  RadioTime radioTime;  // time the radio in different states
#endif

  // function prototypes
  static inline result_t lockAcquire(uint8_t* lock);
  static inline void lockRelease(uint8_t* lock);
  void wakeupRadio();
  void setRadioRx();
  void prepareTx();
  void startSend();
  void prepareRx();
  void updateEnergy();
 
  // functions for using locks
  static inline result_t lockAcquire(uint8_t* lock)
  {
    result_t tmp;
    atomic {
      if (*lock == 0) {
        *lock = 1;
        tmp = SUCCESS;
      } else {
        tmp = FAIL;
      }
    }
    return tmp;
  }
  
  static inline void lockRelease(uint8_t* lock)
  {
    *lock = 0;
  }
  
  
  command result_t RadControl.init()
  {
    // initialize the radio
      
    state = INIT;
    LocalAddr = TOS_LOCAL_ADDRESS;

    avgSignal = RADIO_BUSY_THRESHOLD;
    minSignal = RADIO_BUSY_THRESHOLD;
    noiseLevel = RADIO_NOISE_LEVEL;
    updThreshEnabled = TRUE;
    
    call ADCControl.bindPort(TOS_ADC_CC_RSSI_PORT,TOSH_ACTUAL_CC_RSSI_PORT);
    call ADCControl.init();

    call CC1000StdControl.init();
    call CC1000Control.SelectLock(0x9); // Select MANCHESTER VIOLATION
    bInvertRxData = call CC1000Control.GetLOStatus(); //if need to invert Rcvd Data

    // set SPI clock pin as input -- clock provided by radio
    TOSH_MAKE_SPI_SCK_INPUT();
    
#ifndef DISABLE_CPU_SLEEP
    call PowerManagement.enable(); // enable CPU sleep mode
#endif
#ifdef RADIO_MEASURE_ENERGY
    measureEnergy = FALSE;
#endif
    call RadioState.idle();
    return SUCCESS;
  }
   
   
  command result_t RadControl.start()
  {
    // start radio -- go to idle state
    call RadioState.idle();
    return SUCCESS;
  }
   
   
  command result_t RadControl.stop()
  {
    // turn off radio
    outp(0x00, SPCR);  // turn off SPI
    call CC1000StdControl.stop();
    state = SLEEP;
    radioState = RADIO_SLEEP;
    updateEnergy();
    lockRelease(&stateLock); // clear state lock
    call PowerManagement.adjustPower();
    return SUCCESS;
  }


  void wakeupRadio()
  {
    // wake up radio from sleep
    // when this function is called, the radio will not immediately wake up
    // we have to wait until the WakeupTimer fires for radio to be stable
    call WakeupTimer.start(TIMER_ONE_SHOT, PHY_WAKEUP_DELAY);
    call CC1000StdControl.start();
    call CC1000Control.BIASOn();
//    call WakeupTimer.start(TIMER_ONE_SHOT, PHY_WAKEUP_DELAY);
    call PowerManagement.adjustPower();
  }

  void setRadioRx()
  {
    // set radio into Rx mode
    call CC1000Control.RxMode(); //set radio to Rx mode
    // configure SPI for input
    TOSH_MAKE_MISO_INPUT();
    TOSH_MAKE_MOSI_INPUT();
    outp(0xc0, SPCR);  // start SPI and enable SPI interrupt
  }
      
   
  // set radio into idle state. Automatically detect start symbol
  command int8_t RadioState.idle()
  {
    // set radio into idle state. Automatically detect start symbol
      
    if (state == IDLE) return SUCCESS_DONE;
    if (!lockAcquire(&stateLock)) return FAILURE; // in state transition
    // clear state variables
    PreambleCount = 0;
    SOFCount = 0;
    RxBitOffset = 0;
    RxShiftBuf.W = 0;
    carrSenTime = 0;
    if (state == SYNC_START) {
       state = IDLE;
       radioState = RADIO_IDLE;
       updateEnergy();
       lockRelease(&stateLock); // release state lock
       return SUCCESS_DONE;
    } else if (state == SLEEP) {  // wake up radio if in sleep state
       state = IDLE;
       radioState = RADIO_WAKEUP;
       updateEnergy();
       wakeupRadio();
       return SUCCESS_WAIT;  // wait for radio to be stable
    } else {  // Tx or Rx state
       cbi(SPCR, SPIE);       // disable SPI interrupt
       cbi(SPCR, SPE);   // disable SPI
       setRadioRx();  // put radio into Rx mode
       state = IDLE;
       radioState = RADIO_IDLE;
       updateEnergy();
       lockRelease(&stateLock); // release state lock
       return SUCCESS_DONE;
    }
  }
   
   
   // set radio into sleep mode: can't Tx or Rx
   command result_t RadioState.sleep()
   {
      if (state == SLEEP) return SUCCESS;
      if (!lockAcquire(&stateLock)) return FAIL; // in state transition
      call RadControl.stop();
      return SUCCESS;
   }


  command uint8_t RadioState.get()
  {
    // get current radio hardware state
    return radioState;
  }
  
  
  command result_t RadioByte.startTx(uint16_t addPreamble)
  {
    // start sending a new packet. Automatically send preamble first
    preambleLen = PHY_BASE_PREAMBLE_LEN + addPreamble;
    txType = PACKET;
    prepareTx();
    return SUCCESS;
  }
  
  
  void prepareTx()
  {
    // prepare for Tx -- wake up if in sleep mode
    
    if (!lockAcquire(&stateLock)) return; // in state transition
    cbi(SPCR, SPIE);  // disable SPI interrupt
    cbi(SPCR, SPE);   // disable SPI
    if (state == SLEEP) {  // wake up radio if in sleep state
      state = TRANSMIT;
      radioState = RADIO_WAKEUP;
      updateEnergy();
      wakeupRadio();  // will wait for radio to be stable
    } else {
      state = TRANSMIT;
      radioState = RADIO_TX;
      updateEnergy();
      startSend();
      lockRelease(&stateLock); // release state lock
    }
  }
    
  
  void startSend()
  {
    // start packet sending
    
    uint8_t temp;
    
    nextByte = 0xaa; // buffer second byte
    txCount = 2;
    temp = inp(SPSR);  // clear possible pending SPI interrupt
    outp(0xaa, SPDR);  // put first byte into SPI data register

    //set radio to Tx mode
    call CC1000Control.TxMode();      // radio to tx mode
    TOSH_MAKE_MISO_OUTPUT();
    TOSH_MAKE_MOSI_OUTPUT();
    outp(0xc0, SPCR);  // enable SPI and SPI interrupt
  }    
  
  
  command result_t RadioByte.txNextByte(uint8_t data)
  {
    // send next byte
    nextByte = data;
    return SUCCESS;
  }
  
  command result_t TxPreamble.preload(uint16_t length)
  {
    return SUCCESS;
  }

  command result_t TxPreamble.start(uint16_t length)
  {
    // send start symbol only -- can be used as a wakeup tone
    preambleLen = length;
    txType = PREAMBLE_ONLY;
    prepareTx();
    return SUCCESS;
  }
  
  
  default async event void TxPreamble.done()
  {
    // default do-nothing handler
  }
  
  
  async event result_t WakeupTimer.fired()
  {
    // now radio wakup is done, radio becomes stable
    if (state == IDLE) {
      setRadioRx();  // put radio into Rx mode
      radioState = RADIO_IDLE;
      updateEnergy();
      lockRelease(&stateLock); // release state lock
      signal RadioState.wakeupDone();
    } else if (state == TRANSMIT) {
      startSend();
      radioState = RADIO_TX;
      updateEnergy();
      lockRelease(&stateLock); // release state lock
    }
    return SUCCESS;
  }


  default async event result_t RadioState.wakeupDone()
  {
    return SUCCESS;
  }
  

  command result_t CarrierSense.start(uint16_t numSamples)
  {
    // start carrier sense
    if ((state != IDLE && state != SYNC_START) || numSamples == 0) 
      return FAIL;
    extFlag = 0;
    carrSenTime = numSamples;
    call RSSIADC.getData(); // take sample immediately
    return SUCCESS;
  }
	
  
  default async event result_t CarrierSense.channelIdle()
  {
    // default do-nothing handler for carrier sense
    return SUCCESS;
  }


  default async event result_t CarrierSense.channelBusy()
  {
    return SUCCESS;
  }
   
   
  command result_t RSSISample.get()
  {
    // get a sample of RSSI
    valueRSSI = 0;
    measureRSSI = 1;
    call RSSIADC.getData();
    return SUCCESS;
  }
  
  
  command uint8_t RadioTxPower.get()
  {
    // get current radio Tx power
    return call CC1000Control.GetRFPower();
  }
  
  
  command result_t RadioTxPower.set(uint8_t level)
  {
    // set radio tx power
    return call CC1000Control.SetRFPower(level);
  }
  
  
//  inline void prepareRx()
  void prepareRx()
  {
    // start symbol is detected, prepare for receiving
    // this function is called within SPI interrupt handler, where
    // global interrupt is disabled
    
    if (carrSenTime > 0) {  // MAC is in Carrier Sense state
      carrSenTime = 0;  // stop carrier sense
      signal CarrierSense.channelBusy();
    }
    if (!stateLock) {  // radio state transition allowed
      if (signal RadioByte.startSymDetected(RxBitOffset)) {
        state = RECEIVE;
        radioState = RADIO_RX;
        updateEnergy();
      } else {
        call RadioState.idle();
      }
    }
  }
   
   
  // Interrupt handler for SPI
  // (called everytime a byte arrives from the radio).
  // The signal handler disables global interrupts by default.
  TOSH_SIGNAL(SIG_SPI)
  {
    uint8_t data;
    data = inp(SPDR);
    if (bInvertRxData) data = ~data;

    if (state == TRANSMIT) {
      outp(nextByte, SPDR);  // send buffered byte
      if (txCount < preambleLen) {
        nextByte = 0xaa;
      } else if (txCount < preambleLen + sizeof(start)) {
        nextByte = start[txCount - preambleLen];
        if (txCount == preambleLen + 1 && txType == PREAMBLE_ONLY) {
          // I was asked to only send preamble
          call RadioState.idle();  // go back to idle
          __nesc_enable_interrupt();
          signal TxPreamble.done();
        }
      } else {
        signal RadioByte.txByteReady(); // ask a byte from upper layer
        if (txCount == preambleLen + sizeof(start) + 1) {
          signal RadioByte.startSymSent(); // for outgoing timestamp
        }
      }
      txCount++;
    } else if (state == IDLE) {
      bManchesterBad = call CC1000Control.GetLock();
      if ((!bManchesterBad) && (data == 0xaa || data == 0x55)) {
        PreambleCount++;
        if (PreambleCount > PHY_VALID_PRECURSOR) {
          if (stateLock) return; // radio is in transition
          state = SYNC_START;
        }
      } else {
        PreambleCount = 0;
      }
      if (carrSenTime > 0) call RSSIADC.getData(); // carrier sense
    } else if (state == SYNC_START) {
      uint8_t i;
      if (data == 0xaa || data == 0x55) {
        SOFCount = 0;   // tolerate of additional preamble bytes
      } else {
        uint8_t usTmp;
        SOFCount++;
        switch (SOFCount) {
        case 1:
          RxShiftBuf.MSB = data;
          break;
        case 2:
          RxShiftBuf.LSB = data;
          if (RxShiftBuf.W == SYNC_WORD) {
            // start symbol detected, prepare for receiving
            RxBitOffset = 0;
            prepareRx();
          } 
          break;            
        case 3: 
          // bit shift the data into previous samples to find SOF
          usTmp = data;
          for(i=0;i<8;i++) {
            RxShiftBuf.W <<= 1;
            if(usTmp & 0x80)
              RxShiftBuf.W |= 0x1;
            usTmp <<= 1;
            // check for SOF bytes
            if (RxShiftBuf.W == SYNC_WORD) {
              // start symbol detected, prepare for receiving
              RxBitOffset = 7-i;
              RxShiftBuf.LSB = data;
              prepareRx();
              break;
            }
          }
          break;
        default:
          // We didn't find it after a reasonable number of tries
          call RadioState.idle();
          break;
        }
      }
      if (carrSenTime > 0) call RSSIADC.getData(); // carrier sense
    }else if (state == RECEIVE) {
      uint8_t Byte;
      RxShiftBuf.W <<=8;
      RxShiftBuf.LSB = data;
      Byte = (RxShiftBuf.W >> RxBitOffset);
      signal RadioByte.rxByteDone(Byte);
    }         
  }


  async event result_t RSSIADC.dataReady(uint16_t data)
  {
    // ADC got a sample of signal strength
    if (carrSenTime > 0) {
      carrSenTime--;
      if (carrSenTime > 0 && extFlag == 0) { // requested byte
        if (data <= minSignal) { // stronger than min signal
          carrSenTime = 0; // stop carrier sense
          signal CarrierSense.channelBusy();
        }
      } else if (carrSenTime == 0 && extFlag == 0) { // last requested byte
        if (data <= minSignal) { // stronger than min signal
          signal CarrierSense.channelBusy();
        } else if (data >= noiseLevel) { // weaker than average noise level
          updThreshEnabled = TRUE;
          signal CarrierSense.channelIdle();
        } else { // need to check a few more bytes
          extFlag = 1;  // set flag for extended bytes
          extCsVal = data;
          carrSenTime = PHY_MAX_CS_EXT;
        }
      } else if (extFlag == 1) { // extended byte
        if (data <= minSignal) { // stronger than min signal
          carrSenTime = 0; // stop carrier sense
          signal CarrierSense.channelBusy();
        } else if (data >= noiseLevel) { // weaker than average noise level
          carrSenTime = 0; // stop carrier sense
          updThreshEnabled = TRUE;
          signal CarrierSense.channelIdle();
        } else {  // can't decide with individual sample
          if (carrSenTime > 0) {
            // average on extended samples
            extCsVal = (extCsVal + data) >> 1;
          } else {
            // has to make dicision based on averaged extended bytes
            // use half line between minSignal and noiseLevel as threshold
            if (extCsVal <= ((minSignal + noiseLevel) >> 1)) {
              signal CarrierSense.channelBusy();
            } else {
              updThreshEnabled = TRUE;
              signal CarrierSense.channelIdle();
            }
          }
        }
      }
    }
    if (measureRSSI == 1) {  // measuring signal or noise level
      if (valueRSSI == 0) {
        valueRSSI = data;
        call RSSIADC.getData(); // get another sample
      } else {
        measureRSSI = 0;
        valueRSSI = (valueRSSI + data) >> 1; // average on two samples
        signal RSSISample.ready(valueRSSI);
      }
      
    }
    return SUCCESS;
  }
  
  
  command void CsThreshold.reset()
  {
    // reset carrier sense threshold to initial value
    
    avgSignal = RADIO_BUSY_THRESHOLD;
    minSignal = RADIO_BUSY_THRESHOLD;
    noiseLevel = RADIO_NOISE_LEVEL;
  }    
  
  
  command void CsThreshold.update(uint16_t signalVal, uint16_t noiseVal)
  {
    // update carrier sense threshold with new RSSI samples
    // it is required that ALL samples are taken when a packet is correctly 
    // received, i.e., it should be signaled by PhyRadio after CRC check
    
    if (noiseVal > minSignal) {  // exclude possible false positives
      // average noise level: new sample gets 0.25 weight
      noiseLevel = (noiseLevel >> 1) + ((noiseLevel + noiseVal) >> 2);
    }
    // average signal strength: new sample gets 0.25 weight
    avgSignal = (avgSignal >> 1) + ((avgSignal + signalVal) >> 2);
    if (updThreshEnabled && signalVal > minSignal) {
      minSignal = signalVal;   // busy threshold goes to minimum
      if (noiseLevel < minSignal) {  // noise is too high
        minSignal = noiseLevel;  // signal can't be lower than noise
      }
    }
  }
  
  
  command void CsThreshold.starved()
  {
    // when a node gets starved on Tx, minSignal will be raised to make
    // it more aggressive. Starvation is defined by MAC that uses carrier
    // sense, e.g., consecutive failures on randamized carrier sense
    
    if (minSignal <= RADIO_BUSY_THRESHOLD) return;
    if (avgSignal > RADIO_BUSY_THRESHOLD) {
      minSignal = (minSignal + avgSignal) >> 1;
    } else {
      minSignal = (minSignal + RADIO_BUSY_THRESHOLD) >> 1;
    }
    updThreshEnabled = FALSE;  // don't lower busy threshold during starvation
  }
  
  
  default async command uint8_t PowerManagement.adjustPower()
  {
    // default command if PowerManagement is not used
    return 1;
  }
  
  
  command result_t RadioEnergy.startMeasure()
  {
    // start measuring radio energy consumption
    // it clears all measurement variables
#ifdef RADIO_MEASURE_ENERGY
    lastUpdateTime = call LocalTime.get();
    lastRadioState = radioState;
    radioTime.sleepTime = 0;
    radioTime.wakeupTime = 0;
    radioTime.idleTime = 0;
    radioTime.rxTime = 0;
    radioTime.txTime = 0;
    measureEnergy = TRUE;
#endif
    return SUCCESS;
  }
  
  
  command result_t RadioEnergy.stopMeasure()
  {
    // stop measuring radio energy consumption
    // add the time since last update
#ifdef RADIO_MEASURE_ENERGY
    atomic{
      updateEnergy();
      measureEnergy = FALSE;
    }
#endif
    return SUCCESS;
  }
  
  
  command RadioTime* RadioEnergy.get()
  {
    // get energy measurement result
#ifdef RADIO_MEASURE_ENERGY
    updateEnergy();
    return &radioTime;
#else
    return NULL; // might cause problems if caller doesn't check return value
#endif
  }
  
  
  void updateEnergy()
  {
    // update radio energy after radio state changes
#ifdef RADIO_MEASURE_ENERGY
    uint32_t now, timeElapsed;
    if (!measureEnergy) return;
    now = call LocalTime.get();
    timeElapsed = now - lastUpdateTime;
    if (lastRadioState == RADIO_SLEEP) {
      radioTime.sleepTime += timeElapsed;
    } else if (lastRadioState == RADIO_WAKEUP) {
      radioTime.wakeupTime += timeElapsed;
    } else if (lastRadioState == RADIO_IDLE) {
      radioTime.idleTime +=  timeElapsed;
    } else if (lastRadioState == RADIO_RX) {
      radioTime.rxTime +=  timeElapsed;
    } else if (lastRadioState == RADIO_TX) {
      radioTime.txTime +=  timeElapsed;
    }
    lastRadioState = radioState;
    lastUpdateTime = now;
#endif
  }    

}  // end of implementation
