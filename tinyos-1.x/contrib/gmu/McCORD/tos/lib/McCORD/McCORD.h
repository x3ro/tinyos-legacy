/**
 * Copyright (c) 2008 - George Mason University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL GEORGE MASON UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF GEORGE MASON
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * GEORGE MASON UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND GEORGE MASON UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 **/

/**
 * @author Leijun Huang <lhuang2@gmu.edu>
 **/

#ifndef __MCCORD_H__
#define __MCCORD_H__

enum {
#if defined(PLATFORM_PC)
//  SCHED_SLOT_LENGTH     = 6144,
//  PKTS_PER_PAGE     = 128,
// for quick test:
  SCHED_SLOT_LENGTH     = 2048,  
  PKTS_PER_PAGE     = 24,
#elif defined(PLATFORM_TELOSB)
  SCHED_SLOT_LENGTH     = 2048,
  PKTS_PER_PAGE     = 48,
#elif defined(PLATFORM_MICA2)
  SCHED_SLOT_LENGTH     = 4096,
  PKTS_PER_PAGE     = 48,
#endif
  PKT_PAYLOAD_SIZE  = 20,
  PKTS_BITVEC_SIZE  = (((PKTS_PER_PAGE-1) / 8) + 1),

  BYTES_PER_PKT = PKT_PAYLOAD_SIZE,
  BYTES_PER_PAGE = (PKTS_PER_PAGE * BYTES_PER_PKT),
};

enum {
  AM_ADVMSG = 163,
  AM_REQMSG  = 164,
  AM_DATAMSG = 165,
  AM_CORECOMPETEMSG = 166,
  AM_CORECLAIMMSG = 167,
  AM_CORESUBSCRIBEMSG = 168,
  AM_HELLOMSG = 169,
  AM_NEIGHBORSMSG = 170,
  AM_SCHEDMSG = 171,

  AM_UARTMETAMSG = 172,
  AM_UARTDATAMSG = 173,
};

/* Time in milliseconds. */
enum {
  MAX_JITTER = 32,
  MAX_REQ_DELAY = 512, 

#if defined(PLATFORM_PC)
  PACKET_TRANSMISSION_TIME = 48,  // PowerTOSSIM: average CSMA time = 40.95ms (http://www.eecs.harvard.edu/~shnayder/ptossim/mica2bench/summary.html)
#elif defined(PLATFORM_TELOSB)
  PACKET_TRANSMISSION_TIME = 16,
#elif defined(PLATFORM_MICA2)
  PACKET_TRANSMISSION_TIME = 32,
#endif

  RANDOM_DELAY = 16,
  INIT_LISTEN_PERIOD = (MAX_REQ_DELAY) + MAX_JITTER + PACKET_TRANSMISSION_TIME,
};

enum {
  IDLE_DETECT_PACKETS = 3,
  MAX_NOAVAIL_REQUESTS = 3,
};

enum {
  INVALID_NODE_ADDR = 0xffff,
  INVALID_DEPTH = 0xff,
  MAX_NEIGHBORS = 11,
  MAX_IN_LINKS  = 22,  // including both good and bad links.
};

enum {
  HELLO_INTERVAL = 1024,
  HELLO_DELAY = 1000,
  HELLO_MSGS = 8, // for each channel
  HELLO_MSGS_THRESHOLD = 6, // to be considered a good link
  NEIGHBORS_MSGS = 3, // for each channel
};

// In simulation, this must be greater than BASE_BOOT_TIME (global.h).
enum { 
  NEIGHBOR_PROBE_START_TIME = 20480ul,  // in milliseconds. 
};

enum {
  DATA_TRANSFER_START_SLOTS = 4,  // number of slots base waits before transfer.
};

typedef struct AdvMsg {
  uint16_t sourceAddr;
  uint8_t  sourceDepth;
  uint8_t  completePages;
  uint8_t  phase2Flag;
} __attribute__((packed)) AdvMsg;

typedef struct ReqMsg {
  uint16_t destAddr;
  uint16_t sourceAddr;
  uint8_t  sourceDepth;
  uint8_t  page;
  uint8_t  requestedPkts[PKTS_BITVEC_SIZE];
  uint8_t  isCoreNode;
} __attribute__((packed)) ReqMsg;

