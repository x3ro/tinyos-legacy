/*********************************************************
**	Author: 	Greg Moore - UCSB SensorNetProject
**
**	FileName:	SnoopM.nc
**
**	Purpose:	Snoop all radio messages and report them 
**				to the PC.
**				On the PC side you can listen for any type 
**				of message, but DelugeSnoop.java is setup
**				to check snoop all Deluge Messages to see 
**				how the Deluge app. communicates.
**
**	Future:		On the PC side you can listen for any type
**				of message.
**				Might want to try doing frequency shifting 
**				until some sort of useful radio packet is
**				sniffed.  Could be a great hacking tool.
**
*********************************************************/
module SnoopM {
	provides interface StdControl;
	uses {
		interface StdControl as UARTControl;
		interface BareSendMsg as UARTSend;
		interface ReceiveMsg as UARTReceive;
		interface TokenReceiveMsg as UARTTokenReceive;
		
		interface StdControl as RadioControl;
		interface ReceiveMsg as RadioReceive;
		interface BareSendMsg as RadioSend;
		interface Leds;
	}
}
implementation {
	enum {
		OK = 0,
		SENDING = 1
	};
	uint8_t Flags;
	command result_t StdControl.init() {
		result_t ok1, ok2, ok3;
		ok1 = call RadioControl.init();
		ok2 = call Leds.init();
		ok3 = call UARTControl.init();
		
		return rcombine3(ok1, ok2, ok3);
	}
	command result_t StdControl.start() {
		result_t ok1, ok2;
		ok1 = call RadioControl.start();
		ok2 = call UARTControl.start();
		
		return rcombine(ok1, ok2);
	}
	command result_t StdControl.stop() {
		return SUCCESS;
	}
	event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr pMsg) {
		if(pMsg->length == 28)
			call Leds.yellowToggle();
			
		if(Flags == SENDING) {
			call Leds.redToggle();
			return pMsg;
		} else if(Flags == OK) {
			atomic Flags = SENDING;
			if(call UARTSend.send(pMsg))
				call Leds.greenToggle();
			else 
				call Leds.redToggle();
		}
		return pMsg;
	}
	event result_t RadioSend.sendDone(TOS_MsgPtr pMsg, result_t success) {
		atomic Flags = OK;
		pMsg->length = 0;
		return SUCCESS;		
	}
	event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr pMsg) {
		return pMsg;
	}
	event TOS_MsgPtr UARTTokenReceive.receive(TOS_MsgPtr pMsg, uint8_t Token) {
		return pMsg;
	}
	event result_t UARTSend.sendDone(TOS_MsgPtr pMsg, result_t success) {
		atomic Flags = OK;
		pMsg->length = 0;
		return SUCCESS;
	}
}