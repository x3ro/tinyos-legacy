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
 *
 * An MW Clipboard with a MSP430x1611 processor installed
 */

#ifndef _H_hardware_h
#define _H_hardware_h

#include "msp430hardware.h"
#include "MSP430ADC12.h"

#define USART0_RTS_CTS 1

// LEDs
TOSH_ASSIGN_PIN(RED_LED, 1, 5); // unused
TOSH_ASSIGN_PIN(GREEN_LED, 1, 5);
TOSH_ASSIGN_PIN(YELLOW_LED, 1, 6);

//Buttons
#define BUTTON_PORT 2
#define BUTTON1_PIN 3
#define BUTTON2_PIN 2
#define BUTTON3_PIN 1
#define BUTTON4_PIN 0
TOSH_ASSIGN_PIN(BUTTON1, BUTTON_PORT, BUTTON1_PIN);
TOSH_ASSIGN_PIN(BUTTON2, BUTTON_PORT, BUTTON2_PIN);
TOSH_ASSIGN_PIN(BUTTON3, BUTTON_PORT, BUTTON3_PIN);
TOSH_ASSIGN_PIN(BUTTON4, BUTTON_PORT, BUTTON4_PIN);

#define BUTTON1_PUSHED() (!(TOSH_READ_BUTTON1_PIN()) ? 1 : 0)
#define BUTTON2_PUSHED() (!(TOSH_READ_BUTTON2_PIN()) ? 1 : 0)
#define BUTTON3_PUSHED() (!(TOSH_READ_BUTTON3_PIN()) ? 1 : 0)
#define BUTTON4_PUSHED() (!(TOSH_READ_BUTTON4_PIN()) ? 1 : 0)


// CC2420 RADIO #defines
TOSH_ASSIGN_PIN(RADIO_FIFO, 1, 0);
TOSH_ASSIGN_PIN(RADIO_FIFOP, 1, 7);

TOSH_ASSIGN_PIN(RADIO_CCA, 5, 0);
TOSH_ASSIGN_PIN(RADIO_CSN, 5, 4);
TOSH_ASSIGN_PIN(RADIO_RESET, 5, 5);
TOSH_ASSIGN_PIN(RADIO_VREF, 5, 6);
TOSH_ASSIGN_PIN(RADIO_SFD, 5, 7);

// flash pins
TOSH_ASSIGN_PIN(FLASH_CS, 3, 6);
// not avail in rev c is a test point  TOSH_ASSIGN_PIN(FLASH_RDY, 1, 7);
TOSH_ASSIGN_PIN(FLASH_WP, 1, 1);
TOSH_ASSIGN_PIN(FLASH_RST, 3, 7);

// LCD Pins
// no longer all on one port
#define LCD_LEFT_L_NUM          (7) // CS address slave
#define LCD_RIGHT_L_NUM         (6) // CS address master
#define LCD_RESET_L_NUM         (5) // reset
#define LCD_CMD_L_NUM           (4) // A0 is low for command mode
#define LCD_WR_L_NUM            (6) // assert WR, data latches on edge of deassertion
#define LCD_RD_L_NUM            (5) // assert RD ** first read just latches the data so you need 2 reads to get 1 byte

#define LCD_LEFT_L_VAL          (1 << LCD_LEFT_L_NUM) // CS address slave
#define LCD_RIGHT_L_VAL         (1 << LCD_RIGHT_L_NUM) // CS address master

#define LCD_DATA_IN_PORT  (P4IN)
#define LCD_DATA_OUT_PORT (P4OUT)
#define LCD_DATA_DIR_PORT (P4DIR)
#define LCD_DATA_READ     (0x00)
#define LCD_DATA_WRITE    (0xff)

//backlight
TOSH_ASSIGN_PIN(LCD_BACKLIGHT, 6, 7);

//data bus
TOSH_ASSIGN_PIN(LCD_D0, 4, 0);
TOSH_ASSIGN_PIN(LCD_D1, 4, 1);
TOSH_ASSIGN_PIN(LCD_D2, 4, 2);
TOSH_ASSIGN_PIN(LCD_D3, 4, 3);
TOSH_ASSIGN_PIN(LCD_D4, 4, 4);
TOSH_ASSIGN_PIN(LCD_D5, 4, 5);
TOSH_ASSIGN_PIN(LCD_D6, 4, 6);
TOSH_ASSIGN_PIN(LCD_D7, 4, 7);

// control lines
TOSH_ASSIGN_PIN(LCD_LEFT_L, 2, LCD_LEFT_L_NUM);
TOSH_ASSIGN_PIN(LCD_RIGHT_L, 2, LCD_RIGHT_L_NUM);
TOSH_ASSIGN_PIN(LCD_RESET_L, 2, LCD_RESET_L_NUM);
TOSH_ASSIGN_PIN(LCD_CMD_L, 2, LCD_CMD_L_NUM);
TOSH_ASSIGN_PIN(LCD_WR_L, 6, LCD_WR_L_NUM);
TOSH_ASSIGN_PIN(LCD_RD_L, 6, LCD_RD_L_NUM);

// battery
TOSH_ASSIGN_PIN(ADC_0, 6, 0);

// ADC lines on the testpoints
TOSH_ASSIGN_PIN(ADC_1, 6, 1);
TOSH_ASSIGN_PIN(ADC_2, 6, 2);