typedef struct DataMsg {
  uint16_t sourceAddr;
  uint8_t  sourceDepth;
  uint8_t  page;
  uint8_t  packet;
  uint8_t  morePackets;
  uint8_t  data[PKT_PAYLOAD_SIZE];
  uint8_t  completePages;
  uint8_t  phase2Flag;
} __attribute__((packed)) DataMsg;


typedef struct NeighborsMsg {
   uint16_t sourceAddr;
   uint8_t  channelIndex;
   uint8_t  pad;
   uint16_t neighbors[MAX_NEIGHBORS]; 
} __attribute__((packed)) NeighborsMsg;


typedef struct HelloMsg {
   uint16_t sourceAddr;
   uint16_t pktTotal;
   uint16_t seqno;
} __attribute__((packed)) HelloMsg;


typedef struct CoreCompeteMsg {
  uint16_t sourceAddr;
  uint8_t sourceDepth;
  uint8_t channelIndex;
  uint16_t stateOffset;  // Time in milliseconds.
  uint16_t coveredNodes[MAX_NEIGHBORS];
} __attribute__((packed)) CoreCompeteMsg;

typedef struct CoreClaimMsg {
  uint16_t sourceAddr;
  uint8_t sourceDepth;
  uint8_t channelIndex;
  uint16_t stateOffset;  // Time in milliseconds.
  uint16_t coveredNodes[MAX_NEIGHBORS];
} __attribute__((packed)) CoreClaimMsg;

typedef struct CoreSubscribeMsg {
  uint16_t sourceAddr;
  uint16_t destAddr;
} __attribute__((packed)) CoreSubscribeMsg;


enum {
    LQI_THRESHOLD = 95,  // LQI values are between 50 and 110.
};

enum {
    BLOCKSTORAGE_ID_0 = unique("StorageManager"),
    BLOCKSTORAGE_VOLUME_ID_0 = 0xDF,
}; 

typedef struct {
    uint16_t  objId;  // valid obj id starts from 1.
    uint8_t   numPages;
    uint8_t   numPktsLastPage;
    uint8_t   numPagesComplete; 
    uint8_t   pad;    // pad must be set 0 when computing crc.
    uint16_t  crcData;  // CRC of object data.
    uint16_t  crcMeta;  // CRC of all above.
} __attribute__((packed)) ObjMetadata;

#define METADATA_SIZE	16

typedef struct SchedMsg {
    uint32_t startTimeMillis;
    ObjMetadata metadata; 
} __attribute__((packed)) SchedMsg;


// These messages are used to upload object to the base (node 0)
// through UART.

typedef struct UARTDataMsg {
    uint8_t  page;
    uint8_t  packet;
    uint8_t  data[PKT_PAYLOAD_SIZE];
} __attribute__((packed)) UARTDataMsg;

typedef struct UARTMetaMsg {
    ObjMetadata metadata; 
} __attribute__((packed)) UARTMetaMsg;

enum {
  BASE_ID = 0,
};

bool __isBase() {
    if (TOS_LOCAL_ADDRESS == BASE_ID) 
        return TRUE;
    else
        return FALSE;
}

// For experiments that do neighbor probing on channels.
uint8_t __gChannelsToProbe[] = { 0, 1, 2, 3 };
#define CHANNELS_TO_PROBE (sizeof(__gChannelsToProbe)/sizeof(uint8_t))
#define USE_SINGLE_CHANNEL	(CHANNELS_TO_PROBE == 1)
#define INIT_CHANNEL	0

/**
 * The following definitions are for debug purpose only.
 */
#ifdef HW_DEBUG

enum {
    DEBUG_NEIGHBOR_PROBE = 1,
    DEBUG_CORE = 2,
};

enum {
    DEBUG_TX = 1,
    DEBUG_RX = 2,
};

/**
 * Debug log entry. size at most 16 bytes.
 */
typedef struct DebugLog {
    uint8_t who;
    uint8_t dir;
    uint8_t type;        
    uint8_t pad;
    uint16_t addr;  // dst for TX, src for RX.
    uint8_t  data[10]; 
} __attribute__((packed)) DebugLog;

#endif

#endif
