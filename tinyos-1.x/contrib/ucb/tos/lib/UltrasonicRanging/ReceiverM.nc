// $Id: ReceiverM.nc,v 1.2 2003/10/07 21:45:38 idgay Exp $

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

includes Omnisound;

module ReceiverM {
	provides {
		interface StdControl;
		interface UltrasonicRangingReceiver;
	}

	uses {		
		interface ReceiveMsg as ChirpReceive;
		interface ReceiveMsg as Timestamp;
		interface StdControl as SignalToAtmega8Control;
		interface SignalToAtmega8;
		interface RadioCoordinator as RadioReceiveCoordinator;
	}
}

implementation {
	uint16_t transmitterId, perform_ranging, receivedRangingId;
	uint16_t distance;

	command result_t StdControl.init() {
		transmitterId = 0;
		distance = 0;
		perform_ranging = FALSE;
		return call SignalToAtmega8Control.init();
	}

	command result_t StdControl.start() {
		return SUCCESS;
	}

	command result_t StdControl.stop() {
		return SUCCESS;
	}

	event TOS_MsgPtr ChirpReceive.receive(TOS_MsgPtr msg) {
		ChirpMsg* temp = (ChirpMsg*)(msg->data);
		transmitterId = temp->transmitterId;
		receivedRangingId = temp->rangingId;
		// here we assume RadioReceiveCoordinator has been called (at the right time).
		signal UltrasonicRangingReceiver.receive(transmitterId,
							 temp->rangingId,
							 temp->sequenceNumber,
							 temp->initiateRangingSchedule);
		return msg;
	}       

	event TOS_MsgPtr Timestamp.receive(TOS_MsgPtr msg){
		TimestampMsg* t = (TimestampMsg*)(msg->data);
		distance = t->timestamp;
//		distance = (distance+3200) / 33;
		if (perform_ranging == TRUE){
			signal UltrasonicRangingReceiver.receiveDone(transmitterId,
								     receivedRangingId,
								     distance);
			perform_ranging = FALSE;
		}
		return msg;
	}
	
	async event void RadioReceiveCoordinator.startSymbol() {
//		call SignalToAtmega8.sendSignal(); // may need revising
	}
	
	async event void RadioReceiveCoordinator.byte( TOS_MsgPtr msg, uint8_t byteCount ) {
		// Note: these bytes have not passed the CRC check.
		
		if( (byteCount == 4)
		    && (msg->group == TOS_AM_GROUP)
		    && (msg->type == AM_CHIRPMSG)
			)
			{
			        perform_ranging = TRUE;
				call SignalToAtmega8.sendSignal(); // may need revising
			}
		
	}
/*  	default event result_t UltrasonicRangingReceiver.receive(uint16_t id) { */
/*  		return SUCCESS; */
/*  	} */
	
/*  	default event void UltrasonicRangingReceiver.receiveDone(uint16_t id, uint16_t rangingId, */
/*  								 uint8_t sequenceNumber, */
/*  								 uint16_t dist) {}	 */
}








