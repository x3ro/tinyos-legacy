/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/* Copyright (c) 2003, UC Berkeley, Intel Corp
 * Author: Fred Jiang, Kamin Whitehouse
 * Date last modified: 06/27/03
 */

module TransmitterAppM {
	provides interface StdControl;
	uses {
		interface ReceiveMsg as TransmitCommand;
		interface UltrasonicRangingTransmitter as Transmitter;
		interface Timer;
		interface TimedLeds as Leds;
	}
}

implementation {
	uint8_t sequenceNumber=0;
	bool RangingSchedule=FALSE;
	
	command result_t StdControl.init() {
		return SUCCESS;
	}

	command result_t StdControl.start() {
	        call Leds.redOn(200);
				return call Timer.start(TIMER_REPEAT, 2000);
	}

	command result_t StdControl.stop() {
		call Timer.stop();
	}
	
	task void timer_fire_task() {
		call Transmitter.send(TOS_LOCAL_ADDRESS,0,sequenceNumber, RangingSchedule); //the last 3 parameters are for localization, so don't worry about them
	}
	
	event result_t Timer.fired() {
		post timer_fire_task();
		sequenceNumber++;
		return SUCCESS;
	}

	event TOS_MsgPtr TransmitCommand.receive(TOS_MsgPtr msg) {
		call Transmitter.send(TOS_LOCAL_ADDRESS,0,1,RangingSchedule);
		return msg;
	}

	event void Transmitter.sendDone(result_t success) {
	  if(success==SUCCESS){
	    call Leds.redOn(50);
	  }
	}
}

