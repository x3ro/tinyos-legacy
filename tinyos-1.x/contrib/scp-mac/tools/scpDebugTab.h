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

char *stateEvent[27] = {
   /* states */
   "state:IDLE",
   "state:TX_TONE",
   "state:TX_PKT",
   "state:undefined",
   "state:undefined",
   
   /* events */
   "event:VIRTUAL_CS_IDLE",
   "event:VIRTUAL_CS_BUSY",
   "event:CHANNEL_IDLE_DETECTED",
   "event:CHANNEL_BUSY_DETECTED",
   "event:TX_TIMER_FIRED",
   "event:SYNC_TIMER_FIRED",
   "event:ADAPTIVE_TIMER_FIRED",
   "event:TX_REQUEST_ACCEPTED",
   "event:TX_REQUEST_REJECTED_MSG_ERROR",
   "event:TX_REQUEST_REJECTED_NO_BUFFER",
   "event:TX_TONE_DONE",
   "event:START_SYMBOL_SENT",
   "event:TX_MSG_DONE",
   "event:CSMA_RADIO_DONE",
   "event:START_SYMBOL_DETECTED",
   "event:RX_MSG_DONE",
   "event:RADIO_IDLE_DONE",
   "event:RADIO_IDLE_WAIT",
   "event:RADIO_IDLE_FAILED",
   "event:CARRIER_SENSE_STARTED",
   "event:ADAPTIVE_TX_PKT",
   "event:ADAPTIVE_TIMER_STARTED"
   "event:NO_PKT_TO_SEND"
   
};

#endif
