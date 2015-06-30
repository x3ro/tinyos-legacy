// $Id: RSSIRangingReceiverM.nc,v 1.3 2004/04/21 07:04:17 ckarlof Exp $

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

module RSSIRangingReceiverM {
  provides {
    interface StdControl;
    interface RangingReceiver;
  }
  
  uses {		
    interface ReceiveMsg as ChirpReceive;
    interface TimedLeds as Leds;
    interface RadioCoordinator as RadioReceiveCoordinator;
    interface ADC as RSSIADC;
    interface DiagMsg;
  }
}

implementation {

  bool sampling = FALSE;
  uint32_t RSSISum = 0;
  uint8_t RSSICount = 0;
  
  command result_t StdControl.init() {
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  event TOS_MsgPtr ChirpReceive.receive(TOS_MsgPtr msg) {
    ChirpMsg* temp = (ChirpMsg*)(msg->data);
    uint16_t strength;

    atomic {
      sampling = FALSE;
      if(RSSICount != 0)
	strength = RSSISum/RSSICount;
      else
	strength = -1;
    }
    signal RangingReceiver.receive(temp->transmitterId,
				   temp->rangingId,
				   temp->batchNumber,
				   temp->sequenceNumber);
    signal RangingReceiver.receiveDone(temp->transmitterId,
				       temp->rangingId,
				       strength,
				       temp->initiateRangingSchedule);

/*    if( call DiagMsg.record() == SUCCESS ) {
      call DiagMsg.str("samples");
      call DiagMsg.uint16(temp->transmitterId);
      call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
      call DiagMsg.uint16(strength);
      call DiagMsg.uint16(RSSICount);
      call DiagMsg.uint16(RSSISum);
      call DiagMsg.send();
      }    
*/       
    return msg;
  }       
  
  async event void RadioReceiveCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff) {
    bool flag = FALSE;
    atomic {
      if(sampling)
	flag = TRUE;
      sampling = TRUE;
      RSSISum = 0;
      RSSICount = 0;
    }
    if(!flag)
      call RSSIADC.getData();
  }

  async event void RadioReceiveCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) {
    bool flag = FALSE;
    atomic {
      if(!sampling) {
	sampling = TRUE;
	flag = TRUE;
      }
    }
    if(flag)
      call RSSIADC.getData();
  }

  async event void RadioReceiveCoordinator.blockTimer() {

  }

  async event result_t RSSIADC.dataReady(uint16_t data) {
    atomic {
      if(sampling) {
	RSSISum += data;
	RSSICount++;
	sampling = FALSE;
      }
    }
    return SUCCESS;
  }

  
  
/*  	default event result_t RangingReceiver.receive(uint16_t id) { */
/*  		return SUCCESS; */
/*  	} */
	
/*  	default event void RangingReceiver.receiveDone(uint16_t id, uint16_t rangingId, */
/*  								 uint8_t sequenceNumber, */
/*  								 uint16_t dist) {}	 */
}








