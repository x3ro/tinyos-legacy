/*
 * Copyright (c) 2004,2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Structions used in IEEE utility
 */

#ifndef _IEEE_UTILITY_H
#define _IEEE_UTILITY_H

// FCF1
enum {
  FRAME_TYPE_BEACON       = 0x00,
  FRAME_TYPE_DATA         = 0x01,
  FRAME_TYPE_ACK          = 0x02,
  FRAME_TYPE_CMD          = 0x03,
  FRAME_TYPE_MASK         = 0x07,

  SECURITY_ENABLED        = 0x08,
  FRAME_PENDING           = 0x10,
  ACK_REQUEST             = 0x20,
  INTRA_PAN               = 0x40
};

// FCF2
enum {
  DEST_MODE_SHORT         = 0x08,
  DEST_MODE_LONG          = 0x0c,
  DEST_MODE_MASK          = 0x0c,

  SRC_MODE_SHORT          = 0x80,
  SRC_MODE_LONG           = 0xc0,
  SRC_MODE_MASK           = 0xc0
};

// COMMAND frames
enum {
  CMD_FRAME_ASSOCIATION_REQUEST          = 1,
  CMD_FRAME_ASSOCIATION_RESPONSE         = 2,
  CMD_FRAME_DISASSOCIATION_NOTIFICATION  = 3,
  CMD_FRAME_DATA_REQUEST                 = 4,
  CMD_FRAME_PAN_ID_CONFLICT_NOTIFICATION = 5,
  CMD_FRAME_ORPHAN_NOTIFICATION          = 6,
  CMD_FRAME_BEACON_REQUEST               = 7,
  CMD_FRAME_COORDINATOR_REALIGNMENT      = 8,
  CMD_FRAME_GTS_REQUEST                  = 9
};

// Section 7.2.2.1.2, Figure 40 
// Just the high 8 bits

enum {
  BEACON_SUPERFRAME_BATTERY_LIFE_EXT   = 0x10,
  BEACON_SUPERFRAME_PAN_COORDINATOR    = 0x40,
  BEACON_SUPERFRAME_ASSOCIATION_PERMIT = 0x80
};

// Section 7.3.1.1.2, Figure 49 

enum {
  CAP_ALTERNATE_PAN_COORDINATOR      = 0x01,
  CAP_DEVICE_TYPE_FFD                = 0x02,
  CAP_POWER_SOURCE                   = 0x04,  // Set if plugged in
  CAP_RECEIVER_ON_WHEN_IDLE          = 0x08,
  CAP_SECURITY                       = 0x40,  // Set if can use secured MAC frames (section 7.6)
  CAP_ALLOCATE_ADDRESS               = 0x80
};

// Section 7.3.1.3.2, Table 69

enum {
  DISASSOCIATION_REASON_COORDINATOR  = 1,
  DISASSOCIATION_REASON_DEVICE       = 2
};
  

struct Address {
  uint16_t pan_id;

  union {
    uint16_t saddr;
    uint8_t  laddr[8];
  } a;
};

struct DecodedHeader {
  uint8_t fcf1;
  uint8_t fcf2;
    
  struct Address dest;
  struct Address src;

  int8_t  rssi;
  uint8_t lqi;
};

// Zigbee specification, Table 139

enum {
  HANDHELDS_IP_NETWORK = 1,
};

#endif
