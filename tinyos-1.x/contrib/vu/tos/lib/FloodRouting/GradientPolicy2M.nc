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

/* VIJAI: Changed IntCommand.execute(...) to reflect the 16 bit return value in IntCommand.ack(...) -
		  1. Changed "ret" from 8 bit to 16 bit
		  2. Removed (uint8_t) downcast for function calls except for msgCount.
*/

includes GradientPolicyMsg;

module GradientPolicy2M
{
	provides
	{
		interface StdControl;
		interface GradientPolicy;
		interface FloodingPolicy;
		interface IntCommand;
	}
	uses
	{
		interface FloodRouting;
		interface Timer;
	}
}

implementation
{
	uint16_t hopCountSum;
	uint8_t msgCount;
	uint16_t pulses;
	uint8_t lastCounter;

	/**** hop count ****/

	command void GradientPolicy.setRoot()
	{
		pulses = 0xFFFF;
		hopCountSum = 0;
		msgCount = 1;
		lastCounter = lastCounter | 0x0F;

		call Timer.start2(TIMER_REPEAT, TIMER_JIFFY / 2);
	}

	command uint16_t GradientPolicy.getRoot()
	{
		if( hopCountSum == 0 && msgCount == 1 )
			return TOS_LOCAL_ADDRESS;

		return 0xFFFF;
	}

	command uint16_t GradientPolicy.getHopCount()
	{
		if( msgCount == 0 )
			return 0xFFFF;

		return (hopCountSum << 2) / msgCount;
	}

	/**** implementation ****/

	struct packet
	{
		uint8_t counter;	// 0-3: pulse counter, 4-7: sequence number
		uint8_t hopCount;	// hop count of the sender
	};

	uint8_t buffer[30];

	command result_t StdControl.init() { return SUCCESS; }
	
	command result_t StdControl.start()
	{
		msgCount = 0;
		lastCounter = 0xFF;

		return call FloodRouting.init(2, 1, buffer, sizeof(buffer));
	}

	command result_t StdControl.stop()
	{
		call FloodRouting.stop();
		return SUCCESS;
	}

	event result_t FloodRouting.receive(void *p)
	{
#define data	((struct packet*)p)

		int8_t age = (data->counter & 0xF0) - (lastCounter & 0xF0);
		uint8_t pulse;

		if( age < 0 )
			return FAIL;

		pulse =  ((uint16_t)1) << (data->counter & 0x0F);

		if( age > 0 )
		{
			pulses = 0;
			hopCountSum = 0;
			msgCount = 0;
		}
		else if( (pulses & pulse) != 0 )
			return FAIL;

		lastCounter = data->counter;
		pulses |= pulse;
		hopCountSum += ++(data->hopCount);
		++msgCount;

		return SUCCESS;
#undef data
	}

	event result_t Timer.fired()
	{
		struct packet data = { ++lastCounter, 0 };
		call FloodRouting.send(&data);

		if( (lastCounter & 0x0F) == 0x0F )
			call Timer.stop();

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
		uint16_t ret = 0xFFFF;

		if( param == 0 )
			ret = call GradientPolicy.getRoot();
		else if( param == 1 )
			ret = call GradientPolicy.getHopCount();
		else if( param == 2 )
		{
			call GradientPolicy.setRoot();
			ret = SUCCESS;
		}
		else if( param == 3 )
			ret = msgCount;

		signal IntCommand.ack(ret);
	}
}
