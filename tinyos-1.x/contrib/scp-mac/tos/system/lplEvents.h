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
 * this file defines the events in LPL for debugging
 */

#ifndef LPL_EVENTS
#define LPL_EVENTS

#define INIT_EVENT_NO 5

#define POLL_TIMER_FIRED (INIT_EVENT_NO)
#define START_CARRIER_SENSE (POLL_TIMER_FIRED + 1)
#define POLL_CHANNEL_FAIL_NOT_SLEEP (START_CARRIER_SENSE + 1)
#define POLL_CHANNEL_FAIL_NOT_ENABLED (POLL_CHANNEL_FAIL_NOT_SLEEP + 1)
#define POLL_CHANNEL_FAIL_VIRTUAL_CS (POLL_CHANNEL_FAIL_NOT_ENABLED + 1)
#define POLL_CHANNEL_FAIL_WAKEUP_RADIO (POLL_CHANNEL_FAIL_VIRTUAL_CS + 1)
#define POLL_CHANNEL_ENABLED (POLL_CHANNEL_FAIL_WAKEUP_RADIO + 1)
#define POLL_CHANNEL_DISABLED (POLL_CHANNEL_ENABLED + 1)
#define VIRTUAL_CS_IDLE (POLL_CHANNEL_DISABLED + 1)
#define VIRTUAL_CS_BUSY (VIRTUAL_CS_IDLE + 1)
#define TRY_TO_SLEEP_FAILED (VIRTUAL_CS_BUSY + 1)
#define CHANNEL_IDLE_DETECTED (TRY_TO_SLEEP_FAILED + 1)
#define CHANNEL_BUSY_DETECTED (CHANNEL_IDLE_DETECTED + 1)
#define WAIT_TIMER_STARTED (CHANNEL_BUSY_DETECTED + 1)
#define WAIT_TIMER_FIRED (WAIT_TIMER_STARTED + 1)
#define RESEND_REQUESTED (WAIT_TIMER_FIRED + 1)
#define TX_REQUEST_ACCEPTED (RESEND_REQUESTED + 1)
#define TX_REQUEST_REJECTED_MSG_ERROR (TX_REQUEST_ACCEPTED + 1)
#define TX_REQUEST_REJECTED_NO_BUFFER (TX_REQUEST_REJECTED_MSG_ERROR + 1)
#define TX_MSG_DONE (TX_REQUEST_REJECTED_NO_BUFFER + 1)
#define CSMA_RADIO_DONE (TX_MSG_DONE + 1)
#define START_SYMBOL_DETECTED (CSMA_RADIO_DONE + 1)
#define RX_MSG_DONE (START_SYMBOL_DETECTED + 1)
#define SET_RADIO_SLEEP (RX_MSG_DONE + 1)
#endif // LPL_EVENTS
