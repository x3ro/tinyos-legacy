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
		call Transmitter.send(0,0,FALSE);
		call Leds.redToggle();
	}
	
	event result_t Timer.fired() {
		post timer_fire_task();
		return SUCCESS;
	}

	event void Transmitter.sendDone() {}
	/* Transmitter code end */


	/* Receiver code start */



	event result_t Receiver.receive(uint16_t id, uint16_t rangingId,
									uint16_t rangingSequenceNumber,
									bool initiateRangingSchedule) {
		return SUCCESS;
	}
	
	event void Receiver.receiveDone(uint16_t transmitterId,
									uint16_t receivedRangingId,
									uint16_t distance) {
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


	
