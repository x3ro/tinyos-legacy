/*
 * Copyright (C) 2005 the University of Southern California.
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * In addition to releasing this program under the LGPL, the authors are
 * willing to dual-license it under other terms. You may contact the authors
 * of this project by writing to Wei Ye, USC/ISI, 4676 Admirality Way, Suite 
 * 1001, Marina del Rey, CA 90292, USA.
 */
/*
 * Authors: Wei Ye
 *
 * This file configures parameters of all components used by the application.
 * It is supposed to be included before any other files in an 
 * application's configuration (wiring) file, such as Test.nc, so that these
 * macro definations will override default definations in other files.
 * These macros are in the global name space, so use a prefix to indicate
 * which layers they belong to.
 *
 */

#ifndef CONFIG
#define CONFIG

// disable CPU sleep mode when radio is off
// should disable CPU sleep when UART debugging is used
//#define DISABLE_CPU_SLEEP

// Configure Physical layer. Definitions here override default values
// Default values are defined in PhyMsg.h and PhyConst.h
// --------------------------------------------------------------
#define PHY_MAX_PKT_LEN 100       // max: 250 (bytes), default: 100

// configure radio transmission power (0x01--0xff)
// Following sample values are for 433MHz mica2: 0x0f=0dBm (TinyOS default)
// 0x0B = -3dBm, 0x08 = -6dBm, 0x05 = -9dBm, 0x03 = -14dBm 0x01 = -20dBm
// 0x0f =  0dBm, 0x50 =  3dBm, 0x80 =  6dBm, 0xe0 =  9dBm, 0xff =  10dBm
//#define RADIO_TX_POWER 0x03

// tell PHY to measure radio energy usage, only for performace analysis
//#define RADIO_MEASURE_ENERGY

// Configure CSMA, look for CsmaConst.h for details
// -----------------------------------------------
//#define CSMA_CONT_WIN 32          // contention window size, 0--255
//#define CSMA_BACKOFF_TIME 20
#define CSMA_RTS_THRESHOLD 101
//#define CSMA_BACKOFF_LIMIT 7
//#define CSMA_RETX_LIMIT 3
//#define CSMA_ENABLE_OVERHEARING  // overhearing is disabled by default

// Configure the test application
// -------------------------------
#define TST_MIN_NODE_ID 1        // at least 2 nodes. node IDs must be
#define TST_MAX_NODE_ID 3        // consecutive from min to max

// TST_MSG_INTERVAL controls how fast a node generates a message. Setting
// it to 0 makes it generates second packet right after the first is sent.
#define TST_MSG_PERIOD 0         // in binary ms

// By default, each node keeps sending until it is powered off.
// To let a node automatically stop after sending sepecified number of 
// messages, define the following macro
//#define TST_NUM_MSGS 20

// By default, each node alternate in sending broadcast and unicast
// for unicast, node i sends to (i+1), and node MaxId sends to MinId
//#define TST_BROADCAST_ONLY     // test broadcast only if defined
//#define TST_UNICAST_ONLY       // test unicast only if defined
//#define TST_UNICAST_ADDR 2     // specify unicast addr instead of default one

// make a node receive only
//#define TST_RECEIVE_ONLY
// receive-only node will report result after a delay from last Rx
//#define TST_REPORT_DELAY 4096

// debugging with LEDs
#define CSMA_LED_DEBUG
#define PHY_LED_DEBUG

// debugging with a snooper
// -----------------------------
// Debug by adding bytes to data pkts, so that snooper can show them
//#define CSMA_SNOOPER_DEBUG

// debugging with a serial port (UART)
// -----------------------------------------
// Don't enable it unless you know what's going to happen.
// There is a known problem on Mica2 motes. If UART debugging is enabled
// but the mote is not connected with the serial board/cable, very often
// it fails to start. It occasionally happens when the mote connects with
// the serial board/cable.

// Debugging with predefined states and events
// The following macros are mutually exclusive. You should only define one.
//#define CSMA_UART_DEBUG_STATE_EVENT
//#define TIMER_UART_DEBUG_STATE_EVENT

// Debugging by sending an arbitrary byte to UART
// The following macros are not mutually exclusive. You can define multiples.
//#define CSMA_UART_DEBUG_BYTE
//#define PHY_UART_DEBUG_BYTE
//#define TIMER_UART_DEBUG_BYTE

// include MAC message and header definitions
#include "CsmaMsg.h"
typedef CsmaHeader MacHeader;

#endif  // CONFIG
