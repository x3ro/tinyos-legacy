// $Id: hardware.h,v 1.3 2006/02/07 15:36:23 rogmeier Exp $

/*									tab:2
 *
 *
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
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

#ifndef __HARDWARE_H__
#define __HARDWARE_H__

#include "msp430hardware.h"

// internal flash is 16 bits in width
typedef uint16_t in_flash_addr_t;
// external flash is 32 bits in width
typedef uint32_t ex_flash_addr_t;

void wait(uint16_t t) {
  for ( ; t > 0; t-- );
}

// LEDs
TOSH_ASSIGN_PIN(RED_LED, 1, 6);
TOSH_ASSIGN_PIN(GREEN_LED, 2, 3);
TOSH_ASSIGN_PIN(YELLOW_LED, 2, 4);

// FLASH
TOSH_ASSIGN_PIN(FLASH_OUT, 3, 1); // = SIMO0
TOSH_ASSIGN_PIN(FLASH_IN, 3, 2); // = SOMI0
TOSH_ASSIGN_PIN(FLASH_CLK, 3, 3); // = UCLK0
TOSH_ASSIGN_PIN(FLASH_PWR, 4, 3);
TOSH_ASSIGN_PIN(FLASH_CS, 4, 7);
TOSH_ASSIGN_PIN(FLASH_RST, 4, 6);

void TOSH_SET_PIN_DIRECTIONS(void)
{
  //LEDS
  TOSH_CLR_RED_LED_PIN();
  TOSH_CLR_GREEN_LED_PIN();
  TOSH_CLR_YELLOW_LED_PIN();
  TOSH_MAKE_RED_LED_OUTPUT();
  TOSH_MAKE_GREEN_LED_OUTPUT();
  TOSH_MAKE_YELLOW_LED_OUTPUT();

  //FLASH PINS
  TOSH_MAKE_FLASH_OUT_OUTPUT();
  TOSH_MAKE_FLASH_IN_INPUT();
  TOSH_MAKE_FLASH_CLK_OUTPUT();
  TOSH_MAKE_FLASH_PWR_OUTPUT();
  TOSH_SET_FLASH_PWR_PIN();
  TOSH_MAKE_FLASH_CS_OUTPUT();
  TOSH_SET_FLASH_CS_PIN();
  TOSH_SET_FLASH_RST_PIN();
  TOSH_MAKE_FLASH_RST_OUTPUT();
}

#endif
