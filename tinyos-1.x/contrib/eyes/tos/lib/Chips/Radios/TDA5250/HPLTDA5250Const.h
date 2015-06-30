/*
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
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
 * - Description ---------------------------------------------------------
 * Macros for configuring the TDA5250.
 * - Revision ------------------------------------------------------------
 * $Revision: 1.5 $
 * $Date: 2005/11/29 12:16:07 $
 * Author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

#ifndef HPLTDA5250CONST_H
#define HPLTDA5250CONST_H

// List of valid output frequencies for clock
typedef enum {
   NINE_MHZ                        = 0x00,
   FOUR_POINT_FIVE_MHZ             = 0x01,
   THREE_MHZ                       = 0x02,
   TWO_POINT_TWO_FIVE_MHZ          = 0x03,
   ONE_POINT_EIGHT_MHZ             = 0x04,
   ONE_POINT_FIVE_MHZ              = 0x05,
   ONE_POINT_TWO_EIGHT_MHZ         = 0x06,
   ONE_POINT_ONE_TWO_FIVE_MHZ      = 0x07,
   ONE_MHZ                         = 0x08,
   POINT_NINE_MHZ                  = 0x09,
   POINT_EIGHT_TWO_MHZ             = 0x0A,
   POINT_SEVEN_FIVE_MHZ            = 0x0B,
   POINT_SIX_NINE_MHZ              = 0x0C,
   POINT_SIX_FOUR_MHZ              = 0x0D,
   POINT_SIX_MHZ                   = 0x0E,
   POINT_FIVE_SIX_MHZ              = 0x0F,
   THIRTY_TWO_KHZ                  = 0x80,
   WINDOW_COUNT_COMPLETE           = 0xC0,
} TDA5250ClockOutFreqs_t;

#define RECEIVE_FREQUENCY               868.3      // kHz
#define OSCILLATOR_FREQUENCY            ((3.0/4.0) * RECEIVE_FREQUENCY) // kHz
#define INTERMEDIATE_FREQUENCY          ((3.0) * RECEIVE_FREQUENCY) // kHz
#define INTERNAL_OSC_FREQUENCY          32.768 //kHz
#define CLOCK_OUT_BASE_FREQUENCY        18089.6 //kHz
#define CONSTANT_FOR_FREQ_TO_TH_VALUE   2261  //khz of integer for 18089.6/2/4
#define CONVERT_TIME(time)         ((uint16_t)(0xFFFF - ((time*INTERNAL_OSC_FREQUENCY))))
#define CONVERT_FREQ_TO_TH_VALUE(freq, clock_freq) \
           ((CONSTANT_FOR_FREQ_TO_TH_VALUE/(clock_freq*freq))*1000)

#define SYSTEM_SETUP_TIME            394  // 12 ms
#define RECEIVER_SETUP_TIME           94  // 2.86 ms
#define DATA_DETECTION_SETUP_TIME    111  // 3.38 ms
#define RSSI_STABLE_TIME             111  // 3.38 ms
#define CLOCK_OUT_SETUP_TIME          17  // 0.5 ms
#define TRANSMITTER_SETUP_TIME        47  // 1.43 ms
#define XTAL_STARTUP_TIME             17  // 0.5 ms

// Subaddresses of data registers write
#define ADRW_CONFIG            0x00
#define ADRW_FSK               0x01
#define ADRW_XTAL_TUNING       0x02
#define ADRW_LPF               0x03
#define ADRW_ON_TIME           0x04
#define ADRW_OFF_TIME          0x05
#define ADRW_COUNT_TH1         0x06
#define ADRW_COUNT_TH2         0x07
#define ADRW_RSSI_TH3          0x08
#define ADRW_CLK_DIV           0x0D
#define ADRW_XTAL_CONFIG       0x0E
#define ADRW_BLOCK_PD          0x0F

// Subaddresses of data registers read
#define ADRR_STATUS            0x80
#define ADRR_ADC               0x81

// Default values of data registers
#define DATA_CONFIG_DEFAULT           0x04F9
#define DATA_FSK_DEFAULT              0x0A0C
#define DATA_XTAL_TUNING_DEFAULT      0x0012
#define DATA_LPF_DEFAULT              0x6A
#define DATA_ON_TIME_DEFAULT          0xFEC0
#define DATA_OFF_TIME_DEFAULT         0xF380
#define DATA_COUNT_TH1_DEFAULT        0x0000
#define DATA_COUNT_TH2_DEFAULT        0x0001
#define DATA_RSSI_TH3_DEFAULT         0xFF
#define DATA_CLK_DIV_DEFAULT          0x08
#define DATA_XTAL_CONFIG_DEFAULT      0x01
#define DATA_BLOCK_PD_DEFAULT         0xFFFF

// Mask Values for write registers (16 or 8 bit)
/************* Apply these masks by & with original */
#define MASK_CONFIG_SLICER_RC_INTEGRATOR       0x7FFF 
#define MASK_CONFIG_ALL_PD_NORMAL              0xBFFF
#define MASK_CONFIG_TESTMODE_NORMAL            0xDFFF
#define MASK_CONFIG_CONTROL_TXRX_EXTERNAL      0xEFFF
#define MASK_CONFIG_ASK_NFSK_FSK               0xF7FF
#define MASK_CONFIG_RX_NTX_TX                  0xFBFF
#define MASK_CONFIG_CLK_EN_OFF                 0xFDFF
#define MASK_CONFIG_RX_DATA_INV_NO             0xFEFF
#define MASK_CONFIG_D_OUT_IFVALID              0xFF7F
#define MASK_CONFIG_ADC_MODE_ONESHOT           0xFFBF
#define MASK_CONFIG_F_COUNT_MODE_ONESHOT       0xFFDF
#define MASK_CONFIG_LNA_GAIN_LOW               0xFFEF
#define MASK_CONFIG_EN_RX_DISABLE              0xFFF7
#define MASK_CONFIG_MODE_2_SLAVE               0xFFFB
#define MASK_CONFIG_MODE_1_SLAVE_TIMER         0xFFFD
#define MASK_CONFIG_PA_PWR_LOWTX               0xFFFE
/************* Apply these masks by | with original */
#define MASK_CONFIG_SLICER_PEAK_DETECTOR       0x8000
#define MASK_CONFIG_ALL_PD_POWER_DOWN          0x4000
#define MASK_CONFIG_TESTMODE_TESTMODE          0x2000
#define MASK_CONFIG_CONTROL_TXRX_REGISTER      0x1000
#define MASK_CONFIG_ASK_NFSK_ASK               0x0800
#define MASK_CONFIG_RX_NTX_RX                  0x0400
#define MASK_CONFIG_CLK_EN_ON                  0x0200
#define MASK_CONFIG_RX_DATA_INV_YES            0x0100
#define MASK_CONFIG_D_OUT_ALWAYS               0x0080
#define MASK_CONFIG_ADC_MODE_CONT              0x0040
#define MASK_CONFIG_F_COUNT_MODE_CONT          0x0020
#define MASK_CONFIG_LNA_GAIN_HIGH              0x0010
#define MASK_CONFIG_EN_RX_ENABLE               0x0008
#define MASK_CONFIG_MODE_2_TIMER               0x0004
#define MASK_CONFIG_MODE_1_SELF_POLLING        0x0002
#define MASK_CONFIG_PA_PWR_HIGHTX              0x0001

