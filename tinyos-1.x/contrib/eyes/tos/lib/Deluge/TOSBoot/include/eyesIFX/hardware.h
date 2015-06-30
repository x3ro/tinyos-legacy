/*
 * Copyright (c) 2004, Technische Universität Berlin
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
 * - Neither the name of the Technische Universität Berlin nor the names
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
 * $Id: hardware.h,v 1.1 2004/09/07 18:59:41 janhauer Exp $
 *
 */

#ifndef TOSH_HARDWARE_EYESIFX
#define TOSH_HARDWARE_EYESIFX

#include "msp430hardware.h"
#include "MSP430ADC12.h" 

// LED assignments
TOSH_ASSIGN_PIN(RED_LED, 5, 0); // Compatibility with the mica2
TOSH_ASSIGN_PIN(GREEN_LED, 5, 1);
TOSH_ASSIGN_PIN(YELLOW_LED, 5, 2);

// Debug Pin assignments
TOSH_ASSIGN_PIN(DEBUG_PIN1, 1, 2);
TOSH_ASSIGN_PIN(DEBUG_PIN2, 1, 3);

TOSH_ASSIGN_PIN(LED0, 5, 0);
TOSH_ASSIGN_PIN(LED1, 5, 1);
TOSH_ASSIGN_PIN(LED2, 5, 2);
TOSH_ASSIGN_PIN(LED3, 5, 3);

// TDA5250 assignments
TOSH_ASSIGN_PIN(TDA_PWDDD, 1, 0); // TDA PWDDD
TOSH_ASSIGN_PIN(TDA_DATA, 1, 1);  // TDA DATA (timerA, CCI0A)
TOSH_ASSIGN_PIN(TDA_TXRX, 1, 4);  // TDA TX/RX
TOSH_ASSIGN_PIN(TDA_BUSM, 1, 5);  // TDA BUSM
TOSH_ASSIGN_PIN(TDA_ENTDA, 1, 6); // TDA EN_TDA

// USART0 assignments
TOSH_ASSIGN_PIN(SIMO0, 3, 1); // SIMO (MSP) -> BUSDATA (TDA5250)
TOSH_ASSIGN_PIN(SOMI0, 3, 2); // SOMI (MSP) -> BUSDATA (TDA5250)
TOSH_ASSIGN_PIN(UCLK0, 3, 3); // UCLK (MSP) -> BUSCLK (TDA5250)
TOSH_ASSIGN_PIN(UTXD0, 3, 4);   // USART0 -> data1 (TDA5250)
TOSH_ASSIGN_PIN(URXD0, 3, 5);   // USART0 -> data1 (TDA5250)

// USART1 assignments
TOSH_ASSIGN_PIN(UTXD1, 3, 6);   // USART1 -> ST3232
TOSH_ASSIGN_PIN(URXD1, 3, 7);   // USART1 -> ST3232
TOSH_ASSIGN_PIN(UCLK1, 5, 3);
TOSH_ASSIGN_PIN(SOMI1, 5, 2);
TOSH_ASSIGN_PIN(SIMO1, 5, 1);

// Sensor assignments
TOSH_ASSIGN_PIN(RSSI, 6, 3);
TOSH_ASSIGN_PIN(TEMPERATURE, 6, 0);
TOSH_ASSIGN_PIN(LIGHT, 6, 2);

// Potentiometer
TOSH_ASSIGN_PIN(POT_EN, 2, 4);
TOSH_ASSIGN_PIN(POT_SD, 2, 3);

// Flash 
TOSH_ASSIGN_PIN(FLASH_CS, 1, 7);

void TOSH_SET_PIN_DIRECTIONS(void)
{
  TOSH_CLR_RED_LED_PIN();
  TOSH_MAKE_RED_LED_OUTPUT();
  TOSH_CLR_GREEN_LED_PIN();
  TOSH_MAKE_GREEN_LED_OUTPUT();
  TOSH_CLR_YELLOW_LED_PIN();
  TOSH_MAKE_YELLOW_LED_OUTPUT();
  TOSH_CLR_LED3_PIN();
  TOSH_MAKE_LED3_OUTPUT();

  TOSH_SEL_RSSI_MODFUNC();
  TOSH_MAKE_RSSI_INPUT();

  TOSH_SEL_TEMPERATURE_MODFUNC();
  TOSH_MAKE_TEMPERATURE_INPUT();

  TOSH_SEL_LIGHT_MODFUNC();
  TOSH_MAKE_LIGHT_INPUT();
  
  TOSH_CLR_DEBUG_PIN1_PIN();
  TOSH_CLR_DEBUG_PIN2_PIN();
  TOSH_MAKE_DEBUG_PIN1_OUTPUT();
  TOSH_MAKE_DEBUG_PIN2_OUTPUT();

  TOSH_SEL_FLASH_CS_IOFUNC();
  TOSH_SET_FLASH_CS_PIN();
  TOSH_MAKE_FLASH_CS_OUTPUT();    
}

