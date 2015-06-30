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
 * Author: Brano Kusy
 * Date last modified: 01/16/04
 */
module TimeSyncCommandsM{
	provides{
		interface IntCommand;
	}
	uses{
		interface SendMsg;
		interface ReceiveMsg;
		interface Timer;
		interface TimeStamping;
		interface Leds;
		interface GlobalTime;
		interface TimeSyncInfo;
		interface StdControl as TSControl;
	}
}

implementation{
	typedef struct TimeSyncCommandsPoll
	{
		uint16_t	senderAddr;
		uint16_t	msgID;
		uint8_t		type;
		uint32_t	sendingTime;
	}TimeSyncCommandsPoll;

	enum{
		TIMESYNCCMDPOLL_LEN = sizeof(TimeSyncCommandsPoll),
	};

	TOS_Msg msg; 	
	#define TimeSyncCmdPollMsg ((TimeSyncCommandsPoll *)(msg.data))

	command void IntCommand.execute(uint16_t param){
		
		if (param == 0 || param == 1){
			TimeSyncCmdPollMsg->senderAddr = TOS_LOCAL_ADDRESS;
			TimeSyncCmdPollMsg->msgID ++;
			TimeSyncCmdPollMsg->type = (uint8_t)param;
			call Timer.start(TIMER_ONE_SHOT,1000u);
		}
		else{
			uint16_t ret=0;

			if ( param == 2 ){
				ret = (uint16_t) call TimeSyncInfo.getRootID();
			}
			else if ( param == 3 ){
				ret = (uint16_t) call TimeSyncInfo.getSeqNum();
			}
			else if ( param == 4 ){
				ret = (uint16_t) call TimeSyncInfo.getNumEntries();
			}
			else if ( param == 5 ){
				ret = (uint16_t) call TimeSyncInfo.getHeartBeats();
			}
			signal IntCommand.ack( ret );
		}
	}
	
	event result_t Timer.fired(){
		uint32_t localTime, globalTime;
		globalTime = localTime = call GlobalTime.getLocalTime();
		call GlobalTime.local2Global(&globalTime);
		
		
		TimeSyncCmdPollMsg->sendingTime = globalTime - localTime;
		if (call SendMsg.send(TOS_BCAST_ADDR, TIMESYNCCMDPOLL_LEN, &msg) == SUCCESS)
			call TimeStamping.addStamp( offsetof(TimeSyncCommandsPoll,sendingTime) );

		return SUCCESS;
	}

	event result_t SendMsg.sendDone(TOS_MsgPtr p, result_t success){
		if (success == SUCCESS){ 
			int16_t ret=0;
			uint32_t sendTime = ((TimeSyncCommandsPoll *)(p->data))->sendingTime;
			uint8_t tmp = TimeSyncCmdPollMsg->type;
			if ( tmp == 0 )
				ret = 0;
			else if ( tmp == 1 )
				ret = (uint16_t)sendTime;
			else
				return SUCCESS;
			signal IntCommand.ack( ret );
		}

		return SUCCESS;
	}

	event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p)
	{
		uint32_t time = call TimeStamping.getStamp();
		uint32_t sendTime = ((TimeSyncCommandsPoll *)(p->data))->sendingTime;
		uint8_t tmp = ((TimeSyncCommandsPoll *)(p->data))-> type;

		int16_t ret;

		if ( tmp == 0 ){
			call GlobalTime.local2Global(&time);
//			if (time > sendTime)
//				ret = (uint16_t)(time - sendTime);
//			else 

			ret = (int16_t)(sendTime - time);
		}
		else if ( tmp == 1 ){
			call GlobalTime.local2Global(&time);
			ret = (uint16_t)(time);
		}
		else 
			return p;

		signal IntCommand.ack(ret);

		return p;
	}
}
