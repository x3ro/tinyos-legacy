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
 * Author: Andras Nadas, Miklos Maroti, Sachin Mujumdar
 * Date last modified: 08/21/03
 */

includes Timer;

module RemoteControlM
{
	provides
	{
		interface StdControl;
	}

	uses
	{
		interface IntCommand[uint8_t id];
		interface DataCommand[uint8_t id];
		interface StdControl as StdControlCommand[uint8_t id];

		interface ReceiveMsg;
		interface SendMsg;
		interface Timer;
		interface FloodRouting;
	}
}

implementation
{
	typedef struct RemoteControlMsg
	{
		uint8_t	seqNum;		// sequence number (incremeneted at the base station)
		uint16_t target;	// node id of final destination, or 0xFFFF for all, or 0xFF?? or a group of nodes
		uint8_t dataType;	// what kind of command is this
		uint8_t appId;		// app id of final destination
		uint8_t data[0];	// variable length data packet
	} __attribute__ ((packed))RemoteControlMsg;
	// "__attribute__ ((packed))" added by Sachin - to make it work on PC, and prevent errors in typecasting
	// TOS_Msg back to RemoteControlMsg

#ifndef TOS_SUBGROUP_ADDR
#define TOS_SUBGROUP_ADDR 0xFF00
#endif

	uint8_t sentSeqNum;
	TOS_Msg tosMsg;
	uint8_t lastAppId;

	uint8_t state;
	enum
	{
		STATE_BUSY = 0x00,
		STATE_FORWARDED = 0x01,
		STATE_EXECUTED = 0x02,
		STATE_IDLE = 0x03,
	};

#define controlMsg ((RemoteControlMsg*)tosMsg.data)

	command result_t StdControl.init()
	{
		result_t ret = SUCCESS;

		// initialize all remotely controlled components
		uint8_t id = 0;
		do 
			ret = rcombine(ret, call StdControlCommand.init[id++]());
		while( id != 0 );

		return ret;
	}

	struct reply
	{
		uint16_t nodeId;
		uint8_t seqNum;
		uint8_t ret;
	};
	
#ifdef LEAF_NODE
	uint8_t routingBuffer[20];
#else
	uint8_t routingBuffer[100];
#endif

	command result_t StdControl.start()
	{
		sentSeqNum = 0;
		controlMsg->seqNum = 0;
		state = STATE_IDLE;

		call FloodRouting.init(4, 3, routingBuffer, sizeof(routingBuffer));

		return call Timer.start2(TIMER_REPEAT, TIMER_JIFFY / 4);
	}

	command result_t StdControl.stop()
	{
		call Timer.stop();
		return SUCCESS;
	}

	event result_t Timer.fired()
	{
		if( sentSeqNum != controlMsg->seqNum )
			call SendMsg.send(TOS_BCAST_ADDR, tosMsg.length, &tosMsg);

		return SUCCESS;
	}

	event result_t SendMsg.sendDone(TOS_MsgPtr p, result_t success)
	{
		sentSeqNum = controlMsg->seqNum;
		state |= STATE_FORWARDED;

		return SUCCESS;
	}

	void task execute()
	{
		lastAppId = controlMsg->appId;

		if( controlMsg->dataType == 0 )		// IntCommand
			call IntCommand.execute[lastAppId](*(uint16_t*)controlMsg->data);
		else if( controlMsg->dataType == 1 )	// DataCommand
			call DataCommand.execute[lastAppId](controlMsg->data, 
				tosMsg.length - sizeof(RemoteControlMsg));
		else if( controlMsg->dataType == 2 )	// StdControlCommand
		{
			struct reply reply = { TOS_LOCAL_ADDRESS, controlMsg->seqNum, 0xFF };

			uint8_t cmd = *(uint8_t*)controlMsg->data;
			if( cmd == 0 )	// stop
				reply.ret = call StdControlCommand.stop[lastAppId]();
			else if( cmd == 1 )	// start
				reply.ret = call StdControlCommand.start[lastAppId]();
			else if( cmd == 2 )	// restart
				reply.ret = rcombine(call StdControlCommand.stop[lastAppId](),
					call StdControlCommand.start[lastAppId]());

			call FloodRouting.send(&reply);
		}

		state |= STATE_EXECUTED;
	}

	event result_t FloodRouting.receive(void *data) { return SUCCESS; }

	event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p)
	{
		int8_t age = ((RemoteControlMsg*)p->data)->seqNum - controlMsg->seqNum;
		if( state == STATE_IDLE && 0 < age )
		{
			state = STATE_BUSY;
			tosMsg = *p;

			if( controlMsg->target == TOS_LOCAL_ADDRESS 
					|| controlMsg->target == TOS_BCAST_ADDR
					|| controlMsg->target == TOS_SUBGROUP_ADDR )
				post execute();
			else
				state |= STATE_EXECUTED;
		}
		return p;
	}
	
	event void IntCommand.ack[uint8_t appId](uint8_t returnValue)
	{
		if( appId == lastAppId ) {
			struct reply reply = { TOS_LOCAL_ADDRESS, controlMsg->seqNum, returnValue };
		        call FloodRouting.send(&reply);
		}
	}

	event void DataCommand.ack[uint8_t appId](uint8_t returnValue)
	{
		if( appId == lastAppId ) {
			struct reply reply = { TOS_LOCAL_ADDRESS, controlMsg->seqNum, returnValue };
		        call FloodRouting.send(&reply);
		}
	}
	
	default command void IntCommand.execute[uint8_t appId](uint16_t param) {}
	default command void DataCommand.execute[uint8_t appId](void *data, uint8_t length) {}
	default command result_t StdControlCommand.init[uint8_t appId]() { return 0xFF; }
	default command result_t StdControlCommand.start[uint8_t appId]() { return 0xFF; }
	default command result_t StdControlCommand.stop[uint8_t appId]() { return 0xFF; }
}
