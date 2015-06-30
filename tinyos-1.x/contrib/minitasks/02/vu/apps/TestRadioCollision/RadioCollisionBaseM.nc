/*
 * Copyright (c) 2003, Vanderbilt University
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
 * Author: Miklos Maroti
 * Date last modified: 05/13/03
 */

includes RadioCollisionMsg;
includes Timer;

module 	RadioCollisionBaseM
{
	provides 
	{
		interface StdControl;
	}
	uses
	{
		interface Timer;
		interface Leds;
		interface DiagMsg;
		interface ReceiveMsg;
	}
}

implementation
{
	enum
	{
		UPDATE_RATE = 7,	// in seconds
		MAX_ENTRIES = 100,	// max number of Senders
		PACKET_LEN = sizeof(RadioCollisionMsg),
	};

	struct Entry
	{
		uint16_t nodeID;
		uint16_t lastSeqNum;
		uint16_t received;		// # of messages
		uint16_t missing;
	};

	struct Entry entries[MAX_ENTRIES];
	uint8_t entryCount;

	command result_t StdControl.init()
	{
		call Leds.init();
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		call DiagMsg.setBaseStation(TOS_UART_ADDR);
		call Timer.start(TIMER_REPEAT, UPDATE_RATE * 1000);
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	task void report()
	{
		uint16_t minReceived = 65535u;
		uint16_t minMissing = 65535u;
		uint16_t maxReceived = 0;
		uint16_t maxMissing = 0;
		uint32_t totalReceived = 0;
		uint32_t totalMissing = 0;

		uint8_t i = entryCount;
		while( i-- != 0 )
		{
			if( entries[i].received < minReceived )
				minReceived = entries[i].received;
			if( entries[i].received > maxReceived )
				maxReceived = entries[i].received;
			if( entries[i].missing < minMissing )
				minMissing = entries[i].missing;
			if( entries[i].missing > maxMissing )
				maxMissing = entries[i].missing;
			
			totalReceived += entries[i].received;
			totalMissing += entries[i].missing;
		}

		// translate it to byte/sec

		minReceived = (minReceived * PACKET_LEN) / UPDATE_RATE;
		minMissing = (minMissing * PACKET_LEN) / UPDATE_RATE;
		maxReceived = (maxReceived * PACKET_LEN) / UPDATE_RATE;
		maxMissing = (maxMissing * PACKET_LEN) / UPDATE_RATE;
		
		totalReceived = (totalReceived * PACKET_LEN) / UPDATE_RATE;
		totalMissing = (totalMissing * PACKET_LEN) / UPDATE_RATE;

		if( call DiagMsg.record() )
		{
			call Leds.greenToggle();

			call DiagMsg.str("RCA");
			call DiagMsg.uint8(entryCount);
			call DiagMsg.uint32(totalReceived);
			call DiagMsg.uint32(totalMissing);
			call DiagMsg.uint16(minReceived);
			call DiagMsg.uint16(minMissing);
			call DiagMsg.uint16(maxReceived);
			call DiagMsg.uint16(maxMissing);
			call DiagMsg.send();
		}

		entryCount = 0;
	}

	event result_t Timer.fired()
	{
		post report();

		return SUCCESS;
	}

	event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p)
	{
		RadioCollisionMsg* m = (RadioCollisionMsg*)p->data;
		uint16_t nodeID = m->nodeID;

		struct Entry *entry = entries;
		struct Entry *end = entries + entryCount;

		call Leds.yellowToggle();
		
		while( entry < end && entry->nodeID != nodeID )
			++entry;

		if( entry < end )
		{
			entry->received += 1;
			entry->missing += (uint16_t)(m->seqNum - entry->lastSeqNum - 1);
			entry->lastSeqNum = m->seqNum;
		}
		else if( entry < entries + MAX_ENTRIES )
		{
			entry->nodeID = nodeID;
			entry->received = 1;
			entry->missing = 0;
			entry->lastSeqNum = m->seqNum;

			++entryCount;
		}

		return p;
	}
}
