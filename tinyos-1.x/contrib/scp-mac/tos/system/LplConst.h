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
 * constants that can be used by applications
 */

#ifndef LPL_CONST
#define LPL_CONST

// include lower layer constants
#include "CsmaConst.h"

/* User-adjustable LPL parameters
 * Do not directly change this file
 * Change default values in each application's config.h file
 */

// period for each node to poll the channel 
#ifndef LPL_POLL_PERIOD
#define LPL_POLL_PERIOD 512
#endif

/***
 * Following parameters are not user adjustable
 * but can be used by other components
 */

// min and max bytes to sample in polling when channel is idle
#define LPL_MIN_POLL_BYTES 1
#define LPL_MAX_POLL_BYTES (LPL_MIN_POLL_BYTES + PHY_MAX_CS_EXT)

// MicaZ specific parameters
#ifdef PLATFORM_MICAZ

// prevent LPL to return to sleep state too early
#ifndef LPL_EXTEND_RECEIVE_TIME
#define LPL_EXTEND_RECEIVE_TIME
#endif 

#endif  // PLATFORM_MICAZ

#endif  // LPL_CONST
