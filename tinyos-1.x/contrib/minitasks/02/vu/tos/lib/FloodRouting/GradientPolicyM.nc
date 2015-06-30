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
 * Author: Miklos Maroti, Gabor Pap
 * Date last modified: 06/30/03
 */

includes GradientPolicyMsg;

module GradientPolicyM
{
	provides
	{
		interface GradientPolicy;
		interface FloodingPolicy;
		interface IntCommand;
	}
	uses
	{
		interface SendMsg;
		interface ReceiveMsg;
		interface Timer;
	}
}

implementation
{
	uint16_t root = 0xFFFF;
	uint16_t hopCountSum;
	uint8_t msgCount = 0;
	uint8_t lastSeqNum;
	uint8_t nextHopCount;

	/**** hop count ****/

	command void GradientPolicy.setRoot()
	{
		if( root != TOS_LOCAL_ADDRESS )
			lastSeqNum = 0xFF;

		root = TOS_LOCAL_ADDRESS;
		hopCountSum = 0;
		msgCount = 1;
		nextHopCount = 0;

		call Timer.start2(TIMER_REPEAT, TIMER_JIFFY / 2);
	}

	command uint16_t GradientPolicy.getRoot()
	{
		return root;
	}

	command uint16_t GradientPolicy.getHopCount()
	{
		if( msgCount == 0 )
			return 0xFFFF;

		return (hopCountSum << 2) / msgCount;
	}

	/**** implementation ****/

	TOS_Msg msg;
	bool sending = FALSE;

	task void sendMsg()
	{
		if( sending )
			return;

		atomic
		{
			((GradientPolicyMsg*)msg.data)->root = root;
			((GradientPolicyMsg*)msg.data)->seqNum = lastSeqNum;
			((GradientPolicyMsg*)msg.data)->hopCount = nextHopCount;
		}

		if( call SendMsg.send(TOS_BCAST_ADDR, sizeof(GradientPolicyMsg), &msg) == SUCCESS )
			sending = TRUE;
		else
			post sendMsg();
	}

	event result_t SendMsg.sendDone(TOS_MsgPtr p, result_t success)
	{
		sending = FALSE;
		return SUCCESS;
	}

	event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p)
	{
		GradientPolicyMsg *m = (GradientPolicyMsg*)p->data;

		if( m->root == TOS_LOCAL_ADDRESS )
			goto exit;
		else if( m->root != root || (m->seqNum & 0xF0) != (lastSeqNum & 0xF0) )
		{
			root = m->root;
			hopCountSum = m->hopCount + 1;
			msgCount = 1;
		}
		else if( ((int8_t)(m->seqNum - lastSeqNum)) > 0 )
		{
			hopCountSum += m->hopCount + 1;
			msgCount += 1;
		}
		else
			goto exit;

		nextHopCount = m->hopCount + 1;
		lastSeqNum = m->seqNum;
		post sendMsg();

	exit:
		return p;
	}

	event result_t Timer.fired()
	{
		if( (++lastSeqNum & 0x0F) == 0x0F )
			call Timer.stop();

		post sendMsg();
		return SUCCESS;
	}

	/**** flooding policy ****/

/* 
	0 --sent--> 1 --tick--> 3 --tick--> 4 --sent--> 5 --tick--> 6 --sent--> 7
	7 --tick--> 9 --tick--> ... --tick--> 65 --tick--> 0xff
*/
	command uint16_t FloodingPolicy.getLocation()
	{
		return call GradientPolicy.getHopCount();
	}

	command uint8_t FloodingPolicy.sent(uint8_t priority)
	{
		uint16_t myLocation = call FloodingPolicy.getLocation();

		if( priority == 4 && myLocation == 0 )
			return 6;
		else if( priority == 0 || priority == 4 || priority == 6 )
			return priority + 1;
		else
			return priority;
	}

	command result_t FloodingPolicy.accept(uint16_t location)
	{
		uint16_t myLocation = call FloodingPolicy.getLocation();

		if( myLocation == location )
			return FALSE;
		else
			return TRUE;
	}

	command uint8_t FloodingPolicy.received(uint16_t location, uint8_t priority)
	{
		uint16_t myLocation = call FloodingPolicy.getLocation();

		if( priority == 0 && myLocation == 0 )
			return 4;
		else if( priority < 7 && myLocation > location )
			return 7;
		else if( priority > 7 && myLocation <= location )
			return 7;
		else
			return priority;
	}

	command uint8_t FloodingPolicy.age(uint8_t priority)
	{
		if( (priority & 0x01) == 0 )
			return priority;
		else if( priority == 3 || priority == 5 )
			return priority + 1;
		else if( priority < 65 )
			return priority + 2;
		else
			return 0xFF;
	}

	/**** remote command ****/
	
	command void IntCommand.execute(uint16_t param)
	{
		if( param == 0 )
			signal IntCommand.ack((uint8_t)call GradientPolicy.getRoot());
		else if( param == 1 )
			signal IntCommand.ack((uint8_t)call GradientPolicy.getHopCount());
		else if( param == 2 )
		{
			call GradientPolicy.setRoot();
			signal IntCommand.ack(SUCCESS);
		}
	}
}
