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
 
/* VIJAI: Changed "rval" in IntCommand.execute(...) to 16 bit from 8 bit since the value myTimeSlot assigned to it was 16 bit anywayz. */
 
includes AM;
includes MsgList;
includes TimeSlotNegotiation;

module TimeSlotNegotiationM {
	provides {
		interface TimeSlotNegotiation;
		interface StdControl;
		interface IntCommand;
	}
	uses {
		interface Leds;
		interface Timer;
		interface SendMsg as SendDispatchMsg;
		interface ReceiveMsg as ReceiveDispatchMsg;
		interface Random;
		interface MsgList;
   }
}

implementation {
	
	TOS_Msg msgs[MSG_BUFFER_SIZE];
	TOS_MsgList toRadio;
	TOS_MsgList free;
	
	TimeSlotData timeSlots[TIMESLOT_COUNT];
	int16_t myTimeSlot;
	bool negotiating;
	uint8_t freeTimeSlots;
	
	void getRandomTimeSlot();
	
	command result_t StdControl.init() {
		// init Random
		call Random.init();
		myTimeSlot = NO_TIMESLOT;
		return SUCCESS;
	}

	command result_t StdControl.start() {
		uint8_t i;
		
		if(negotiating)
			return FAIL;
		else {
			negotiating = TRUE;
	  
			// reset variables and data structures
			call MsgList.init(&toRadio);
			call MsgList.init(&free);
			call MsgList.addAll(&free, msgs, MSG_BUFFER_SIZE);

			//round = 0;

			for(i=0; i<TIMESLOT_COUNT; i++) timeSlots[i].moteID = 0;
			freeTimeSlots = TIMESLOT_COUNT;

			// start timeout Timer
			// TODO: randomized timer
			call Timer.start(TIMER_REPEAT, ROUND_TIME);
		  
			// generate a random timeslot and broadcast it
			getRandomTimeSlot();

			return SUCCESS;
		}
	}

	command result_t StdControl.stop() {
		negotiating = FALSE;
		call Timer.stop();
		return SUCCESS;
	}
		
	void wait(uint16_t ms) {
		uint16_t i;
		i = ms;
		while(i-- >0) TOSH_uwait(1000);
	}
	
	task void sendMsg() {
		TOS_MsgPtr msgPtr;

		if( !call MsgList.isEmpty(&toRadio)) {

			msgPtr = call MsgList.removeFirst(&toRadio);

			if(call SendDispatchMsg.send(0xffff, sizeof(TimeSlotMsg), msgPtr)!=SUCCESS) {
				call MsgList.addFirst(&toRadio, msgPtr);
				post sendMsg();
			} else {
				call Leds.greenOn();
			}
		}
	}

	int16_t getTimeSlot(uint16_t moteID) {
		uint8_t i;
		
		for(i=0; i<TIMESLOT_COUNT; i++)
			if(timeSlots[i].moteID == moteID) return i;
		
		return -1;
	}

	inline void removeFromTimeSlotTable(uint16_t moteID)
	{
		if(timeSlots[getTimeSlot(moteID)].moteID != 0) {
			timeSlots[getTimeSlot(moteID)].moteID = 0;
			freeTimeSlots++;
		}
	}

	void getRandomTimeSlot() {
		uint16_t i, j;

		// if our moteID is in the TimeSlots table, remove it
		removeFromTimeSlotTable(TOS_LOCAL_ADDRESS);

		if(freeTimeSlots>0) {
			j = ((call Random.rand() ^ __inw_atomic(TCNT1L))) % freeTimeSlots;
			for(i=0; i<TIMESLOT_COUNT; i++)
				if(timeSlots[i].moteID==0)
					 if(j--==0) myTimeSlot = i;
			// put mote into the TimeSlots table
			timeSlots[myTimeSlot].moteID = TOS_LOCAL_ADDRESS;
			timeSlots[myTimeSlot].timeSlot = myTimeSlot;
			timeSlots[myTimeSlot].hopCount = 0;
			freeTimeSlots--;
		} else {
			myTimeSlot = NO_TIMESLOT;
		}
	}

	void updateTimeSlotsTable(uint16_t moteID, int16_t timeSlot, uint8_t hopCount) {
		
		if(timeSlot < TIMESLOT_COUNT) {

			// return if the moteID is in the right place in the table
			if(getTimeSlot(moteID)==timeSlot) return;

			// if mote is in the TimeSlots table, remove it
			removeFromTimeSlotTable(moteID);

			// check if received timeslot conflicts with myTimeSlot, but we win
			if(timeSlot == myTimeSlot && TOS_LOCAL_ADDRESS<moteID) return;
			
			// put mote into the TimeSlots table
			timeSlots[timeSlot].moteID = moteID;
			timeSlots[timeSlot].timeSlot = timeSlot;
			timeSlots[timeSlot].hopCount = hopCount;
			freeTimeSlots--;
			
			// check if received timeslot conflicts with myTimeSlot, and we lose
			if(timeSlot == myTimeSlot && TOS_LOCAL_ADDRESS>moteID) getRandomTimeSlot();
		}
	}

	void sendTimeSlotMsgs() {
		uint8_t i = 0;

		while(i<TIMESLOT_COUNT && !call MsgList.isEmpty(&free)) {
			
			TOS_MsgPtr msgPtr = call MsgList.removeFirst(&free);	
			TimeSlotMsg* timeSlotMsgPtr = (TimeSlotMsg*)(msgPtr->data);
			
			// message now contains 0 entries
			timeSlotMsgPtr->timeSlotDataCount = 0;
			
			while(i<TIMESLOT_COUNT && timeSlotMsgPtr->timeSlotDataCount<TIMESLOTDATA_PER_MSG) {
				// get next used time slot in i
				if(timeSlots[i].moteID != 0 && timeSlots[i].hopCount < 2) {
			
					// add corresponding timeSlotData to the message
					timeSlotMsgPtr->timeSlots[timeSlotMsgPtr->timeSlotDataCount].moteID = timeSlots[i].moteID;
					timeSlotMsgPtr->timeSlots[timeSlotMsgPtr->timeSlotDataCount].timeSlot = timeSlots[i].timeSlot;
					timeSlotMsgPtr->timeSlots[timeSlotMsgPtr->timeSlotDataCount].hopCount = timeSlots[i].hopCount;
					timeSlotMsgPtr->timeSlotDataCount++;
				}
				i++;
			}
			// put message in the send queue
			call MsgList.addLast(&toRadio, msgPtr);
			post sendMsg();
		} 
	}

	event result_t SendDispatchMsg.sendDone(TOS_MsgPtr msgPtr, bool success) {
		call Leds.greenOff();
		call MsgList.addLast(&free, msgPtr);
		return SUCCESS;
	}

	event TOS_MsgPtr ReceiveDispatchMsg.receive(TOS_MsgPtr receivedMsgPtr){
		TimeSlotMsg* timeSlotMsgPtr = (TimeSlotMsg*)(receivedMsgPtr->data);
		uint8_t i;
		
		if(!negotiating) return receivedMsgPtr;
		
		call Leds.yellowOn();
		
		for(i=0; i<timeSlotMsgPtr->timeSlotDataCount; i++)
			if(timeSlotMsgPtr->timeSlots[i].moteID != TOS_LOCAL_ADDRESS)
				updateTimeSlotsTable(timeSlotMsgPtr->timeSlots[i].moteID,
									 timeSlotMsgPtr->timeSlots[i].timeSlot,
									 timeSlotMsgPtr->timeSlots[i].hopCount + 1);
		call Leds.yellowOff();
		return receivedMsgPtr;
	}

	event result_t Timer.fired() {
		// TODO: remove random wait if random timer included
		
		// random wait to avoid sending at the same time
		wait(call Random.rand() % MAX_RANDOM_WAIT);
		sendTimeSlotMsgs();
		
		return SUCCESS;
	}

	command void IntCommand.execute(uint16_t param) {
		uint16_t rval = myTimeSlot;
		switch(param & 0xff) {
			case 0: rval = call StdControl.stop(); break;
			case 1: rval = call StdControl.start(); break;
			case 2: rval = negotiating; break;
			case 3: if(call StdControl.stop()==SUCCESS) {
						myTimeSlot = param >> 8 & 0xff;
						rval = SUCCESS;
					} else rval = FAIL;
					break;
		}
		signal IntCommand.ack(rval);
	}
	
	command int16_t TimeSlotNegotiation.getTimeSlot() {
		return myTimeSlot;
	}

	command uint8_t TimeSlotNegotiation.getTimeSlotCount() {
		return TIMESLOT_COUNT;
	}

	command bool TimeSlotNegotiation.isNegotiating() {
		return negotiating;
	}
}
