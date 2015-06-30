// $Id: TransmitterM.nc,v 1.2 2003/10/07 21:45:38 idgay Exp $

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

module TransmitterM {
	provides {
		interface StdControl;
		interface UltrasonicRangingTransmitter;
	}
	
	uses {
		interface SendMsg as Chirp;
		interface SendMsg as TransmitMode;
		interface StdControl as SignalToAtmega8Control;
		interface SignalToAtmega8;
		interface RadioCoordinator as RadioSendCoordinator;
	}
}

implementation {
	
	TOS_Msg m_msg;
	TransmitModeMsg* transmitMode;
	ChirpMsg* chirpMsg;
	uint8_t sendUltraSound=0, sequenceNumber=0, batchNumber=0;
	uint16_t sendingRangingId;
	bool initiateRangingSchedule=FALSE;
	
	command result_t StdControl.init() {
		transmitMode=(TransmitModeMsg*)(m_msg.data);
		chirpMsg=(ChirpMsg*)(m_msg.data);
		return call SignalToAtmega8Control.init();
	}

	command result_t StdControl.start() {
		return SUCCESS;
	}

	command result_t StdControl.stop() {
		return SUCCESS;
	}

	command result_t UltrasonicRangingTransmitter.send(uint16_t rangingId,
							   uint8_t rangingBatchNumber,
							   uint8_t rangingSequenceNumber,
							   bool initiateRangingSchedule_) {
		transmitMode->mode = TRANSMIT;
		sendingRangingId = rangingId;
		sequenceNumber = rangingSequenceNumber;
		batchNumber = rangingBatchNumber;
		initiateRangingSchedule = initiateRangingSchedule_;
		return call TransmitMode.send(TOS_UART_ADDR, LEN_TRANSMITMODEMSG, &m_msg);
	}
	
	event result_t TransmitMode.sendDone(TOS_MsgPtr m, result_t success) {
		chirpMsg->transmitterId = TOS_LOCAL_ADDRESS;
		chirpMsg->rangingId = sendingRangingId;
		chirpMsg->batchNumber = batchNumber;
		chirpMsg->sequenceNumber = sequenceNumber;
		chirpMsg->initiateRangingSchedule = initiateRangingSchedule;
		if (call Chirp.send(TOS_BCAST_ADDR, LEN_CHIRPMSG, &m_msg) == SUCCESS){
			sendUltraSound = 1;
		}else{
			signal UltrasonicRangingTransmitter.sendDone();
		}
		return SUCCESS;
	}
	
	event result_t Chirp.sendDone(TOS_MsgPtr m, result_t success) {
		return SUCCESS;
	}
	
	default event void UltrasonicRangingTransmitter.sendDone() {};
	
	
	async event void RadioSendCoordinator.startSymbol() {}
	
	async event void RadioSendCoordinator.byte( TOS_MsgPtr msg, uint8_t byteCount ){
		if (byteCount == 10)
			if (sendUltraSound == 1){
				sendUltraSound = 0;
				call SignalToAtmega8.sendSignal();
				signal UltrasonicRangingTransmitter.sendDone();
			}
	}
}








