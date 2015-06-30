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

includes GlobalTime;
includes DiagMsg;
includes TestTimeSyncPollerMsg;

module TimeSyncDebuggerM
{
	provides
		interface StdControl;
	uses
	{
		interface GlobalTime;
		interface ReceiveMsg;
		interface LocalTime;
		interface DiagMsg;
		interface Timer;
	}
}

implementation
{
	typedef struct data_t{
		uint16_t	msgID;
		uint32_t	globalClock;
		uint32_t	localClock;
			
		float		skew;
		int32_t		offset;
		uint32_t	syncPoint;
		uint32_t	senderAddr;
	} data_t;

	data_t d;
	bool reporting;

	command result_t StdControl.init(){
		reporting = FALSE;
		return SUCCESS;
	}

	command result_t StdControl.start() {
		return call Timer.start2(32678u * 3);
	}

	command result_t StdControl.stop() {
		return call Timer.stop();
	}

	task void report() {
		if( reporting && call DiagMsg.record() == SUCCESS )
		{
			call DiagMsg.uint8((uint8_t)TOS_LOCAL_ADDRESS);
			call DiagMsg.uint16(d.msgID);
			call DiagMsg.uint32(d.globalClock);
			call DiagMsg.uint32(d.localClock);
			
			//call DiagMsg.real(d.skew);
			//call DiagMsg.int32(d.offset);
			//call DiagMsg.uint16(d.syncPoint);

			call DiagMsg.token(DIAGMSG_END);
			call DiagMsg.setBaseStation(d.senderAddr);
			call DiagMsg.send();
		}

		reporting = FALSE;
	}

	event result_t Timer.fired() {
		post report();
		return SUCCESS;
	}

	event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p)
	{
		if( !reporting )
		{
			d.localClock = d.globalClock = ((TimeSyncPoll*)p->data)->arrivalTime;
			call GlobalTime.local2Global(&d.globalClock);

			d.msgID=((TimeSyncPoll *)(p->data))->msgID;
				
			d.skew=call GlobalTime.getSkew();
			d.offset=call GlobalTime.getOffset();
			d.syncPoint=call GlobalTime.getSyncPoint();
			d.senderAddr=((TimeSyncPoll *)(p->data))->senderAddr;

			reporting = TRUE;
		}

		return p;
	}
}
