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
 *   The FloodRouting component provides a generic framework for writing and using 
 * routing protocols based on directed flooding. The user of the FloodRouting 
 * component can send and receive regular sized data packets, can select the
 * flooding policy (like broadcast, convergecats, tree routing, etc.). Multiple
 * data packet types and flooding policies can be used simultaneously. The 
 * framework automatically supports the aggregation of multiple data packets
 * into a single TOS_Msg, and allows the modification and control of the routed
 * messages in the network. 
 * See FloodRouting.txt for more details.
 *
 *   @author Miklos Maroti
 *   @author Brano Kusy, kusy@isis.vanderbilt.edu
 *   @modified Jan05 doc fix
 */

includes FloodRoutingMsg;
includes Timer;
#include <string.h>

// #define FLOODROUTING_DEBUG

module FloodRoutingM
{
	provides
	{
		interface StdControl;
		interface FloodRouting[uint8_t id];
	}
	uses
	{
		interface FloodingPolicy[uint8_t id];
		interface SendMsg;
		interface ReceiveMsg;
		interface Timer;
		interface StdControl as SubControl;
		interface Leds;
	}
}

implementation
{
	/**
	* Block is an encapsulation of data packet that is routed.
	* Blocks are stored sequentially in a buffer that the user of FloodRouting
	*	provides.
	*/
	struct block
	{
		uint8_t priority;	// lower value is higher priority
		uint8_t data[0];	// the packet data of length dataLength
	};

	/**
	* States of the desc->dirty flag in the struct descriptor.
	* dirty flag contains information for all blocks in the buffer;
	* allows for optimization in routing engine - can skip the whole
	*   descriptor, no need to visit all blocks in the descriptor
	*/
	enum
	{
		DIRTY_CLEAN = 0x00,	// no action is needed for this descriptor
		DIRTY_AGING = 0x01,	// only aging is required, no sending
		DIRTY_SENDING = 0x03,	// some packets are ready to be sent
	};

	/**
	* Descriptor is a logical structure which we build on top of a buffer (
	*   a 'chunk of data' provided by user), each parametrized FloodRouting
	*   interface has one descriptor.
	*   buffer is structured the following way: the first 10 bytes is a header and
	*   the next bytes are sequentially stored data packets (called blocks).
	*   sequential representation of blocks saves space, to be able to access the blocks,
	*   we use the fact that blocks have uniform size (blockLength), and we store
	*   a pointer to the first block (blocks) and to the last block(blocksEnd).
	*/
	struct descriptor
	{
		uint8_t appId;		// comes from parametrized FloodRouting interface
		struct descriptor *nextDesc;// allows to go through multiple buffers
		uint8_t dataLength; 	// size of a data packet in bytes (i.e. size of block.data)
		uint8_t uniqueLength;	// size of unique part of data a packet in bytes
		uint8_t blockLength;	// dataLength + 1, where 1 is a size of priority field
		uint8_t maxDataPerMsg;	// how many packets can fit in the buffer
		uint8_t dirty;		// common information about states of all blocks 
		struct block *blocksEnd;// pointer to the last block in the descriptor
		struct block blocks[0]; // pointer to the first block in the descriptor
	};
	
	/** 
	* Descriptors are stored as a linked list.
	*/
	struct descriptor *firstDesc;

	/** 
	* Find descriptor for a specific parametrized interface.
	*/
	struct descriptor *getDescriptor(uint8_t appId)
	{
		struct descriptor *desc = firstDesc;
		while( desc != 0 )
		{
			if( desc->appId == appId )
				return desc;

			desc = desc->nextDesc;
		}
		return 0;
	}

	/**
	* Return the next block in the descriptor.
	*/
	static inline struct block* nextBlock(struct descriptor *desc, struct block* blk)
	{
		return (struct block*)(((void*)blk) + desc->blockLength);
	}

	/**
	* Returns match or block with lowest priority (set to 0xFF).
	*/
	struct block *getBlock(struct descriptor *desc, uint8_t *data)
	{
		struct block *blk = desc->blocks;
		struct block *selected = blk;

		do
		{
			if( blk->priority != 0xFF
				&& memcmp(blk->data, data, desc->uniqueLength) == 0 )
				return blk;

			if( blk->priority > selected->priority )
				selected = blk;

			blk = nextBlock(desc, blk);
		} while( blk < desc->blocksEnd );

		selected->priority = 0xFF;
		return selected;
	}

	TOS_Msg rxMsgData, txMsg;
	TOS_MsgPtr rxMsg;

	/* 
	* There are three concurrent activities, that routing engine performs.
	*  (1) sending of packets, 
	*  (2) processing of a received msg, and
	*  (3) aging of packets
	*/
	uint8_t state;
	enum
	{
		STATE_IDLE = 0x00,
		STATE_SENDING = 0x01,
		STATE_PROCESSING = 0x02,
		STATE_AGING = 0x04,
	};
	
	// see selectData comments
	struct block freeBlock = { 0xFF };

	/**
	* Selects blocks for transmission from desc and stores them in selection. 
	*	selection buffer is provided by caller.
	*	 blocks are selected based on priority.
	*	 blocks are sorted in decreasing order (priority field) in selection.
	*/
	void selectData(struct descriptor *desc, struct block **selection)
	{
		uint8_t maxPriority = 0xFF;
		struct block *blk = desc->blocks;
		struct block **s = selection + desc->maxDataPerMsg;
		struct block stopBlock = { 0x00 };

		// the blocks in selection are in decreasing order, initialization:
		//  - the last block has highest priority (0x00)
		//  - all other blocks have lowest priority (0xFF)
		//  - free Block needs to be a global variable, since if there is 
		//	less to be transmitted packets in desc, than the maximum we
		//	can fit to the FloodRouting message, selection would point
		//	to non-existent data after returning
		*s = &stopBlock;
		do
			*(--s) = &freeBlock;
		while( s != selection );

		// go through all blocks in desc, find the highest priority block
		// and insert them in selection in decreasing order
		do
		{
			uint8_t priority = blk->priority;
			//only block with even priority can be transmitted
			//see FloodingPolicy.nc for more details
			if( (priority & 0x01) == 0 && priority < maxPriority )
			{
				s = selection;
				while( priority < (*(s+1))->priority )
				{
					*s = *(s+1);
					++s;
				}

				*s = blk;
				maxPriority = (*selection)->priority;
			}

			blk = nextBlock(desc, blk);
		} while( blk < desc->blocksEnd );
	}

	/**
	* Creates FloodRouting message by copying selection of blocks into the message.
	*	 selection provides blocks in the decreasing order, the last
	*	  block having the highest priority, that's why we want to 
	*	  start copying data from the end of selection.
	*	 if FLOODROUTING_DEBUG is specified, priority fields of particular
	*	  blocks get transmitted as well.
	*	 copyData() will be called after selectData().
	*/
	void copyData(struct descriptor *desc, struct block **selection)
	{
		struct block **s = selection + desc->maxDataPerMsg;
		uint8_t *data = ((FloodRoutingMsg*)txMsg.data)->data;

		while( s != selection && (*(--s))->priority != 0xFF )
		{
			memcpy(data, (*s)->data, desc->dataLength);
#ifdef FLOODROUTING_DEBUG
			*(data + desc->dataLength - 1) = (*s)->priority;
#endif
			data += desc->dataLength;
		}

		((FloodRoutingMsg*)txMsg.data)->appId = desc->appId;
		((FloodRoutingMsg*)txMsg.data)->location = call FloodingPolicy.getLocation[desc->appId]();
		txMsg.length = data - ((uint8_t*)txMsg.data);
	}

	/**
	*  Task sendMsg() goes through the descriptions list and schedules radio messages for transmission.
	*   first a buffer is created, where the selected blocks will be stored, then for each
	*	description, we call selectData() (puts blocks into the selection buffer) and
	*	copyData() (copies selection blocks into a radio message).
	*   we transmit 1 TOSMSG containing the first blocks found in the first descriptor
	*	that had at least one block to be sent, 1 msg contains only blocks from 1 descriptor.
	*   if at least one block from a descriptor is transmitted, desc->dirty is set to aging.
	*/
	task void sendMsg()
	{
		// 1 + FLOODROUTING_MAXDATA / 2 is the upper bound on the size of selection, 
		// assuming that the data part of each block is at least 1 byte long;
		// note that selection contains certain number blocks that are copied into
		// a radio message
		struct block *selection[1 + FLOODROUTING_MAXDATA / 2];

		struct descriptor *desc = firstDesc;
		while( desc != 0 )
		{
			//if DIRTY_SENDING, then there exists at least one block that need to be
			//transmitted in desc
			if( desc->dirty == DIRTY_SENDING )
			{
				selectData(desc, selection);
				copyData(desc, selection);

				//if there is at least one block to be sent
				if( txMsg.length > FLOODROUTING_HEADER )
				{
					if( call SendMsg.send(TOS_BCAST_ADDR, txMsg.length, &txMsg) != SUCCESS 
							&& ! post sendMsg() )
						state &= ~STATE_SENDING;
					
					call Leds.redToggle();
					return;
				}
				
				//we have sent at least one packet, this packet needs to be aged	
				desc->dirty = DIRTY_AGING;
			}
			desc = desc->nextDesc;
		}

		state &= ~STATE_SENDING;
	}

	/**
	* Upon successfull sending, we call task sendMsg() again, to transmit all the data which
	* are waiting to be transmitted.
	*/
	task void sendMsgDone()
	{
		FloodRoutingMsg *msg = (FloodRoutingMsg*)txMsg.data;
		struct descriptor *desc = getDescriptor(msg->appId);

		if( desc != 0 )
		{
			//call policy.sent() on each of the transmitted blocks
			//this allows to update priority of the block according to the policy
			uint8_t *data = ((uint8_t*)txMsg.data) + txMsg.length;
			while( msg->data <= (data -= desc->dataLength) )
			{
				struct block *block = getBlock(desc, data);
				if( block->priority != 0xFF )
					block->priority = call FloodingPolicy.sent[desc->appId](block->priority);
			}
		}

		if( ! post sendMsg() )
			state &= ~STATE_SENDING;
	}

	event result_t SendMsg.sendDone(TOS_MsgPtr p, result_t success)
	{
		if( success != SUCCESS )
		{
			if( ! post sendMsg() )
				state &= ~STATE_SENDING;
		}
		else
		{
			if( ! post sendMsgDone() )
				state &= ~STATE_SENDING;
		}

		return SUCCESS;
	}

	/**
	* Blocks are extracted out from the received message and stored in routing
	* buffer, if the routing policy accepts the packet and the application that 
	* initialized FloodRouting accepts the packet as well(signal 
	* FloodRouting.receive[](data) == SUCCESS).
	**/
	task void procMsg()
	{
		FloodRoutingMsg *msg = (FloodRoutingMsg*)rxMsg->data;
		struct descriptor *desc = getDescriptor(msg->appId);

		call Leds.greenToggle();

		if( desc != 0 && call FloodingPolicy.accept[desc->appId](msg->location) )
		{
			uint8_t *data = ((uint8_t*)rxMsg->data) + rxMsg->length;
			while( msg->data <= (data -= desc->dataLength) )
			{
				struct block *block = getBlock(desc, data);
				if( block->priority == 0xFF )
				{
					if( signal FloodRouting.receive[msg->appId](data) != SUCCESS )
						continue;

					memcpy(block->data, data, desc->dataLength);
					block->priority = 0x00;
				}
				block->priority = call FloodingPolicy.received[desc->appId](msg->location, block->priority);
			}

			desc->dirty = DIRTY_SENDING;
			if( (state & STATE_SENDING) == 0 && post sendMsg() )
				state |= STATE_SENDING;
		}

		state &= ~STATE_PROCESSING;
	}

	/**
	* Routing message from a different mote is scheduled for processing.
	*  since the pointer p which we obtain in the receive event can not be used
	*   after we return from the event handler, and we need to take long time to
	*   process the received message (i.e. we post a task), we need to save the
	*   pointer to some local variable (rxMsg)
	*/
	event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p)
	{
		if( (state & STATE_PROCESSING) == 0 )
		{
			TOS_MsgPtr t;

			t = rxMsg;
			rxMsg = p;
			p = t;

			if( post procMsg() )
				state |= STATE_PROCESSING;
		}

		return p;
	}

	/**
	* Packets need to be aged, until they are thrown out from the buffer.
	*  moreover, after a packet has been aged, it may have to be resend (depending on
	*   the current policy), therefore we need to check for this and post a send task
	*   if it happens.
	*  dirty flag for desc is set to DIRTY_AGING, if there is at least one packet that
	*   needs to be aged, and set to DIRTY_SENDING if it needs to be sent().
	*/
	task void age()
	{
		struct descriptor *desc = firstDesc;
		while( desc != 0 )
		{
			if( desc->dirty != DIRTY_CLEAN )
			{
				struct block *blk = desc->blocks;
				desc->dirty = DIRTY_CLEAN;
				do
				{
					if( blk->priority != 0xFF )
					{
						blk->priority = call FloodingPolicy.age[desc->appId](blk->priority);

						if( (blk->priority & 0x01) == 0 )
							desc->dirty = DIRTY_SENDING;
						else
							desc->dirty |= DIRTY_AGING;
					}
					blk = nextBlock(desc, blk);
				} while( blk < desc->blocksEnd );

				if( desc->dirty == DIRTY_SENDING 
						&& (state & STATE_SENDING) == 0 
						&& post sendMsg() )
					state |= STATE_SENDING;
			}
			desc = desc->nextDesc;
		}
		state &= ~STATE_AGING;
	}

	/**
	* Each timer event triggers aging of the blocks in descriptors.
	*  this may result in sending a radio message.
	*/
	event result_t Timer.fired()
	{
		if( (state & STATE_AGING) == 0 && post age() )
			state |= STATE_AGING;

		return SUCCESS;
	}

	/** Find the actual block in a descriptor based on the match of unique data
	*   part, the new block gets assigned 0x00 priority and is sent from a task.
	*/
	command result_t FloodRouting.send[uint8_t id](void *data)
	{
		struct descriptor *desc = getDescriptor(id);
		if( desc != 0 )
		{
			struct block *blk = getBlock(desc, data);
			if( blk->priority == 0xFF )
			{
				memcpy(blk->data, data, desc->dataLength);
				blk->priority = 0x00;

				desc->dirty = DIRTY_SENDING;
				if( (state & STATE_SENDING) == 0 && post sendMsg() )
					state |= STATE_SENDING;

				call Leds.yellowToggle();
				return SUCCESS;
			}
		}
		return FAIL;
	}

	command result_t FloodRouting.init[uint8_t id](uint8_t dataLength, uint8_t uniqueLength,
		void *buffer, uint16_t bufferLength)
	{
		struct block *blk;
		struct descriptor *desc;
		
		//if debug is specified, then block.priority(1 byte) is transmitted over the radio
#ifdef FLOODROUTING_DEBUG
		++dataLength;
#endif
		if( dataLength < 2 //dataLength is too small
			|| dataLength > FLOODROUTING_MAXDATA //single packet does not fit in TOSMSG
			|| uniqueLength > dataLength	     
			|| bufferLength <= 		//single packet does not fit in the buffer
				sizeof(struct descriptor) + dataLength 
			|| getDescriptor(id)!=0 )	//the descriptor for id already exists
			return FAIL;

		desc = (struct descriptor*)buffer;
		desc->appId = id;
		desc->dataLength = dataLength;
		desc->uniqueLength = uniqueLength;
		desc->blockLength = dataLength + 1;
		desc->maxDataPerMsg = FLOODROUTING_MAXDATA / dataLength;
		desc->dirty = DIRTY_CLEAN;

		buffer += bufferLength - dataLength;	// this is the first invalid position
		blk = desc->blocks;
		while( (void*)blk < buffer )
		{
			blk->priority = 0xFF;
			blk = nextBlock(desc, blk);
		}
		desc->blocksEnd = blk;
		
		desc->nextDesc = firstDesc;
		firstDesc = desc;

		return SUCCESS;
	}

	/** Just remove the descriptor from the linked list, the information is lost.
	*  stop() can not be undone (i.e. restarted).
	*/
	command void FloodRouting.stop[uint8_t id]()
	{
		struct descriptor **desc = &firstDesc;
		while( *desc != 0 )
		{
			if( (*desc)->appId == id )
			{
				*desc = (*desc)->nextDesc;
				return;
			}
			desc = &((*desc)->nextDesc);
		}
	}

	default command uint16_t FloodingPolicy.getLocation[uint8_t id]() { return 0; }
	default command uint8_t FloodingPolicy.sent[uint8_t id](uint8_t priority) { return 0xFF; }
	default command result_t FloodingPolicy.accept[uint8_t id](uint16_t location) { return FALSE; }
	default command uint8_t FloodingPolicy.received[uint8_t id](uint16_t location, uint8_t priority) { return 0xFF; }
	default command uint8_t FloodingPolicy.age[uint8_t id](uint8_t priority) { return priority; }
	default event result_t FloodRouting.receive[uint8_t id](void *data) { return FAIL; }

	command result_t StdControl.init()
	{
		firstDesc = 0;
		rxMsg = &rxMsgData;
		state = STATE_IDLE;

		return call SubControl.init();
	}
	
	command result_t StdControl.start()
	{
		call SubControl.start();
		call Timer.start(TIMER_REPEAT, 1024);	// one second timer
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		call Timer.stop();
		return SUCCESS;
	}
}
