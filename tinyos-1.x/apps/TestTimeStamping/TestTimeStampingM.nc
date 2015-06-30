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
 * Date last modified: 12/06/03
 */

includes Timer;

module TestTimeStampingM
{
	provides
	{
		interface StdControl;
	}
	uses
	{
		interface DiagMsg;
		interface Timer;
		interface SendMsg;
		interface ReceiveMsg;
		interface TimeStamping;
		interface Leds;
#ifdef TIMESTAMPING_CALIBRATE
		command uint8_t getBitOffset();
#endif
	}
}

implementation
{
	enum
	{
		RATE = 1000,	// once per second
	};

	typedef struct TestMsg
	{
		uint16_t sender;	// the node if of the sender
		uint32_t sendingTime;	// in local time 
	} TestMsg;

	command result_t StdControl.init()
	{
		call Leds.init();
		return SUCCESS;
	}		

	command result_t StdControl.start()
	{
		call Timer.start(TIMER_REPEAT, RATE);
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		call Timer.stop();
		return SUCCESS;
	}

	TOS_Msg msg;
	bool busy = FALSE;
#define testMsg ((TestMsg*)msg.data)

	task void send()
	{
		testMsg->sender = TOS_LOCAL_ADDRESS;
		testMsg->sendingTime = 0;

		if( call SendMsg.send(TOS_BCAST_ADDR, sizeof(TestMsg), &msg) == SUCCESS )
		{
			call TimeStamping.addStamp(offsetof(TestMsg, sendingTime));
			call Leds.redToggle();
		}
		else
			post send();
	}

	event result_t SendMsg.sendDone(TOS_MsgPtr ptr, result_t success)
	{
		busy = FALSE;
		return SUCCESS;
	}

	event result_t Timer.fired()
	{
		if( ! busy )
		{
			busy = TRUE;
			post send();
		}

		return SUCCESS;
	}

#define inMsg ((TestMsg*)p->data)

	event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p)
	{
		uint32_t rcvTime = call TimeStamping.getStamp();
#ifdef TIMESTAMPING_CALIBRATE
		uint8_t offset = call getBitOffset();
#else
		uint8_t offset = 0;
#endif

		call Leds.greenToggle();

		if( call DiagMsg.record() == SUCCESS )
		{
			call DiagMsg.str("TS");
			call DiagMsg.uint16(inMsg->sender);
			call DiagMsg.uint32(inMsg->sendingTime);
			call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
			call DiagMsg.uint32(rcvTime);
			call DiagMsg.uint8(offset);
			call DiagMsg.send();
		}

		return p;
	}
}
