/* Copyright (c) 2003, UC Berkeley, Intel Corp
 * Author: Fred Jiang
 * Date last modified: 06/27/03
 */

includes Omnisound;

module TransmitterAppM {
	provides interface StdControl;
	uses {
		interface UltrasonicRangingTransmitter as Transmitter;
                interface UltrasonicRangingReceiver;
	        interface SendMsg as ReportRangingEst;
		interface Timer;
		interface Leds;
	}
}

implementation {
	TOS_Msg buf;
	uint8_t sequenceNumber=0;
	bool RangingSchedule=FALSE;
	
	command result_t StdControl.init() {
		return SUCCESS;
	}

	command result_t StdControl.start() {
		return call Timer.start(TIMER_REPEAT, 512);
	}

	command result_t StdControl.stop() {
		return call Timer.stop();
	}
	
	task void timer_fire_task() {
		call Transmitter.send(TOS_LOCAL_ADDRESS,sequenceNumber, RangingSchedule);
		call Leds.redToggle();
	}
	
	event result_t Timer.fired() {
		post timer_fire_task();
		sequenceNumber++;
		return SUCCESS;
	}

	event void Transmitter.sendDone() {}

	// Place this here Temporarly
	event void UltrasonicRangingReceiver.receiveDone(uint16_t id, uint16_t rid, uint16_t dist){
	  EstReportMsg * tsMsg = (EstReportMsg *) (buf.data);
	  tsMsg->recvNode = TOS_LOCAL_ADDRESS;
	  tsMsg->transmitterId = id;
	  tsMsg->timestamp = dist;
	  call ReportRangingEst.send(TOS_BCAST_ADDR, LEN_ESTREPORTMSG, &buf);
	}

	event result_t UltrasonicRangingReceiver.receive(uint16_t id, uint16_t rangingId, uint16_t rangingSequenceNumber, bool initiateRangingSchedule) {
		return SUCCESS;
	}
	
	event result_t ReportRangingEst.sendDone(TOS_MsgPtr msg, result_t success){
	  return SUCCESS;
	}

}

