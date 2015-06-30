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
 * Physical layer parameters
 */

#ifndef PHY_CONST
#define PHY_CONST

/***
 * These parameters are not user adjustable
 * but can be used by other components
 */

// the bandwidth on Mica2 radio is 38400b/s
// with Manchester coding, actual data rate is 19200b/s

// time to transmit a byte (binary microseconds)
// nominal value is 427, but measurement shows 428
#define PHY_TX_BYTE_TIME 428

// carrier sense sample interval (binary microseconds)
#define PHY_CS_SAMPLE_INTERVAL 428

// maximum carrier sense extension (bytes) when channel state can't be
// immediately determined by requested samples
//#define PHY_MAX_CS_EXT 4
#define PHY_MAX_CS_EXT 3

// transition delay from sleep to active (ms)
#define PHY_WAKEUP_DELAY 2

// number of sychronization bytes (start of a frame)
#define PHY_NUM_SYNC_BYTES 2

// base preamble length (bytes)
//#define BASE_PREAMBLE_LEN 18
#define PHY_BASE_PREAMBLE_LEN 8

// number of preamble bytes to be received for considering as valid preamble
//#define VALID_PRECURSOR 5
#define PHY_VALID_PRECURSOR 2

// number of bytes before each pkt with base preamble
#define PHY_BASE_PRE_BYTES (PHY_BASE_PREAMBLE_LEN + PHY_NUM_SYNC_BYTES)

// processing delay for each received packet (ms)
// mainly caused by noise level measurement
#define PHY_PROCESSING_DELAY 1

// Delay between timestamping outgoing packet and incoming packet
#define PHY_TIMESTAMP_DELAY 0 // in ms

// Time to load a packet into the CC2420 FIFO (before sending)
#define PHY_LOADTONE_DELAY 0 // in ms

// Number of tones used (only in micaz)
#define PHY_NUMBER_OF_TONES 0
#endif
