/* Copyright (c) 2003, UC Berkeley, Intel Corp
 * Author: Fred Jiang
 * Date last modified: 06/30/03
 */

includes Omnisound;

module TransceiverAppM {
	provides interface StdControl;
	uses {
		interface StdControl as TransmitterControl;
		interface UltrasonicRangingTransmitter as Transmitter;
		interface StdControl as ReceiverControl;
		interface UltrasonicRangingReceiver as Receiver;
		interface Timer;
		interface Leds;
		interface ReceiveMsg as PulseMsg;
		interface SendMsg as TimestampSend;
	}
}

implementation {
	enum{
		START=169,
		STOP=170
		};
	
	TOS_Msg m_msg;

	typedef struct
	{
		uint8_t action;
	} Action;
	
	command result_t StdControl.init() {
		call TransmitterControl.init();
		call ReceiverControl.init();
		return SUCCESS;
	}
	
	command result_t StdControl.start() {
		return call ReceiverControl.start();
	}
	
	command result_t StdControl.stop() {
		call Timer.stop();
		call TransmitterControl.stop();
		call ReceiverControl.stop();
	}

	event TOS_MsgPtr PulseMsg.receive(TOS_MsgPtr msg) {
		Action* t = (Action*)(msg->data);
		if (t->action == START) {
			call Leds.redToggle();
			call ReceiverControl.stop();
			call TransmitterControl.start();
			call Timer.start(TIMER_REPEAT, 1000);
		}
		else if (t->action == STOP) {
			call Timer.stop();
			call TransmitterControl.stop();
			call ReceiverControl.start();
		}
		return msg;
	}
	
	/* Transmitter code start */
	task void timer_fire_task() {
		call Transmitter.send();
		call Leds.redToggle();
	}
	
	event result_t Timer.fired() {
		post timer_fire_task();
		return SUCCESS;
	}

	event void Transmitter.sendDone() {}
	/* Transmitter code end */


	/* Receiver code start */
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
	/* Receiver code end */
}


	
