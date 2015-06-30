/*                                                      tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * A rewrite of the low-power-listening CC1000 radio stack.
 * This file contains the CSMA and low-power listening logic. Actual
 * packet transmission and reception is in SendReceive.
 *
 * This code has some degree of platform-independence, via the
 * CC1000Control, RSSIADC and SpiByteFifo interfaces which must be provided
 * by the platform. However, these interfaces may still reflect some
 * particularities of the mica2 hardware implementation.
 *
 * @author Philip Buonadonna
 * @author Jaein Jeong
 * @author Joe Polastre
 * @author David Gay
 * @author David Moss
 */

includes crc;
includes CC1000Const;

module CC1000CsmaM {
  provides {
    interface StdControl;
    interface CsmaControl;
    interface CsmaBackoff;
    interface LowPowerListening;
  }
  
  uses {
    interface StdControl as ByteRadioControl;
    interface ByteRadio;

    interface CC1000Control;
    interface CC1000Squelch;
    interface Random;
    interface Timer as WakeupTimer;
    interface BusyWait;

    interface Rssi as RssiNoiseFloor;
    interface Rssi as RssiCheckChannel;
    interface Rssi as RssiPulseCheck;
  }
}

implementation {
  
  norace uint8_t radioState;
  
  uint8_t count;

  int16_t macDelay;

  uint8_t lplTxPower;
  
  uint8_t lplRxPower;

  uint16_t sleepTime;

  uint16_t rssiForSquelch;

  enum {
    TIME_AFTER_CHECK =  128,
  };
  
  /** Flags */
  struct {
    uint8_t ccaOff : 1;
    uint8_t txPending : 1;
  } f;

  enum {
    DISABLED_STATE,
    IDLE_STATE,
    RX_STATE,
    TX_STATE,
    POWERDOWN_STATE,
    PULSECHECK_STATE
  };

  /***************** Prototypes ****************/  
  task void setWakeupTask();
  task void adjustSquelch();
  task void sleepCheck();
  
  void enterIdleState();
  void enterIdleStateSetWakeup();
  void enterDisabledState();
  void enterPowerDownState();
  void enterRxState();
  void enterTxState();
  void radioOn();
  void radioOff();
  void setPreambleLength();
  void setSleepTime();
  void setWakeup();
  void congestion();
  
  
  /***************** StdControl Commands ****************/
  command result_t StdControl.init() {
    radioState = DISABLED_STATE;
    call ByteRadioControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    atomic {
      if (radioState == DISABLED_STATE) {
        call ByteRadioControl.start();
        enterIdleStateSetWakeup();
        f.txPending = FALSE;
        setPreambleLength();
        setSleepTime();
        
      } else {
        return SUCCESS;
      }
    }
    
    radioOn();

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    atomic {
      call ByteRadioControl.stop();
      enterDisabledState();
      radioOff();
    }
    
    call WakeupTimer.stop();
    
    return SUCCESS;
  }

  /***************** CsmaControl Commands ****************/
  /**
   * Enable congestion control.
   * @return SUCCESS if congestion control enabled, FAIL otherwise.
   */
  async command result_t CsmaControl.enableCca() {
    atomic f.ccaOff = FALSE;
    return SUCCESS;
  }

  /**
   * Disable congestion control.
   * @return SUCCESS if congestion control disabled, FAIL otherwise.
   */
  async command result_t CsmaControl.disableCca() {
    atomic f.ccaOff = TRUE;
    return SUCCESS;
  }

  /***************** LowPowerListening Commands ****************/
  /**
   * Set the current Low Power Listening mode.
   * Setting the LPL mode sets both the check interval and preamble length.
   * The listening mode can only be set while the radio is stopped.
   *
   * Modes include:
   *  0 = Radio fully on
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
   * @return SUCCESS if the mode was successfully changed, FAIL otherwise
   */
  async command result_t LowPowerListening.setListeningMode(uint8_t power) {
    if (power >= CC1K_LPL_STATES) {
      return FAIL;
    }

    atomic {
      lplTxPower = power;
      lplRxPower = power;
      setPreambleLength();
      setSleepTime();
    }
    
    return SUCCESS;
  }

  /**
   * Get the current Low Power Listening mode
   * @return mode number (see SetListeningMode)
   */
  async command uint8_t LowPowerListening.getListeningMode() {
    atomic return lplRxPower;
  }

  /**
   * Set the transmit mode.  This allows for hybrid schemes where
   * the transmit mode is different than the receive mode.
   * Use SetListeningMode first, then change the mode with SetTransmitMode.
   *
   * @param mode mode number (see SetListeningMode)
   * @return SUCCESS if the mode was successfully changed, FAIL otherwise
   */
  async command result_t LowPowerListening.setTransmitMode(uint8_t power) {
    if (power >= CC1K_LPL_STATES) {
      return FAIL;
    }

    atomic {
      lplTxPower = power;
      setPreambleLength();
    }
    
    return SUCCESS;
  }

  /**
   * Get the current Low Power Listening transmit mode
   * @return mode number (see SetListeningMode)
   */
  async command uint8_t LowPowerListening.getTransmitMode() {
    atomic return lplTxPower;
  }

  /**
   * Set the preamble length of outgoing packets. Note that this overrides
   * the value set by setListeningMode or setTransmitMode.
   *
   * @param bytes length of the preamble in bytes
   * @return SUCCESS if the preamble length was successfully changed, FAIL
   *   otherwise
   */
  async command result_t LowPowerListening.setPreambleLength(uint16_t bytes) {
    call ByteRadio.setPreambleLength(bytes);
    return SUCCESS;
  }

  /**
   * Get the preamble length of outgoing packets
   *
   * @return length of the preamble in bytes
   */
  async command uint16_t LowPowerListening.getPreambleLength() {
    return call ByteRadio.getPreambleLength();
  }

  /**
   * Set the check interval (time between waking up and sampling
   * the radio for activity in low power listening). The sleep time
   * can only be changed if low-power-listening is enabled 
   * (setListeningMode called with a non-zero value).
   *
   * @param ms check interval in milliseconds
   * @return SUCCESS if the check interval was successfully changed,
   *   FAIL otherwise.
   */
  async command result_t LowPowerListening.setCheckInterval(uint16_t ms) {
    atomic {
      if (lplRxPower == 0) {
        return FAIL;
      }

      sleepTime = ms;
    }
    
    return SUCCESS;
  }

  /**
   * Get the check interval currently used by low power listening
   *
   * @return length of the check interval in milliseconds
   */
  async command uint16_t LowPowerListening.getCheckInterval() {
    atomic return sleepTime;
  }


  /***************** WakeupTimer Events ****************/
  event result_t WakeupTimer.fired() {
    atomic {
      switch (radioState) {
        case IDLE_STATE:
          /* 
           * If we appear to be receiving a packet we don't check the
           * noise floor. For LPL, this means that going to sleep will
           * be delayed by another TIME_AFTER_CHECK ms. 
           */
          if (!call ByteRadio.syncing()) {
            call RssiNoiseFloor.cancel();  // Cancel all RSSI tasks
            call RssiNoiseFloor.read();
          }
          break;

        case POWERDOWN_STATE:
          radioState = PULSECHECK_STATE;
          count = 0;
          call RssiPulseCheck.read();
          call BusyWait.wait(80);
          return SUCCESS;
          /** Returned, don't set wakeup */
        
        default:
          break;
      }
  
      setWakeup();
    }
      
    return SUCCESS;
  }


  /***************** ByteRadio Events ****************/
  async event void ByteRadio.rx() {
    enterRxState();
  }

  async event void ByteRadio.rxDone() {
    call RssiNoiseFloor.cancel();
    enterIdleStateSetWakeup();
  }
  
  event void ByteRadio.rts() {
    atomic {
      f.txPending = TRUE;

      if (radioState == POWERDOWN_STATE) {
        post sleepCheck();
      }
      
      if (!f.ccaOff) {
        macDelay = signal CsmaBackoff.initial();
      } else {
        macDelay = 1;
      }
    }
  }

  async event void ByteRadio.sendDone() {
    f.txPending = FALSE;
    enterIdleStateSetWakeup();
  }

  async event void ByteRadio.idleByte(bool preamble) {
    if (f.txPending) {
      if (!f.ccaOff && preamble) {
        congestion();
    
      } else if (macDelay && !--macDelay) {
        call RssiCheckChannel.cancel();
        count = 0;
        call RssiCheckChannel.read();
      }
    }
  }
  
  /***************** RssiNoiseFloor Events ****************/
  async event void RssiNoiseFloor.readDone(result_t result, uint16_t data) {
    if (result != SUCCESS) {
      /* We just ignore failed noise floor measurements */
      post sleepCheck();
      return;
    }

    rssiForSquelch = data;
    post adjustSquelch();
    post sleepCheck();
  }
  
  
  /***************** RssiCheckChannel Events ****************/
  async event void RssiCheckChannel.readDone(result_t result, uint16_t data) {
    if (result != SUCCESS) {
      /* We'll retry the transmission at the next SPI event. */
      atomic macDelay = 1;
      return;
    }
    
    count++;
    
    if ((data > call CC1000Squelch.get() - CC1K_SquelchBuffer) || f.ccaOff) {
      enterTxState();
      call ByteRadio.cts();

    } else if (count == CC1K_MaxRSSISamples) {
      congestion();
   
    } else {
      call RssiCheckChannel.read();
      call BusyWait.wait(80);
    }
  }
  
  
  /***************** RssiPulseCheck Events ****************/
  async event void RssiPulseCheck.readDone(result_t result, uint16_t data) {
    
    if(count == 0) {
      // The microcontroller has woken up. Enable the radio and read.
      count++;
      call CC1000Control.biasOn();
      call CC1000Control.rxMode();
      call BusyWait.wait(800);
      call RssiPulseCheck.read();
      return;
    }
    
    /*
     * We got some RSSI data for our LPL check. Decide whether to:
     *  - go back to sleep (quiet)
     *  - wake up (channel active)
     *  - get more RSSI data
     */
    if (data > call CC1000Squelch.get() - (call CC1000Squelch.get() >> 2)) {
      radioOff();
      post sleepCheck();
      
      // don't be too agressive (ignore really quiet thresholds).
      if (data < call CC1000Squelch.get() + (call CC1000Squelch.get() >> 3)) {
          // adjust the noise floor level, go back to sleep.
          rssiForSquelch = data;
          post adjustSquelch();
      }
      
    } else if (count++ > 5) {
      //go to the idle state since no outliers were found
      enterIdleStateSetWakeup();
      call ByteRadio.listen();
      
    } else {
      // The current reading looked good, take a few more to verify
      call RssiPulseCheck.read();
    }
  }
  
  /***************** Tasks ****************/
  /**
   * Should we go to sleep, or turn the radio fully on? 
   */
  task void sleepCheck() {
    bool turnOn = FALSE;

    atomic {
      if (f.txPending) {
        if (radioState == PULSECHECK_STATE || radioState == POWERDOWN_STATE) {
            enterIdleStateSetWakeup();
            turnOn = TRUE;
        }
      
      } else if (lplRxPower > 0 && call CC1000Squelch.settled() && !call ByteRadio.syncing()) {
        radioOff();
        enterPowerDownState();
        setWakeup();
      }
    }

    if (turnOn) {
      radioOn();
    }
  }
  
  task void adjustSquelch() {
    uint16_t squelchData;

    atomic squelchData = rssiForSquelch;
    call CC1000Squelch.adjust(squelchData);
  }

  task void setWakeupTask() {
    atomic setWakeup();
  }
  
  
  /***************** Functions ****************/
  /**
   * Set the length of time before the WakeupTimer is fired
   */
  void setWakeup() {
    switch (radioState) {
      case IDLE_STATE:
        if (call CC1000Squelch.settled()) {
          if (lplRxPower == 0 || f.txPending) {
            call WakeupTimer.start(TIMER_ONE_SHOT, CC1K_SquelchIntervalSlow);
            
          } else {
            // timeout for receiving a message after an lpl check
            // indicates channel activity.
            call WakeupTimer.start(TIMER_ONE_SHOT, TIME_AFTER_CHECK);
          } 
            
        } else {
          call WakeupTimer.start(TIMER_ONE_SHOT, CC1K_SquelchIntervalFast);
        } 

        break;
        
      case PULSECHECK_STATE:
        // Radio warm-up time.
        call WakeupTimer.start(TIMER_ONE_SHOT, 1);
        break;
     
      case POWERDOWN_STATE:
        // low-power listening check interval
        call WakeupTimer.start(TIMER_ONE_SHOT, sleepTime);
        break;
       
      default:
        break;
    }
  }

  void enterIdleState() {
    call RssiNoiseFloor.cancel();
    radioState = IDLE_STATE;
  }

  void enterIdleStateSetWakeup() {
    enterIdleState();
    post setWakeupTask();
  }

  void enterDisabledState() {
    call RssiNoiseFloor.cancel();
    radioState = DISABLED_STATE;
  }

  void enterPowerDownState() {
    call RssiNoiseFloor.cancel();
    radioState = POWERDOWN_STATE;
  }

  void enterRxState() {
    call RssiNoiseFloor.cancel();
    radioState = RX_STATE;
  }

  void enterTxState() {
    radioState = TX_STATE;
  }


  void radioOn() {
    call CC1000Control.coreOn();
    call BusyWait.wait(2000);
    call CC1000Control.biasOn();
    call BusyWait.wait(200);
    atomic call ByteRadio.listen();
  }

  void radioOff() {
    call ByteRadio.off();
    call CC1000Control.off();
  }

  void setPreambleLength() {
    uint16_t len =
      (uint16_t)PRG_RDB(&CC1K_LPL_PreambleLength[lplTxPower * 2]) << 8
      | PRG_RDB(&CC1K_LPL_PreambleLength[lplTxPower * 2 + 1]);
    call ByteRadio.setPreambleLength(len);
  }

  void setSleepTime() {
    sleepTime =
      (uint16_t)PRG_RDB(&CC1K_LPL_SleepTime[lplRxPower *2 ]) << 8 |
      PRG_RDB(&CC1K_LPL_SleepTime[lplRxPower * 2 + 1]);
  }
  
  void congestion() {
    macDelay = signal CsmaBackoff.congestion();
  }
  
  
  /***************** Defaults ****************/
  default async event uint16_t CsmaBackoff.initial() { 
    // initially back off [1,32] bytes (approx 2/3 packet)
    return (call Random.rand16() & 0x1F) + 1;
  }

  default async event uint16_t CsmaBackoff.congestion() { 
    return (call Random.rand16() & 0xF) + 1;
  }
}
