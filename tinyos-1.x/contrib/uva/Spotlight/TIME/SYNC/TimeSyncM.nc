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

includes Timer;
includes TimeSyncMsg;

module TimeSyncM
{
	provides 
	{
		interface StdControl;
		interface GlobalTime;
		interface TimeSyncInfo;
	}
	uses
	{
		interface SendMsg;
		interface ReceiveMsg;
		interface Timer;
		interface Leds;
		interface TimeStamping;
#ifdef TIMESYNC_SYSTIME
		interface SysTime;
#else
		interface LocalTime;
#endif
	}
}
implementation
{
#ifndef TIMESYNC_RATE
#define TIMESYNC_RATE	10
#endif

	enum {
		MAX_ENTRIES = 8,		// number of entries in the table
		BEACON_RATE = TIMESYNC_RATE,	// how often send the beacon msg (in seconds)
		ROOT_ALONE_TIMEOUT = 4,		// when to declare ourself the root if no current root (in send period)
		ROOT_SWITCH_TIMEOUT = 8,	// when to replace the current root if our id is smaller (in send period)
		ROOT_IGNORE_TIMEOUT = 3,	// after becoming the root ignore other roots messages (in send period)
		ENTRY_VALID_LIMIT = 4,		// number of entries to become synchronized
		ENTRY_SEND_LIMIT = 3,		// number of entries to send sync messages
		ENTRY_THROWOUT_LIMIT = 100,	// if time sync error is bigger than this clear the table
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

	TableItem	table[MAX_ENTRIES];

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
	uint8_t		numEntries;	// the number of full entries in the table

	TOS_Msg processedMsgBuffer;
	TOS_MsgPtr processedMsg;

	TOS_Msg outgoingMsgBuffer;
	#define outgoingMsg	((TimeSyncMsg*)outgoingMsgBuffer.data)

	uint8_t heartBeats;	// the number of sucessfully sent messages
				// since adding a new entry with lower beacon id than ours

	command uint32_t GlobalTime.getLocalTime()
	{
#ifdef TIMESYNC_SYSTIME
		return call SysTime.getTime32();
#else
		return call LocalTime.read();
#endif
	}

	command result_t GlobalTime.getGlobalTime(uint32_t *time)
	{ 
		*time = call GlobalTime.getLocalTime();
		return call GlobalTime.local2Global(time);
	}

	command result_t GlobalTime.local2Global(uint32_t *time)
	{
		*time += offsetAverage + (int32_t)(skew * (int32_t)(*time - localAverage));
		return numEntries>=ENTRY_VALID_LIMIT || outgoingMsg->rootID==TOS_LOCAL_ADDRESS;
	}

	command result_t GlobalTime.global2Local(uint32_t *time)
	{
		uint32_t approxLocalTime = *time - offsetAverage;
		*time = approxLocalTime - (int32_t)(skew * (int32_t)(approxLocalTime - localAverage));
		return numEntries>=ENTRY_VALID_LIMIT || outgoingMsg->rootID==TOS_LOCAL_ADDRESS;
	}
	
	command float GlobalTime.getSkew() { return skew; }
	command uint32_t GlobalTime.getOffset() { return offsetAverage; }
	command uint32_t GlobalTime.getSyncPoint() { return localAverage; }

	command uint16_t TimeSyncInfo.getRootID() { return outgoingMsg->rootID; }
	command uint8_t TimeSyncInfo.getSeqNum() { return outgoingMsg->seqNum; }
	command uint8_t TimeSyncInfo.getNumEntries() { return numEntries; } 
	command uint8_t TimeSyncInfo.getHeartBeats() { return heartBeats; }

	void calculateConversion()
	{
		float newSkew = skew;
		uint32_t newLocalAverage;
		int32_t newOffsetAverage;
		uint8_t newNumEntries;

		int64_t localSum;
		int64_t offsetSum;

		int8_t i;

		for(i = 0; i < MAX_ENTRIES && table[i].state != ENTRY_FULL; ++i)
			;

		if( i >= MAX_ENTRIES )	// table is empty
			return;
/*
		We use a rough approximation first to avoid time overflow errors. The idea 
		is that all times in the table should be relatively close to each other.
*/
		newLocalAverage = table[i].localTime;
		newOffsetAverage = table[i].timeOffset;

		localSum = 0;
		offsetSum = 0;
		newNumEntries = 1;

		while( ++i < MAX_ENTRIES )
			if( table[i].state == ENTRY_FULL ) {
				localSum += (int32_t)(table[i].localTime - newLocalAverage);
				offsetSum += (int32_t)(table[i].timeOffset - newOffsetAverage);
				++newNumEntries;
			}

		newLocalAverage += (localSum + (newNumEntries >> 1)) / newNumEntries;
		newOffsetAverage += (offsetSum + (newNumEntries >> 1)) / newNumEntries;

		localSum = offsetSum = 0;
		for(i = 0; i < MAX_ENTRIES; ++i)
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
			numEntries = newNumEntries;
		}
	}

	void clearTable()
	{
		int8_t i;
		for(i = 0; i < MAX_ENTRIES; ++i)
			table[i].state = ENTRY_EMPTY;

		numEntries = 0;
	}

	void addNewEntry(TimeSyncMsg *msg)
	{
		int8_t i, freeItem = -1, oldestItem = 0;
		uint32_t age, oldestTime = 0;
		int32_t timeError;

		// clear table if the received entry is inconsistent
		timeError = msg->arrivalTime;
		call GlobalTime.local2Global(&timeError);
		timeError -= msg->sendingTime;
		if (numEntries >= ENTRY_SEND_LIMIT &&
			(timeError > ENTRY_THROWOUT_LIMIT || timeError < -ENTRY_THROWOUT_LIMIT))
				clearTable();

		for(i = 0; i < MAX_ENTRIES; ++i) {
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

	void task processMsg()
	{
		TimeSyncMsg* msg = (TimeSyncMsg*)processedMsg->data;

		if( msg->rootID < outgoingMsg->rootID && 
		    (heartBeats > ROOT_IGNORE_TIMEOUT || outgoingMsg->rootID != TOS_LOCAL_ADDRESS || outgoingMsg->rootID == 0xFFFF) ){
			outgoingMsg->rootID = msg->rootID;
			outgoingMsg->seqNum = msg->seqNum;
		}
		else if( outgoingMsg->rootID == msg->rootID && (int8_t)(msg->seqNum - outgoingMsg->seqNum) > 0 ) {
			outgoingMsg->seqNum = msg->seqNum;
		}
		else
			goto exit;

		//call Leds.greenToggle();
		if( outgoingMsg->rootID < TOS_LOCAL_ADDRESS )
			heartBeats = 0;

		addNewEntry(msg);
		calculateConversion();

	exit:
		state &= ~STATE_PROCESSING;
	}

	event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p)
	{
#ifdef TIMESYNC_DEBUG	// this code was used to simulate multiple hops
		uint8_t incomingID = (uint8_t)((TimeSyncMsg*)p->data)->nodeID;
		int8_t diff = (incomingID & 0x0F) - (TOS_LOCAL_ADDRESS & 0x0F);
		if( diff < -1 || diff > 1 )
			return p;
		diff = (incomingID & 0xF0) - (TOS_LOCAL_ADDRESS & 0xF0);
		if( diff < -16 || diff > 16 )
			return p;
#endif

		if( (state & STATE_PROCESSING) == 0 ) {
			TOS_MsgPtr old = processedMsg;

			processedMsg = p;
			((TimeSyncMsg*)(processedMsg->data))->arrivalTime = call TimeStamping.getStamp();

			state |= STATE_PROCESSING;
			post processMsg();

			return old;
		}

		return p;
	}

	task void sendMsg()
	{
		uint32_t localTime, globalTime;

		globalTime = localTime = call GlobalTime.getLocalTime();
		call GlobalTime.local2Global(&globalTime);

		// we need to periodically update the reference point for the root
		// to avoid wrapping the 32-bit (localTime - localAverage) value
		if( outgoingMsg->rootID == TOS_LOCAL_ADDRESS ) {
			if( (int32_t)(localTime - localAverage) >= 0x20000000 )
			{
				atomic
				{
					localAverage = localTime;
					offsetAverage = globalTime - localTime;
				}
			}
		}
		else if( heartBeats >= ROOT_SWITCH_TIMEOUT ) {
			heartBeats = 0;	//to allow ROOT_SWITCH_IGNORE to work
			outgoingMsg->rootID = TOS_LOCAL_ADDRESS;
			++(outgoingMsg->seqNum); // maybe set it to zero?
		}

		outgoingMsg->sendingTime = globalTime - localTime;

		// we send time sycn message even if we have 3 messages in the table
		if( numEntries < ENTRY_SEND_LIMIT && outgoingMsg->rootID != TOS_LOCAL_ADDRESS ){
			++heartBeats;
			state &= ~STATE_SENDING;
		}
		else{
			if( call SendMsg.send(TOS_BCAST_ADDR, TIMESYNCMSG_LEN, &outgoingMsgBuffer) != SUCCESS )
				state &= ~STATE_SENDING;
			else
				call TimeStamping.addStamp(offsetof(TimeSyncMsg,sendingTime));
		}
	}

	event result_t SendMsg.sendDone(TOS_MsgPtr ptr, result_t success)
	{
		if( success )
		{
			++heartBeats;
			//red denotes it is root
			if(outgoingMsg->rootID == TOS_LOCAL_ADDRESS);
			 // call Leds.redToggle();
			else
			  call Leds.yellowOn();	  

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

	command result_t StdControl.start() 
	{
		
		if(TOS_LOCAL_ADDRESS == 0 ) heartBeats = ROOT_ALONE_TIMEOUT;
		
		call Timer.start(TIMER_REPEAT, (uint32_t)1000 * BEACON_RATE);

		return SUCCESS; 
	}

	command result_t StdControl.stop() 
	{
		call Timer.stop();
		return SUCCESS; 
	}
	
  command uint32_t GlobalTime.jiffy2ms(uint32_t jiffies){
      
	  uint64_t ms = jiffies;

	  ms *=125;
	  ms -=63;
	  ms >>=12;	  
     return (ms);
  }
  
  command uint32_t GlobalTime.ms2jiffy(uint32_t ms){
  
  		// change it to jiffies (1/32768 secs)
		uint64_t jiffies = ms;   		         
		jiffies <<= 12;
		jiffies += 63;	
		jiffies /= 125;		  
      return jiffies;
  }
  	
}
