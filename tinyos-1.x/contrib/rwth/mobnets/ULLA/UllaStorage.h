/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */
 
/*
 *
 * Storage header file
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 */

// validity in seconds
enum {
	LINK_ID_VALIDITY = 5,
	LQI_VALIDITY = 5,
	RSSI_VALIDITY = 5,
	TEMPERATURE_VALIDITY = 10,
	TSR_VALIDITY = 2,
	PAR_VALIDITY = 2,
	INT_TEMP_VALIDITY = 30,
	INT_VOLT_VALIDITY = 60,
	RF_POWER_VALIDITY = 5,
	DEFAULT_VALIDITY = 1,
};

enum {
	MAX_ATTRIBUTE = 25,
	MAX_LINKS = 10,
	MAX_TUPLE = 1,
};

typedef struct StorageMsg {
	uint16_t buffer[MAX_ATTRIBUTE];
	uint16_t counter;
	uint32_t timestamp;
	bool result_is_old[MAX_ATTRIBUTE];
} StorageMsg;

typedef struct SingleTuple {
  uint16_t linkid;
	union {
		uint8_t value8;
		uint16_t value16;
	} u;
	
} SingleTuple;

typedef struct ullaLinkHorizontalTuple {
	uint8_t attr;
	uint8_t num_links;
	SingleTuple single_tuple[MAX_LINKS];
} ullaLinkHorizontalTuple;


typedef struct elseHorizontalTuple {
	uint8_t attr;
	union {
		uint8_t value8;
		uint16_t value16;
	}u;
} elseHorizontalTuple;