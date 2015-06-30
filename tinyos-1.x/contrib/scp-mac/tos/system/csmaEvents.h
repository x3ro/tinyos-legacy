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
 * this file defines the events in CSMA for debugging
 */

#ifndef CSMA_EVENTS
#define CSMA_EVENTS

#define INIT_EVENT_NO 11

// packet transmission
#define TX_MSG_ACCEPTED INIT_EVENT_NO
#define TX_MSG_REJECTED_ERROR (TX_MSG_ACCEPTED + 1)
#define TX_MSG_REJECTED_BUFFERED (TX_MSG_REJECTED_ERROR + 1)
#define TX_MSG_DONE (TX_MSG_REJECTED_BUFFERED + 1)
#define TX_BCAST_DONE (TX_MSG_DONE + 1)
#define TX_RTS_DONE  (TX_BCAST_DONE + 1)
#define TX_CTS_DONE  (TX_RTS_DONE + 1)
#define TX_UCAST_DONE (TX_CTS_DONE + 1)
#define TX_ACK_DONE (TX_UCAST_DONE + 1)

// packet reception
#define RX_MSG_ERROR (TX_ACK_DONE + 1)
#define RX_BCAST_DONE (RX_MSG_ERROR + 1)
#define RX_RTS_DONE (RX_BCAST_DONE + 1)
#define RX_CTS_DONE (RX_RTS_DONE + 1)
#define RX_UCAST_DONE (RX_CTS_DONE + 1)
#define RX_ACK_DONE (RX_UCAST_DONE + 1)
#define RX_UNKNOWN_PKT (RX_ACK_DONE + 1)
#define RX_RTS_OTHERS (RX_UNKNOWN_PKT + 1)
#define RX_CTS_OTHERS (RX_RTS_OTHERS + 1)
#define RX_UCAST_OTHERS (RX_CTS_OTHERS + 1)
#define RX_ACK_OTHERS (RX_UCAST_OTHERS + 1)

// timer event
#define TIMER_STARTED_NAV (RX_ACK_OTHERS + 1)
#define TIMER_UPDATED_NAV (TIMER_STARTED_NAV + 1)
#define TIMER_STARTED_NEIGHB_NAV (TIMER_UPDATED_NAV + 1)
#define TIMER_UPDATED_NEIGHB_NAV (TIMER_STARTED_NEIGHB_NAV + 1)
#define TIMER_FIRE_NAV (TIMER_UPDATED_NEIGHB_NAV + 1)
#define TIMER_FIRE_NEIGHB_NAV (TIMER_FIRE_NAV + 1)
#define TIMER_FIRE_BACKOFF (TIMER_FIRE_NEIGHB_NAV + 1)

// carrier sense
#define CHANNEL_BUSY_DETECTED (TIMER_FIRE_BACKOFF + 1)
#define CHANNEL_IDLE_DETECTED (CHANNEL_BUSY_DETECTED + 1)
#define START_SYMBOL_DETECTED (CHANNEL_IDLE_DETECTED + 1)
#define START_SYMBOL_SENT (START_SYMBOL_DETECTED + 1)

// other events
#define TRYTOSEND_SUCCESS (START_SYMBOL_SENT + 1)
#define TRYTOSEND_FAILURE (TRYTOSEND_SUCCESS + 1)
#define UPPER_LAYER_RADIO_ON (TRYTOSEND_FAILURE + 1)
#define UPPER_LAYER_RADIO_OFF (UPPER_LAYER_RADIO_ON + 1)
#define POLL_CHANNEL_SUCCESS (UPPER_LAYER_RADIO_OFF + 1)
#define POLL_CHANNEL_FAIL_NOT_SLEEP (POLL_CHANNEL_SUCCESS + 1)
#define POLL_CHANNEL_FAIL_NOT_ENABLED (POLL_CHANNEL_FAIL_NOT_SLEEP + 1)
#define POLL_CHANNEL_FAIL_VIRTUAL_CS (POLL_CHANNEL_FAIL_NOT_ENABLED + 1)
#define LPL_SLEEP_STATE_RADIO_DONE (POLL_CHANNEL_FAIL_VIRTUAL_CS + 1)
#define LPL_SLEEP_STATE_VIRTUAL_CS (LPL_SLEEP_STATE_RADIO_DONE + 1)
#define LPL_IDLE_STATE_TRYTOSLEEP_FAIL (LPL_SLEEP_STATE_VIRTUAL_CS + 1)
#define LPL_IDLE_STATE_CS_BUSY (LPL_IDLE_STATE_TRYTOSLEEP_FAIL + 1)
#define LPL_IDLE_STATE_WAIT_TIMER_FIRE (LPL_IDLE_STATE_CS_BUSY + 1)
#define LPL_IDLE_STATE_RESEND (LPL_IDLE_STATE_WAIT_TIMER_FIRE + 1)


#endif // SMAC_EVENTS
