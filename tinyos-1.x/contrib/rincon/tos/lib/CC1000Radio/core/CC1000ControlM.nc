/*
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
 * This module provides the CONTROL functionality for the Chipcon1000
 * series radio.  It exports a custom interface to control CC1000
 * operation.
 *
 * @author Philip Buonadonna
 * @author Jaein Jeong
 * @author David Gay
 * @author David Moss
 */

includes CC1000Const;

module CC1000ControlM {
  provides {
    interface CC1000Control;
    interface StdControl;
  }
  
  uses {
    interface Timer as RecalibrationTimer;
    interface HPLCC1000;
    interface BusyWait;
    interface ByteRadio;
  }
}

implementation {

  norace uint8_t txCurrent;
  
  norace uint8_t rxCurrent;
  
  norace uint8_t power;

  /** The number of hours before an auto recalibration of the radio */
  uint8_t recalibrationHours;
  
  /** TRUE if the radio is being calibrated */
  bool calibrating;
  
  enum {
    IF = 150000,
    FREQ_MIN = 4194304,
    FREQ_MAX = 16751615
  };

  const uint32_t fRefTbl[9] = {
                   2457600,
                   2106514,
                   1843200,
                   1638400,
                   1474560,
                   1340509,
                   1228800,
                   1134277,
                   1053257};
  
  const uint16_t corTbl[9] = {
                  1213,
                  1416,
                  1618,
                  1820,
                  2022,
                  2224,
                  2427,
                  2629,
                  2831};
  
  const uint16_t fsepTbl[9] = {
                   0x1AA,
                   0x1F1,
                   0x238,
                   0x280,
                   0x2C7,
                   0x30E,
                   0x355,
                   0x39C,
                   0x3E3};
  
  enum {
    DEFAULT_RECALIBRATION_HOURS = 8,
  };
  
  /***************** Prototypes ****************/
  void calibrateNow();
  
  void singleCalibration();
  
  uint32_t calculateFrequency(uint32_t desiredFreq);
  
  task void attemptCalibration();
  
  /***************** StdControl Commands ****************/
  command result_t StdControl.init() {
    call HPLCC1000.init();

    recalibrationHours = DEFAULT_RECALIBRATION_HOURS;
    
    // wake up xtal and reset unit
    call HPLCC1000.write(CC1K_MAIN,
          1 << CC1K_RX_PD | 1 << CC1K_TX_PD | 
          1 << CC1K_FS_PD | 1 << CC1K_BIAS_PD);
          
    // clear reset.
    call CC1000Control.coreOn();
    call BusyWait.wait(2000);

    // Set default parameter values
    // POWER: 0dbm (~900MHz), 6dbm (~430MHz)
    power = 8 << CC1K_PA_HIGHPOWER | 0 << CC1K_PA_LOWPOWER;
    call HPLCC1000.write(CC1K_PA_POW, power);

    // select Manchester Violation for CHP_OUT
    call HPLCC1000.write(CC1K_LOCK_SELECT, 9 << CC1K_LOCK_SELECT);

    // Default modem values = 19.2 Kbps (38.4 kBaud), Manchester encoded
    call HPLCC1000.write(CC1K_MODEM2, 0);
    
    call HPLCC1000.write(CC1K_MODEM1, 
          3 << CC1K_MLIMIT |
          1 << CC1K_LOCK_AVG_MODE | 
          3 << CC1K_SETTLING |
          1 << CC1K_MODEM_RESET_N);
          
    call CC1000Control.doubleBaudRate(FALSE);

    call HPLCC1000.write(CC1K_FSCTRL, 1 << CC1K_FS_RESET_N);

#ifdef CC1K_DEF_FREQ
    call CC1000Control.tuneManual(CC1K_DEF_FREQ);
#else
    call CC1000Control.tunePreset(CC1K_DEF_PRESET);
#endif

    call CC1000Control.off();
    
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call RecalibrationTimer.start(TIMER_REPEAT, recalibrationHours*3600*1024);
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  /***************** CC1000Control Commands ****************/
  /**
   * Tune the radio to one of the frequencies available in the CC1K_Params
   * table.  Calling Tune will allso reset the rfpower and LockVal
   * selections to the table values.
   * 
   * @param freq The index into the CC1K_Params table that holds the
   * desired preset frequency parameters.
   */
  command void CC1000Control.tunePreset(uint8_t freq) {
    int i;

    // FREQA, FREQB, FSEP, CURRENT(RX), FRONT_END, POWER, PLL
    for (i = CC1K_FREQ_2A; i <= CC1K_PLL; i++) {
      call HPLCC1000.write(i, PRG_RDB(&CC1K_Params[freq][i]));
    }
    
    call HPLCC1000.write(CC1K_MATCH, PRG_RDB(&CC1K_Params[freq][CC1K_MATCH]));
    rxCurrent = PRG_RDB(&CC1K_Params[freq][CC1K_CURRENT]);
    txCurrent = PRG_RDB(&CC1K_Params[freq][CC1K_MATCH + 1]);
    power = PRG_RDB(&CC1K_Params[freq][CC1K_PA_POW]);

    post attemptCalibration();
  }
  
  /**
   * Tune the radio to a given frequency. Since the CC1000 uses a digital
   * frequency synthesizer, it cannot tune to just an arbitrary frequency.
   * This routine will determine the closest achievable channel, compute
   * the necessary parameters and tune the radio.
   * 
   * @param The desired channel frequency, in Hz.
   * 
   * @return The actual computed channel frequency, in Hz.  A return value
   * of '0' indicates that no frequency was computed and the radio was not
   * tuned.
   */
  command uint32_t CC1000Control.tuneManual(uint32_t freqHz) {
    uint32_t actualFreq = calculateFrequency(freqHz);
    post attemptCalibration();
    return actualFreq;
  }

  /**
   * Set the baud rate to 76.8 kBaud or 38.4 kBaud.
   * The default is 38.4 kBaud, compatible across all motes.
   * If your network does not contain any mica2dot motes, 
   * you should double the baud rate - saving power when communicating
   * by increasing throughput.
   *
   * @param doubleBaud - TRUE to double the default baud rate to 76.8 kBaud,
   *     FALSE to set the baud rate to 38.4 kBaud.
   */
  command void CC1000Control.doubleBaudRate(bool doubleBaud) {
    if(doubleBaud) {
      call HPLCC1000.write(CC1K_MODEM0, 
          5 << CC1K_BAUDRATE |
          1 << CC1K_DATA_FORMAT | 
          0 << CC1K_XOSC_FREQ);
          
    } else {
      call HPLCC1000.write(CC1K_MODEM0, 
          5 << CC1K_BAUDRATE |
          1 << CC1K_DATA_FORMAT | 
          1 << CC1K_XOSC_FREQ);
    }
  }
  
  /** 
   * Auto-Recalibration is on by default.
   *
   * Enable or disable the automatic recalibrations. Temperature and
   * voltage variations will cause the frequency to drift over time.
   * Recalibrating the radio frequencies every few hours will prevent this
   * @param on - TRUE if recalibration should be on, FALSE if it shouldn't
   * @param hours - The delay, in hours, after which to auto recalibrate
   */
  command void CC1000Control.setAutoRecalibration(bool on, uint8_t hours) {
    if(hours == 0) {
      recalibrationHours = DEFAULT_RECALIBRATION_HOURS;
    } else {
      recalibrationHours = hours;
    }
      
    if(on) {
      call RecalibrationTimer.start(TIMER_REPEAT, recalibrationHours*3600*1024);
      
    } else {
      call RecalibrationTimer.stop();
    }
  }
  
  /**
   * Shift the CC1000 Radio into transmit mode.
   */
  async command void CC1000Control.txMode() {
    // MAIN register to TX mode
    call HPLCC1000.write(CC1K_MAIN,
          1 << CC1K_RXTX |
          1 << CC1K_F_REG |
          1 << CC1K_RX_PD | 
          1 << CC1K_RESET_N);
          
    // Set the TX mode VCO Current
    call HPLCC1000.write(CC1K_CURRENT, txCurrent);
    call BusyWait.wait(250);
    call HPLCC1000.write(CC1K_PA_POW, power);
    call BusyWait.wait(20);
  }

  /**
   * Shift the CC1000 Radio in receive mode.
   */
  async command void CC1000Control.rxMode() {
    // MAIN register to RX mode
    // Powerup Freqency Synthesizer and Receiver
    call HPLCC1000.write(CC1K_CURRENT, rxCurrent);
    call HPLCC1000.write(CC1K_PA_POW, 0); // turn off power amp
    call HPLCC1000.write(CC1K_MAIN, 1 << CC1K_TX_PD | 1 << CC1K_RESET_N);
    call BusyWait.wait(125);
  }

  /**
   * Turn off the bias power on the CC1000 radio, but leave the core and
   * crystal oscillator powered.  This will result in approximately a 750
   * uA power savings.
   */
  async command void CC1000Control.coreOn() {
    // MAIN register to SLEEP mode
    call HPLCC1000.write(CC1K_MAIN,
          1 << CC1K_RX_PD |
          1 << CC1K_TX_PD | 
          1 << CC1K_FS_PD |
          1 << CC1K_BIAS_PD |
          1 << CC1K_RESET_N);
  }

  /**
   * Turn the bias power on. This function must be followed by a call to
   * either rxMode() or txMode() to place the radio in a recieve/transmit
   * state respectively. There is approximately a 200us delay when
   * restoring bias power.
   */
  async command void CC1000Control.biasOn() {
    call HPLCC1000.write(CC1K_MAIN,
          1 << CC1K_RX_PD |
          1 << CC1K_TX_PD | 
          1 << CC1K_FS_PD | 
          1 << CC1K_RESET_N);
  }

  /**
   * Turn the CC1000 off
   */
  async command void CC1000Control.off() {
    // MAIN register to power down mode. Shut everything off
    call HPLCC1000.write(CC1K_MAIN,
          1 << CC1K_RX_PD |
          1 << CC1K_TX_PD | 
          1 << CC1K_FS_PD |
          1 << CC1K_CORE_PD |
          1 << CC1K_BIAS_PD |
          1 << CC1K_RESET_N);
          
    // Turn off rf amp
    call HPLCC1000.write(CC1K_PA_POW, 0);
  }

  /**
   * Set the transmit RF power value.  The input value is simply an
   * arbitrary index that is programmed into the CC1000 registers.  Consult
   * the CC1000 datasheet for the resulting power output/current
   * consumption values.
   *
   * @param power A power index between 1 and 255.
   */
  command void CC1000Control.setRFPower(uint8_t newPower) {
    power = newPower;
  }

  /**
   * Get the present RF power index.
   *
   * @return The power index value.
   */
  command uint8_t CC1000Control.getRFPower() {
    return power;
  }

  /** 
   * Select the signal to monitor at the CHP_OUT pin of the CC1000.  See
   * the CC1000 data sheet for the available signals.
   * 
   * @param LockVal The index of the signal to monitor at the CHP_OUT pin
   */
  command void CC1000Control.selectLock(uint8_t fn) {
    // Select function of CHP_OUT pin (readable via getLock)
    call HPLCC1000.write(CC1K_LOCK, fn << CC1K_LOCK_SELECT);
  }

  /**
   * Get the binary value from the CHP_OUT pin.  Analog signals cannot be
   * read using function.
   *
   * @return 1 - Pin is high or 0 - Pin is low
   */
  command uint8_t CC1000Control.getLock() {
    return call HPLCC1000.GetLOCK(); 
  }
  
  
  /***************** RecalibrationTimer Events ****************/
  /**
   * Time to recalibrate the radio
   */
  event result_t RecalibrationTimer.fired() {
    post attemptCalibration();
    return SUCCESS;
  }
  
  /***************** Empty ByteRadio Events ****************/
  /**
   * SendReceive wants to send a packet.
   */
  event void ByteRadio.rts() {
  }
  
  /**
   * SendReceive signals this event for every radio-byte-time while
   * listening is enabled and a message isn't being received or
   * transmitted.
   * @param preamble TRUE if a message preamble byte has been received
   */
  async event void ByteRadio.idleByte(bool preamble) {
  }

  /**
   * A message is being received
   */
  async event void ByteRadio.rx() {
  }

  /**
   * Message reception is complete.
   */
  async event void ByteRadio.rxDone() {
  }
  
  /**
   * Transmission complete.
   */
  async event void ByteRadio.sendDone() {
  }
  
  
  /***************** Tasks ****************/
  task void attemptCalibration() {
    if(call ByteRadio.isFree()) {
      call ByteRadio.off();
      singleCalibration();
      call ByteRadio.listen();
      
    } else {
      post attemptCalibration();
    }
  }
  
  
  /***************** Functions ****************/
  /**
   * Run the single calibration algorithm, involving two individual 
   * calibrations.
   */
  void singleCalibration() {
    call HPLCC1000.write(CC1K_PA_POW, 0x00);  // turn off rf amp
    call HPLCC1000.write(CC1K_TEST4, 0x3f);   // chip rate >= 38.4kb

    // RX - configure main freq A
    call HPLCC1000.write(CC1K_MAIN, 1 << CC1K_TX_PD | 1 << CC1K_RESET_N);

    calibrateNow();

    // TX - configure main freq B
    call HPLCC1000.write(CC1K_MAIN,
          1 << CC1K_RXTX |
          1 << CC1K_F_REG |
          1 << CC1K_RX_PD | 
          1 << CC1K_RESET_N);
          
    // Set TX current
    call HPLCC1000.write(CC1K_CURRENT, txCurrent);
    call HPLCC1000.write(CC1K_PA_POW, 0);

    calibrateNow();

    call CC1000Control.rxMode();
  }

  /**
   * Perform a calibration on the pre-selected frequency register
   */
  void calibrateNow() {
    // start cal
    call HPLCC1000.write(CC1K_CAL,
          1 << CC1K_CAL_START |
          1 << CC1K_CAL_WAIT |
          6 << CC1K_CAL_ITERATE);
   
    while ((call HPLCC1000.read(CC1K_CAL) & 1 << CC1K_CAL_COMPLETE) == 0)
      ;

    //exit cal mode
    call HPLCC1000.write(CC1K_CAL, 1 << CC1K_CAL_WAIT | 6 << CC1K_CAL_ITERATE);
  }

  /**
   * Compute an achievable frequency and the necessary CC1K parameters from
   * a given desired frequency (Hz). The function returns the actual achieved
   * channel frequency in Hz.
   *
   * This routine assumes the following:
   *  - Crystal Freq: 14.7456 MHz
   *  - LO Injection: High
   *  - Separation: 64 KHz
   *  - IF: 150 KHz
   * 
   */
  uint32_t calculateFrequency(uint32_t desiredFreq) {
    uint32_t actualFrequency = 0;
    uint32_t rxFreq = 0;
    uint32_t txFreq = 0;
    uint32_t nRef;
    uint32_t fRef;
    uint32_t frequency;
    uint32_t rxCalc;
    uint32_t txCalc;
    int32_t diff;
    int32_t offset = 0x7fffffff;
    uint16_t fsep = 0;
    uint8_t refDiv = 0;
    uint8_t i;
    uint8_t match;
    uint8_t frontend;
    
    for (i = 0; i < 9; i++) {
      nRef = desiredFreq + IF;
      fRef = fRefTbl[i];
      frequency = 0;
      rxCalc = 0;
      txCalc = 0;

      nRef = ((desiredFreq + IF)  <<  2) / fRef;
      if (nRef & 0x1) {
        nRef++;
      }

      if (nRef & 0x2) {
        rxCalc = 16384 >> 1;
        frequency = fRef >> 1;
      }

      nRef >>= 2;

      rxCalc += (nRef * 16384) - 8192;
      if ((rxCalc < FREQ_MIN) || (rxCalc > FREQ_MAX)) {
        continue;
      }
    
      txCalc = rxCalc - corTbl[i];
      if (txCalc < FREQ_MIN || txCalc > FREQ_MAX) {
        continue;
      }
      
      frequency += nRef * fRef;
      frequency -= IF;
      diff = frequency - desiredFreq;
      
      if (diff < 0) {
        diff = -diff;
      }

      if (diff < offset) {
        rxFreq = rxCalc;
        txFreq = txCalc;
        actualFrequency = frequency;
        fsep = fsepTbl[i];
        refDiv = i + 6;
        offset = diff;
      }
    }

    if (refDiv != 0) {
      call HPLCC1000.write(CC1K_FREQ_0A, rxFreq);
      call HPLCC1000.write(CC1K_FREQ_1A, rxFreq >> 8);
      call HPLCC1000.write(CC1K_FREQ_2A, rxFreq >> 16);

      call HPLCC1000.write(CC1K_FREQ_0B, txFreq);
      call HPLCC1000.write(CC1K_FREQ_1B, txFreq >> 8);
      call HPLCC1000.write(CC1K_FREQ_2B, txFreq >> 16);

      call HPLCC1000.write(CC1K_FSEP0, fsep);
      call HPLCC1000.write(CC1K_FSEP1, fsep >> 8);

      if (actualFrequency < 500000000) {
          if (actualFrequency < 400000000) {
            rxCurrent = 8 << CC1K_VCO_CURRENT | 1 << CC1K_LO_DRIVE;
            txCurrent = 9 << CC1K_VCO_CURRENT | 1 << CC1K_PA_DRIVE;
            
          } else {
            rxCurrent = 4 << CC1K_VCO_CURRENT | 1 << CC1K_LO_DRIVE;
            txCurrent = 8 << CC1K_VCO_CURRENT | 1 << CC1K_PA_DRIVE;
          }
          
          frontend = 1 << CC1K_IF_RSSI;
          match = 7 << CC1K_RX_MATCH;
          
      } else {
          rxCurrent = 8 << CC1K_VCO_CURRENT | 3 << CC1K_LO_DRIVE;
          txCurrent = 15 << CC1K_VCO_CURRENT | 3 << CC1K_PA_DRIVE;
          
          frontend = 1 << CC1K_BUF_CURRENT | 2 << CC1K_LNA_CURRENT | 1 << CC1K_IF_RSSI;
          match = 2 << CC1K_RX_MATCH;
      }
      
      call HPLCC1000.write(CC1K_CURRENT, rxCurrent);
      call HPLCC1000.write(CC1K_MATCH, match);
      call HPLCC1000.write(CC1K_FRONT_END, frontend);
      call HPLCC1000.write(CC1K_PLL, refDiv << CC1K_REFDIV);
    }

    return actualFrequency;
  }
  
}
