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
 * Defination of parameters and packet format for T-MAC
 * To be included by TMACM.nc
 * If upper layer uses T-MAC it needs to include T-MAC header as the first
 * element in its own packet declaration.
 *
 * Original S-MAC code author: Wei Ye (USC/ISI)
 * T-MAC modifications: Tom Parker
 */

/**
 * @author Wei Ye (USC/ISI)
 * @author Tom Parker
 */

#ifndef TMAC_MSG
#define TMAC_MSG

/* defaults for t-mac implementation */

#define PERIOD_LENGTH 610u
// 610ms, length specified in original T-MAC experiments

#define TMAC_RETRY_LIMIT 3
// max number of retries

#define SYNC_PERIOD 10
// send a sync packet every this many periods

/* end defaults */

// In Berkeley's stack, it is defined in AM.h
// Since we are not using it, define it here.
#ifndef TOS_BCAST_ADDR
#define TOS_BCAST_ADDR 0xffff
#endif

// include TOS_Msg defination
#include "AM.h"

// define PHY_MAX_PKT_LEN before include TMACMsg.h. Otherwise default 
// value (100) will be used when TMACMsg.h includes PhyRadioMsg.h.
#define MAC_HEADER_LEN 9
#define PHY_MAX_PKT_LEN (MAC_HEADER_LEN + sizeof(TOS_Msg) + 2)

/*#ifndef PHY_MSG
#include "PhyRadioMsg.h"
#endif*/

// MAC packet types
typedef enum
{ DATA_PKT = 6, RTS_PKT, CTS_PKT, ACK_PKT, SYNC_PKT }
__attribute__((packed)) pktTypes;

#define FIRST_PKT_TYPE DATA_PKT
#define LAST_PKT_TYPE SYNC_PKT

#define BASIC_HEADERS	uint8_t length;\
	pktTypes type;\
	uint16_t fromAddr; \
	int16_t sleepTime;  // my sleeptime counter 


// MAC header to be included by upper layer headers -- nested headers
typedef struct {
	BASIC_HEADERS
	uint16_t toAddr;
} __attribute__((packed)) MACHeader;


/************************************************************** 
This is an example showing how an application that used T-MAC to
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

// control packet -- RTS, CTS, ACK
typedef struct {
	BASIC_HEADERS
	uint16_t toAddr;
	uint16_t duration; // ms that this sequence will take
	uint16_t crc;  // must be last two bytes, required by PhyRadio
} __attribute__((packed))  MACCtrlPkt;

// sync packet
typedef struct {
	BASIC_HEADERS
	uint16_t crc;  // must be last two bytes, required by PhyRadio
} __attribute__((packed)) MACSyncPkt;

#ifdef TMAC_PERFORMANCE
// for performance measurement
typedef struct {
	uint32_t sleepTime;
	uint32_t idleTime;
	uint32_t rxTime;
	uint32_t txTime;
} RadioTime;
#endif

/* Internal MAC parameters
 *--------------------------
 * Do NOT change them unless for tuning T-MAC
 * PRE_PKT_BYTES: Length of start symbol (not including pre/post bytes)
 * SLOTTIME: time of each slot in contention window, in recieved bits. It should be large
 *   enough to receive the whole start symbol.
 * GUARDTIME: Max out-of-sync time allowed on schedules
 * UPDATE_NEIGHB_PERIOD: period to update neighbor list, is n times of SYNC_PERIOD.
 * RTS_CONTEND: RTS contention time (must be (2^n)-1), in number of possible slots
 */

#define PRE_PKT_BYTES 2
#define SLOTTIME PRE_PKT_BYTES*8
#define SCHED_CHECK_PERIODS 12
#define RTS_CONTEND 15
#define GUARDTIME 25
#endif //TMAC_MSG