// Mask Values for write registers (16 or 8 bit)
/************* Apply these masks by & with original */
#define CONFIG_SLICER_RC_INTEGRATOR(config)        (config & 0x7FFF)
#define CONFIG_ALL_PD_NORMAL(config)              (config & 0xBFFF)
#define CONFIG_TESTMODE_NORMAL(config)            (config & 0xDFFF)
#define CONFIG_CONTROL_TXRX_EXTERNAL(config)      (config & 0xEFFF)
#define CONFIG_ASK_NFSK_FSK(config)               (config & 0xF7FF)
#define CONFIG_RX_NTX_TX(config)                  (config & 0xFBFF)
#define CONFIG_CLK_EN_OFF(config)                 (config & 0xFDFF)
#define CONFIG_RX_DATA_INV_NO(config)             (config & 0xFEFF)
#define CONFIG_D_OUT_IFVALID(config)              (config & 0xFF7F)
#define CONFIG_ADC_MODE_ONESHOT(config)           (config & 0xFFBF)
#define CONFIG_F_COUNT_MODE_ONESHOT(config)       (config & 0xFFDF)
#define CONFIG_LNA_GAIN_LOW(config)               (config & 0xFFEF)
#define CONFIG_EN_RX_DISABLE(config)              (config & 0xFFF7)
#define CONFIG_MODE_2_SLAVE(config)               (config & 0xFFFB)
#define CONFIG_MODE_1_SLAVE_OR_TIMER(config)      (config & 0xFFFD)
#define CONFIG_PA_PWR_LOWTX(config)               (config & 0xFFFE)
#define XTAL_CONFIG_FET(xtal)                     (xtal & 0xFE)
#define XTAL_CONFIG_FSK_RAMP0_FALSE(xtal)         (xtal & 0xFB)
#define XTAL_CONFIG_FSK_RAMP1_FALSE(xtal)         (xtal & 0xFD)
/************* Apply these masks by | with original */
#define CONFIG_SLICER_PEAK_DETECTOR(config)       (config | 0x8000)
#define CONFIG_ALL_PD_POWER_DOWN(config)          (config | 0x4000)
#define CONFIG_TESTMODE_TESTMODE(config)          (config | 0x2000)
#define CONFIG_CONTROL_TXRX_REGISTER(config)      (config | 0x1000)
#define CONFIG_ASK_NFSK_ASK(config)               (config | 0x0800)
#define CONFIG_RX_NTX_RX(config)                  (config | 0x0400)
#define CONFIG_CLK_EN_ON(config)                  (config | 0x0200)
#define CONFIG_RX_DATA_INV_YES(config)            (config | 0x0100)
#define CONFIG_D_OUT_ALWAYS(config)               (config | 0x0080)
#define CONFIG_ADC_MODE_CONT(config)              (config | 0x0040)
#define CONFIG_F_COUNT_MODE_CONT(config)          (config | 0x0020)
#define CONFIG_LNA_GAIN_HIGH(config)              (config | 0x0010)
#define CONFIG_EN_RX_ENABLE(config)               (config | 0x0008)
#define CONFIG_MODE_2_TIMER(config)               (config | 0x0004)
#define CONFIG_MODE_1_SELF_POLLING(config)        (config | 0x0002)
#define CONFIG_PA_PWR_HIGHTX(config)              (config | 0x0001)
#define XTAL_CONFIG_BIPOLAR(xtal)                 (xtal | 0x01)
#define XTAL_CONFIG_FSK_RAMP0_TRUE(xtal)          (xtal | 0x04)
#define XTAL_CONFIG_FSK_RAMP1_TRUE(xtal)          (xtal | 0x02)

#endif //HPLTDA5250CONST_H
