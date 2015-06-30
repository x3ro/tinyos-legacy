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
 **/
 /** 
 *   The GradientPolicy component is used to convergecast messages to a stationary
 * base station. This policy has to be used together with the FloodRouting component.
 * The GradientPolicy first calculates the hop count distance from the root,
 * then based on this information forwards packets. Tha basic idea is that if the 
 * same packet is heard from a node closer to the root than the currect node, 
 * then the packet is not sent from this node. Otherwise, we send each packet up to
 * three times (with 2 and 1 sec delays in between). 
 * See GradientPolicy.txt for further details.
 *
 *   @author Miklos Maroti
 *   @author Brano Kusy, kusy@isis.vanderbilt.edu
 *   @modified Jan05 doc fix
 */
 
includes GradientPolicyMsg;

module GradientPolicyM
{
	provides
	{
		interface GradientPolicy;
		interface FloodingPolicy;
		interface IntCommand;
		interface DataCommand as GradientPolicyDownloadConfigurationCommands;
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
	uint8_t lastSeqNum = 0xFF;
	uint8_t nextHopCount;

	// hop count ****/

	command void GradientPolicy.setRoot()
	{
		root = TOS_LOCAL_ADDRESS;
		//update the first half-byte of seqNum, so that others know the new root
		//is being set up
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

	// implementation ****/

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

	/**
	* The hopcount of the sender is retrieved from the message, our hopcount is one bigger.
	* We just average the received hopcounts over last couple of messages received. Sequence
	* number makes sure, for each roots message, only the first one is being averaged. root variable
	* allows to differentiate new root from the old one - averaging needs to be reinitiated.
	* If new message was received, it is rebroadcasted -> this is flooding.
	*/
	event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p)
	{
		GradientPolicyMsg *m = (GradientPolicyMsg*)p->data;
#ifdef SIMULATE_MULTIHOP	
		// this code was used to simulate multiple hops, just least significant 8 bits of TOS_LOCAL_ADDRESS  
		// are important and are assumed to have this format: 0xXY, where X,Y are coordinates of mote in 2D space
		// all incoming messages from non-neighbors are thrown out
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

	/**
	* Timer ticks only at the root, which is the initiator of the GradienPolicy messages.
	* Root sends one message per timer tick, up to 16 times.
	*/
	event result_t Timer.fired()
	{
		if( root != TOS_LOCAL_ADDRESS || (++lastSeqNum & 0x0F) == 0x0F )
			call Timer.stop();

		if( root == TOS_LOCAL_ADDRESS && !sending )
			post sendMsg();

		return SUCCESS;
	}

	// flooding policy ****/

/*      State machine:
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

	/** Remote command, that allows to set the root remotely.
	* Also gradientPolicy status data can be obtained remotely.
	*
	*
	*/
	
	command void IntCommand.execute(uint16_t param)
	{
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
	
	command uint16_t GradientPolicy.setHopCount(uint16_t hc){
		msgCount = 1;
		return hopCountSum = hc;
	}
	
	command uint16_t GradientPolicy.setRootAs(uint16_t r){
		return root = r;
	}
	
	typedef struct _ParametersConfigMessage {
    	uint8_t appid;
    	uint8_t configMsg[TOSH_DATA_LENGTH-1];
    } ParametersConfigMessage;
    
    typedef struct _GradientConfigMessage {
    	uint16_t root;
    	uint16_t hopcount;
    } GradientConfigMessage;
    
    command void GradientPolicyDownloadConfigurationCommands.execute(void* data,uint8_t length){
    	ParametersConfigMessage *baseMsg = (ParametersConfigMessage*) data;
    	if(baseMsg -> appid == 0xa3){
	    	GradientConfigMessage *cmsg = (GradientConfigMessage*) baseMsg -> configMsg;
	    	call GradientPolicy.setRootAs(cmsg->root);
	    	call GradientPolicy.setHopCount(cmsg->hopcount);
	    	signal GradientPolicyDownloadConfigurationCommands.ack(SUCCESS);
	   	}
    }
}
