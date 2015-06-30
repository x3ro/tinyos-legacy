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

// Configure Physical layer. Definitions here override default values
// Default values are defined in PhyMsg.h
// --------------------------------------------------------------
//#define PHY_MAX_PKT_LEN 250       // max: 250, default: 100

// Configure the test application
// -------------------------------
// Number of packets in each group. Should match that in apps/PhyTestSender/
#define TST_NUM_PKTS 100

// delay time (binary ms) to send a report packet
#define TST_REPORT_DELAY 10240

// enable/disable UART debug
//#define UART_DEBUG_ENABLE
// Debugging with LEDS
#define PHY_LED_DEBUG

#endif  // CONFIG
