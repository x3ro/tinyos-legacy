/*
 * Copyright (c) 2002, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Janos Sallai
 * Date last modified: 05/21/03
 */

#ifndef TIMESLOTNEGOTIATION_H_INCLUDED
#define TIMESLOTNEGOTIATION_H_INCLUDED

#include "AM.h"
typedef struct TimeSlotData {
	uint16_t moteID;
	int16_t timeSlot;
	uint8_t hopCount;
} TimeSlotData;

enum {
	AM_TIMESLOTMSG = 21,
	MSG_BUFFER_SIZE = 10,
	ROUND_TIME = 8000,
	TIMESLOT_COUNT = 32,
	NO_TIMESLOT = -1,
	MAX_RANDOM_WAIT = 500,
	TIMESLOTDATA_PER_MSG = (TOSH_DATA_LENGTH - 1) / sizeof(TimeSlotData) 
};

typedef struct TimeSlotMsg {
	uint8_t timeSlotDataCount;
	TimeSlotData timeSlots[TIMESLOTDATA_PER_MSG];
} TimeSlotMsg;
#endif
