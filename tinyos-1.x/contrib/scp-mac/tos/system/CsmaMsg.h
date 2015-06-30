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
 * Packet format for CSMA
 */

#ifndef CSMA_MSG
#define CSMA_MSG

// In Berkeley's stack, it is defined in AM.h
// Since we are not useing it, define it here.

// When using emtos, AM is included, so there's an enum-define collision
#ifndef PLATFORM_EMSTAR
#ifndef TOS_BCAST_DEFINED
#ifndef AM_H_INCLUDED
#define TOS_BCAST_ADDR 0xffff
#endif
#endif
#endif

#ifndef PHY_MSG
#include "PhyRadioMsg.h"
#endif

// # of bytes going out
#define AIRED_DATA_SIZE (sizeof(PhyHeader) + PHY_MAX_PAYLOAD +2)

// MAC header to be included by upper layer headers -- nested headers
// type: CSMA only uses higher 4 bits
//       lower 4 bits can be used by a MAC above CSMA, such as SCP-MAC
// seqFragNo: for broadcast packets, it's just sequence no; for unicast,
//            higher 5 bits are sequence no, lower 3 are fragment no.
typedef struct {
   PhyHeader phyHdr;
   uint8_t type;  // type is the first byte following phyHdr
   uint16_t fromAddr;
   uint16_t toAddr;
    #ifdef SCP_HEAVY_SYNC
    uint16_t sync_time;
    #endif
//   uint8_t seqFragNo;
} __attribute__((packed)) CsmaHeader;


/************************************************************** 
This is an example showing how an application that used S-MAC to
to define its packet structures.

App-layer header should include MAC_Header as its first field, e.g.,

typedef struct {
	MACHeader hdr;
	// now add app-layer header fields
	char appField1;
	int16_t appField2;
} AppHeader;

This is an nested header structure, as MACHeader includes PhyHeader
as its first field.

You can get the maximum payload length by the following macro.

#define MAX_APP_PAYLOAD (PHY_MAX_PKT_LEN - sizeof(AppHeader) - 2)

The app packet with maximum allowed length is then

typedef struct {
	AppHeader hdr;
	char data[MAX_APP_PAYLOAD];
	int16_t crc;  // must be last two bytes, required by PhyRadio.
} AppPkt;

******************************************************************/

// control packets -- internal to CSMA

typedef struct {
  PhyHeader phyHdr;  // include before my own stuff
  uint8_t type;  // type is the first byte following phyHdr
  uint16_t fromAddr;
  uint16_t toAddr;
  uint16_t duration;
  int16_t crc;  // must be last two bytes, required by PhyRadio
} __attribute__((packed)) RTSPkt;

typedef struct {
  PhyHeader phyHdr;  // include before my own stuff
  uint8_t type;  // type is the first byte following phyHdr
  uint16_t toAddr;
  uint16_t duration;
  int16_t crc;  // must be last two bytes, required by PhyRadio
} __attribute__((packed)) CTSPkt;

typedef struct {
  PhyHeader phyHdr;  // include before my own stuff
  uint8_t type;  // type is the first byte following phyHdr
  uint16_t toAddr;
//  uint16_t duration;  // for debugging
  int16_t crc;  // must be last two bytes, required by PhyRadio
} __attribute__((packed)) ACKPkt;

// control pkt buffer should have the size of the largest control pkt
#define CSMA_CTRL_PKT_BUF sizeof(RTSPkt)

#endif //CSMA_MSG
