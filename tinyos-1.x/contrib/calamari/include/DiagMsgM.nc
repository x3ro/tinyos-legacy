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
 * Author: Miklos Maroti
 * Date last modified: 2/14/03
 */

includes DiagMsg;
includes cqueue;

module DiagMsgM
{
	provides 
	{
		interface DiagMsg;
		interface StdControl;
	}

	uses 
	{
		interface SendMsg;
		interface MsgBuffers;
	}
}

implementation
{
	enum
	{
		STATE_READY = 1,
		STATE_RECORDING_FIRST = 2,
		STATE_RECORDING_SECOND = 3,
		STATE_FULL = 4,
	};

	volatile uint8_t state;	// the state of the recording

	//TOS_Msg msgs[DIAGMSG_RECORDED_MSGS];	// circular buffer of messages
	TOS_MsgPtr msgs[DIAGMSG_RECORDED_MSGS];  // circular buffer of message pointers
	cqueue_t cq; // recording index is cq.back, sending is cq.front

	//TOS_MsgPtr recording;	// the message that is beeing or going to be recorded
	//TOS_MsgPtr sending;	// the message that is beeing sent, or the null pointer
	uint16_t sendToID;

	uint8_t nextData;	// points to the next unsued byte
	uint8_t prevType;	// points to the type descriptor
	uint8_t retries;	// number of remaining retries

	command result_t StdControl.init()
	{
		sendToID = DIAGMSG_BASE_STATION;
		state = STATE_READY;
		//recording = msgs;
		//sending = 0;
		call MsgBuffers.init();
		init_cqueue( &cq, DIAGMSG_RECORDED_MSGS );

		return SUCCESS;
	}

	command result_t StdControl.start() { return SUCCESS; }
	command result_t StdControl.stop() { return SUCCESS; }

	// two type fields are stored in on byte
	enum
	{
		TYPE_END = 0,
		TYPE_INT8 = 1,
		TYPE_UINT8 = 2,
		TYPE_HEX8 = 3,
		TYPE_INT16 = 4,
		TYPE_UINT16 = 5,
		TYPE_HEX16 = 6,
		TYPE_INT32 = 7,
		TYPE_UINT32 = 8,
		TYPE_HEX32 = 9,
		TYPE_FLOAT = 10,
		TYPE_CHAR = 11,
		TYPE_INT64 = 12,
		TYPE_UINT64 = 13,
		TYPE_TOKEN = 14,
		TYPE_ARRAY = 15,
	};

/*
	The format of the msg.data is as follows: 
	
	Each value has an associated data type descriptor. The descriptor takes 4-bits,
	and two descriptors are packed into one byte. The double-descriptor is followed
	by the data bytes needed to store the corresponding value. Two sample layouts are:

	[D2, D1] [V1] ... [V2] [V2] ... [V2]
	[D2, D1] [V1] ... [V1] [V2] ... [V2] [0, D3] [V3] ... [V3]

	where D1, D2, D3 denotes the data type descriptors, and V1, V2 and V3
	denotes the bytes where the corresponding values are stored. If there is an odd
	number of data descriptors, then a zero data descriptor <code>TYPE_END</code> 
	is inserted.

	Each data type (except arrays) uses a fixed number of bytes to store the value.
	For arrays, the first byte of the array holds the data type of the array (higer
	4 bits) and the length of the array (lower 4 bits). The actual data follows 
	this first byte.
*/

	command result_t DiagMsg.record()
	{
		TOS_MsgPtr msg;

		// currently recording or no more space
		if( state != STATE_READY || is_full_cqueue(&cq) || G_Config.diagMsgOn==0)
			return FAIL;

		msg = call MsgBuffers_alloc();
		if( msg == 0 )
		  return FAIL;

		push_back_cqueue( &cq );
		msgs[cq.back] = msg;

		// there is a slight race condition here
		state = STATE_RECORDING_FIRST;
		nextData = 0;

		return SUCCESS;
	}

	/**
	 * Allocates space in the message for <code>size</code> bytes
	 * and sets the type information to <code>type</code>. 
	 * Returns the index in <code>msg.data</code> where the data 
	 * should be stored or <code>-1</code> if no more space is avaliable.
	 */
	int8_t allocate(uint8_t size, uint8_t type)
	{
		int8_t ret = -1;

		if( state == STATE_RECORDING_FIRST )
		{
			if( nextData + 1 + size <= DATA_LENGTH )
			{
				state = STATE_RECORDING_SECOND;

				prevType = nextData++;
				msgs[cq.back]->data[prevType] = type;
				ret = nextData;
				nextData += size;
			}
			else
				state = STATE_FULL;
		}
		else if( state == STATE_RECORDING_SECOND )
		{
			if( nextData + size <= DATA_LENGTH )
			{
				state = STATE_RECORDING_FIRST;

				msgs[cq.back]->data[prevType] += (type << 4);
				ret = nextData;
				nextData += size;
			}
			else
				state = STATE_FULL;
		}

		return ret;
	}

#define IMPLEMENT(NAME, TYPE, TYPE2) \
	command void DiagMsg.NAME(TYPE value) \
	{ \
		int8_t start = allocate(sizeof(TYPE), TYPE2); \
		if( start >= 0 ) \
			*(TYPE*)&msgs[cq.back]->data[start] = value; \
	} \
	command void DiagMsg.NAME##s(TYPE *value, uint8_t len) \
	{ \
		int8_t start; \
		if( len > 15 ) len = 15; \
		start = allocate(sizeof(TYPE)*len + 1, TYPE_ARRAY); \
		if( start >= 0 ) \
		{ \
			msgs[cq.back]->data[start++] = (TYPE2 << 4) + len; \
			while( len-- != 0 ) \
				((TYPE*)&msgs[cq.back]->data[start])[len] = value[len]; \
		} \
	}

	IMPLEMENT(int8, int8_t, TYPE_INT8)
	IMPLEMENT(uint8, uint8_t, TYPE_UINT8)
	IMPLEMENT(hex8, uint8_t, TYPE_HEX8)
	IMPLEMENT(int16, int16_t, TYPE_INT16)
	IMPLEMENT(uint16, uint16_t, TYPE_UINT16)
	IMPLEMENT(hex16, uint16_t, TYPE_HEX16)
	IMPLEMENT(int32, int32_t, TYPE_INT32)
	IMPLEMENT(uint32, uint32_t, TYPE_UINT32)
	IMPLEMENT(hex32, uint32_t, TYPE_HEX32)
	IMPLEMENT(int64, int64_t, TYPE_INT64)
	IMPLEMENT(uint64, uint64_t, TYPE_UINT64)
	IMPLEMENT(real, float, TYPE_FLOAT)
	IMPLEMENT(chr, char, TYPE_CHAR)
	IMPLEMENT(token, uint8_t, TYPE_TOKEN)

	command void DiagMsg.boolean(bool value)
	{
		call DiagMsg.token(value ? DIAGMSG_TRUE : DIAGMSG_FALSE);
	}

	command void DiagMsg.str(char* str)
	{
		int8_t len = 0;
		while( str[len] != 0 && len < 15 )
			++len;
		
		call DiagMsg.chrs(str, len);
	}

	task void send()
	{
		if( call SendMsg.send(G_Config.debugAddr, msgs[cq.front]->length, msgs[cq.front]) != SUCCESS )
			post send();
	}

	command void DiagMsg.setBaseStation(uint16_t nodeID)
	{
		sendToID = nodeID;
	}

	command void DiagMsg.send()
	{
		// no message recorded
		if( state == STATE_READY )
			return;

		// store the length
		msgs[cq.back]->length = nextData;

		retries = DIAGMSG_RETRY_COUNT;
		post send();

		//recording = nextPointer(recording);
		state = STATE_READY;
	}

	event result_t SendMsg.sendDone(TOS_MsgPtr p, result_t success)
	{
		// retry if not successful
		if( (success != SUCCESS || !p->ack) && --retries > 0 )
			post send();
		else
		{
			call MsgBuffers.free( p );
			msgs[cq.front] = 0;
			pop_front_cqueue( &cq );

			if( is_empty_cqueue(&cq) != TRUE
			    && (cq.front != cq.back || state == STATE_READY) )
			{
				retries = DIAGMSG_RETRY_COUNT;
				post send();
			}
		}

		return SUCCESS;
	}
}
