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

#include "c55xxhardware.h"

#include "CC2420Const.h"

#define eint() 
#define dint()

TOSH_ASSIGN_INTERRUPT(LAN_INT_H, 0)
TOSH_ASSIGN_INTERRUPT(CC_FIFO, 1)
TOSH_ASSIGN_INTERRUPT(CC_CCA, 2)
TOSH_ASSIGN_INTERRUPT(CC_FIFOP, 3)
TOSH_ASSIGN_INTERRUPT(SPARE_INT, 4)

TOSH_ASSIGN_PIN(CODEC_CSN, 0, 1);

// CC2420 RADIO #defines
TOSH_ASSIGN_PIN(RADIO_CSN, 0, 0);
//TOSH_ASSIGN_PIN(RADIO_VREF, 0, );
TOSH_ASSIGN_PIN(RADIO_RESET, 5, 5);
// reworked to go to tp_sw_atn_l 
//TOSH_ASSIGN_PIN(RADIO_FIFOP, 1, 0);
// reworked again to be swapped with lcd_backlight
TOSH_ASSIGN_PIN(RADIO_FIFOP, 2, 1);

//TOSH_ASSIGN_PIN(CC_FIFO, 4, 5);
//TOSH_ASSIGN_PIN(CC_SFD, 4, 6);
//TOSH_ASSIGN_PIN(CC_VREN, 5, 6);
TOSH_ASSIGN_PIN(CC_RSTN, 0, 4);

// LEDs
TOSH_ASSIGN_PIN(RED_LED, 1, 5); // unused
TOSH_ASSIGN_PIN(GREEN_LED, 1, 5);
TOSH_ASSIGN_PIN(YELLOW_LED, 1, 6);

void TOSH_SET_PIN_DIRECTIONS(void)
{
}

#endif /* _H_hardware_h */
