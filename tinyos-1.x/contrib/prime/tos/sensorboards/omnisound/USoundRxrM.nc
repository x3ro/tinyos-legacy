/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:		Fred Jiang, Kamin Whitehouse
 * Date last modified:  3/22/2003
 *
 */

//includes sensorboard;


module USoundRxrM {
  provides {
	  interface StdControl;
	  interface UltrasoundReceive;
  }
  uses {
	  interface USoundDetector;
	  interface ReceiveMsg as SetPotLevel;
  }
}
implementation {
	uint8_t debugState;
	uint8_t state;
	
	bool m_redOn = FALSE;
	
	void redOn() { TOSH_CLR_RED_LED_PIN(); m_redOn=TRUE; }
	void redOff() { TOSH_SET_RED_LED_PIN(); m_redOn=FALSE; }
	void redToggle() {redOn(); TOSH_uwait(50000); redOff();}
	
	command result_t StdControl.init() {
//these should be moved into PotM
		TOSH_MAKE_POT_SELECT_OUTPUT();
		TOSH_MAKE_INC_OUTPUT();
		TOSH_MAKE_UD_OUTPUT();
		TOSH_MAKE_5V_ENABLE_OUTPUT(); //needed for the switch
		TOSH_MAKE_USOUND_SWITCH_OUTPUT();
		TOSH_MAKE_ULTRASOUND_RECV_PWR_OUTPUT();
		sbi(TCCR1B, CS10); // set counter to match system clock (max frequency)
		
		debugState=0;
		state=NOT_RECEIVING;
		return call USoundDetector.setThreshold(23);
//  TOSH_CLR_INC_PIN();!! what's this?
	}
	
	command result_t StdControl.start() {
		
		TOSH_CLR_5V_ENABLE_PIN(); //for switch power
		TOSH_CLR_USOUND_SWITCH_PIN();
		TOSH_SET_ULTRASOUND_RECV_PWR_PIN();
		return SUCCESS;
	}
	
	command result_t StdControl.stop() {
//		TOSH_CLR_5V_ENABLE_PIN();
		TOSH_CLR_ULTRASOUND_RECV_PWR_PIN();
		return call UltrasoundReceive.stopListening();
	}
	
	command result_t UltrasoundReceive.startListening() {
		state=RECEIVING;
		outp(0, TCNT1H); // reset TIMER1
		outp(0, TCNT1L); // reset TIMER1
		return call USoundDetector.enable();
	}
	
	command result_t UltrasoundReceive.stopListening() {
		return call USoundDetector.disable();
	}
	
	event result_t USoundDetector.detected(uint16_t timestamp) {
		if(state==RECEIVING){
			signal UltrasoundReceive.TimeOfFlight(timestamp);//(inp(TCNT1L));
			call UltrasoundReceive.stopListening();
			state=NOT_RECEIVING;
		}
//	  else{bug!}
		return SUCCESS;
	}

	event TOS_MsgPtr SetPotLevel.receive(TOS_MsgPtr msg) {
		SensitivityMsg* potLevel;
		potLevel = (SensitivityMsg*)(msg->data);
		call USoundDetector.setThreshold(potLevel->potLevel);
		return msg;
	}	
}









