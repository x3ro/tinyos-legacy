/*
 * Copyright (C) 2003-2005 the University of Southern California.
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

#define TST_MIN_PKT_LEN 10     // don't change this

// Configure Physical layer. Definitions here override default values
// Default values are defined in PhyMsg.h
// --------------------------------------------------------------
//#define PHY_MAX_PKT_LEN 250  // min: TST_MIN_PKT_LEN, max: 250, default: 100

// configure radio transmission power (0x01--0xff)
// Following sample values are for 433MHz mica2: 0x0f=0dBm (TinyOS default)
// 0x0B = -3dBm, 0x08 = -6dBm, 0x05 = -9dBm, 0x03 = -14dBm 0x01 = -20dBm
// 0x0f =  0dBm, 0x50 =  3dBm, 0x80 =  6dBm, 0xe0 =  9dBm, 0xff =  10dBm
//#define RADIO_TX_POWER 0x03

// tell PHY to measure radio energy usage, only for performace analysis
//#define RADIO_MEASURE_ENERGY

// if the following constant is defined, each packet will add the fixed
// length preamble with the specified time (miliseconds).
// min value: 0, max value: 27327 (ms)
// if the following constant is not defined, a random length preamble (0--255
// bytes) will be added for each packet
//#define ADD_FIXED_PREAMBLE 1000

// Configure the test application
// -------------------------------
// num of pkts to be sent, max value is 255
#define TST_NUM_PKTS 100

// pkt interval (binary ms). when it is 0, pkts are send back-to-back
#define TST_PKT_INTERVAL 10

// if defined, will send packets with random length between 10--250
//#define TST_RANDOM_PKT_LEN

// the following constant specifies the length of preamble (bytes) 
// to be added to the base preamble
// if it is not defined, a random length preamble (0--255 bytes) will
// be added for each packet
#define TST_ADD_FIXED_PREAMBLE 0

// Debugging with UART
//#define PHY_UART_DEBUG_BYTE

#endif  // CONFIG
