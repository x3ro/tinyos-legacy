/*
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitaet Berlin nor the names
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
 * - Description ---------------------------------------------------------
 * Macros for configuring the TDA5250.
 * - Revision ------------------------------------------------------------
 * $Revision: 1.9 $
 * $Date: 2005/11/29 12:16:07 $
 * Author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

#ifndef TDA5250CONST_H
#define TDA5250CONST_H

typedef enum {
    SPI_IDLE,
    UART_TX_DISABLED,
    UART_RX_DISABLED,
    
    SPI_LOCKED,
    UART_TX,
    UART_RX,
} usartState_t;

typedef enum {
    BUS_RELEASED,
    WANT_BUS,
    HAVE_BUS,
    BUS_REQUESTED
} busState_t;

typedef enum {
    RADIO_IDLE,
    RADIO_STARTUP,
    CCA,
    RX,
    TX,
    SLEEP,
    TIMER,
    SELF_POLLING
} phyState_t;

typedef enum {
    FRAMER_IDLE,
    RX_PREAMBLE_FROZEN,
    RX_PREAMBLE,
    RX_SYNC,
    RX_SFD,
    RX_DATA,
    TX_PREAMBLE,
    TX_SYNC,
    TX_SFD,
    TX_DATA
} frameState_t;

/**************** Module Definitions  *****************/
#define PREAMBLE_BYTE                  0x55
#define SYNC_BYTE                      0xFF
#define SFD_BYTE                       0x33

#define INIT_POT_VALUE        255
#define TH_RSSI_HIGHGAIN      26
#define TH_RSSI_LOWGAIN       17
#define TH_RSSI_RX_DELTA      3
#define TH1_VALUE_RX          0x0000 //117
#define TH2_VALUE_RX          0xFFFF //1159
#define TH1_VALUE_PREAMBLE    35 // 70 // 35  //0x0000 //117
#define TH2_VALUE_PREAMBLE    600 // 300 // 150 //389 //0xFFFF //1159

#endif //TDA5250CONST_H
