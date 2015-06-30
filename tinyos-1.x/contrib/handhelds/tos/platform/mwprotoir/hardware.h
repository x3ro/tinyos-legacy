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

// msp2150 cts pin
TOSH_ASSIGN_PIN(CTS0, 1, 5);

// LEDs
TOSH_ASSIGN_PIN(RED_LED_1, 4, 4);
TOSH_ASSIGN_PIN(RED_LED_2, 4, 5); 
TOSH_ASSIGN_PIN(GREEN_LED, 4, 6);
TOSH_ASSIGN_PIN(YELLOW_LED, 4, 7);

// LCD Pins

#define LCD_LEFT_L_NUM          (2) // CS address slave
#define LCD_RIGHT_L_NUM         (3) // CS address master
#define LCD_RESET_L_NUM         (4) // reset
#define LCD_CMD_L_NUM           (5) // A0 is low for command mode
#define LCD_WR_L_NUM            (6) // assert WR, data latches on edge of deassertion
#define LCD_RD_L_NUM            (7) // assert RD ** first read just latches the data so you need 2 reads to get 1 byte

#define LCD_LEFT_L_VAL          (1 << LCD_LEFT_L_NUM) // CS address slave
#define LCD_RIGHT_L_VAL         (1 << LCD_RIGHT_L_NUM) // CS address master
#define LCD_RESET_L_VAL         (1 << LCD_RESET_L_NUM) // reset
#define LCD_CMD_L_VAL           (1 << LCD_CMD_L_NUM) // A0 is low for command mode
#define LCD_WR_L_VAL            (1 << LCD_WR_L_NUM) // assert WR, data latches on edge of deassertion
#define LCD_RD_L_VAL            (1 << LCD_RD_L_NUM) // assert RD ** first read just latches the data so you need 2 reads to get 1 byte


#define LCD_CMD_PORT      (P2OUT)
#define LCD_CMD_MASK      (0xfc)
#define LCD_DATA_IN_PORT  (P3IN)
#define LCD_DATA_OUT_PORT (P3OUT)
#define LCD_DATA_DIR_PORT (P3DIR)


#define LCD_DATA_READ     (0x00)
#define LCD_DATA_WRITE    (0xff)

//backlight
TOSH_ASSIGN_PIN(LCD_BACKLIGHT, 1, 4);

//data bus
TOSH_ASSIGN_PIN(LCD_D0, 3, 0);
TOSH_ASSIGN_PIN(LCD_D1, 3, 1);
TOSH_ASSIGN_PIN(LCD_D2, 3, 2);
TOSH_ASSIGN_PIN(LCD_D3, 3, 3);
// hacked for uart test
TOSH_ASSIGN_PIN(LCD_D4, 5, 4);
TOSH_ASSIGN_PIN(LCD_D5, 5, 5);
//
TOSH_ASSIGN_PIN(LCD_D6, 3, 6);
TOSH_ASSIGN_PIN(LCD_D7, 3, 7);

// UART pins
// first three are dummies, used by lcd
TOSH_ASSIGN_PIN(SOMI0, 3, 2);
TOSH_ASSIGN_PIN(SIMO0, 3, 1);
TOSH_ASSIGN_PIN(UCLK0, 3, 3);
TOSH_ASSIGN_PIN(UTXD0, 3, 4);
TOSH_ASSIGN_PIN(URXD0, 3, 5);

// control lines
TOSH_ASSIGN_PIN(LCD_LEFT_L, 2, LCD_LEFT_L_NUM);
TOSH_ASSIGN_PIN(LCD_RIGHT_L, 2, LCD_RIGHT_L_NUM);
TOSH_ASSIGN_PIN(LCD_RESET_L, 2, LCD_RESET_L_NUM);
TOSH_ASSIGN_PIN(LCD_CMD_L, 2, LCD_CMD_L_NUM);
TOSH_ASSIGN_PIN(LCD_WR_L, 2, LCD_WR_L_NUM);
TOSH_ASSIGN_PIN(LCD_RD_L, 2, LCD_RD_L_NUM);



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

  //UART PINS

  TOSH_MAKE_UTXD0_OUTPUT();
  TOSH_CLR_UTXD0_PIN();
  TOSH_CLR_URXD0_PIN();

  // LCD
  TOSH_MAKE_LCD_BACKLIGHT_OUTPUT();
  TOSH_CLR_LCD_BACKLIGHT_PIN();
  // control lines the state of the
  // data lines is controlled by the code
  // as it is a bidirectional bus
  TOSH_MAKE_LCD_LEFT_L_OUTPUT();
  TOSH_SET_LCD_LEFT_L_PIN();
  TOSH_MAKE_LCD_RIGHT_L_OUTPUT();
  TOSH_SET_LCD_RIGHT_L_PIN();
  TOSH_MAKE_LCD_RESET_L_OUTPUT();
  TOSH_SET_LCD_RESET_L_PIN();
  TOSH_MAKE_LCD_CMD_L_OUTPUT();
  TOSH_SET_LCD_CMD_L_PIN();
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





  
  
}


#endif // _H_hardware_h

