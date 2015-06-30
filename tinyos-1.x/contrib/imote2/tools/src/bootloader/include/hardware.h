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
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * @Author Philip Buonadonna
 * @Author Robbie Adler
 * NOTE; Ported form the TinyOS Tree. Jan 9, 2006 - Junaith
 *
 */

#ifndef TOSH_HARDWARE_H__
#define TOSH_HARDWARE_H__

#include <types.h>
#include <pxa27xhardware.h>
#include <CC2420Const.h>
//#include "AM.h"

#define MIN(a,b) ((a) < (b) ? (a) : (b))

/* Watchdog Prescaler
 */
enum {
  TOSH_period16 = 0x00, // 47ms
  TOSH_period32 = 0x01, // 94ms
  TOSH_period64 = 0x02, // 0.19s
  TOSH_period128 = 0x03, // 0.38s
  TOSH_period256 = 0x04, // 0.75s
  TOSH_period512 = 0x05, // 1.5s
  TOSH_period1024 = 0x06, // 3.0s
  TOSH_period2048 = 0x07 // 6.0s
};

// LED assignments
TOSH_ASSIGN_PIN(RED_LED, A, 103);
TOSH_ASSIGN_PIN(GREEN_LED, A, 104);
TOSH_ASSIGN_PIN(YELLOW_LED, A, 105);

// CC2420 RADIO #defines
#define CC_VREN_PIN (115)
#define CC_RSTN_PIN (22)
#define CC_FIFO_PIN (114)
#define RADIO_CCA_PIN (116)
#define CC_FIFOP_PIN (0)
#define CC_SFD_PIN (16)
#define CC_CSN_PIN (39)

#define SSP3_RXD (41)
#define SSP3_RXD_ALTFN (3)
#define SSP3_TXD (35)
#define SSP3_TXD_ALTFN (3)
#define SSP3_SFRM (39)
#define SSP3_SFRM_ALTFN (3)
#define SSP3_SCLK (34)
#define SSP3_SCLK_ALTFN (3)

#define SSP1_RXD (26)
#define SSP1_RXD_ALTFN (1 )
#define SSP1_TXD (25)
#define SSP1_TXD_ALTFN (2 )
#define SSP1_SCLK (23)
#define SSP1_SCLK_ALTFN (2 )
#define SSP1_SFRM (24)
#define SSP1_SFRM_ALTFN (2 )

TOSH_ASSIGN_PIN(CC_VREN,A,CC_VREN_PIN); 
TOSH_ASSIGN_PIN(CC_RSTN,A,CC_RSTN_PIN);
TOSH_ASSIGN_PIN(CC_FIFO,A,CC_FIFO_PIN);
TOSH_ASSIGN_PIN(RADIO_CCA,A,RADIO_CCA_PIN);
TOSH_ASSIGN_PIN(CC_FIFOP,A,CC_FIFOP_PIN);
TOSH_ASSIGN_PIN(CC_SFD,A,CC_SFD_PIN);
TOSH_ASSIGN_PIN(CC_CSN,A,CC_CSN_PIN);


#endif //TOSH_HARDWARE_H
