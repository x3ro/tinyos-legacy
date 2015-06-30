/*
 * Copyright (c) 2002-2004 the University of Southern California
 * Copyright (c) 2004 TU Delft/TNO
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement 
 * is hereby granted, provided that the above copyright notice and the
 * following two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * COPYRIGHT HOLDERS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE COPYRIGHT HOLDERS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER
 * IS ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDERS HAVE NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Authors:	Wei Ye (original S-MAC version), Tom Parker (T-MAC modifications)
 *
 * This file defines the header fields of phy_radio that will be
 * added before the payload of each packet.
 * The upper layer (MAC) that use phy_radio should include this header
 * as its first field and CRC as its last field in each packet it 
 * declares (see TMACMsg.h for example).
 * 
 */

/**
 * @author Wei Ye
 * @author Tom Parker
 */

#ifndef PHY_MSG
#define PHY_MSG 1

// include TOS_Msg defination
#include "AM.h"

// define PHY_MAX_PKT_LEN before include TMACMsg.h. Otherwise default 
// value (100) will be used when TMACMsg.h includes PhyRadioMsg.h.
#define MAC_HEADER_LEN 9
#define PHY_MAX_PKT_LEN (MAC_HEADER_LEN + sizeof(TOS_Msg) + 2)

// Maximum packet length -- including headers of all layers
// Each application can override the default max length in Makefile
// Maximum allowable value is 250
#ifndef PHY_MAX_PKT_LEN
#define PHY_MAX_PKT_LEN 100
#endif

// packet information to be recorded by physical layer
typedef struct {
    uint16_t timeCoarse;    // T-MAC system time w/ resolution of 1 ms
} PhyPktInfo;

// Physical layer packet buffer (for receiving packets)
// Sending buffer should be provided by the top-level application

#define PHY_MIN_PKT_LEN (sizeof(uint8_t) + 2)
#define PHY_MAX_PAYLOAD (PHY_MAX_PKT_LEN - PHY_MIN_PKT_LEN)

typedef struct {
	uint8_t length; // length of entire packet
	uint8_t data[PHY_MAX_PAYLOAD];
	//int16_t crc;    // last field of a packet
	PhyPktInfo info;  // not part of a packet
} PhyPktBuf;

#endif  // PHY_MSG
