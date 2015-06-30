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
 * Date last modified: 2/18/03
 */

includes AM;
includes BigMsg;

module SendBigMsgM
{
	provides
	{
		interface SendBigMsg[uint8_t id];
		interface StdControl;
	}

	uses
	{
		interface SendMsg[uint8_t id];
	}
}

implementation
{
	// the segments of the current message
	void* starts[4];
	void* ends[4];

	uint8_t segmentCount;		// the total number of segments, 0 if stopped
	uint8_t segment;		// the current segment in the range [0, segmentCount]
	int8_t* head;			// the next byte that goes into the next message
	TOS_Msg msg;			// we store the address, length and seqNum here
	uint8_t retryCount;		// the number of remaining retries for failed acks
	uint16_t totalLength;		// the total length of the message

#define	msgAddress	msg.addr
#define msgLength	msg.length
#define msgSource	(((BigMsg*)msg.data)->source)
#define msgSeqNum	(((BigMsg*)msg.data)->seqNum)
#define msgId		msg.type	// the (AM) id of the currently running send

	command result_t StdControl.init()
	{
		segmentCount = 0;
		msgSource = TOS_LOCAL_ADDRESS;

		return SUCCESS;
	}

	command result_t StdControl.start() { return SUCCESS; }
	command result_t StdControl.stop() { return SUCCESS; }

	// retry sending the message untill the radio stack accepts it for sending
	task void sendMsg()
	{
		if( call SendMsg.send[msgId](msgAddress, msgLength, &msg) != SUCCESS )
			post sendMsg();
	}

	// fill up a new message
	task void fillMsg()
	{
		int8_t *data;
		int8_t *end;
		uint8_t room;

		// the space for new data
		data = ((BigMsg*)msg.data)->data;
		room = BIGMSG_DATA_LENGTH;

		// the end of the current segment;
		end = ends[segment];

		// copy the data
		do
		{
			--room;
			*(data++) = *(head++);

			// if end of this segment, go to the next
			if( head >= end )
			{
				// no more segments
				if( ++segment >= segmentCount )
					break;
				
				head = starts[segment];
				end = ends[segment];
			}
		} while( room > 0 );

		// increase the sequence number
		msgSeqNum += 1;

		// the length of the message including the sequence number
		msgLength = BIGMSG_HEADER_LENGTH + BIGMSG_DATA_LENGTH - room;

		// reset the retry counter and send the message
		retryCount = BIGMSG_RETRY_COUNT;
		post sendMsg();
	}

	event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr p, result_t success)
	{
		// if this is our message
		if( id == msgId && p == &msg )
		{
#ifdef PLATFORM_MICA2
			msg.ack = retryCount == 1;
#endif
			if( success == SUCCESS && msg.ack )
			{
				// if there is still more data, send the next packet
				if( segment < segmentCount )
					post fillMsg();
				else
				{
					// we are done
					segmentCount = 0;
					signal SendBigMsg.sendDone[id](SUCCESS);
				}
			}
			else
			{
				// retry the last message
				if( --retryCount > 0 )
					post sendMsg();
				else
				{
					// we are done
					segmentCount = 0;
					signal SendBigMsg.sendDone[id](FAIL);
				}
			}
		}

		return SUCCESS;
	}

	void addSegment(void *start, void *end)
	{
		if( start != 0 && end != 0 && start < end )
		{
			starts[segmentCount] = start;
			ends[segmentCount] = end;

			totalLength += end - start;
			segmentCount++;
		}
	}

	command result_t SendBigMsg.send3[uint8_t id](uint16_t address, 
		void *start1, void *end1,
		void *start2, void *end2,
		void *start3, void *end3)
	{
		// if the component is busy
		if( segmentCount != 0 )
			return FAIL;

		// do not include the length
		totalLength = -sizeof(totalLength);
		addSegment(&totalLength, &totalLength + 1);
		addSegment(start1, end1);
		addSegment(start2, end2);
		addSegment(start3, end3);

		// empty message
		if( segmentCount == 0 )
			return FAIL;

		// initialize all variables
		segment = 0;
		msgId = id;
		head = starts[0];
		msgAddress = address;

		// init the sequence number, it will be incremented to 0
		msgSeqNum = -1;

		post fillMsg();

		return SUCCESS;
	}

	command result_t SendBigMsg.send[uint8_t id](uint16_t address, 
		void *start1, void *end1)
	{
		return call SendBigMsg.send3[id](address,
			start1, end1, 0, 0, 0, 0);
	}

	command result_t SendBigMsg.send2[uint8_t id](uint16_t address, 
		void *start1, void *end1, void *start2, void *end2)
	{
		return call SendBigMsg.send3[id](address,
			start1, end1, start2, end2, 0, 0);
	}

	default event void SendBigMsg.sendDone[uint8_t id](result_t success)
	{
	}
}