// UART pins
TOSH_ASSIGN_PIN(UCLK1, 5, 3);
TOSH_ASSIGN_PIN(SOMI1, 5, 2);
TOSH_ASSIGN_PIN(SIMO1, 5, 1);

TOSH_ASSIGN_PIN(UCLK0, 3, 3); /* not to be used for SPI on mwclipboardC used for the irda mcp2150 chip in uart mode*/
TOSH_ASSIGN_PIN(SOMI0, 3, 2); /* not to be used for SPI on mwclipboardC used for the irda mcp2150 chip in uart mode*/
TOSH_ASSIGN_PIN(SIMO0, 3, 1); /* not to be used for SPI on mwclipboardC used for the irda mcp2150 chip in uart mode*/

// UART 0 is used for IrDA on the MCP2150
TOSH_ASSIGN_PIN(UTXD0, 3, 4);
TOSH_ASSIGN_PIN(URXD0, 3, 5);
TOSH_ASSIGN_PIN(RTS0, 3, 3);
TOSH_ASSIGN_PIN(CTS0, 1, 4);
TOSH_ASSIGN_PIN(DSR0, 1, 3);
TOSH_ASSIGN_PIN(DTR0, 6, 3); /* set to 1 */
TOSH_ASSIGN_PIN(CD0, 6, 4); /* set to 1 */

TOSH_ASSIGN_PIN(MCP2150_EN_H, 3, 1);
TOSH_ASSIGN_PIN(MCP2150_RESET_L, 3, 2);

// Xilinx IR transceiver pins
TOSH_ASSIGN_PIN(IR_LOWPRW_H, 3, 0); /* set to 1 */
TOSH_ASSIGN_PIN(IR_RX, 1, 2);   // Direct connection to the IR transceiver RX line (active low)

#define UART_HACK 1
#ifdef UART_HACK
//XXX these are now routed to test points so they dont hurt anyone
TOSH_ASSIGN_PIN(UTXD1, 6, 3);
TOSH_ASSIGN_PIN(URXD1, 6, 4);
#endif

/*
 * After power-on-reset (POR) all pins will be set to digital input
 * To save space, we shouldn't reset them in this module.
 */

void TOSH_SET_PIN_DIRECTIONS(void)
{
  //LEDS (remember, there is no RED LED)
  TOSH_SET_GREEN_LED_PIN();
  TOSH_SET_YELLOW_LED_PIN();
  TOSH_MAKE_GREEN_LED_OUTPUT();
  TOSH_MAKE_YELLOW_LED_OUTPUT();

  //Buttons
  TOSH_SET_BUTTON1_PIN();
  TOSH_SET_BUTTON2_PIN();
  TOSH_SET_BUTTON3_PIN();
  TOSH_SET_BUTTON4_PIN();

  //RADIO CC2420 pins
  TOSH_CLR_RADIO_VREF_PIN();     // Disable the voltage regulator on the CC2420
  TOSH_MAKE_RADIO_VREF_OUTPUT();
  TOSH_SET_RADIO_RESET_PIN();    // Digital reset, active low
  TOSH_MAKE_RADIO_RESET_OUTPUT();
  TOSH_SET_RADIO_CSN_PIN();      // SPI chip select, active low
  TOSH_MAKE_RADIO_CSN_OUTPUT();

  // IrDA MCP2150
  TOSH_MAKE_UTXD0_OUTPUT();
  TOSH_SEL_UTXD0_MODFUNC();
  TOSH_SEL_URXD0_MODFUNC();

  TOSH_SET_RTS0_PIN(); /* set 1: msp430 not ready to receive */
  TOSH_MAKE_RTS0_OUTPUT();
  TOSH_CLR_DTR0_PIN(); /* set 0 so mcp2150 does not enter programming mode */
  TOSH_MAKE_DTR0_OUTPUT();

  TOSH_MAKE_MCP2150_EN_H_OUTPUT();
  TOSH_CLR_MCP2150_EN_H_PIN();    // Disable the MCP2150
  TOSH_MAKE_MCP2150_RESET_L_OUTPUT();
  TOSH_SET_MCP2150_RESET_L_PIN(); 

  // Xilinx IR transceiver
  //  TOSH_MAKE_IR_RX_INPUT();
  TOSH_MAKE_IR_LOWPRW_H_OUTPUT(); 
  TOSH_SET_IR_LOWPRW_H_PIN();     // Low power mode, active high (put IR transceiver to sleep)

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

  // ADC lines on the testpoints output by default for debugging
  //  TOSH_MAKE_ADC_0_INPUT();
  TOSH_MAKE_ADC_1_OUTPUT();
  TOSH_CLR_ADC_1_PIN();
  TOSH_MAKE_ADC_2_OUTPUT();
  TOSH_CLR_ADC_2_PIN();

  // Flash chip settings
  TOSH_MAKE_FLASH_CS_OUTPUT();
  TOSH_SET_FLASH_CS_PIN();
  TOSH_MAKE_FLASH_WP_OUTPUT();
  TOSH_SET_FLASH_WP_PIN();
  TOSH_MAKE_FLASH_RST_OUTPUT();
  TOSH_SET_FLASH_RST_PIN();
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
         INPUT_CHANNEL_A0, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_2_5
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

