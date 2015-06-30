/*
 * Copyright (C) 2003-2006 the University of Southern California.
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
 * of this project by writing to USC/ISI, 4676 Admirality Way, Suite 
 * 1001, Marina del Rey, CA 90292, USA.
 */
/*
 * Authors: Wei Ye and Fabio Silva
 * 
 * This is the physical layer that sends and receives a packet,
 * providind the following interfaces:
 *
 *   - PhyPkt: sends and receives packets from the CC2420 Radio
 *   - PhyNotify: used for timestamping (signaling start of send/receive packets)
 *   - CarrierSense: used for detecting channel idle/busy
 *   - PhyState: used for sleeping/waking up the radio
 *   - PhyStreamByte: empty, only provided for compatibility with mica-2 code
 *
 */

module PhyRadioM
{
   provides {
      interface SplitControl;
      interface StdControl as PhyControl;
      interface RadioState as PhyState;
      interface PhyPkt;
      interface PhyNotify;
      interface TxPreamble as PhyTxPreamble;
      interface PhyStreamByte;
      interface CarrierSense;
      interface CsThreshold;
      interface GetSetU8 as RadioTxPower;
      interface RadioEnergy;
   }
   uses {
      interface StdControl as LTimeControl;
      interface GetSetU32 as LocalTime;
      interface ClockSCP as CSMAClock;
      interface Timer as RxTimer;
      interface Leds;
      interface UartDebug;

      interface SplitControl as CC2420SplitControl;
      interface CC2420Control;

      command result_t PowerEnable();
      interface PowerManagement;

      interface HPLCC2420 as HPLChipcon;
      interface HPLCC2420FIFO as HPLChipconFIFO;
      interface HPLCC2420Interrupt as FIFOP;
      interface HPLCC2420Capture as SFD;
   }
}

