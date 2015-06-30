/*
 * Copyright (c) 2005 Hewlett-Packard Company
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

#include "CC2420Const.h"

// LEDs
TOSH_ASSIGN_PIN(RED_LED, 1, 5); // unused
TOSH_ASSIGN_PIN(GREEN_LED, 1, 5);
TOSH_ASSIGN_PIN(YELLOW_LED, 1, 6);

//Buttons
#define BUTTON_PORT 6
#define BUTTON1_PIN 4
#define BUTTON2_PIN 5
#define BUTTON3_PIN 6
#define BUTTON4_PIN 7
TOSH_ASSIGN_PIN(BUTTON1, BUTTON_PORT, BUTTON1_PIN);
TOSH_ASSIGN_PIN(BUTTON2, BUTTON_PORT, BUTTON2_PIN);
TOSH_ASSIGN_PIN(BUTTON3, BUTTON_PORT, BUTTON3_PIN);
TOSH_ASSIGN_PIN(BUTTON4, BUTTON_PORT, BUTTON4_PIN);

#define BUTTON1_PUSHED() (!(TOSH_READ_BUTTON1_PIN()) ? 1 : 0)
#define BUTTON2_PUSHED() (!(TOSH_READ_BUTTON2_PIN()) ? 1 : 0)
#define BUTTON3_PUSHED() (!(TOSH_READ_BUTTON3_PIN()) ? 1 : 0)
#define BUTTON4_PUSHED() (!(TOSH_READ_BUTTON4_PIN()) ? 1 : 0)


// CC2420 RADIO #defines
TOSH_ASSIGN_PIN(RADIO_CSN, 5, 4);
TOSH_ASSIGN_PIN(RADIO_VREF, 5, 6);
TOSH_ASSIGN_PIN(RADIO_RESET, 5, 5);
// reworked to go to tp_sw_atn_l 
//TOSH_ASSIGN_PIN(RADIO_FIFOP, 1, 0);
// reworked again to be swapped with lcd_backlight
TOSH_ASSIGN_PIN(RADIO_FIFOP, 2, 1);

TOSH_ASSIGN_PIN(RADIO_SFD, 4, 6);
TOSH_ASSIGN_PIN(RADIO_GIO0, 4, 5);
TOSH_ASSIGN_PIN(RADIO_FIFO, 4, 5);
TOSH_ASSIGN_PIN(RADIO_GIO1, 4, 4);
TOSH_ASSIGN_PIN(RADIO_CCA, 4, 4);
// reworked to go to tp_sw_atn_l 
//TOSH_ASSIGN_PIN(CC_FIFOP, 1, 0);
// reworked again to be swapped with lcd_backlight
TOSH_ASSIGN_PIN(CC_FIFOP, 2, 1);

TOSH_ASSIGN_PIN(CC_FIFO, 4, 5);
TOSH_ASSIGN_PIN(CC_SFD, 4, 6);
TOSH_ASSIGN_PIN(CC_VREN, 5, 6);
TOSH_ASSIGN_PIN(CC_RSTN, 5, 5);


// LCD Pins

#define LCD_LEFT_L_NUM          (2) // CS address slave
#define LCD_RIGHT_L_NUM         (3) // CS address master
#define LCD_RESET_L_NUM         (4) // reset
#define LCD_CMD_L_NUM           (5) // A0 is low for command mode
#define LCD_WR_L_NUM            (6) // assert WR, data latches on edge of deassertion
#define LCD_RD_L_NUM            (7) // assert RD ** first read just latches the data so you need 2 reads to get 1 byte

// these can be the pins or just 2 different bits e.g. 1 2 4 8 ...
#define LCD_LEFT_L_VAL          (4) // CS address slave
#define LCD_RIGHT_L_VAL         (8) // CS address master




#define LCD_DATA_IN_PORT  (P3IN)
#define LCD_DATA_OUT_PORT (P3OUT)
#define LCD_DATA_DIR_PORT (P3DIR)
#define LCD_DATA_READ     (0x00)
#define LCD_DATA_WRITE    (0xff)

//backlight
TOSH_ASSIGN_PIN(LCD_BACKLIGHT, 4, 7);

//data bus
TOSH_ASSIGN_PIN(LCD_D0, 3, 0);
TOSH_ASSIGN_PIN(LCD_D1, 3, 1);
TOSH_ASSIGN_PIN(LCD_D2, 3, 2);
TOSH_ASSIGN_PIN(LCD_D3, 3, 3);
TOSH_ASSIGN_PIN(LCD_D4, 3, 4);
TOSH_ASSIGN_PIN(LCD_D5, 3, 5);
TOSH_ASSIGN_PIN(LCD_D6, 3, 6);
TOSH_ASSIGN_PIN(LCD_D7, 3, 7);

// control lines
TOSH_ASSIGN_PIN(LCD_LEFT_L, 2, LCD_LEFT_L_NUM);
TOSH_ASSIGN_PIN(LCD_RIGHT_L, 2, LCD_RIGHT_L_NUM);
TOSH_ASSIGN_PIN(LCD_RESET_L, 2, LCD_RESET_L_NUM);
TOSH_ASSIGN_PIN(LCD_CMD_L, 2, LCD_CMD_L_NUM);
TOSH_ASSIGN_PIN(LCD_WR_L, 2, LCD_WR_L_NUM);
TOSH_ASSIGN_PIN(LCD_RD_L, 2, LCD_RD_L_NUM);






// battery
//TOSH_ASSIGN_PIN(BATTERY_ADC0, 6, 0);



// UART pins
TOSH_ASSIGN_PIN(UCLK1, 5, 3);
TOSH_ASSIGN_PIN(SOMI1, 5, 2);
TOSH_ASSIGN_PIN(SIMO1, 5, 1);

#define UART_HACK 1
#ifdef UART_HACK
//XXX these are now routed to test points so they dont hurt anyone
TOSH_ASSIGN_PIN(UTXD1, 6, 3);
TOSH_ASSIGN_PIN(URXD1, 5, 7);
#endif




void TOSH_SET_PIN_DIRECTIONS(void)
{
  //LEDS
  TOSH_SET_RED_LED_PIN();
  TOSH_SET_GREEN_LED_PIN();
  TOSH_SET_YELLOW_LED_PIN();
  TOSH_MAKE_RED_LED_OUTPUT();
  TOSH_MAKE_GREEN_LED_OUTPUT();
  TOSH_MAKE_YELLOW_LED_OUTPUT();

  //Buttons
  TOSH_SET_BUTTON1_PIN();
  TOSH_MAKE_BUTTON1_INPUT();
  TOSH_SET_BUTTON2_PIN();
  TOSH_MAKE_BUTTON2_INPUT();
  TOSH_SET_BUTTON3_PIN();
  TOSH_MAKE_BUTTON3_INPUT();
  TOSH_SET_BUTTON4_PIN();
  TOSH_MAKE_BUTTON4_INPUT();


    //RADIO PINS
  //CC2420 pins
  //bavery spi needs to do this
  //TOSH_SET_SOMI1_PIN();
  //TOSH_MAKE_SOMI1_INPUT();
  //TOSH_MAKE_SIMO1_OUTPUT();
  //TOSH_MAKE_UCLK1_OUTPUT();
  TOSH_SET_RADIO_RESET_PIN();
  TOSH_MAKE_RADIO_RESET_OUTPUT();
  TOSH_CLR_RADIO_VREF_PIN();
  TOSH_MAKE_RADIO_VREF_OUTPUT();
  TOSH_SET_RADIO_CSN_PIN();
  TOSH_MAKE_RADIO_CSN_OUTPUT();
  TOSH_MAKE_RADIO_FIFOP_INPUT();
  TOSH_MAKE_RADIO_GIO0_INPUT();
  TOSH_MAKE_RADIO_SFD_INPUT();
  TOSH_MAKE_RADIO_GIO1_INPUT();


  //XXX need to remove eventually
  //UART PINS
#ifdef UART_HACK
  TOSH_MAKE_UTXD1_OUTPUT();
  TOSH_MAKE_URXD1_OUTPUT();
  TOSH_CLR_UTXD1_PIN();
  TOSH_CLR_URXD1_PIN();
#endif


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


  //TOSH_MAKE_BATTERY_ADC0_INPUT();


  
  
}

enum
{
  TOS_ADC_BAT_PORT,
  TOS_ADC_INTERNAL_TEMP_PORT,
  TOS_ADC_INTERNAL_VOLTAGE_PORT
};


enum {
  TOSH_ADC_PORTMAPSIZE = 3 // bat voltage + 2 internals
};

#if 1
enum
{
  TOSH_ACTUAL_ADC_BAT_PORT = ASSOCIATE_ADC_CHANNEL(
         INPUT_CHANNEL_A0, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5
         ),
};

#else

// this worked with a power supply hooked to the A0 pin.  need to gett he 0402 divider properly soldered down
// for a real test.
enum
{
  TOSH_ACTUAL_ADC_BAT_PORT = ASSOCIATE_ADC_CHANNEL(
         INPUT_CHANNEL_A0, REFERENCE_AVcc_AVss, REFVOLT_LEVEL_NONE
         ),
};
#endif

#endif // _H_hardware_h

