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
 * SCP-MAC constants that can be used by applications
 */

#ifndef SCP_CONST
#define SCP_CONST

// include lower layer constants
#include "LplConst.h"

/* User-adjustable SCP parameters
 * Do not directly change this file
 * Change default values in each application's config.h file
 */

// to enable booting the old way i.e. Master-Slave configuration
//#define USE_FIXED_BOOT

// in case of Fixed boot, only one master node starts a schedule in the network
// the master node will broadcast it schedule after it starts
// slave nodes only performs LPL and wait to synchronize with master schedule
//#define SCP_MASTER_SCHEDULE

// adaptive listen is enabled by default
// define the following macro to disable it
//#define SCP_DISABLE_ADAPTIVE_LISTEN

// make each node maintain Age of the Schedule 
//#define MAINTAIN_SCHEDULE_AGE

// period for each node to poll the channel
#ifndef SCP_POLL_PERIOD
#define SCP_POLL_PERIOD 1024
#endif

// period for each node to poll the channel (default 10min)
#ifndef SCP_SYNC_PERIOD
#define SCP_SYNC_PERIOD  4096
//#define SCP_SYNC_PERIOD 614400
//#define SCP_SYNC_PERIOD 1228800
#endif

#ifndef NEIGH_DISC_PERIOD
#define NEIGH_DISC_PERIOD 81920
//#define NEIGH_DISC_PERIOD 1228800
//#define NEIGH_DISC_PERIOD 2457600
#endif

// contention window size on sending wakeup tone, max 127
#ifndef SCP_TONE_CONT_WIN
#define SCP_TONE_CONT_WIN 7
#endif

// contention window size on siding packets, must be, max 127
#ifndef SCP_PKT_CONT_WIN
#define SCP_PKT_CONT_WIN 15
#endif


// number of high-rate polling after receiving a pkt in regular polling
#ifndef SCP_NUM_HI_RATE_POLL
#define SCP_NUM_HI_RATE_POLL 3
#endif

// timeout for passive discovery mode in terms of number of SCP frames
#ifndef SCP_PASSIVE_DISCOVERY_TIMEOUT
#define SCP_PASSIVE_DISCOVERY_TIMEOUT 1
// <-1 invalid
// -1 implies infinite/blocking passive discovery mode
//  0 implies skipping passive discovery phase
//  >0 valid
#endif

// timeout for each request in the active discovery mode in terms of number of SCP frames
#ifndef SCP_ACTIVE_DISCOVERY_TIMEOUT
#define SCP_ACTIVE_DISCOVERY_TIMEOUT 4
// <1 invalid
//  >=1 valid
#endif

// number of retries for SYNC_REQ in active discovery mode
#ifndef NUM_SCP_ACTIVE_DISCOVERY_REQUESTS
#define NUM_SCP_ACTIVE_DISCOVERY_REQUESTS 5
// <-1 invalid
// -1 means infinite number of requests
//  0 implies skipping active discovery phase
// >0 valid
#endif

/***
 * Following parameters are not user adjustable
 * but can be used by other components
 */

// guard time (bytes) on schedule drift between sync info exchange
// minimum value is 2
#define SCP_GUARD_TIME 4
#define AGE_GUARD_TIME 10

#endif  // SCP_CONST
