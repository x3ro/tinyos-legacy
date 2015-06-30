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
 * This file defines the packet format for the application
 */

#ifndef TEST_MSG
#define TEST_MSG

// Should define MacHeader first before going on

typedef struct {
  MacHeader hdr;   // include lower-layer header first
  uint8_t seqNo;  // sequence number of my sending packet
  uint8_t numTxBcast; // number of transmitted broadcast packets
  uint8_t numTxUcast; // number of transmitted unicast packetsa
  uint8_t numRxBcast; // number of transmitted broadcast packets
  uint8_t numRxUcast; // number of transmitted unicast packetsa
  uint32_t lastTxTime; // time when my last transmission is done
  uint32_t lastRxTime; // time when my last reception is done
  uint16_t lastRxSignal; // signal strength of last received pkt
  uint16_t lastRxNoise;  // noise level after last received pkt
} AppHeader;

// it looks like nesC does not recognize the following macro
//#define APP_HEADER_SIZE sizeof(AppHeader)
//#if (APP_HEADER_SIZE < PHY_MAX_PKT_LEN)
//#error PHY_MAX_PKT_LEN is too small
//#endif

#define APP_PAYLOAD_LEN (PHY_MAX_PKT_LEN - sizeof(AppHeader) - 2)

typedef struct {
  AppHeader hdr;
  char data[APP_PAYLOAD_LEN];
  int16_t crc;   // crc must be the last field -- required by PhyRadio
} AppPkt;

#endif
