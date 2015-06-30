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
 * Packet format for SCP-MAC
 */

#ifndef SCP_MSG
#define SCP_MSG

// include CSMA header and packet definitions
#include "CsmaMsg.h"

// just use CsmaHeader as SCP MAC header -- no new field added
typedef CsmaHeader ScpHeader;

// sync packet
typedef struct {
  CsmaHeader csmaHdr;  // include before my own stuff
  volatile uint16_t pollTime;  // my next channel polling time from now
#ifdef GLOBAL_SCHEDULE
        uint16_t syncNode;      // initializer of the my schedule
        uint32_t schedAge;      // schedule age
  uint8_t        txLplMod;      // send in LPL node
  uint8_t        chgSched;      // Schedule Changed
#endif
#ifdef SCP_SNOOPER_DEBUG
  // debugging bytes
        uint16_t        OrglNode; // initiator of the my schedule
        uint16_t        myPollTm; // schedule age
        uint16_t        nbPollTm; // schedule age
  int16_t               timeDiff;
        uint8_t         normlpl;
        uint8_t         chgnums;
        uint8_t         suppressed;
        uint32_t        CurrAge;        // my schedule age
        uint32_t        RecdAge;        // received schedule age
  int32_t               ageDiff;
  uint8_t               reason1;
  uint8_t               reason2;
  uint8_t               numRxSync;
        uint8_t         syncbcast;

#endif
  /*
    #ifdef MAINTAIN_SCHEDULE_AGE
      uint8_t validAge;
      uint32_t scheduleAge; // age of the schedule
    #endif
  */
  int16_t crc;  // must be last two bytes, required by PhyRadio
} __attribute__((packed)) SyncPkt;

#endif //SCP_MSG
