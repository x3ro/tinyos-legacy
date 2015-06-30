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
 * Author: Wei Ye
 *
 * this file is the messages to be printed out for debugging
 * This table of states and events is used by uartDebugServer.c
 * and uartDebugParser.c
 */

#ifndef STATE_EVENT
#define STATE_EVENT

char *stateEvent[46] = {
   /* CSMA states */
   "state:SLEEP",
   "state:IDLE",
   "state:PRE_TX",
   "state:CARR_SENSE",
   "state:TX_PKT",
   "state:BACKOFF",
   "state:RECEIVE",
   "state:WAIT_CTS",
   "state:WAIT_DATA",
   "state:WAIT_ACK",
   "state:undefined",
   
   /* pkt transmission events */
   "event:TX_MSG_ACCEPTED",
   "event:TX_MSG_REJECTED_ERROR",
   "event:TX_MSG_REJECTED_BUFFERED",
   "event:TX_MSG_DONE",
   "event:TX_BCAST_DONE",
   "event:TX_RTS_DONE",
   "event:TX_CTS_DONE",
   "event:TX_UCAST_DONE",
   "event:TX_ACK_DONE",
   
   /* pkt reception events */
   "event:RX_MSG_ERROR",
   "event:RX_BCAST_DONE",
   "event:RX_RTS_DONE",
   "event:RX_CTS_DONE",
   "event:RX_UCAST_DONE",
   "event:RX_ACK_DONE",
   "event:RX_UNKNOWN_PKT",
   "event:RX_RTS_OTHERS",
   "event:RX_CTS_OTHERS",
   "event:RX_UCAST_OTHERS",
   "event:RX_ACK_OTHERS",
   
   /* timer events */
   "event:TIMER_STARTED_NAV",
   "event:TIMER_UPDATED_NAV",
   "event:TIMER_STARTED_NEIGHB_NAV",
   "event:TIMER_UPDATED_NEIGHB_NAV",
   "event:TIMER_FIRE_NAV",
   "event:TIMER_FIRE_NEIGHB_NAV",
   "event:TIMER_FIRE_BACKOFF",
   
   /* carrier sense events */
   "event:CHANNEL_BUSY_DETECTED",
   "event:CHANNEL_IDLE_DETECTED",
   "event:START_SYMBOL_DETECTED",
   "event:START_SYMBOL_SENT",
   
   /* other events */
   "event:TRYTOSEND_SUCCESS",
   "event:TRYTOSEND_FAILURE",
   "event:UPPER_LAYER_RADIO_ON",
   "event:UPPER_LAYER_RADIO_OFF",
   
};

#endif
