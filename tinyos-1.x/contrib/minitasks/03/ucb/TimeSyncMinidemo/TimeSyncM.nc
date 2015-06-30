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
 * Author: Miklos Maroti, Brano Kusy
 * Date last modified: 03/17/03
 */

//!! Config 150 { uint8_t timesyncRate = 30; }

includes Config;
includes Timer;
includes TimeSyncMsg;

module TimeSyncM
{
	provides 
	{
		interface StdControl;
		interface GlobalTime;
	}
	uses
	{
		interface StdControl as SubControl;
		interface LocalTime;
		interface SendMsg;
		interface ReceiveMsg;
		interface Timer;
		interface Timer as PrecisionTimer;
		interface Leds;
		interface Config_timesyncRate;
	}
}

implementation
{
#ifndef TIMESYNC_RATE
#define TIMESYNC_RATE	G_Config.timesyncRate
#endif

	enum {
		MAX_ENTREES = 8,		// number of entrees in the table
		ROOT_ALONE_TIMEOUT = 2,		// when to declare ourself the root if no current root (in send period)
		ROOT_SWITCH_TIMEOUT = 20,	// when to replace the current root if our id is smaller (in send period)
	};

	typedef struct TableItem
	{
		uint8_t		state;
		uint32_t	localTime;
		int32_t		timeOffset;	// globalTime - localTime
	} TableItem;

	enum {
		ENTRY_EMPTY = 0,
		ENTRY_FULL = 1,
	};

	TableItem	table[MAX_ENTREES];

	enum {
		STATE_IDLE = 0x00,
		STATE_PROCESSING = 0x01,
		STATE_SENDING = 0x02,
		STATE_INIT = 0x04,
	};

	uint8_t state;
	
/*
	We do linear regression from localTime to timeOffset (globalTime - localTime). 
	This way we can keep the slope close to zero (ideally) and represent it 
	as a float with high precision.
		
		timeOffset - offsetAverage = skew * (localTime - localAverage)
		timeOffset = offsetAverage + skew * (localTime - localAverage) 
		globalTime = localTime + offsetAverage + skew * (localTime - localAverage)
*/

	float		skew;
	uint32_t	localAverage;
	int32_t		offsetAverage;
	uint8_t		numEntrees;	// the number of full entrees in the table

	command result_t GlobalTime.getGlobalTime(uint32_t *time) { 
		*time = call LocalTime.read();
		return call GlobalTime.local2Global(time);
	}

	command result_t GlobalTime.local2Global(uint32_t *time){
		*time += offsetAverage + (int32_t)(skew * (int32_t)(*time - localAverage));
		return SUCCESS;
	}

	command int32_t GlobalTime.getOffset() { return offsetAverage; }
	command float GlobalTime.getSkew() { return skew; }
	command uint32_t GlobalTime.getSyncPoint() { return localAverage; }

	TOS_Msg processedMsgBuffer;
	TOS_MsgPtr processedMsg;

	TOS_Msg outgoingMsgBuffer;
	#define outgoingMsg	((TimeSyncMsg*)outgoingMsgBuffer.data)

	uint8_t heartBeats;	// the number of sucessfully sent messages
				// since adding a new entry with lower beacon id than ours
	void calculateConversion()
	{
		float newSkew = skew;
		uint32_t newLocalAverage;
		int32_t newOffsetAverage;
		uint8_t newNumEntrees;

		int64_t localSum;
		int64_t offsetSum;

		int8_t i;

		for(i = 0; i < MAX_ENTREES && table[i].state != ENTRY_FULL; ++i)
			;

		if( i >= MAX_ENTREES )	// table is empty
			return;
/*
		We use a rough approximation first to avoid time overflow errors. The idea 
		is that all times in the table should be relatively close to each other.
*/
		newLocalAverage = table[i].localTime;
		newOffsetAverage = table[i].timeOffset;

		localSum = 0;
		offsetSum = 0;
		newNumEntrees = 1;

		while( ++i < MAX_ENTREES )
			if( table[i].state == ENTRY_FULL ) {
				localSum += (int32_t)(table[i].localTime - newLocalAverage);
				offsetSum += (int32_t)(table[i].timeOffset - newOffsetAverage);
				++newNumEntrees;
			}

		newLocalAverage += (localSum + (newNumEntrees >> 1)) / newNumEntrees;
		newOffsetAverage += (offsetSum + (newNumEntrees >> 1)) / newNumEntrees;

		localSum = offsetSum = 0;
		for(i = 0; i < MAX_ENTREES; ++i)
			if( table[i].state == ENTRY_FULL ) {
				int32_t a = table[i].localTime - newLocalAverage;
				int32_t b = table[i].timeOffset - newOffsetAverage;

				localSum += (int64_t)a * a;
				offsetSum += (int64_t)a * b;
			}

		if( localSum != 0 )
			newSkew = (float)offsetSum / (float)localSum;

		atomic
		{
			skew = newSkew;
			offsetAverage = newOffsetAverage;
			localAverage = newLocalAverage;
			numEntrees = newNumEntrees;
		}
	}

	void addNewEntry(TimeSyncMsg *msg)
	{
		int8_t i, freeItem = -1, oldestItem = 0;
		uint32_t age, oldestTime = 0;

		for(i = 0; i < MAX_ENTREES; ++i) {
			if( table[i].state == ENTRY_EMPTY ) 
				freeItem = i;

			age = msg->arrivalTime - table[i].localTime;
			if( age >= oldestTime ) {
				oldestTime = age;
				oldestItem = i;
			}
		}

		if( freeItem < 0 )
			freeItem = oldestItem;

		table[freeItem].state = ENTRY_FULL;

		table[freeItem].localTime = msg->arrivalTime;
		table[freeItem].timeOffset = msg->sendingTime - msg->arrivalTime;
	}

	void clearTable()
	{
		int8_t i;
		for(i = 0; i < MAX_ENTREES; ++i)
			table[i].state = ENTRY_EMPTY;

		numEntrees = 0;
	}

	void task processMsg()
	{
		TimeSyncMsg* msg = (TimeSyncMsg*)processedMsg->data;

		if( outgoingMsg->rootID > msg->rootID ){
			outgoingMsg->rootID = msg->rootID;
			outgoingMsg->seqNum = msg->seqNum;
			clearTable();
		}
		else if( outgoingMsg->rootID == msg->rootID && (int8_t)(msg->seqNum - outgoingMsg->seqNum) > 0 ) {
			outgoingMsg->seqNum = msg->seqNum;
		}
		else
			goto exit;

		call Leds.greenToggle();
		if( outgoingMsg->rootID < TOS_LOCAL_ADDRESS )
			heartBeats = 0;

		if (numEntrees>2) {
			int32_t diff = msg->arrivalTime + offsetAverage - msg->sendingTime;
			if (diff > 100 || diff < -100)
				clearTable();
		}
		addNewEntry(msg);
		calculateConversion();

	exit:
		state &= ~STATE_PROCESSING;
	}

	event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p)
	{
//		the follwing code was used to simulate multiple hops

		uint16_t incomingID = ((TimeSyncMsg*)p->data)->nodeID;
		if( incomingID < TOS_LOCAL_ADDRESS - 1 || incomingID > TOS_LOCAL_ADDRESS + 1 )
			return p;


		if( (state & STATE_PROCESSING) == 0 ) {
			TOS_MsgPtr old = processedMsg;

			processedMsg = p;
			state |= STATE_PROCESSING;
			post processMsg();

			return old;
		}

		return p;
	}

	task void sendMsg()
	{
		uint32_t localTime, globalTime;

		if( outgoingMsg->rootID != TOS_LOCAL_ADDRESS && heartBeats >= ROOT_SWITCH_TIMEOUT ) {
			outgoingMsg->rootID = TOS_LOCAL_ADDRESS;
			++(outgoingMsg->seqNum);
			skew = 0.0;
			clearTable();
		}

		globalTime = localTime = call LocalTime.read();
		call GlobalTime.local2Global(&globalTime);

		outgoingMsg->sendingTime = globalTime - localTime;

		if( call SendMsg.send(TOS_BCAST_ADDR, TIMESYNCMSG_LEN, &outgoingMsgBuffer) != SUCCESS )
			state &= ~STATE_SENDING;
	}

	event result_t SendMsg.sendDone(TOS_MsgPtr ptr, result_t success)
	{
		if( success )
		{
			++heartBeats;
			call Leds.redToggle();

			if( outgoingMsg->rootID == TOS_LOCAL_ADDRESS )
				++(outgoingMsg->seqNum);
		}

		state &= ~STATE_SENDING;
		return SUCCESS;
	}

	event result_t Timer.fired()
	{
		if( outgoingMsg->rootID == 0xFFFF && ++heartBeats >= ROOT_ALONE_TIMEOUT ) {
			outgoingMsg->seqNum = 0;
			outgoingMsg->rootID = TOS_LOCAL_ADDRESS;
		}
		
		if( outgoingMsg->rootID != 0xFFFF && (state & STATE_SENDING) == 0 ) {
			state |= STATE_SENDING;
			post sendMsg();
		}

		return SUCCESS;
	}

	command result_t StdControl.init() 
	{ 
		call SubControl.init();

		skew = 0.0;
		localAverage = 0;
		offsetAverage = 0;

		clearTable();

		outgoingMsg->rootID = 0xFFFF;
		outgoingMsg->nodeID = TOS_LOCAL_ADDRESS;

		processedMsg = &processedMsgBuffer;
		state = STATE_INIT;

		return SUCCESS;
	}

	event result_t PrecisionTimer.fired()
	{
		return SUCCESS;
	}

	command result_t StdControl.start() 
	{
		call SubControl.start();

		heartBeats = 0;
		if (state == STATE_INIT)
			call PrecisionTimer.start2(200);
		call Timer.start2(32768ul * TIMESYNC_RATE);

		return SUCCESS; 
	}

	command result_t StdControl.stop() 
	{
		call Timer.stop();
		return SUCCESS; 
	}
	
	event void Config_timesyncRate.updated(){
		call Timer.stop();
		call Timer.start2(32768ul * TIMESYNC_RATE);
	}
}
