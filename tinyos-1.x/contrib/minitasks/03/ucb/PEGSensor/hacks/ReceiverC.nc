/* Copyright (c) 2003, UC Berkeley, Intel Corp
 * Author: Fred Jiang, Kamin Whitehouse
 * Date last modified: 06/27/03
 */

includes Omnisound;

module ReceiverC {
	provides {
		interface StdControl;
		interface UltrasonicRangingReceiver;
	}
}

implementation {

	command result_t StdControl.init() {return SUCCESS;}
	command result_t StdControl.start() {return SUCCESS;}
	command result_t StdControl.stop() {return SUCCESS;}

	}
