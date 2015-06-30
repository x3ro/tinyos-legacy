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
 * XE1205 constants and helper macros and functions.
 *
 * Copyright (C) 2004  Remy Blank, Shockfish SA
 */

/**
 * @author Henri Dubois-Ferriere
 * @author Remy Blank
 *
 */


#ifndef _XE1205CONST_H
#define _XE1205CONST_H

/* 
 * Default settings for some initial parameters.
 */ 

#ifndef XE1205_FREQDEV_DEFAULT
#define XE1205_FREQDEV_DEFAULT  100000
#endif

#ifndef XE1205_BITRATE_DEFAULT
#define XE1205_BITRATE_DEFAULT  76170
#endif


/*
 * Register calculation helper macros.
 */
#define XE1205_FREQ(value_)                     (((value_) * 100) / 50113L)
#define XE1205_EFFECTIVE_FREQ(value_)           (((int32_t)((int16_t)(value_)) * 50113L) / 100)
#define XE1205_FREQ_DEV_HI(value_)              ((XE1205_FREQ(value_) >> 8) & 0x01)
#define XE1205_FREQ_DEV_LO(value_)              (XE1205_FREQ(value_) & 0xff)
#define XE1205_LO_FREQ_HI(value_)               ((XE1205_FREQ(value_) >> 8) & 0xff)
#define XE1205_LO_FREQ_LO(value_)               (XE1205_FREQ(value_) & 0xff)
#define XE1205_BIT_RATE(value_)                 ((152340L / (value_) - 1) & 0x7f)
#define XE1205_EFFECTIVE_BIT_RATE(value_)       (152340L / ((value_) + 1))
#define XE1205_OUTPUT_POWER(value_)             ((((value_) / 5) & 0x3) << 6)

/*
 * Register address generators.
 */
#define XE1205_WRITE(register_)                 (((register_) << 1) | 0x01)
#define XE1205_READ(register_)                  (((register_) << 1) | 0x41)

/**
 * Register addresses.
 */
enum {
  MCParam_0 = 0,
  MCParam_1 = 1,
  MCParam_2 = 2,
  MCParam_3 = 3,
  MCParam_4 = 4,
  IRQParam_5 = 5,
  IRQParam_6 = 6,
  TXParam_7 = 7,
  RXParam_8 = 8,
  RXParam_9 = 9,
  RXParam_10 = 10,
  RXParam_11 = 11,
  RXParam_12 = 12,
  Pattern_13 = 13,
  Pattern_14 = 14,
  Pattern_15 = 15,
  Pattern_16 = 16,
  OSCParam_17 = 17,
  OSCParam_18 = 18,
  TParam_19 = 19,
  TParam_21 = 21,
  TParam_22 = 22,
  Xe1205_RegCount
};

/**
 * Frequency bands.
 */
enum {
  Xe1205_Band_434 = 434000000,
  Xe1205_Band_869 = 869000000,
  Xe1205_Band_915 = 915000000
};

/**
 * Receiver modes.
 */
enum {
  Xe1205_LnaModeA = 0,
  Xe1205_LnaModeB = 1
};

/**
 * Packet detection pattern and ack code.
 */
enum {
  Xe1205_lplPattern = 0x555555,
  Xe1205_Pattern = 0x123456,
  Xe1205_Ack_code = 0x789abc
};


/** 
 * Radio Transition times.
 * See Table 4 of the XE1205 data sheet.
 */
enum {
  Xe1205_TS_SRE = 700,   // RX wakeup time (us), with quartz oscillator enabled
  Xe1205_TS_RE = 500,    // RX wakeup time (us), with freq. synthesizer enabled
  Xe1205_TS_STR = 250,   // TX wakeup time (us), with quartz oscillator enabled
  Xe1205_TS_TR = 100,    // TX wakeup time (us), with freq. synthesizer enabled
  Xe1205_TS_FS = 200,    // Frequency synthesizer wakeup time
  Xe1205_TS_OS = 1000    // Quartz oscillator wakeup time ( xxx 7ms for 3rd overtone????)
};


/**
 * More recognizable aliases for the above transition times.
 */
