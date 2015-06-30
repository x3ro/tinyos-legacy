/*********************************************************
**	Author: 	Greg Moore - UCSB SensorNetProject
**
**	FileName:	FieldMoteM.nc
**
**	Purpose:	Allow user to test the bandwidth between 
**				two motes.  This is the remote mote.  It receives 
**				messages and counts the amount successfully received.
**				It computes the average signal strength and keeps
**				track of the good and bad packets.
**				When a BWDONE message is received, it sends the 
**				stored data back to the base mote for procesing.
**
**	Future:		Make sure this still works
**
*********************************************************/
includes BWMsg;

module FieldMoteM {
	provides interface StdControl;
	uses {
		interface StdControl as RadioControl;
		interface BareSendMsg as RadioSend;
		interface ReceiveMsg as RadioReceive;
		interface Leds;
	}
}
implementation {
	enum {
		BWTEST = 1,
		BWDONE = 2
	};
	
	TOS_Msg 	TxRxMsg;
	TOS_MsgPtr 	TxRxMsgPtr;
	uint16_t tCounter;
	uint16_t gCounter;
	uint32_t sigStrengthAvg;
	
	command result_t StdControl.init() {
		tCounter = 0;
		gCounter = 0;
		sigStrengthAvg = 0;
		
		TxRxMsg.length = 0;
		TxRxMsgPtr = &TxRxMsg;
		return rcombine(call RadioControl.init(), call Leds.init());
	}
	command result_t StdControl.start() {
		TxRxMsgPtr->length = sizeof(struct BWMsg);
		TxRxMsgPtr->addr = 1;
		TxRxMsgPtr->type = BWDONE;
		call RadioSend.send(TxRxMsgPtr);
		return call RadioControl.start();
	}
	command result_t StdControl.stop() {
		return call RadioControl.stop();
	}
	
	event result_t RadioSend.sendDone(TOS_MsgPtr Msg, result_t success) {
		call Leds.yellowToggle();
		Msg->length = 0;
		return SUCCESS;
	}

	task void RadioRcvdTask() {
		BWMsg *bwMsg;
		if((TxRxMsgPtr->addr == TOS_LOCAL_ADDRESS) || (TxRxMsgPtr->addr == 0)) {
			if(TxRxMsgPtr->type == BWTEST) {
				if(TxRxMsgPtr->crc) {
					tCounter += 1;
					gCounter += 1;
					sigStrengthAvg += TxRxMsgPtr->strength;			
					call Leds.greenToggle();				
				}else {
					tCounter += 1;
					call Leds.redToggle();
				}
			}else if(TxRxMsgPtr->type == BWDONE) {
				bwMsg = (struct BWMsg *)TxRxMsgPtr->data;
				bwMsg->endTotalCount = tCounter;
				bwMsg->endGoodCount = gCounter;
				bwMsg->sigStrength = (sigStrengthAvg / gCounter);
				TxRxMsgPtr->length = sizeof(struct BWMsg);
				TxRxMsgPtr->type = BWDONE;
				tCounter = 0;
				gCounter = 0;
				sigStrengthAvg = 0;
				if(call RadioSend.send(TxRxMsgPtr))
					call Leds.yellowToggle();
			
			}	
		}	
		
	}
	
	event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr Msg) {
		TxRxMsgPtr = Msg;
		post RadioRcvdTask();
		return Msg;
	}
}