enum
{
  TOS_ADC_RSSI_PORT,                                // RSSI
  TOS_ADC_TEMPERATURE_PORT,                         // ext. TEMPERATURE
  TOS_ADC_LIGHT_PORT,                               // LIGHT
  TOS_ADC_EXTERNAL_REFERENCE_VOLTAGE_PORT,          // VeREF+ (input channel 8)
  TOS_ADC_REFERENCE_VOLTAGE_NEGATIVE_TERMINAL_PORT, // VREF-/VeREF- (input channel 9)
  TOS_ADC_INTERNAL_TEMP_PORT,                       // Temperature diode (input channel 10)
  TOS_ADC_INTERNAL_VOLTAGE_PORT                     // (AVcc-AVss)/2 (input channel 11-15)
};

enum 
{
  TOSH_ADC_PORTMAPSIZE = 7        // this should be the number of members in the above enum
};

enum
{
  TOSH_ACTUAL_ADC_RSSI_PORT = ASSOCIATE_ADC_CHANNEL( INPUT_CHANNEL_A3, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5), 
  TOSH_ACTUAL_ADC_TEMPERATURE_PORT = ASSOCIATE_ADC_CHANNEL( INPUT_CHANNEL_A0, REFERENCE_AVcc_AVss, REFVOLT_LEVEL_NONE),
  TOSH_ACTUAL_ADC_LIGHT_PORT = ASSOCIATE_ADC_CHANNEL( INPUT_CHANNEL_A2, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5)
};

#define RSSI_ADC12_STANDARD_SETTINGS   SET_ADC12_STANDARD_SETTINGS(INPUT_CHANNEL_A3, \
                                                                   REFERENCE_VREFplus_AVss, \
                                                                   SAMPLE_HOLD_4_CYCLES, \
                                                                   REFVOLT_LEVEL_1_5)
#define PHOTO_ADC12_STANDARD_SETTINGS  SET_ADC12_STANDARD_SETTINGS(INPUT_CHANNEL_A2, \
                                                                   REFERENCE_VREFplus_AVss, \
                                                                   SAMPLE_HOLD_64_CYCLES, \
                                                                   REFVOLT_LEVEL_1_5)
#define TEMP_ADC12_STANDARD_SETTINGS   SET_ADC12_STANDARD_SETTINGS(INPUT_CHANNEL_A0, \
                                                                   REFERENCE_AVcc_AVss, \
                                                                   SAMPLE_HOLD_4_CYCLES, \
                                                                   REFVOLT_LEVEL_1_5)
                                                                   
#define RSSI_ADC12_ADVANCED_SETTINGS   SET_ADC12_ADVANCED_SETTINGS(INPUT_CHANNEL_A3, \
                                                                   REFERENCE_VREFplus_AVss, \
                                                                   SAMPLE_HOLD_4_CYCLES, \
                                                                   CLOCK_SOURCE_SMCLK, \
                                                                   CLOCK_DIV_1, \
                                                                   HOLDSOURCE_TIMERB_OUT0,\
                                                                   REFVOLT_LEVEL_1_5)
#define PHOTO_ADC12_ADVANCED_SETTINGS  SET_ADC12_ADVANCED_SETTINGS(INPUT_CHANNEL_A2, \
                                                                   REFERENCE_VREFplus_AVss, \
                                                                   SAMPLE_HOLD_64_CYCLES, \
                                                                   CLOCK_SOURCE_SMCLK, \
                                                                   CLOCK_DIV_1, \
                                                                   HOLDSOURCE_TIMERB_OUT0,\
                                                                   REFVOLT_LEVEL_1_5)
#define TEMP_ADC12_ADVANCED_SETTINGS   SET_ADC12_ADVANCED_SETTINGS(INPUT_CHANNEL_A0, \
                                                                   REFERENCE_AVcc_AVss, \
                                                                   SAMPLE_HOLD_4_CYCLES, \
                                                                   CLOCK_SOURCE_SMCLK, \
                                                                   CLOCK_DIV_1, \
                                                                   HOLDSOURCE_TIMERB_OUT0, \
                                                                   REFVOLT_LEVEL_1_5)
#endif //TOSH_HARDWARE_H
