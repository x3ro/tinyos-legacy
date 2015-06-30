/* Copyright (c) 2006, Jan Flora <janflora@diku.dk>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *  - Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *  - Neither the name of the University of Copenhagen nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
  @author Jan Flora <janflora@diku.dk>
*/

#ifndef _MAC_H_
#define _MAC_H_

// Global state variables.
bool phyIsReceiving = FALSE;
bool phyIsTransmitting = FALSE;

// Type definitions below.

typedef uint32_t time_t;

/*typedef enum {
	TX_SUCCESS = IEEE802154_SUCCESS,
	TX_NO_ACK = IEEE802154_NO_ACK,
	TX_CHANNEL_ACCESS_FAILURE = IEEE802154_CHANNEL_ACCESS_FAILURE,
	TX_PENDING
}*/

#define TX_SUCCESS                    IEEE802154_SUCCESS
#define TX_NO_ACK                     IEEE802154_NO_ACK
#define TX_CHANNEL_ACCESS_FAILURE     IEEE802154_CHANNEL_ACCESS_FAILURE
#define TX_FRAME_TOO_LONG             IEEE802154_FRAME_TOO_LONG
#define TX_PENDING                    4
typedef uint8_t txStatus_t;

/*typedef enum {
	SLOT_EMPTY,
	SLOT_PENDING,
	CSMA_FAIL,
	CSMA_DEFERRED,
	SEND_DONE // NOTE: does not indicate success or failure
} capStatus_t;*/

#define SLOT_EMPTY      0
#define SLOT_PENDING    1
#define CSMA_FAIL       2
#define CSMA_DEFERRED   3
#define SEND_DONE       4

typedef uint8_t capStatus_t;
typedef uint8_t cfpStatus_t;

typedef struct {
	time_t startTime;
	uint8_t beaconLength; // Unit is backoff periods
	time_t beaconInterval;
	time_t slotLength;
	uint8_t capLength;	// Unit is superframe slots.
	bool battLifeExt;
} superframe_t;

typedef struct {
	bool valid;
	uint8_t startSlot;
	uint8_t duration;
	uint8_t direction;
	uint16_t shortAddr;
	uint8_t beaconPublishCount; // Used for publish timeout in coordinator GTSs.
	                            // Used for publish wait timeout in device GTSs.
	uint16_t timeout; // Coordinator GTS slot timeout.
} gtsDescriptor_t;

typedef struct {
	// Filled by requester.
	uint8_t *frame;
	uint8_t length;
	bool isData; // used to distinguish data from mac commands.
	uint8_t msduHandle; // support for PURGE
	bool addDsn;		// generate and add a DSN
	
	superframe_t *superframe; // superframe context
	txStatus_t status;		// Return status
	uint8_t txRetries; 
	// symbol periods required to complete
	// the entire transaction including ack an IFS
	// but without any CSMA backoff
	time_t transactionTime;
} txHeader_t;

typedef struct {
	txHeader_t *header;
	capStatus_t status;
	uint8_t doneToken;
	uint8_t NB; // Number of Backoffs performed
	uint8_t BE; // Backoff Exponent
	uint8_t backoffPeriods; // number of backoff periods to apply
	time_t commenceTime;
} capTx_t;

typedef struct {
	txHeader_t *header;
	uint8_t doneToken;
} txDoneEntry_t;

typedef struct {
	cfpStatus_t status;
	txHeader_t *header;
	uint8_t gtsIndex;
} cfpTx_t;

typedef struct {
	uint8_t status;
	uint8_t token;
	uint8_t addrMode;
	uint8_t *address;
	txHeader_t *data;
	uint16_t expiryCount;
} indirectTxQueue_t;

#endif
