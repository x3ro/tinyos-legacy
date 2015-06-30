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
 * Date last modified: 07/01/03
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
	struct block
	{
		uint8_t priority;	// lower value is higher priority
		uint8_t data[0];	// of length dataLength
	};

	enum
	{
		DIRTY_CLEAN = 0x00,	// no action is needed for this descriptor
		DIRTY_AGING = 0x01,	// only aging is required, no sending
		DIRTY_SENDING = 0x03,	// some packets are ready to be sent
	};

	struct descriptor
	{
		uint8_t appId;
		struct descriptor *nextDesc;
		uint8_t dataLength;
		uint8_t uniqueLength;
		uint8_t blockLength;	// dataLength + 1
		uint8_t maxDataPerMsg;
		uint8_t dirty;
		struct block *blocksEnd;
		struct block blocks[0];
	};
	
	struct descriptor *firstDesc;

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

	static inline struct block* nextBlock(struct descriptor *desc, struct block* blk)
	{
		return (struct block*)(((void*)blk) + desc->blockLength);
	}

	// returns match or block with lowest priority (set to 0xFF)
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

	uint8_t state;
	enum
	{
		STATE_IDLE = 0x00,
		STATE_SENDING = 0x01,
		STATE_PROCESSING = 0x02,
		STATE_AGING = 0x04,
	};
	
	struct block freeBlock = { 0xFF };

	void selectData(struct descriptor *desc, struct block **selection)
	{
		uint8_t maxPriority = 0xFF;
		struct block *blk = desc->blocks;
		struct block **s = selection + desc->maxDataPerMsg;
		struct block stopBlock = { 0x00 };

		// the blocks in selection are in decreasing order
		*s = &stopBlock;
		do
			*(--s) = &freeBlock;
		while( s != selection );

		do
		{
			uint8_t priority = blk->priority;
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

	task void sendMsg()
	{
		struct block *selection[1 + FLOODROUTING_MAXDATA / 2];

		struct descriptor *desc = firstDesc;
		while( desc != 0 )
		{
			if( desc->dirty == DIRTY_SENDING )
			{
				selectData(desc, selection);
				copyData(desc, selection);

				if( txMsg.length > FLOODROUTING_HEADER )
				{
					if( call SendMsg.send(TOS_BCAST_ADDR, txMsg.length, &txMsg) != SUCCESS 
							&& ! post sendMsg() )
						state &= ~STATE_SENDING;
					
					call Leds.redToggle();
					return;
				}
			
				desc->dirty = DIRTY_AGING;
			}
			desc = desc->nextDesc;
		}

		state &= ~STATE_SENDING;
	}

	task void sendMsgDone()
	{
		FloodRoutingMsg *msg = (FloodRoutingMsg*)txMsg.data;
		struct descriptor *desc = getDescriptor(msg->appId);

		if( desc != 0 )
		{
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

	event result_t Timer.fired()
	{
		if( (state & STATE_AGING) == 0 && post age() )
			state |= STATE_AGING;

		return SUCCESS;
	}

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

#ifdef FLOODROUTING_DEBUG
		++dataLength;
#endif
		if( dataLength < 2
			|| dataLength > FLOODROUTING_MAXDATA
			|| uniqueLength > dataLength
			|| bufferLength <= sizeof(struct descriptor) + dataLength 
			|| getDescriptor(id)!=0 )
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
		call Timer.start2(TIMER_REPEAT, TIMER_JIFFY);	// one second timer
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		call Timer.stop();
		return SUCCESS;
	}
}
