/* Copyright (c) 2003, UC Berkeley, Intel Corp
 * Author: Fred Jiang, Kamin Whitehouse
 * Date last modified: 06/27/03
 */

includes Omnisound;

module TransmitterC {
	provides {
		interface StdControl;
		interface UltrasonicRangingTransmitter;
	}
}

implementation {
	command result_t StdControl.init() {return SUCCESS;}
	command result_t StdControl.start() {return SUCCESS;}
	command result_t StdControl.stop() {return SUCCESS;}

	command result_t UltrasonicRangingTransmitter.send(uint16_t rangingId, uint8_t rangingSequenceNumber, bool initiateRangingSchedule) {return FAIL;}

}
