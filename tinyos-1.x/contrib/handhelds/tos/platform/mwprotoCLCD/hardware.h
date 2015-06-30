/*
 * Copyright (c) 2004,2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef _H_hardware_h
#define _H_hardware_h

#include "msp430hardware.h"
#include "MSP430ADC12.h"

// LEDs
TOSH_ASSIGN_PIN(RED_LED_1, 4, 4);
TOSH_ASSIGN_PIN(RED_LED_2, 4, 5); 
TOSH_ASSIGN_PIN(GREEN_LED, 4, 6);
TOSH_ASSIGN_PIN(YELLOW_LED, 4, 7);

// LCD Pins

//data bus
TOSH_ASSIGN_PIN(LCD_D0, 5, 0);
TOSH_ASSIGN_PIN(LCD_D1, 5, 1);
TOSH_ASSIGN_PIN(LCD_D2, 5, 2);
TOSH_ASSIGN_PIN(LCD_D3, 5, 3);
TOSH_ASSIGN_PIN(LCD_D4, 5, 4);
TOSH_ASSIGN_PIN(LCD_D5, 5, 5);
TOSH_ASSIGN_PIN(LCD_D6, 5, 6);
TOSH_ASSIGN_PIN(LCD_D7, 5, 7);

// control lines
TOSH_ASSIGN_PIN(LCD_RESET_L, 4, 3);
TOSH_ASSIGN_PIN(LCD_WR_L, 1, 6);
TOSH_ASSIGN_PIN(LCD_RD_L, 1, 5);
TOSH_ASSIGN_PIN(LCD_RS, 1, 7);
TOSH_ASSIGN_PIN(LCD_CS_L, 4, 2);



// ADC lines on the header
#if 1
TOSH_ASSIGN_PIN(ADC_1, 6, 1);
TOSH_ASSIGN_PIN(ADC_2, 6, 2);
TOSH_ASSIGN_PIN(ADC_3, 6, 3);
TOSH_ASSIGN_PIN(ADC_4, 6, 4);
TOSH_ASSIGN_PIN(ADC_5, 6, 5);
TOSH_ASSIGN_PIN(ADC_6, 6, 6);
TOSH_ASSIGN_PIN(ADC_7, 6, 7);
#endif





void TOSH_SET_PIN_DIRECTIONS(void)
{
  //LEDS
  TOSH_MAKE_RED_LED_1_OUTPUT();
  TOSH_MAKE_RED_LED_2_OUTPUT();
  TOSH_MAKE_GREEN_LED_OUTPUT();
  TOSH_MAKE_YELLOW_LED_OUTPUT();

  TOSH_SET_RED_LED_1_PIN();
  TOSH_SET_RED_LED_2_PIN();
  TOSH_SET_GREEN_LED_PIN();
  TOSH_SET_YELLOW_LED_PIN();


  // LCD
#if 0
  TOSH_MAKE_LCD_BACKLIGHT_OUTPUT();
  TOSH_CLR_LCD_BACKLIGHT_PIN();
#endif
  // control lines the state of the
  // data lines is controlled by the code
  // as it is a bidirectional bus
  TOSH_MAKE_LCD_RS_OUTPUT();
  TOSH_SET_LCD_RS_PIN();
  TOSH_MAKE_LCD_CS_L_OUTPUT();
  TOSH_SET_LCD_CS_L_PIN();
  TOSH_MAKE_LCD_RESET_L_OUTPUT();
  TOSH_SET_LCD_RESET_L_PIN();
  TOSH_MAKE_LCD_WR_L_OUTPUT();
  TOSH_SET_LCD_WR_L_PIN();
  TOSH_MAKE_LCD_RD_L_OUTPUT();
  TOSH_SET_LCD_RD_L_PIN();

  TOSH_MAKE_LCD_D0_OUTPUT();
  TOSH_SET_LCD_D0_PIN();
  TOSH_MAKE_LCD_D1_OUTPUT();
  TOSH_SET_LCD_D1_PIN();
  TOSH_MAKE_LCD_D2_OUTPUT();
  TOSH_SET_LCD_D2_PIN();
  TOSH_MAKE_LCD_D3_OUTPUT();
  TOSH_SET_LCD_D3_PIN();
  TOSH_MAKE_LCD_D4_OUTPUT();
  TOSH_SET_LCD_D4_PIN();
  TOSH_MAKE_LCD_D5_OUTPUT();
  TOSH_SET_LCD_D5_PIN();
  TOSH_MAKE_LCD_D6_OUTPUT();
  TOSH_SET_LCD_D6_PIN();
  TOSH_MAKE_LCD_D7_OUTPUT();
  TOSH_SET_LCD_D7_PIN();


  // ADC lines on the header output by default
#if 1
  TOSH_MAKE_ADC_1_OUTPUT();
  TOSH_SET_ADC_1_PIN();
  TOSH_MAKE_ADC_2_OUTPUT();
  TOSH_SET_ADC_2_PIN();
  TOSH_MAKE_ADC_3_OUTPUT();
  TOSH_SET_ADC_3_PIN();
  TOSH_MAKE_ADC_4_OUTPUT();
  TOSH_SET_ADC_4_PIN();
  TOSH_MAKE_ADC_5_OUTPUT();
  TOSH_SET_ADC_5_PIN();
  TOSH_MAKE_ADC_6_OUTPUT();
  TOSH_SET_ADC_6_PIN();
  TOSH_MAKE_ADC_7_OUTPUT();
  TOSH_SET_ADC_7_PIN();
#endif


  
}


#endif // _H_hardware_h

