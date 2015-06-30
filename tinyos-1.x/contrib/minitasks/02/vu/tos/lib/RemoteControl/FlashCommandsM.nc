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
 * Author: Andras Nadas, Miklos Maroti
 * Date last modified: 04/30/03
 */

module FlashCommandsM
{
	provides
	{
		interface IntCommand;
	}
	uses
	{
		interface SendBigMsg as FlashBigMsg;
		interface ClearFlash;
		interface FlashBackBigMsg;
		interface FlashBackBigMsg as FlashBackBigMsgUART;
		interface GlobalTime;
		interface Leds;
	}
}

implementation
{
	#define RETRY_COUNT 10
	uint8_t retryCount;

	task void read() {
		if(call FlashBackBigMsg.readMsg(0,0) != SUCCESS && --retryCount > 0)
			post read();
	}

	task void readUART() {
		call Leds.yellowToggle();
		if(call FlashBackBigMsgUART.readMsg(0,0) != SUCCESS && --retryCount > 0)
			post readUART();
	}

	event result_t FlashBackBigMsg.readDone(uint8_t *buffer, result_t success, 
		uint16_t msgLen, uint16_t origAddress, uint8_t origType, bool valid)
	{
		if(success == SUCCESS && valid == TRUE)
		{
			retryCount = RETRY_COUNT;
			post read();
		}

		return SUCCESS;
	}

	event result_t FlashBackBigMsgUART.readDone(uint8_t *buffer, result_t success, 
		uint16_t msgLen, uint16_t origAddress, uint8_t origType, bool valid)
	{
		if(success == SUCCESS && valid == TRUE)
		{
			retryCount = RETRY_COUNT;
			post readUART();
		}

		return SUCCESS;
	}

	task void clear() {
		if(call ClearFlash.clear() != SUCCESS && --retryCount > 0)
			post clear();
	}

	event void ClearFlash.clearDone(result_t success) {
		if(success != SUCCESS && --retryCount > 0)
			post clear();
	}

	#define BASE_STATION 1973

	struct
	{
		uint16_t nodeID;
		int16_t mark;
		uint32_t time;
	} data;

	uint16_t waterMark = 0;

	task void write() {

		data.nodeID = TOS_LOCAL_ADDRESS;
		data.mark = ++waterMark;
		call GlobalTime.getGlobalTime(&data.time);

		if(call FlashBigMsg.send(BASE_STATION, &data, &data + 1) != SUCCESS && --retryCount > 0)
			post write();
	}

	event void FlashBigMsg.sendDone(result_t success) {
		if(success != SUCCESS && --retryCount > 0)
			post write();
	}

	enum {
		COMMAND_CLEAR = 1,
		COMMAND_SETMARK = 2,
		COMMAND_SENDBACK = 3,
		COMMAND_SENDBACKUART = 4, 
	};

	command void IntCommand.execute(uint16_t commandID) {
		switch(commandID)
		{
		case COMMAND_CLEAR:
			retryCount = RETRY_COUNT;
			post clear();
			break;
		
		case COMMAND_SENDBACK:
			retryCount = RETRY_COUNT;
			if(call FlashBackBigMsg.reset() == SUCCESS)
				post read();
			break;

		case COMMAND_SENDBACKUART:
			retryCount = RETRY_COUNT;
			if(call FlashBackBigMsg.reset() == SUCCESS)
				post readUART();
			break;

		case COMMAND_SETMARK:
			retryCount = RETRY_COUNT;
			post write();
			break;
		}

		signal IntCommand.ack(SUCCESS);
	}
}
