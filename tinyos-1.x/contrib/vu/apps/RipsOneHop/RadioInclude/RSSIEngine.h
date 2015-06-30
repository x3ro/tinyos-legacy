/*
 * Copyright (c) 2005, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for instruction and non-commercial research only, without
 * fee, and without written agreement is hereby granted, provided that the
 * this copyright notice including the following two paragraphs and the 
 * author's name appear in all copies of this software.
 * 
 * IN NO EVENT SHALL VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 * Date last modified: 02/02/04
 */
/*
   RSSI Engine with multihop sync
   Modified by Peter Volgyesi
 */

#ifndef RSSIENGINE_H
#define RSSIENGINE_H

struct TSHeader{
    uint32_t deadlineTS;
    uint32_t timeStamp;
    uint8_t sender;
    uint8_t hopsToDo;
};

enum
{
    CRASHED = 2,
    SYNC_MH_MSG_AM = 0x52,
    SYNC_MH_MSG_HEADER = sizeof(struct TSHeader),//4b deadline, 4b timestamp, 1b sender, 1b numHops 
	
#ifdef RIPS_OUTSIDE
	RSSIENGINE_SYNC_MH_TIME = 300000L,
	RSSIENGINE_SYNC_MH_SILENCE_TIME = 70000L,
#else
	RSSIENGINE_SYNC_MH_TIME = 150000L,
	RSSIENGINE_SYNC_MH_SILENCE_TIME = 50000L,
#endif
	RSSIENGINE_ACQUIRE_TIME = 6000,
	RSSIENGINE_CALIBRATE_TIME = 30000L, // failed with 24000L,
	RSSIENGINE_RESTORE_TIME = 46000L,
	RSSIENGINE_LOCK_TIME = 1500,	// 500 is enough
	RSSIENGINE_SAMPLE_COUNT = 255,
	RSSIENGINE_TAIL_TIME = 10000L,	// 10000 is enough (AVR Studio analysis) - not really, brano with new radio stack 15kL was throwing error
};

#endif//RSSIENGINE_H
