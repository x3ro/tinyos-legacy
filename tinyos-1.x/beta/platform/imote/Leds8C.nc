/*
 * Copyright (c) 2004, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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

module Leds8C {
  provides interface Leds8;
}
implementation
{
/* for now - why??? */
// #define dbg(a,b) 

  uint8_t ledsOn;

  command result_t Leds8.init() {
    ledsOn = 0;
    // dbg(DBG_BOOT, "LEDS: initialized.\n");

    TOSH_MAKE_LED0_OUTPUT();
    TOSH_MAKE_LED1_OUTPUT();
    TOSH_MAKE_LED2_OUTPUT();
    TOSH_MAKE_LED3_OUTPUT();
    TOSH_MAKE_LED4_OUTPUT();
    TOSH_MAKE_LED5_OUTPUT();
    TOSH_MAKE_LED6_OUTPUT();
    TOSH_MAKE_LED7_OUTPUT();

    TOSH_CLR_LED0_PIN();
    TOSH_CLR_LED1_PIN();
    TOSH_CLR_LED2_PIN();
    TOSH_CLR_LED3_PIN();
    TOSH_CLR_LED4_PIN();
    TOSH_CLR_LED5_PIN();
    TOSH_CLR_LED6_PIN();
    TOSH_CLR_LED7_PIN();

    return SUCCESS;
  }

  // Inefficient implementation to maintain TOSH_SET_<name>_PIN macros
  // Can optimize by exposing parameterized I/O ports to interface.
  command result_t Leds8.bitOn(uint8_t bit) {
    switch (bit) {
      case 0: TOSH_SET_LED0_PIN(); break;
      case 1: TOSH_SET_LED1_PIN(); break;
      case 2: TOSH_SET_LED2_PIN(); break;
      case 3: TOSH_SET_LED3_PIN(); break;
      case 4: TOSH_SET_LED4_PIN(); break;
      case 5: TOSH_SET_LED5_PIN(); break;
      case 6: TOSH_SET_LED6_PIN(); break;
      case 7: TOSH_SET_LED7_PIN(); break;
      default:
    }
    ledsOn |= (1 << bit);
    return SUCCESS;
  }

  command result_t Leds8.bitOff(uint8_t bit) {
    switch (bit) {
      case 0: TOSH_CLR_LED0_PIN(); break;
      case 1: TOSH_CLR_LED1_PIN(); break;
      case 2: TOSH_CLR_LED2_PIN(); break;
      case 3: TOSH_CLR_LED3_PIN(); break;
      case 4: TOSH_CLR_LED4_PIN(); break;
      case 5: TOSH_CLR_LED5_PIN(); break;
      case 6: TOSH_CLR_LED6_PIN(); break;
      case 7: TOSH_CLR_LED7_PIN(); break;
      default:
    }
    ledsOn &= ~(1 << bit);
    return SUCCESS;
  }

  command result_t Leds8.bitToggle(uint8_t bit) {
    if (ledsOn & (1 << bit))
      return call Leds8.bitOff(bit);
    else
      return call Leds8.bitOn(bit);
  }

  command uint8_t Leds8.get() {
     return ledsOn;
  }

  command result_t Leds8.set(uint8_t ledsNum) {
     ledsOn = ledsNum;
     (ledsOn & (1 << 0)) ? TOSH_SET_LED0_PIN() : TOSH_CLR_LED0_PIN();
     (ledsOn & (1 << 1)) ? TOSH_SET_LED1_PIN() : TOSH_CLR_LED1_PIN();
     (ledsOn & (1 << 2)) ? TOSH_SET_LED2_PIN() : TOSH_CLR_LED2_PIN();
     (ledsOn & (1 << 3)) ? TOSH_SET_LED3_PIN() : TOSH_CLR_LED3_PIN();
     (ledsOn & (1 << 4)) ? TOSH_SET_LED4_PIN() : TOSH_CLR_LED4_PIN();
     (ledsOn & (1 << 5)) ? TOSH_SET_LED5_PIN() : TOSH_CLR_LED5_PIN();
     (ledsOn & (1 << 6)) ? TOSH_SET_LED6_PIN() : TOSH_CLR_LED6_PIN();
     (ledsOn & (1 << 7)) ? TOSH_SET_LED7_PIN() : TOSH_CLR_LED7_PIN();
     return SUCCESS;
  }
}
