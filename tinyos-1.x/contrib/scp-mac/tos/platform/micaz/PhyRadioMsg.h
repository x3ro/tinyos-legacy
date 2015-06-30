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
 * This file defines the header fields of phy_radio that will be
 * added before the payload of each packet.
 * The upper layer (MAC) that use phy_radio should include this header
 * as its first field and CRC as its last field in each packet it 
 * declares (see smac_msg.h for example).
 */

#ifndef PHY_MSG
#define PHY_MSG

#ifndef PLATFORM_EMSTAR
#ifndef TOS_BCAST_DEFINED
#ifndef AM_H_INCLUDED
#define TOS_BCAST_ADDR 0xffff
#endif
#endif
#endif

// Maximum packet length -- including headers of all layers
// Each application can override the default max length in Makefile
// Maximum allowable value is 250
#ifndef PHY_MAX_PKT_LEN
#define PHY_MAX_PKT_LEN 120
#endif

// Physical-layer header to be put before data payload
// This is actually transmitted on the radio and used by
// the 802.15.4 phy
typedef struct {
  uint8_t length; // length of entire packet
  uint8_t fcfhi;
  uint8_t fcflo; // fcf is used by the CC2420 for specifying
  		 // ack requests, security, address modes, etc
  uint8_t dsn;   // sequence number for the 802.15.4 frame
  //  uint16_t destpan; // we use broadcast for passing the phy filters
  //  uint16_t addr; // destination address (broadcast)
} __attribute__((packed)) PhyHeader;


// packet information to be recorded by physical layer
typedef struct {
  uint32_t timestamp;   // time stamp based on LocalTime (1ms resolution)
  uint16_t strength;  // signal strength
  uint16_t noise;  // noise measurement immediately following pkt Rx
} __attribute__((packed)) PhyPktInfo;

// Physical layer packet buffer (for receiving packets)
// Sending buffer should be provided by the top-level application

#define PHY_MIN_PKT_LEN (sizeof(PhyHeader) + 2)
#define PHY_MAX_PAYLOAD (PHY_MAX_PKT_LEN - PHY_MIN_PKT_LEN)

typedef struct {
  PhyHeader hdr;
  char data[PHY_MAX_PAYLOAD];
  int16_t crc;      // last field of a packet
  PhyPktInfo info;  // not part of a packet
} __attribute__((packed)) PhyPktBuf;

#endif  // PHY_MSG
