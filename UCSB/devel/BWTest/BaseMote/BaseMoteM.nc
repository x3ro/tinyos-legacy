/*********************************************************
**	Author: 	Greg Moore - UCSB SensorNetProject
**
**	FileName:	BaseMote.nc
**
**	Purpose:	Allow user to test the bandwidth between 
**				two motes.  The bandwidth test tests how much time 
**				it takes to transfer a set amount of data 
**				between two motes.
**				The data is then passed to the PC after the 
**				test has been completed.
**
**	Future:		Make sure this still works
**
*********************************************************/
includes BWMsg;

module BaseMoteM {
	provides interface StdControl;
	uses {
		interface StdControl as UARTControl;
		interface BareSendMsg as UARTSend;
		interface ReceiveMsg as UARTReceive;
		interface TokenReceiveMsg as UARTTokenReceive;
		
		interface StdControl as RadioControl;
		interface BareSendMsg as RadioSend;
		interface ReceiveMsg as RadioReceive;
		interface SysTime;
		interface Timer;
		interface Leds;
	}
}
implementation {
	enum {
		QUEUE_SIZE = 5,
	};

	enum {
		BW_START = 0,
		BW_BUSY = 1,
		BW_DONE = 2,
		BW_OPEN = 3
	};
	enum {
		BWTEST = 1,
		BWDONE = 2
	};
	
	
	
	TOS_Msg RxMsgBuf[QUEUE_SIZE];
	TOS_MsgPtr RxMsgBufTbl[QUEUE_SIZE];
	uint8_t RxHeadIndex, RxTailIndex;
	
	TOS_Msg TxMsg;
	TOS_MsgPtr TxMsgPtr;
	uint8_t uartTxPendingToken;
	uint8_t BWFlags;
	
	uint32_t startTime;
	uint32_t endTime;
	uint16_t nsamples;
	uint8_t destAddr;
	uint8_t expID;
	uint16_t receivedTPackets;
	uint16_t receivedGPackets;
	uint32_t sigStrength;
	
	task void SendAckTask() {
		call UARTTokenReceive.ReflectToken(uartTxPendingToken);
		atomic {
			TxMsgPtr->length = 0;
			//TxFlags = 0;
		}
	}
	
	task void UARTRcvdTask() {
		BWMsg *bwMsg;
		bwMsg = (struct BWMsg *)TxMsgPtr->data;
		if(TxMsgPtr->type == AM_BWMSG) {
			expID = bwMsg->expId;
			atomic destAddr = bwMsg->destAddr;
			
			// This is where I start the test
			TxMsgPtr->addr = destAddr;
			TxMsgPtr->type = BWTEST;
			TxMsgPtr->length = sizeof(struct BWMsg);
			if(BWFlags == BW_START) {
				atomic BWFlags = BW_BUSY;
				nsamples = bwMsg->startCount;
				atomic startTime = call SysTime.getTime32();
			}			
			if(call RadioSend.send(TxMsgPtr))
				call Leds.greenToggle();
			
		}
	}
	task void BWDone() {
		call Timer.start(TIMER_REPEAT, 1000);
		// Start the timer to retreive the count from the fieldMote
	}
	
	event result_t RadioSend.sendDone(TOS_MsgPtr Msg, result_t success) {
		//call Leds.yellowToggle();
		if(nsamples-- > 1) 
			post UARTRcvdTask();
		else {
			atomic endTime = call SysTime.getTime32();
			atomic BWFlags = BW_BUSY;
			post BWDone();
		}
			
		Msg->length = 0;
		return SUCCESS;
	}
	
	event result_t Timer.fired() {
		BWMsg * bwMsg;
		bwMsg = (struct BWMsg *)TxMsgPtr->data;
		TxMsgPtr->length = sizeof(struct BWMsg);
		
		if(BWFlags == BW_BUSY) {
			call Leds.redToggle();
			TxMsgPtr->addr = destAddr;
			TxMsgPtr->type = BWDONE;
			call RadioSend.send(TxMsgPtr);
		}else if(BWFlags == BW_DONE) {
			TxMsgPtr->addr = TOS_BCAST_ADDR;
			TxMsgPtr->type = AM_BWMSG;
			bwMsg->endGoodCount = receivedGPackets;
			bwMsg->endTotalCount = receivedTPackets;
			bwMsg->sigStrength = sigStrength;
			bwMsg->sendTime = startTime;
			bwMsg->receiveTime = endTime;
			
			if(call UARTSend.send(TxMsgPtr))
				call Leds.greenToggle();
		}
		return SUCCESS;
	}
		
	task void RadioRcvdTask() {
		BWMsg * bwMsg;
		bwMsg = (struct BWMsg *)TxMsgPtr->data;
		if(TxMsgPtr->type == BWDONE) {
			atomic BWFlags = BW_DONE;
			receivedTPackets = bwMsg->endTotalCount;
			receivedGPackets = bwMsg->endGoodCount;
			sigStrength = bwMsg->sigStrength;
			
			call Timer.stop();
			call Leds.yellowToggle();
			call Timer.start(TIMER_REPEAT, 1000);
		}
	}
	
	event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr Msg) {
		TOS_MsgPtr pBuf;
		call Leds.yellowToggle();
		dbg(DBG_USR1, "Received Radio Message\n");
		if(Msg->crc) {
			atomic {
				TxMsgPtr = Msg;
			}
			post RadioRcvdTask();
		}
		else {
			pBuf = Msg;
		}
		return pBuf;
	}
	
	command result_t StdControl.init() {
		result_t ok1, ok2, ok3;
		uint8_t i;
		for(i = 0; i < QUEUE_SIZE; i++) {
			RxMsgBuf[i].length = 0;
			RxMsgBufTbl[i] = &RxMsgBuf[i];
		}
		RxHeadIndex = 0;
		RxTailIndex = 0;
		
		TxMsg.length = 0;
		TxMsgPtr = &TxMsg;
		
		BWFlags = BW_OPEN;
				
		ok1 = call UARTControl.init();
		ok2 = call RadioControl.init();
		ok3 = call Leds.init();

		dbg(DBG_USR1, "Done initing working functions\n");
		return rcombine3(ok1, ok2, ok3);
	}
	command result_t StdControl.start() {
		result_t ok1, ok2;
		ok1 = call UARTControl.start();
		ok2 = call RadioControl.start();
		return rcombine(ok1, ok2);
	}
	command result_t StdControl.stop() {
		result_t ok1, ok2;
		ok1 = call UARTControl.stop();
		ok2 = call RadioControl.stop();
		return rcombine(ok1, ok2);
	}

	
	event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr Msg) {
		TOS_MsgPtr pBuf;
		atomic {
			if(BWFlags == BW_OPEN) {
				pBuf = TxMsgPtr;
				BWFlags = BW_START;
				TxMsgPtr = Msg;
			}else {
				pBuf = NULL;				
			}
		}
		if(pBuf == NULL) {
			pBuf = Msg;
		}else {
			post UARTRcvdTask();
		}
		return pBuf;
	}
	
	event TOS_MsgPtr UARTTokenReceive.receive(TOS_MsgPtr Msg, uint8_t Token) {
		TOS_MsgPtr pBuf;
		dbg(DBG_USR1, "BaseMote received UART token packet\n");
		atomic {
			if(BWFlags == BW_OPEN) {
				pBuf = TxMsgPtr;
				BWFlags = BW_START;
				TxMsgPtr = Msg;
				uartTxPendingToken = Token;
			}else {
				pBuf = NULL;
			}
		}
		if(pBuf == NULL) {
			pBuf = Msg;
		}else {
			post UARTRcvdTask();
		}
		return pBuf;
	}
	
	event result_t UARTSend.sendDone(TOS_MsgPtr Msg, result_t success) {
		Msg->length = 0;
		call Timer.stop();
		atomic BWFlags = BW_OPEN;
		return SUCCESS;		
	}
	
}