enum {
  Xe1205_Sleep_to_Standby_Time = Xe1205_TS_OS, 
  Xe1205_Standby_to_RX_Time = Xe1205_TS_SRE, 
  Xe1205_Standby_to_TX_Time = Xe1205_TS_STR, 
  Xe1205_TX_to_RX_Time = Xe1205_TS_RE, 
  Xe1205_RX_to_TX_Time = Xe1205_TS_TR,
  Xe1205_Sleep_to_RX_Time = Xe1205_Sleep_to_Standby_Time + Xe1205_Standby_to_RX_Time, 
  Xe1205_Sleep_to_TX_Time = Xe1205_Sleep_to_Standby_Time + Xe1205_Standby_to_TX_Time
};



/** 
 * RSSI related values and helpers.
 */


// returns the period (in us) between two successive rssi measurements
// (see xemics data sheet 4.2.3.4), as a function of frequency deviation
uint16_t rssi_meas_time(uint32_t freqdev_hz) {
  if (freqdev_hz > 20000)      // at 152kbps, equiv to 2 byte times, at 76kbps, equiv to 1 byte time, at 38kbps equiv to 4 bits, etc
    return 100;
  else if (freqdev_hz > 10000) // at 9.6kbps, equiv to 4 byte times.
    return 200;           
  else if (freqdev_hz > 7000)
    return 300;
  else if (freqdev_hz > 5000)  // at 4.8kbps, equiv to 4 byte times.
    return 400;
  else 
    return 500;                // at 1200, equiv to 13 byte times.
}

// returns appropriate freq. deviation for given bitrate in bits/sec.
uint32_t freq_dev_from_bitrate(uint32_t bitrate) {
  return (bitrate * 6) / 5;
}

// returns appropriate baseband filter bw for given bitrate in bits/sec.
uint16_t baseband_bw_from_bitrate(uint32_t bitrate) {
  return (bitrate * 400) /152340;
}

enum {
  RSSI_BELOW_110 = 0,
  RSSI_110_TO_105 = 1,
  RSSI_105_TO_100 = 2,
  RSSI_100_TO_95 = 3,
  RSSI_95_TO_90 = 4,
  RSSI_90_TO_85 = 5,
  RSSI_ABOVE_85 = 6
};

#define XE1205_RSSI_RANGE(rssi) (rssi >> 2)
#define XE1205_RSSI_VALUE(rssi) (rssi & 0x3)

// rssiTab[(rssiHi << 2) | rssiLo] : convert 2-bit high and low range measures into 3 bits
// Low and high RSSI measurs cannot be made simulataneously, so it is possible that they are "inconsistent" 
// (ie low range measurement says below -100dBm but high range says above -95 dBm)
uint8_t const rssiTab[] = {
  RSSI_BELOW_110,  // 0b0000
  RSSI_110_TO_105, // 0b0001
  RSSI_105_TO_100, // 0b0010
  RSSI_100_TO_95,  // 0b0011
  RSSI_95_TO_90,   // 0b0100 *
  RSSI_95_TO_90,   // 0b0101 *
  RSSI_95_TO_90,   // 0b0110 *
  RSSI_95_TO_90,   // 0b0111
  RSSI_90_TO_85,   // 0b1000 *
  RSSI_90_TO_85,   // 0b1001 *
  RSSI_90_TO_85,   // 0b1010 *
  RSSI_90_TO_85,   // 0b1011 
  RSSI_ABOVE_85,   // 0b1100 *
  RSSI_ABOVE_85,   // 0b1101 *
  RSSI_ABOVE_85,   // 0b1110 *
  RSSI_ABOVE_85    // 0b1111 
  // (*) : 'inconsistent' pairs
};

inline uint8_t rssiFromPair(uint8_t rssiHigh, uint8_t rssiLow) {
  return rssiTab[(rssiHigh << 2) | rssiLow];
}

/**
 * Set and clear specific bits in a byte.
 */
static inline void setReset(uint8_t* ptr_, uint8_t set_, uint8_t reset_)
{
  *ptr_ = (*ptr_ & ~reset_) | set_;
}



/** 
 *  LPL-related constants.
 **/
enum {
  XE1205_LPL_STATES = 4
};


/*
 * Number of LPL preambles (16 bytes each) to send before a packet.
 */
uint16_t const Xe1205_LPL_NPreambles[XE1205_LPL_STATES] = {
  0, 
  15,  
  50,
  205
};

uint16_t const Xe1205_LPL_SleepTimeNPreambles[XE1205_LPL_STATES] = {
  0,
  13, // 10% RX duty cycle at 76kbps
  47, // 3% RX duty cycle at 76kbps
  178 // 0.8% RX duty cycle at 76kbps
};


#endif /* _XE1205CONST_H */

