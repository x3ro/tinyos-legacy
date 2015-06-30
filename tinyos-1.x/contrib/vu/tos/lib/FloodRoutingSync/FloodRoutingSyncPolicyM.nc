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
 * Date last modified: 06/15/04
 */

#ifndef POLICY_DELAY
#define POLICY_DELAY 5
#endif
 
includes GradientPolicyMsg;

module FloodRoutingSyncPolicyM{
	provides{
		interface GradientPolicy;
		interface FloodingPolicy;
		interface IntCommand;
	}
	uses{
		interface SendMsg;
		interface ReceiveMsg;
		interface Timer;
		interface Leds;
	}
}

implementation{
	uint16_t root = 0xFFFF;
	uint16_t hopCountSum;
	uint8_t msgCount = 0;
	uint8_t lastSeqNum = 0xFF;
	uint8_t nextHopCount;

	/**** hop count ****/

	command void GradientPolicy.setRoot()
	{
		root = TOS_LOCAL_ADDRESS;
		lastSeqNum = (lastSeqNum & 0xF0) + 0x10;
		hopCountSum = 0;
		msgCount = 1;
		nextHopCount = 0;

		call Timer.start(TIMER_REPEAT, 1024/2);	// twice per second
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
#ifdef SIMULATE_MULTIHOP	
			((GradientPolicyMsg*)msg.data)->nodeId = TOS_LOCAL_ADDRESS;
#endif	
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
#ifdef SIMULATE_MULTIHOP	
		// this code was used to simulate multiple hops, just least significant 8 bits of TOS_LOCAL_ADDRESS  
		// are important and are assumed to have this format: 0xXY, where X,Y are coordinates of mote in 2D space
		uint8_t incomingID = ((GradientPolicyMsg*)p->data)->nodeId;
		int8_t diff = (incomingID & 0x0F) - (TOS_LOCAL_ADDRESS & 0x0F);
		if( diff < -1 || diff > 1 )
			return p;
		
		diff = (incomingID & 0xF0) - (TOS_LOCAL_ADDRESS & 0xF0);
		if( diff < -16 || diff > 16 )
			return p;
#endif		
		if( m->root != TOS_LOCAL_ADDRESS && (int8_t)(m->seqNum - lastSeqNum) > 0 )
		{
			// shot down a possible ongoing gradient calculation
			if( root == TOS_LOCAL_ADDRESS )
				call Timer.stop();

			lastSeqNum = m->seqNum;
			nextHopCount = m->hopCount + 1;

			if( m->root != root )
			{
				root = m->root;
				hopCountSum = nextHopCount;
				msgCount = 1;
			}
			else
			{
				hopCountSum += nextHopCount;
				msgCount += 1;
			}

			post sendMsg();
		}

		return p;
	}

	event result_t Timer.fired()
	{
		if( root != TOS_LOCAL_ADDRESS || (++lastSeqNum & 0x0F) == 0x0F )
			call Timer.stop();

		if( root == TOS_LOCAL_ADDRESS && !sending )
			post sendMsg();

		return SUCCESS;
	}

	/**** flooding policy ****/

/* 
	0 --sent--> 1 --tick--> 3 --tick--> 4 --sent--> 5 --tick--> 6 --sent--> 7
	7 --tick--> 9 --tick--> ... --tick--> 65 --tick--> 0xff
*/

	command uint16_t FloodingPolicy.getLocation(){
		return call GradientPolicy.getHopCount();
	}

	command uint8_t FloodingPolicy.sent(uint8_t priority){
		uint16_t myLocation = call FloodingPolicy.getLocation();

        call Leds.greenToggle();
        if( myLocation == 0 )
            return POLICY_DELAY*2*3+1;
        else if( priority == 0 || priority == POLICY_DELAY*2 || priority == POLICY_DELAY*2*2 || priority == POLICY_DELAY*2*3 )
            return priority + 1;
        else
            return priority;
	}

	command result_t FloodingPolicy.accept(uint16_t location){
		uint16_t myLocation = call FloodingPolicy.getLocation();

		if( myLocation == location )
			return FALSE;
		else
			return TRUE;
	}

	command uint8_t FloodingPolicy.received(uint16_t location, uint8_t priority){
		uint16_t myLocation = call FloodingPolicy.getLocation();

        if(myLocation == 0 )
            return POLICY_DELAY*2*3+1;
        else if( priority == 0 && myLocation != 0 && myLocation < location)
            return 1;
        else if( priority < POLICY_DELAY*2*3+1 && myLocation >= location )
            return POLICY_DELAY*2*3+1;
        else if( priority > POLICY_DELAY*2*3+1 && myLocation <= location )
            return POLICY_DELAY*2*3+1;
        else
            return priority;
	}

	command uint8_t FloodingPolicy.age(uint8_t priority){
        if( (priority & 0x01) == 0 )
            return priority;
        else if( priority == POLICY_DELAY*2-1 || priority == POLICY_DELAY*2*2-1 || priority == POLICY_DELAY*2*3-1 )
            return priority + 1;
        else if( priority < POLICY_DELAY*2*3+65 )
            return priority + 2;
        else
            return 0xFF;
    }

	command uint16_t GradientPolicy.setRootAs(uint16_t r){
		return root = r;
	}
	command uint16_t GradientPolicy.setHopCount(uint16_t hc){
		msgCount = 1;
		return hopCountSum = hc;
	}

	/**** remote command ****/
	
	command void IntCommand.execute(uint16_t param){
		if( param == 0 )
			signal IntCommand.ack(call GradientPolicy.getRoot());
		else if( param == 1 )
			signal IntCommand.ack(call GradientPolicy.getHopCount());
		else if( param == 2 )
		{
			call GradientPolicy.setRoot();
			signal IntCommand.ack(SUCCESS);
		}
	}
}
