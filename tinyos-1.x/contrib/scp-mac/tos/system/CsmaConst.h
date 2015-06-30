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
 * CSMA constants that can be used by applications
 */

#ifndef CSMA_CONST
#define CSMA_CONST

// include lower layer constants
#include "PhyConst.h"

/***
 * User-adjustable CSMA parameters
 * Do not directly change this file
 * Change default values in each application's config.h file
 */
 
// DCF interframe space -- minimum contention time
#ifndef DIFS
#define DIFS 2
#endif

// contention window size, 0--255
// if set to 0, will bypass carrier sense
// actual number of contention slots is DIFS + a random number in the window
#ifndef CSMA_CONT_WIN
#define CSMA_CONT_WIN 31
#endif

// backoff time when carrier sense fails, slightly longer than preamble time
// should redefine it if sending variable preamble packets
#ifndef CSMA_BACKOFF_TIME
#define CSMA_BACKOFF_TIME (PHY_BASE_PRE_BYTES * PHY_TX_BYTE_TIME / 1000 + 3)
#endif

// use RTS/CTS when unicast pkt length is larger than RTS threshold
#ifndef CSMA_RTS_THRESHOLD
#define CSMA_RTS_THRESHOLD 100
#endif

// re-Tx when a unicast data pkt does not receive an ACK or no CTS for RTS
#ifndef CSMA_RETX_LIMIT
#define CSMA_RETX_LIMIT 3
#endif

// when number of continues backoff reaches the limit, will give up Tx
#ifndef CSMA_BACKOFF_LIMIT
#define CSMA_BACKOFF_LIMIT 7
#endif

// CSMA disables overhearing by default. To enable, define the following
//#define CSMA_ENABLE_OVERHEARING

/***
 * following parameters are not user adjustable, but can be used
 */

// processing delay, including that by PHY
#define CSMA_PROCESSING_DELAY (PHY_PROCESSING_DELAY + 1)

// transmission time of RTS packet
#define CSMA_RTS_DURATION ((PHY_BASE_PRE_BYTES + sizeof(RTSPkt)) * \
        PHY_TX_BYTE_TIME / 1000 + 1)

// transmission time of CTS packet
#define CSMA_CTS_DURATION ((PHY_BASE_PRE_BYTES + sizeof(CTSPkt)) * \
        PHY_TX_BYTE_TIME / 1000 + 1)

// transmission time of ACK packet
#define CSMA_ACK_DURATION ((PHY_BASE_PRE_BYTES + sizeof(ACKPkt)) * \
        PHY_TX_BYTE_TIME / 1000 + 1)

#endif
