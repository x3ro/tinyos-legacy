/* Copyright (c) 2003, UC Berkeley, Intel Corp
 * Author: Fred Jiang
 * Date last modified: 06/27/03
 */

includes Omnisound;
includes ReceiverApp;

module ReceiverAppM {
	provides interface StdControl;
	uses {
		interface UltrasonicRangingReceiver as Receiver;
		interface Leds;
		interface SendMsg as TimestampSend;
	}
}

implementation {
	TOS_Msg m_msg;
	
	command result_t StdControl.init() {
		return SUCCESS;
	}

	command result_t StdControl.start() {
		return SUCCESS;
	}

	command result_t StdControl.stop() {
		return SUCCESS;
	}

	event void Receiver.receive(uint16_t transmitterId) {}
	
	event void Receiver.receiveDone(uint16_t transmitterId, uint16_t distance) {
		TimestampMsg* TS;
		TS = (TimestampMsg*)(m_msg.data);
		TS -> transmitterId = transmitterId;
		TS -> timestamp = distance;
		call TimestampSend.send(TOS_BCAST_ADDR, LEN_TIMESTAMPMSG, &m_msg);
	}

	event result_t TimestampSend.sendDone(TOS_MsgPtr m, result_t success) {
		return SUCCESS;
	}
}





