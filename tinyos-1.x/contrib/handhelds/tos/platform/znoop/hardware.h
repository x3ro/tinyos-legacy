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

#include "CC2420Const.h"

#define USART0_RTS_CTS 1



// LEDs
TOSH_ASSIGN_PIN(RED_LED, 4, 6);
TOSH_ASSIGN_PIN(YELLOW_LED, 4, 7);

// DEBUG LINES :)
TOSH_ASSIGN_PIN(DEBUG0, 4, 0);
TOSH_ASSIGN_PIN(DEBUG1, 4, 2);
TOSH_ASSIGN_PIN(DEBUG2, 4, 3);
TOSH_ASSIGN_PIN(DEBUG3, 4, 4);
TOSH_ASSIGN_PIN(DEBUG4, 4, 5);
TOSH_ASSIGN_PIN(DEBUG5, 5, 0);
TOSH_ASSIGN_PIN(DEBUG6, 6, 3);
TOSH_ASSIGN_PIN(DEBUG7, 6, 4);
TOSH_ASSIGN_PIN(DEBUG8, 6, 5);

//BSL Pins
TOSH_ASSIGN_PIN(PROG_IN, 1, 1);
TOSH_ASSIGN_PIN(PROG_OUT, 2, 2);


// CC2420 RADIO #defines
TOSH_ASSIGN_PIN(RADIO_FIFO, 1, 0);
TOSH_ASSIGN_PIN(RADIO_FIFOP, 1, 7);

TOSH_ASSIGN_PIN(RADIO_CCA, 1, 5);
TOSH_ASSIGN_PIN(RADIO_CSN, 5, 4);
TOSH_ASSIGN_PIN(RADIO_RESET, 5, 5);
TOSH_ASSIGN_PIN(RADIO_VREF, 5, 6);
TOSH_ASSIGN_PIN(RADIO_SFD, 4, 1);

// flash pins
// no znoopy flash yet
//TOSH_ASSIGN_PIN(FLASH_CS, 2, 3);
//TOSH_ASSIGN_PIN(FLASH_RDY, 2, 5);
//TOSH_ASSIGN_PIN(FLASH_WP, 3, 6);
//TOSH_ASSIGN_PIN(FLASH_RST, 2, 4);


// ADC lines on the testpoints
TOSH_ASSIGN_PIN(ADC_0, 6, 0);
TOSH_ASSIGN_PIN(ADC_1, 6, 1);
TOSH_ASSIGN_PIN(ADC_2, 6, 2);

TOSH_ASSIGN_PIN(DAC0_AN, 6, 6);
TOSH_ASSIGN_PIN(DAC1_AN, 6, 7);




// UART pins
// SPI1 attached to flash, cc2420
TOSH_ASSIGN_PIN(UCLK1, 5, 3);
TOSH_ASSIGN_PIN(SOMI1, 5, 2);
TOSH_ASSIGN_PIN(SIMO1, 5, 1);

// used as GPIOs
TOSH_ASSIGN_PIN(UCLK0, 3, 3);
TOSH_ASSIGN_PIN(SOMI0, 3, 2);
TOSH_ASSIGN_PIN(SIMO0, 3, 1);

// connected to ftdi
TOSH_ASSIGN_PIN(UTXD0, 3, 4);
TOSH_ASSIGN_PIN(URXD0, 3, 5);

//RMS detector
TOSH_ASSIGN_PIN(RMS_EN_L, 5, 7);



#define UART_HACK 1
#ifdef UART_HACK
//XXX these are now routed to test points so they dont hurt anyone
TOSH_ASSIGN_PIN(UTXD1, 2, 6);
TOSH_ASSIGN_PIN(URXD1, 2, 7);
#endif




void TOSH_SET_PIN_DIRECTIONS(void)
{
  // Prog Pins tristate em
  TOSH_MAKE_PROG_IN_INPUT();
  TOSH_MAKE_PROG_OUT_INPUT();
  
  
  //LEDS
  TOSH_SET_RED_LED_PIN();
  TOSH_SET_YELLOW_LED_PIN();
  TOSH_MAKE_RED_LED_OUTPUT();
  TOSH_MAKE_YELLOW_LED_OUTPUT();

    //RADIO PINS
  //CC2420 pins
  TOSH_SET_RADIO_RESET_PIN();
  TOSH_MAKE_RADIO_RESET_OUTPUT();
  TOSH_CLR_RADIO_VREF_PIN();
  TOSH_MAKE_RADIO_VREF_OUTPUT();
  TOSH_SET_RADIO_CSN_PIN();
  TOSH_MAKE_RADIO_CSN_OUTPUT();
  TOSH_MAKE_RADIO_FIFOP_INPUT();
  TOSH_MAKE_RADIO_SFD_INPUT();

  //XXX need to remove eventually
  //UART PINS
#ifdef UART_HACK
  TOSH_MAKE_UTXD1_OUTPUT();
  TOSH_MAKE_URXD1_OUTPUT();
  TOSH_CLR_UTXD1_PIN();
  TOSH_CLR_URXD1_PIN();
#endif
  TOSH_MAKE_UTXD0_OUTPUT();
  TOSH_MAKE_URXD0_INPUT();
  TOSH_SEL_UTXD0_MODFUNC();
  TOSH_SEL_URXD0_MODFUNC();

  TOSH_MAKE_RMS_EN_L_OUTPUT();
  TOSH_CLR_RMS_EN_L_PIN();

  // ADC lines
  TOSH_MAKE_ADC_0_INPUT();
  TOSH_MAKE_ADC_1_INPUT();
  TOSH_MAKE_ADC_2_INPUT();
  
  // the testpoints output by default for debugging
  TOSH_MAKE_DEBUG0_OUTPUT();
  TOSH_CLR_DEBUG0_PIN();
  TOSH_MAKE_DEBUG1_OUTPUT();
  TOSH_CLR_DEBUG1_PIN();
  TOSH_MAKE_DEBUG2_OUTPUT();
  TOSH_CLR_DEBUG2_PIN();
  TOSH_MAKE_DEBUG3_OUTPUT();
  TOSH_CLR_DEBUG3_PIN();
  TOSH_MAKE_DEBUG4_OUTPUT();
  TOSH_CLR_DEBUG4_PIN();
  TOSH_MAKE_DEBUG5_OUTPUT();
  TOSH_CLR_DEBUG5_PIN();
  TOSH_MAKE_DEBUG6_OUTPUT();
  TOSH_CLR_DEBUG6_PIN();
  TOSH_MAKE_DEBUG7_OUTPUT();
  TOSH_CLR_DEBUG7_PIN();
  TOSH_MAKE_DEBUG8_OUTPUT();
  TOSH_CLR_DEBUG8_PIN();

  // wanna set up the dacs to be modfunc here later
  
  
}

#endif // _H_hardware_h

