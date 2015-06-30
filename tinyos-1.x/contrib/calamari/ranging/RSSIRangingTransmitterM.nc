// $Id: RSSIRangingTransmitterM.nc,v 1.3 2004/04/21 07:04:18 ckarlof Exp $

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

module RSSIRangingTransmitterM {
	provides {
		interface StdControl;
		interface RangingTransmitter;
	}
	
	uses {
		interface SendMsg as Chirp;
		interface TimedLeds as Leds;
		interface DiagMsg;
	}
}

implementation {
	
	TOS_Msg m_msg;
	ChirpMsg* chirpMsg;
	uint8_t state;

	enum { STATE_IDLE=0,
	       STATE_CHANGING_MODE=1,
	       STATE_CHIRPING=2
	};

	command result_t StdControl.init() {
		chirpMsg=(ChirpMsg*)(m_msg.data);
		state=STATE_IDLE;
		return SUCCESS;
	}

	command result_t StdControl.start() {
		return SUCCESS;
	}

	command result_t StdControl.stop() {
		return SUCCESS;
	}

	command result_t RangingTransmitter.cancel(){
	  state=STATE_IDLE;
	  return SUCCESS;
	}

	command result_t RangingTransmitter.send(uint16_t rangingId,
						 uint8_t rangingBatchNumber,
						 uint8_t rangingSequenceNumber,
						 bool initiateRangingSchedule) {
	  chirpMsg->transmitterId = TOS_LOCAL_ADDRESS;
	  chirpMsg->rangingId = rangingId;
	  chirpMsg->batchNumber = rangingBatchNumber;
	  chirpMsg->sequenceNumber = rangingSequenceNumber;
	  chirpMsg->initiateRangingSchedule = initiateRangingSchedule;
	  state=STATE_CHIRPING;
	  if( (call Chirp.send(0xFFFF, LEN_CHIRPMSG, &m_msg) == FAIL) && (VERBOSE>=2) && (call DiagMsg.record() == SUCCESS) ){
	    state=STATE_IDLE;
	    call DiagMsg.str("TxModeSendFail");
	    call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
	    call DiagMsg.send();
	  }
	  return SUCCESS;
	}
	
	event result_t Chirp.sendDone(TOS_MsgPtr m, result_t success) {
	  state=STATE_IDLE;
	  signal RangingTransmitter.sendDone(success);
	  if( (success==FAIL) && (VERBOSE>=2) && (call DiagMsg.record() == SUCCESS) ){
	    call DiagMsg.str("ChpSndDonFail");
	    call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
	    call DiagMsg.send();
	  }
	  else if(success==SUCCESS){
	    call Leds.redOn(200);
	  }
	  return SUCCESS;
	}
	
	default event void RangingTransmitter.sendDone(result_t success) {};
      	
}