implementation
{
#include "StdReturn.h"
#include "PhyRadioMsg.h"
#include "PhyConst.h"

// Maximum time (in ms) to wait between start symbol and full packet received
#define RX_WAIT_DELAY 8

  // Carrier sense threshold that determines a busy channel
  enum {
    RADIO_BUSY_THRESHOLD = 0x60,  // definitely busy above this level
    RADIO_NOISE_LEVEL = 0x50 // initial noise level before any Rx
  };

  // Physical layer states
  enum {
    DISABLED_TASK,
    DISABLED,
    WARM_UP_FROM_INIT,
    WARM_UP_FROM_SLEEP,
    STOPPING,
    SLEEPING,
    IDLE,
    SLEEP,
    TRANSMIT_FROM_SLEEP,
    TRANSMIT_TONE_FROM_SLEEP,
    RECEIVING,
    TRANSMITTING_TONE,
    TRANSMITTING_TONE_WAIT,
    TRANSMITTING_TONE_DONE,
    TRANSMITTING,
    TRANSMITTING_WAIT,
    TRANSMITTING_DONE,
    CARRIER_SENSE
  };

  // buffer states
  enum {
    FREE,
    BUSY
  };

  // PhyRadio related variables   
  uint8_t state;
  uint8_t stateLock; // lock for state transition
  uint8_t pktLength; // pkt length including my header and trailer
  uint8_t appPktLength; // pkt length for the packet in sendAppPtr;
  PhyPktBuf buffer1;  // 2 buffers for receiving and processing
  PhyPktBuf buffer2;
  PhyPktBuf sendBuffer;  // For sending wake-up tones
  uint8_t recvBufState;  // receiving buffer state
  uint8_t procBufState;  // processing buffer state
  uint8_t* procBufPtr;
  uint8_t* sendAppPtr;
  uint8_t* sendPtr;
  uint8_t* recvPtr;
  uint8_t* procPtr;
  uint32_t recvTime;
  norace uint8_t currentDSN;
  norace bool busySending;
  norace bool busyReceiving;

  //  uint8_t numrecv;// For debugging
  //  uint8_t oldlen; // For debugging

  uint16_t tones_left;
  bool tone_preloaded;

  // RadioControl related variables
  uint8_t radioState;   // radio hardware state, for use by other components
  uint16_t carrSenTime; // carrier sense time
  uint8_t extFlag;      // carrier sense extension flag
  uint8_t minSignal;   // measured minimum signal strength
  uint8_t avgSignal;   // measured average signal strength
  uint8_t noiseLevel;  // measured average noise level
  uint8_t extCsVal;    // extended carrier sense sample
  bool updThreshEnabled; // if updating carrier sense threshold is enabled

#ifdef RADIO_MEASURE_ENERGY
  // Energy measurement related variables
  bool measureEnergy;  // energy measurement flag
  uint8_t lastRadioState;  // last radio state
  uint32_t lastUpdateTime;  // last time to update energy
  RadioTime radioTime;  // time the radio in different states
#endif
   
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

  result_t startSend(bool resend_packet);
  result_t CarrierSenseChannelIdle();
  result_t CarrierSenseChannelBusy();
  result_t wakeUpRadio();
  void setRadioStateIdle();
  void flushRXFIFO();
  void delayedRXFIFO();
  task void delayedRXFIFOtask();
  task void packetReceived();
  task void packetSent();
  void updateEnergy();

  // Init-related code

  command result_t PhyControl.init()
  {
    return call SplitControl.init();
  }

  command result_t SplitControl.init()
  {
    // For debugging
    //    numrecv = 0;
    //    oldlen = 0;

    atomic{
      state = DISABLED;
      recvPtr = (uint8_t*)&buffer1;
      procPtr = (uint8_t*)&buffer2;
      recvBufState = FREE;
      procBufState = FREE;
      currentDSN = 0;
      busySending = FALSE;
      busyReceiving = FALSE;
      avgSignal = RADIO_BUSY_THRESHOLD;
      minSignal = RADIO_BUSY_THRESHOLD;
      noiseLevel = RADIO_NOISE_LEVEL;
      updThreshEnabled = TRUE;
    }
    
#ifndef DISABLE_CPU_SLEEP
    call PowerEnable(); // enable CPU power management
#endif
#ifdef RADIO_MEASURE_ENERGY
    measureEnergy = FALSE;
#endif

    call Leds.init();  // initialize LED debugging
    call LTimeControl.init();  // initialize local system time
    call UartDebug.init(); // initialize UART debugging

    return call CC2420SplitControl.init();
  }
  
  event result_t CC2420SplitControl.initDone()
  {
#ifdef PHY_LED_STATE_DEBUG
    call Leds.greenOn();
#endif
    return signal SplitControl.initDone();
  }

 default event result_t SplitControl.initDone()
   {
     return SUCCESS;
   }

 // Start-related code

 task void startRadio()
 {
   result_t success = FAIL;

   atomic{
     if (state == DISABLED_TASK){
       state = DISABLED;
       success = SUCCESS;
     }
   }

   if (success == SUCCESS)
     call SplitControl.start();
 }

 // Ideally, folks would use the SplitControl interface instead.
 // for StdControl, if we put starting the radio in a task, it will
 // get delayed until other 'start' functions are done. See CC2420RadioM.nc
 // for a complete explanation
 command result_t PhyControl.start()
 {
   result_t success = FAIL;

   atomic{
     if (state == DISABLED){
       // only allows task to be posted once
       if (post startRadio()){
	 success = SUCCESS;
	 state = DISABLED_TASK;
       }
     }
   }

   return success;
 }
    
 command result_t SplitControl.start()
 {
   if (!lockAcquire(&stateLock)) return FAILURE; // in state transition
   if (state != DISABLED){
     lockRelease(&stateLock); // release state lock
     return FAIL;
   }

   // Change radio state to WARM_UP_FROM_INIT
   state = WARM_UP_FROM_INIT;

   call LTimeControl.start();
   call CC2420SplitControl.start();
   return SUCCESS;
 }

 event result_t CC2420SplitControl.startDone()
 {
   uint8_t old_state;
   result_t success;

#ifdef PHY_SHOW_RADIO_ON_PW4
   // For showing radio on
   TOSH_SET_PW4_PIN();
#endif

#ifdef PHY_LED_STATE_DEBUG
   call Leds.yellowOn();
#endif

   if (state == WARM_UP_FROM_INIT || state == WARM_UP_FROM_SLEEP ||
       state == TRANSMIT_FROM_SLEEP || state == TRANSMIT_TONE_FROM_SLEEP){
     call CC2420Control.RxMode();
     call CC2420Control.disableAutoAck();
     call CC2420Control.disableAddrDecode();
     radioState = RADIO_IDLE;
     updateEnergy();
     if (state == WARM_UP_FROM_INIT || state == WARM_UP_FROM_SLEEP){
       // Turning the radio on, either starting or waking up, no
       // packets to send right now, just activate radio interrupts...
       old_state = state;
       state = IDLE;
       busySending = FALSE;
       busyReceiving = FALSE;
       tone_preloaded = FALSE;
      
       // Reset Radio
       atomic{
	 call HPLChipcon.cmd(CC2420_SFLUSHTX);
	 call HPLChipcon.cmd(CC2420_SFLUSHRX);
	 call HPLChipcon.cmd(CC2420_SFLUSHRX); // Do it twice to ensure SFD goes back into its idle state
	 // enable interrupt when receiving packets
	 call FIFOP.startWait(FALSE);
	 // enable start of frame delimiter timer capture (timestamping)
	 call SFD.enableCapture(TRUE);
       }

       lockRelease(&stateLock); // release state lock

       if (old_state == WARM_UP_FROM_INIT){
	 signal SplitControl.startDone();
       }
       else{
	 // old_state must be WARM_UP_FROM_SLEEP
	 signal PhyState.wakeupDone();
       }

       // We're done !
       return SUCCESS;
     }

     // Radio wakeup is done -- it's stable now
     if (state == TRANSMIT_FROM_SLEEP || state == TRANSMIT_TONE_FROM_SLEEP){
       if (state == TRANSMIT_FROM_SLEEP)
	 state = TRANSMITTING;
       else
	 state = TRANSMITTING_TONE;
       busySending = TRUE;
       busyReceiving = FALSE;
       tone_preloaded = FALSE;
       // Reset radio
       atomic{
	 call HPLChipcon.cmd(CC2420_SFLUSHTX);
	 call HPLChipcon.cmd(CC2420_SFLUSHRX);
	 call HPLChipcon.cmd(CC2420_SFLUSHRX); // Do it twice to ensure SFD goes back into its idle state
	 // enable interrupt when receiving packets
	 call FIFOP.startWait(FALSE);
	 // enable start of frame delimiter timer capture (timestamping)
	 call SFD.enableCapture(TRUE);
       }
       success = startSend(FALSE);
       if (success == FAIL){
#ifdef PHY_LED_STATE_DEBUG
	 if (state == TRANSMITTING_TONE){
	   call Leds.redOff(); // Abort sending tone
	 }
	 else{
	   call Leds.greenOff(); // Abort sending packet
	 }
#endif
	 state = IDLE;
	 busySending = FALSE;
       }
       lockRelease(&stateLock); // release state lock
       return SUCCESS;
     }
   }
   return SUCCESS;
 }

 default event result_t SplitControl.startDone()
   {
     return SUCCESS;
   }

 // Stop-related code

 command result_t PhyControl.stop()
 {
   return call SplitControl.stop();
 }
   
 command result_t SplitControl.stop()
 {
   if (!lockAcquire(&stateLock)) return FAILURE; // in state transition
   call SFD.disable();
   call FIFOP.disable();

   state = STOPPING;
   
   call CC2420SplitControl.stop();
#ifndef DISABLE_CPU_SLEEP
   call PowerManagement.adjustPower();
#endif
   return SUCCESS;
 }

 event result_t CC2420SplitControl.stopDone()
 {
#ifdef PHY_LED_STATE_DEBUG
   call Leds.yellowOff();
#endif

   if (state == STOPPING){
     state = DISABLED;
   }
   else{
     if (state == SLEEPING){
       state = SLEEP;
     }
   }

   radioState = RADIO_SLEEP;
   updateEnergy();

   if (state == DISABLED){
     lockRelease(&stateLock); // clear state lock
     return signal SplitControl.stopDone();
   }

   lockRelease(&stateLock); // clear state lock
   return SUCCESS;
 }

 default event result_t SplitControl.stopDone()
   {
     return SUCCESS;
   }

 // This is the end of init/start/stop code

 // Begin of the PhyState interface

 command int8_t PhyState.idle()
 {
   // This function puts the radio in idle state. If we need to wake
   // up the radio from sleep, it will not be immediately ready
   if (!lockAcquire(&stateLock)) return FAILURE; // in state transition
   if (state == DISABLED || state == WARM_UP_FROM_INIT || state == CARRIER_SENSE){
     lockRelease(&stateLock);
     return FAILURE;
   }

   if (state == IDLE){
     if (radioState != RADIO_IDLE){
       radioState = RADIO_IDLE;
       updateEnergy();
     }
     lockRelease(&stateLock);
     return SUCCESS_DONE;
   }

   if (state == SLEEP){
     // We will have to wake up the radio
     radioState = RADIO_WAKEUP;
     updateEnergy();
     state = WARM_UP_FROM_SLEEP;
     call CC2420SplitControl.start();
     // Do not release lock, will wait for CC2420SplitControl.startDone
     return SUCCESS_WAIT;
   }

   // Radio is not sleeping or in a state transition, it should be
   // safe to put it in idle mode
   state = IDLE;
   radioState = RADIO_IDLE;
   updateEnergy();
   lockRelease(&stateLock); // release state lock
#ifdef PHY_LED_STATE_DEBUG
   call Leds.yellowOn();
#endif
   return SUCCESS_DONE;
 }

 void setRadioStateIdle()
 {
   atomic{
     if (radioState != RADIO_IDLE){
       radioState = RADIO_IDLE;
       updateEnergy();
     }
   }
 }

 result_t wakeUpRadio()
 {
   // First update energy consumption measurement
   radioState = RADIO_WAKEUP;
   updateEnergy();

   call CC2420SplitControl.start();
   return SUCCESS_WAIT;
 }

 default async event result_t PhyState.wakeupDone()
   {
     // default do-nothing handler
     return SUCCESS;
   }
     
 command result_t PhyState.sleep()
 {
   if (state == SLEEP || state == SLEEPING) return SUCCESS;
   if (state == CARRIER_SENSE) return FAIL; // Cannot sleep during carrier sense (for now)
   if (!lockAcquire(&stateLock)) return FAIL; // in state transition

   state = SLEEPING;

#ifdef PHY_SHOW_RADIO_ON_PW4
   // For showing radio on
   TOSH_CLR_PW4_PIN();
#endif

   // Stop radio interrupts
   call SFD.disable();
   call FIFOP.disable();

   // Stop radio
   call CC2420SplitControl.stop();

#ifndef DISABLE_CPU_SLEEP
   call PowerManagement.adjustPower();
#endif

   // Will release lock in CC2420SplitControl.stopDone
   return SUCCESS;
 }

 command uint8_t PhyState.get()
 {
   // get radio state
   return radioState;
 }

 // Begin of packet send interface

 command result_t PhyPkt.send(void* packet, uint8_t length, uint16_t addPreamble)
 {
   result_t success;

   if (length > PHY_MAX_PKT_LEN || length < PHY_MIN_PKT_LEN || busySending == TRUE) return FAIL;

   // Check if we have to send a tone before the packet
   if (addPreamble > 0){
     success = call PhyTxPreamble.start(0);
     if (success == FAIL){
       return FAIL; // Cannot send tone now
     }
     // Save packet for later
     sendAppPtr = (uint8_t*)packet;
     appPktLength = length;
     tones_left = addPreamble / (PHY_BASE_PRE_BYTES + PHY_MAX_PKT_LEN);
     if (addPreamble % (PHY_BASE_PRE_BYTES + PHY_MAX_PKT_LEN))
       tones_left++;
     return SUCCESS;
   }

   if (!lockAcquire(&stateLock)) return FAIL; // in state transition
   if (state != IDLE && state != SLEEP){
     lockRelease(&stateLock); // release state lock
     return FAIL; // Cannot send if radio busy or not fully initialized
   }

#ifdef PHY_LED_SEND_RCV_DEBUG
   call Leds.greenOn();
#endif

   if (state == SLEEP){
     // We first need to wake up the radio
     state = TRANSMIT_FROM_SLEEP;
     success = wakeUpRadio();
     if (success == SUCCESS_DONE){
#ifdef PHY_LED_STATE_DEBUG
       call Leds.yellowOn();
#endif
       state = IDLE;
     }
     else{
       if (success == FAILURE){
	 // Didn't work
	 state = SLEEP;
	 lockRelease(&stateLock); // release state lock
#ifdef PHY_LED_SEND_RCV_DEBUG
	 call Leds.greenOff();
#endif
 	 return FAIL;
       }
     }
   }

   // Now we prepare the packet header
   sendPtr = (uint8_t*)packet;
   // Not sending packet after the tone
   sendAppPtr = NULL;
   appPktLength = 0;
   // We decrement length by 1 byte to account for the length field in the 802.15.4 frame
   pktLength = length;
   ((PhyHeader*)sendPtr)->length = length - 1;
   // Fill the rest of the 802.15.4 header
   ((PhyHeader*)sendPtr)->fcflo = CC2420_DEF_FCF_LO;
   ((PhyHeader*)sendPtr)->fcfhi = CC2420_DEF_FCF_HI;
   ((PhyHeader*)sendPtr)->dsn = (++currentDSN) & 0x7f;

   // We will post the sendPacket task later
   if (state == TRANSMIT_FROM_SLEEP){
     return SUCCESS;
   }

   // Try start sending the packet
   state = TRANSMITTING;
   success = startSend(FALSE);

   if (success == SUCCESS){
     busySending = TRUE;
   }
   else{
     state = IDLE;
#ifdef PHY_LED_SEND_RCV_DEBUG
     call Leds.greenOff();
#endif
   }

   lockRelease(&stateLock); // release state lock
   return success;
 }

 result_t startSend(bool resend_packet)
 {
   uint8_t status;

   if (!resend_packet){
     // Flush the TX fifo of stale data
     if (!call HPLChipcon.cmd(CC2420_SFLUSHTX))
       return FAIL;

     // We've just flushed the sending buffer
     tone_preloaded = FALSE;

     // Signal the layer above for putting in timestamp information into
     // the packet. Even though the packet is not being sent yet, this
     // is the last chance we have to update it (before writing the
     // packet to the CC2420 FIFO).
     if (state == TRANSMITTING){
#ifdef PHY_SHOW_SEND_DELAY_PW6
       // For getting delay in sending
       TOSH_SET_PW6_PIN();
#endif
       signal PhyNotify.startSymSent(sendPtr);
     }

     // Write the packet into the TX buffer
     if (!call HPLChipconFIFO.writeTXFIFO(pktLength + 1, sendPtr))
       return FAIL;
   }

   // Write is completed, we can send it right now...
   // Tell the radio to send the packet
   call HPLChipcon.cmd(CC2420_STXON);

   status = call HPLChipcon.cmd(CC2420_SNOP);

   if ((status >> CC2420_TX_ACTIVE) & 0x01){

#ifdef PHY_SHOW_TP_PW3
     // For showing sending tones and packets
     TOSH_SET_PW3_PIN();
#endif

#ifdef PHY_SHOW_SEND_DELAY_PW6
     // For getting delay in sending
     TOSH_CLR_PW6_PIN();
#endif

     // Set radio into tx mode (for energy measurement)
     if (radioState != RADIO_TX){
       radioState = RADIO_TX;
       updateEnergy();
     }
     // Wait for the SFD to go high for the transmit SFD
     call SFD.enableCapture(TRUE);
   }
   else{
     return FAIL;
   }
   return SUCCESS;
 }

 async event result_t HPLChipconFIFO.TXFIFODone(uint8_t length, uint8_t *data)
 {
   return SUCCESS;
 }
  
 task void packetSent()
 {
   result_t success;
   uint8_t old_state = state;

   if (lockAcquire(&stateLock)){
     old_state = state;

     if (state == TRANSMITTING_TONE_DONE){
       if (tones_left > 0){
	 tones_left--;
	 state = TRANSMITTING_TONE;
	 success = startSend(TRUE);
	 if (success == FAIL){
	   state = IDLE;
#ifdef PHY_LED_SEND_RCV_DEBUG
	   call Leds.greenOff();
	   call Leds.redOff();
#endif
	   setRadioStateIdle();
	   busySending = FALSE;
	   lockRelease(&stateLock);
	   return;
	 }
	 lockRelease(&stateLock);
	 return;
       }
       if ((sendAppPtr) && (appPktLength > 0)){
	 // We have a packet to send after the tone
	 // First we setup the pkt pointers as in send
	 sendPtr = sendAppPtr;
	 sendAppPtr = NULL;
	 pktLength = appPktLength;
	 appPktLength = 0;
	 // Then, we prepare the packet header
	 ((PhyHeader*)sendPtr)->length = pktLength - 1;
	 // Fill the rest of the 802.15.4 header
	 ((PhyHeader*)sendPtr)->fcflo = CC2420_DEF_FCF_LO;
	 ((PhyHeader*)sendPtr)->fcfhi = CC2420_DEF_FCF_HI;
	 ((PhyHeader*)sendPtr)->dsn = (++currentDSN) & 0x7f;

	 // Wait for a while to give receiver time to process tone
	 TOSH_uwait(PHY_WAIT_AFTER_TONE);

	 // Try to start sending
	 state = TRANSMITTING;
	 if (startSend(FALSE) == SUCCESS){
#ifdef PHY_LED_SEND_RCV_DEBUG
	   call Leds.redOff();
	   call Leds.greenOn();
#endif
	   busySending = TRUE;
	 }
	 else{
	   state = IDLE;
#ifdef PHY_LED_SEND_RCV_DEBUG
	   call Leds.greenOff();
	   call Leds.redOff();
#endif
	   setRadioStateIdle();
	   busySending = FALSE;
	 }
	 lockRelease(&stateLock);
	 // Either way, we return
	 return;
       }
       else{
	 // Just finished sending a tone, no packet to send after
	 state = IDLE;
#ifdef PHY_LED_SEND_RCV_DEBUG
	 call Leds.redOff();
#endif
	 setRadioStateIdle();
	 busySending = FALSE;
	 lockRelease(&stateLock);
       }
     }
     else{
       if (state == TRANSMITTING_DONE){
	 state = IDLE;
#ifdef PHY_LED_SEND_RCV_DEBUG
	 call Leds.greenOff();
#endif
	 setRadioStateIdle();
	 busySending = FALSE;
	 lockRelease(&stateLock);
       }
     }
   }
     
   // Signal layer above that send is completed
   if (old_state == TRANSMITTING_TONE_DONE){
     signal PhyTxPreamble.done();
   }
   else{
     if (old_state == TRANSMITTING_DONE){
       signal PhyPkt.sendDone(sendPtr);
     }
   }
 }

 // Captured an edge transition on the SFD pin. This is useful for
 // time synchronization and for determining when packets finish
 // transmission
 async event result_t SFD.captured(uint16_t time)
 {
   if (!lockAcquire(&stateLock)) return SUCCESS; // in state transition
   switch(state){
   case TRANSMITTING_TONE:
     call SFD.enableCapture(FALSE);
     // If pin already fell, disable capture and let next state handle capture
     if (!TOSH_READ_CC_SFD_PIN()){
       call SFD.disable();
     }
     else{
       state = TRANSMITTING_TONE_WAIT;
       break;
     }
   case TRANSMITTING_TONE_WAIT:
     state = TRANSMITTING_TONE_DONE;
     call SFD.disable();
     call SFD.enableCapture(TRUE);
     // Set radio into idle mode (for energy measurement)
     setRadioStateIdle();

#ifdef PHY_SHOW_TP_PW3
     // For showing sending tones and packets
     TOSH_CLR_PW3_PIN();
#endif

     post packetSent();
     break;
   case TRANSMITTING:
     call SFD.enableCapture(FALSE);
     // If pin already fell, disable capture and let next state handle capture
     if (!TOSH_READ_CC_SFD_PIN()){
       call SFD.disable();
     }
     else{
       state = TRANSMITTING_WAIT;
     }
     // Signal the transmission of the preamble
     // However, we will have to change this later as
     // now it is too late to change timestamps in the packet
     // signal PhyNotify.startSymSent(sendPtr);

     if (state == TRANSMITTING_WAIT){
       break;
     }
   case TRANSMITTING_WAIT:
     state = TRANSMITTING_DONE;
     call SFD.disable();
     call SFD.enableCapture(TRUE);
     // Set radio into idle mode (for energy measurement)
     setRadioStateIdle();

#ifdef PHY_SHOW_TP_PW3
     // For showing sending tones and packets
     TOSH_CLR_PW3_PIN();
#endif

     post packetSent();
     break;
   default:
     // In receive mode
     if ((state == IDLE) && (recvBufState == FREE)){
       // We have a buffer to receive this packet
       state = RECEIVING;
       // Set radio into receive mode (for energy measurement)
       if (radioState != RADIO_RX){
	 radioState = RADIO_RX;
	 updateEnergy();
       }
#ifdef PHY_LED_SEND_RCV_DEBUG
       call Leds.yellowOn();
#endif
       // Adds 1ms resolution local time to packet
       ((PhyPktBuf *)recvPtr)->info.timestamp = call LocalTime.get();
       // Signal upper layer
       lockRelease(&stateLock); // clear state lock

#ifdef PHY_SHOW_RECV_PW6
       // For getting time packet is received
       TOSH_SET_PW6_PIN();
#endif
       // Signal layer above about detecting the start symbol
       signal PhyNotify.startSymDetected(recvPtr, 0);
       // Start receive timer
       recvTime = call LocalTime.get();
       if (call RxTimer.getRemainingTime() == 0){
	 call RxTimer.start(TIMER_ONE_SHOT, RX_WAIT_DELAY);
       }
       else{
	 call RxTimer.setRemainingTime(RX_WAIT_DELAY);
       }
       return SUCCESS;
     }
   }

   lockRelease(&stateLock); // clear state lock
   return SUCCESS;
 }

 // Packet receive-related functions

 event result_t RxTimer.fired()
 {
   uint32_t currentTime;

   if (!lockAcquire(&stateLock)) return SUCCESS; // in state transition
   if (state == RECEIVING){
     currentTime = call LocalTime.get();
     if ((currentTime - recvTime) > PHY_MAX_RECEIVE_TIME){
       // Time is up, reset state to IDLE
       state = IDLE;
       setRadioStateIdle(); // This also set radio to idle for energy measurement
#ifdef PHY_SHOW_RECV_PW6
       // For getting time packet is received
       TOSH_CLR_PW6_PIN();
#endif
       // Signal upper layer just in case it is waiting for packet
       signal PhyPkt.receiveDone(NULL, PKT_ERROR);
#ifdef PHY_LED_SEND_RCV_DEBUG
       //       call Leds.redToggle();
#endif
     }
   }
   lockRelease(&stateLock);
   return SUCCESS;
 }

 void flushRXFIFO()
 {
   call FIFOP.disable();
   call HPLChipcon.read(CC2420_RXFIFO);
   call HPLChipcon.cmd(CC2420_SFLUSHRX);
   call HPLChipcon.cmd(CC2420_SFLUSHRX);
   atomic busyReceiving = FALSE;
   call FIFOP.startWait(FALSE);
 }

 // FIFOP lo Interrupt: Rx data available in the CC2420 fifo
 // Radio must have been in the Rx mode to get this interrupt
 // If FIFO pin = lo, then fifo overflow, flush fifo & exit
 async event result_t FIFOP.fired()
 {
   result_t status = SUCCESS;

   // Packet completed, set radio state into idle mode (for energy measurement)
   atomic{
     if (state == IDLE && radioState != RADIO_IDLE){
       radioState = RADIO_IDLE;
       updateEnergy();
     }
   }

#ifdef PHY_SHOW_RECV_PW6
   // For getting time packet is received
   TOSH_CLR_PW6_PIN();
#endif

   // Check for RXFIFO overflow
   if (!TOSH_READ_CC_FIFO_PIN()){
     call RxTimer.stop();
     flushRXFIFO();
     // Signal upper layer just in case it is waiting for packet
     signal PhyPkt.receiveDone(NULL, PKT_ERROR);
     // Reset state to IDLE
     if (lockAcquire(&stateLock)){
       if (state == RECEIVING)
	 state = IDLE;
       lockRelease(&stateLock);
     }
     return SUCCESS;
   }

   atomic {
     if (post delayedRXFIFOtask()){
       call FIFOP.disable();
       status = FAIL;
     }
     else{
       flushRXFIFO();
     }
   }

   // Return SUCCESS to keep getting FIFOP events
   return status;
 }

 /**
  * Delayed RXFIFO is used to read the receive FIFO of the CC2420
  * in task context after the uC receives an interrupt that a packet
  * is in the RXFIFO.  Task context is necessary since reading from
  * the FIFO may take a while and we'd like to get other interrupts
  * during that time, or notifications of additional packets received
  * and stored in the CC2420 RXFIFO.
  */
 task void delayedRXFIFOtask() {
   delayedRXFIFO();
 }

 void delayedRXFIFO() {
   uint8_t len = PHY_MAX_PKT_LEN; // MSG_DATA_SIZE;  
   uint8_t _busyReceiving;

   if ((!TOSH_READ_CC_FIFO_PIN()) && (!TOSH_READ_CC_FIFOP_PIN())){
     flushRXFIFO();
     return;
   }

   atomic {
     _busyReceiving = busyReceiving;
      
     if (_busyReceiving){
       if (!post delayedRXFIFOtask())
	 flushRXFIFO();
     }
     else{
       busyReceiving = TRUE;
     }
   }
    
   // JP NOTE: TODO: move readRXFIFO out of atomic context to permit
   // high frequency sampling applications and remove delays on
   // interrupts being processed.  There is a race condition
   // that has not yet been diagnosed when RXFIFO may be interrupted.
   if (!_busyReceiving){
     // The len field is the maximum size we can accept from readRXFIFO
     if (!call HPLChipconFIFO.readRXFIFO(len, (uint8_t*)recvPtr)){
       atomic busyReceiving = FALSE;
       if (!post delayedRXFIFOtask()){
	 flushRXFIFO();
       }
       return;
     }
   }
   flushRXFIFO();
 }

 // After the buffer is received from the RXFIFO, we process it
 // Then, we post a task to signal higher layers
 async event result_t HPLChipconFIFO.RXFIFODone(uint8_t length, uint8_t *data)
 {
   uint8_t status;
   uint8_t *tempPtr;
   uint16_t noise = 0;
   uint8_t rssi;
   int8_t rssi2;
   bool ok = TRUE;
   uint8_t error_code = PKT_ERROR;

   //   numrecv++; // For debugging

   if (lockAcquire(&stateLock)){
     // If a FIFO overflow occurs or if the data length is invalid, flush
     // the RXFIFO to get back to a normal state
     if (!TOSH_READ_CC_FIFO_PIN() && !TOSH_READ_CC_FIFOP_PIN()){
       ok = FALSE;
     }
     else{
       // Check if in receive state
       if (state != RECEIVING){
	 ok = FALSE;
       }
       else{
	 // Check packet length
	 if (length == 0 || length > PHY_MAX_PKT_LEN){
	   ok = FALSE;
	 }
	 else{
	   // Check CRC
	   if (!(data[length-1] & 0x80)){
	     ok = FALSE;
	   }
	   else{
	     // Check if this is a packet or a tone (we will ignore the tone)
	     if ((((PhyPktBuf *)recvPtr)->hdr.dsn & 0x80)){
	       ok = FALSE;
	       error_code = PKT_ERROR_TONE_RECV;
	     }
	   }
	 }
       }
     }

     if (ok == FALSE){
       flushRXFIFO();
       state = IDLE;
       setRadioStateIdle();
       call RxTimer.stop();
#ifdef PHY_LED_SEND_RCV_DEBUG
       call Leds.yellowOff();
#endif
       lockRelease(&stateLock);
       signal PhyPkt.receiveDone(NULL, error_code);
       return SUCCESS;
     }

     ((PhyPktBuf *)recvPtr)->hdr.length = ((PhyPktBuf *)recvPtr)->hdr.length + 1;

     // Put in the packet RSSI (first convert it so we can use)
     //     rssi = recvPtr[length - 2];
     //     rssi = ((rssi >= 0) ? rssi + 128 : rssi - 128);
     rssi2 = recvPtr[length - 2];
     rssi =  ((rssi2 >= 0) ? rssi2 + 128 : rssi2 - 128);
     ((PhyPktBuf *)recvPtr)->info.strength = rssi;

     // Need to add the noise measurement
     // First wait for 8 symbols
     TOSH_uwait(8 * CC2420_SYMBOL_TIME);

     // First we check if the RSSI is valid (it should be!)
     status = call HPLChipcon.cmd(CC2420_SNOP);
     if ((status >> CC2420_RSSI_VALID) & 0x01){
       noise = call HPLChipcon.read(CC2420_RSSI);
     }
     // Convert noise so we can compare it with RSSI
     noise = ((noise >= 0) ? noise + 128 : noise - 128);
     ((PhyPktBuf *)recvPtr)->info.noise = noise;

     // data[length - 1] = oldlen;  // For debugging
     // data[length - 2] = numrecv; // For debugging
     // oldlen = length; // For debugging

     // Let's try to switch buffers if we can
     if (procBufState == FREE){
       // This packet is complete and can go up to the application
       if (post packetReceived()){
	 tempPtr = recvPtr;
	 recvPtr = procPtr;
	 procPtr = tempPtr;
	 procBufState = BUSY;
	 recvBufState = FREE;
       }
       else{
	 // Can't post task, signal MAC in case it is waiting
	 state = IDLE;
	 call RxTimer.stop();
	 lockRelease(&stateLock);
	 signal PhyPkt.receiveDone(NULL, PKT_ERROR);
	 flushRXFIFO();
	 return SUCCESS;
       }
     }
     else{
       recvBufState = BUSY;
     }
     // Stop receiver timer
     call RxTimer.stop();
     state = IDLE;
     lockRelease(&stateLock);
   }
   flushRXFIFO();
   return SUCCESS;
 }

 task void packetReceived()
 {
   void *tmp;
   uint8_t error;

   // Update Carrier Sense Threshold
   call CsThreshold.update(((PhyPktBuf*)procPtr)->info.strength,
			   ((PhyPktBuf*)procPtr)->info.noise);

   // Signal layer above of packet arrival
#ifdef PHY_LED_SEND_RCV_DEBUG
   call Leds.yellowOff();
#endif
   
   tmp = signal PhyPkt.receiveDone(procPtr, PKT_RECV);

   if (tmp){
     error = 0;
     atomic{
       if (recvBufState == BUSY) { // waiting for a free buffer
	 procPtr = recvPtr;
	 recvPtr = (uint8_t*)tmp;
	 recvBufState = FREE;  // can start receive now
	 if (!(post packetReceived())){  // signal the pending packet
	   error = 1; // task queue is full
	   procBufState = FREE;
	 }
       }
       else{
	 procPtr = (uint8_t*)tmp;
	 procBufState = FREE;
       }
     }
     if (error){
       // Can't post task, signal in case MAC is waiting
       signal PhyPkt.receiveDone(NULL, PKT_ERROR);
     }
   }
 }
 
 // Default do-nothing event handlers for the PhyNotify interface
 default async event result_t PhyNotify.startSymSent(void* packet)
   {
     return SUCCESS;
   }
      
 default async event result_t PhyNotify.startSymDetected(void* packet, uint8_t bitOffset)
   {
     return SUCCESS;
   }
    

 // Default do-nothing event handlers for the PhyPkt interface
 default event result_t PhyPkt.sendDone(void* packet)
   {
     return SUCCESS;
   }
      
 default event void* PhyPkt.receiveDone(void* packet, uint8_t error)
   {
     return packet;
   }

 // Start of the PhyTxPreamble interface (for sending tones)
 
 command result_t PhyTxPreamble.preload(uint16_t length)
 {
   if (!lockAcquire(&stateLock)) return FAIL; // in state transition
   if (state != IDLE){
     lockRelease(&stateLock);
     return FAIL; // Radio not in IDLE mode
   }

   // Setup the tone packet header
   sendPtr = (uint8_t*) &sendBuffer;
   // Not sending packet after the tone
   sendAppPtr = NULL;
   appPktLength = 0;
   // We decrement length by 1 byte to account for the length field in the 802.15.4 frame
   pktLength = PHY_MAX_PKT_LEN;
   ((PhyHeader*)sendPtr)->length = pktLength - 1;
   // Fill the rest of the 802.15.4 header
   ((PhyHeader*)sendPtr)->fcflo = CC2420_DEF_FCF_LO;
   ((PhyHeader*)sendPtr)->fcfhi = CC2420_DEF_FCF_HI;
   ((PhyHeader*)sendPtr)->dsn = (++currentDSN) | 0x80;

   if (!call HPLChipcon.cmd(CC2420_SFLUSHTX)){
     lockRelease(&stateLock);
     return FAIL;
   }

   // We've just flushed the tx fifo
   tone_preloaded = FALSE;

   // Write the packet into the TX buffer
   if (!call HPLChipconFIFO.writeTXFIFO(pktLength + 1, sendPtr)){
     lockRelease(&stateLock);
     return FAIL;
   }

   // Tone is now preloaded in the send buffer
   tone_preloaded = TRUE;

   // Tone is not in the send queue
   lockRelease(&stateLock);
   return SUCCESS;
 } 

 command result_t PhyTxPreamble.start(uint16_t length)
 {
   result_t success;

   // Figure out how many tones we need to send
   if (length == 0){
     tones_left = 0;
   }
   else{
     tones_left = PHY_NUMBER_OF_TONES - 1;
   }

   if (!lockAcquire(&stateLock)) return FAIL; // in state transition
   if (state != IDLE && state != SLEEP){
     lockRelease(&stateLock);
     return FAIL; // Radio not in IDLE mode
   }

#ifdef PHY_LED_SEND_RCV_DEBUG
     call Leds.redOn();
#endif

   if (state == SLEEP){
     // We first need to wake up the radio
     state = TRANSMIT_TONE_FROM_SLEEP;
     tone_preloaded = FALSE;
     success = wakeUpRadio();
     if (success == SUCCESS_DONE){
#ifdef PHY_LED_STATE_DEBUG
       call Leds.yellowOn();
#endif
       state = IDLE;
     }
     else{
       if (success == FAILURE){
	 // Didn't work
	 state = SLEEP;
	 lockRelease(&stateLock); // release state lock
#ifdef PHY_LED_SEND_RCV_DEBUG
	 call Leds.redOff();
#endif
 	 return FAIL;
       }
     }
   }

   // Setup header if it hasn't been done before
   if (tone_preloaded == FALSE){
     // Setup the tone packet header
     sendPtr = (uint8_t*) &sendBuffer;
     // Not sending packet after the tone
     sendAppPtr = NULL;
     appPktLength = 0;
     // We decrement length by 1 byte to account for the length field in the 802.15.4 frame
     pktLength = PHY_MAX_PKT_LEN;
     ((PhyHeader*)sendPtr)->length = pktLength - 1;
     // Fill the rest of the 802.15.4 header
     ((PhyHeader*)sendPtr)->fcflo = CC2420_DEF_FCF_LO;
     ((PhyHeader*)sendPtr)->fcfhi = CC2420_DEF_FCF_HI;
     ((PhyHeader*)sendPtr)->dsn = (++currentDSN) | 0x80;
   }

   // We will post the sendPacket task later
   if (state == TRANSMIT_TONE_FROM_SLEEP){
     return SUCCESS;
   }

   // Try start sending the tone
   state = TRANSMITTING_TONE;
   success = startSend(tone_preloaded);

   if (success == SUCCESS){
     busySending = TRUE;
   }
   else{
     state = IDLE;
#ifdef PHY_LED_SEND_RCV_DEBUG
     call Leds.redOff();
#endif
   }
      
   lockRelease(&stateLock); // release state lock
   return success;
 }
    
 default async event void PhyTxPreamble.done()
   {
     // default do-nothing handler
   }
    
 // default do-nothing handler for PhyStreamByte
 default event void PhyStreamByte.rxDone(uint8_t* buffer, uint8_t byteIdx)
   {
   }

 // CarrierSense Interface

 command result_t CarrierSense.start(uint16_t numSamples)
 {
   if (!lockAcquire(&stateLock)) return FAIL; // in state transition
   if (state != IDLE || numSamples == 0){
     lockRelease(&stateLock); // radio must be in idle state
     return FAIL;
   }

   // Let's begin carrier sense
#ifdef PHY_SHOW_CS_PW3
     TOSH_SET_PW3_PIN();
#endif
#ifdef PHY_LED_CS_DEBUG
     call Leds.greenOff();
     call Leds.yellowOff();
     call Leds.redOn();
#endif

   state = CARRIER_SENSE;
   carrSenTime = numSamples;
   extFlag = 0;
   lockRelease(&stateLock); // release state lock

   call CSMAClock.start();
   return SUCCESS;
 }

 event void CSMAClock.fire()
 {
   uint8_t status;
   uint8_t rssi;
   int8_t rssi2;
   
   // Stop the timer (will re-enable it later if we need it to continue)
   call CSMAClock.stop();

   if (carrSenTime > 0){
     carrSenTime--;

     // Get rssi sample
     status = call HPLChipcon.cmd(CC2420_SNOP);
     if ((status >> CC2420_RSSI_VALID) & 0x01){
       rssi2 = call HPLChipcon.read(CC2420_RSSI);
       rssi = ((rssi2 >= 0) ? rssi2 + 128 : rssi2 - 128);
     }
     else{
       // RSSI reading not available, return and try again later
       if (carrSenTime == 0){
	 if (extFlag == 0){
	   extFlag = 1;
	   carrSenTime = PHY_MAX_CS_EXT;
	   call CSMAClock.start();
	 }
	 else{
	   // This should not happen, maybe we should reset radio to a stable state
	   state = IDLE;
	   CarrierSenseChannelBusy();
	 }
       }
       else{
	 call CSMAClock.start();
       }
       return;
     }

     if (carrSenTime > 0 && extFlag == 0){ // requested byte
       if (rssi >= minSignal){ // stronger than min signal
	 carrSenTime = 0; // stop carrier sense
	 state = IDLE;
	 CarrierSenseChannelBusy();
       }
     }
     else{
       if (carrSenTime == 0 && extFlag == 0){ // last requested byte
	 if (rssi >= minSignal){ // stronger than min signal
	   state = IDLE;
	   CarrierSenseChannelBusy();
	 }
	 else
	   if (rssi <= noiseLevel){ // weaker than average noise level
	     updThreshEnabled = TRUE;
	     state = IDLE;
	     CarrierSenseChannelIdle();
	   }
	   else{
	     // need to check a few more bytes
	     extFlag = 1;  // set flag for extended bytes
	     extCsVal = rssi;
	     carrSenTime = PHY_MAX_CS_EXT;
	   }
       }
       else{
	 if (extFlag == 1){ // extended byte
	   if (rssi >= minSignal){ // stronger than min signal
	     carrSenTime = 0; // stop carrier sense
	     state = IDLE;
	     CarrierSenseChannelBusy();
	   }
	   else{
	     if (rssi <= noiseLevel){ // weaker than average noise level
	       carrSenTime = 0; // stop carrier sense
	       updThreshEnabled = TRUE;
	       state = IDLE;
	       CarrierSenseChannelIdle();
	     }
	     else{  // can't decide with individual sample
	       if (carrSenTime > 0){
		 extCsVal = (extCsVal + rssi) >> 1; // average on extended samples
	       }
	       else{
		 // Now, we have to make a decision based on averaged extended bytes
		 // use half line between minSignal and noiseLevel as threshold
		 state = IDLE;
		 if (extCsVal >= ((minSignal + noiseLevel) >> 1)){
		   CarrierSenseChannelBusy();
		 }
		 else{
		   updThreshEnabled = TRUE;
		   CarrierSenseChannelIdle();
		 }
	       }
	     }
	   }
	 }
       }
     }
     // Re-enable clock if we want to continue carrier sense
     if ((carrSenTime > 0) && (state == CARRIER_SENSE))
       call CSMAClock.start();
   }
 }

 result_t CarrierSenseChannelIdle()
 {
   if (lockAcquire(&stateLock)){
     // put the radio back in idle mode
#ifdef PHY_SHOW_CS_PW3
     TOSH_CLR_PW3_PIN();
#endif
     state = IDLE;
#ifdef PHY_LED_CS_DEBUG
     call Leds.greenOn();
     call Leds.yellowOff();
     call Leds.redOff();
#endif
     lockRelease(&stateLock);
   }
   signal CarrierSense.channelIdle();
   return SUCCESS;
 }

 result_t CarrierSenseChannelBusy()
 {
   if (lockAcquire(&stateLock)){
     // put the radio back in idle mode
#ifdef PHY_SHOW_CS_PW3
     TOSH_CLR_PW3_PIN();
#endif
     state = IDLE;
#ifdef PHY_LED_CS_DEBUG
     call Leds.yellowOn();
     call Leds.greenOff();
     call Leds.redOff();
#endif
     lockRelease(&stateLock);
   }
   signal CarrierSense.channelBusy();
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

 // CsThreshold interface

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
    
   if (noiseVal < minSignal){  // exclude possible false positives
     // average noise level: new sample gets 0.25 weight
     noiseLevel = (noiseLevel >> 1) + ((noiseLevel + noiseVal) >> 2);
   }
   // average signal strength: new sample gets 0.25 weight
   avgSignal = (avgSignal >> 1) + ((avgSignal + signalVal) >> 2);
   if (updThreshEnabled && signalVal < minSignal){
     minSignal = signalVal;   // busy threshold goes to minimum
     if (noiseLevel > minSignal){  // noise is too high
       minSignal = noiseLevel;  // signal can't be lower than noise
     }
   }
 }
    
 command void CsThreshold.starved()
 {
   // when a node gets starved on Tx, minSignal will be raised to make
   // it more aggressive. Starvation is defined by MAC that uses carrier
   // sense, e.g., consecutive failures on randamized carrier sense
   if (minSignal >= RADIO_BUSY_THRESHOLD) return;
   if (avgSignal < RADIO_BUSY_THRESHOLD){
     minSignal = (minSignal + avgSignal) >> 1;
   }
   else{
     minSignal = (minSignal + RADIO_BUSY_THRESHOLD) >> 1;
   }
   updThreshEnabled = FALSE;  // don't lower busy threshold during starvation
 }
    
 // RadioTxPower interface

 command uint8_t RadioTxPower.get()
 {
   // get current radio Tx power
   return call CC2420Control.GetRFPower();
 }

 // Valid parameters are integers between 1 and 31
    
 command result_t RadioTxPower.set(uint8_t level)
 {
   // Check if level is within valid range
   if ((level < 1) || (level > 31))
     return FAIL;

   // set radio tx power
   return call CC2420Control.SetRFPower(level);
 }

 default async command uint8_t PowerManagement.adjustPower()
   {
     // default command if PowerManagement is not used
     return 1;
   }

 // RadioEnergy interface
    
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
