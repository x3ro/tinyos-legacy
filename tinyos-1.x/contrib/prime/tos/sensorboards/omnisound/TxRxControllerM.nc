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
 * Date last modified:  3/21/2003
 *
 */

includes Omnisound;
includes sensorboard;

module TxRxControllerM {
  provides interface StdControl;
  provides interface TxRxMode;
  uses interface StdControl as CommControl;
  uses interface StdControl as USoundRxrControl;
  uses interface StdControl as USoundTxrControl;
  uses interface UltrasoundReceive;
  uses interface UltrasoundTransmit;
  uses interface ReceiveMsg as SetTxRxMode;
  uses interface SendMsg as TOF;
  uses interface ReceiveMsg as ResetMsg;
//  uses interface Clock;
}

implementation {
	uint8_t debugState;
	uint8_t txRxMode;
	uint8_t wdtCount;
	uint8_t send_pending;
	TransmitModeMsg* transmitModeMsg;
	TimestampMsg* timestampMsg;
	TOS_Msg m_msg;
	bool m_redOn;
	
	void redOn() { TOSH_CLR_RED_LED_PIN(); m_redOn=TRUE; }
	void redOff() { TOSH_SET_RED_LED_PIN(); m_redOn=FALSE; }
	void redToggle() {redOn(); TOSH_uwait(50000); redOff();}
	
	command result_t StdControl.init(){
		
	  redOff();
	  TOSH_MAKE_UART_TXD_OUTPUT();
	  TOSH_MAKE_UART_RXD_INPUT();
	  TOSH_MAKE_USOUND_SWITCH_OUTPUT(); // debugging only
  	  TOSH_MAKE_INT0_INPUT();
	  TOSH_MAKE_ULTRASOUND_RECV_PWR_OUTPUT();
	  timestampMsg = (TimestampMsg*)&(m_msg.data);
	  call USoundRxrControl.init();
	  call USoundTxrControl.init();
	  call CommControl.init();
//	  call Clock.setIntervalAndScale(0xff, 4);
	  call TxRxMode.setReceiveMode();
	  debugState=0;	  
	  return SUCCESS;
  }

  command result_t StdControl.start(){
	  call CommControl.start();
	  redToggle();
	  cbi(MCUCR, ISC01); //set int0 to be low-level triggered
	  sbi(GICR, INT0); // enable INT0
	  return SUCCESS;
  }
  
  command result_t StdControl.stop(){
	cbi(GICR, INT0); //disable interrupt 0
	call CommControl.stop();
    call USoundRxrControl.stop();
    call USoundTxrControl.stop();
	return SUCCESS;
  }


  command result_t TxRxMode.setTransmitMode() {	
	txRxMode=TRANSMIT;
    call USoundRxrControl.stop();
    call USoundTxrControl.start();
    return SUCCESS;
  }

  command result_t TxRxMode.setReceiveMode() {
	txRxMode=RECEIVE;
    call USoundRxrControl.start();
    call USoundTxrControl.stop();
    return SUCCESS;
  }
	  
  event TOS_MsgPtr SetTxRxMode.receive(TOS_MsgPtr msg){
	  transmitModeMsg = (TransmitModeMsg*)&(msg->data);
	  txRxMode = transmitModeMsg->mode;
	  //change the physical switch to enable one circuit or the other
	  if(txRxMode==TRANSMIT){
		  call TxRxMode.setTransmitMode(); //uncomment
		  redToggle();
	  }
	  else if(txRxMode==RECEIVE){
		  call TxRxMode.setReceiveMode();
	  }
	  return msg;
  }
  
  
  event result_t UltrasoundReceive.TimeOfFlight(uint16_t tof){
	  redToggle();
	  timestampMsg->transmitterId=0xffff;
	  timestampMsg->timestamp=tof;
	  send_pending = call TOF.send(TOS_BCAST_ADDR, LEN_TIMESTAMPMSG, &m_msg); //how does it broadcast!!
	  return SUCCESS;
  }	
  
  event result_t TOF.sendDone(TOS_MsgPtr msg, result_t suc){
	  send_pending = 0;
	  return SUCCESS;
  }

  TOSH_SIGNAL(SIG_INTERRUPT0) {
	  TOSH_interrupt_enable();
	  if(txRxMode==TRANSMIT){
		  call UltrasoundTransmit.sendUltrasoundPulse(500); // uncomment
		  call TxRxMode.setReceiveMode(); // comment out for transmit
	  }
	  else if(txRxMode==RECEIVE){ 
		  call UltrasoundReceive.startListening();
	  }  
  }

  event TOS_MsgPtr ResetMsg.receive(TOS_MsgPtr resetMsgPtr) {
	  if (*(uint16_t*)(resetMsgPtr -> data)==0xdead) {
		  while (1)
			  wdt_enable(1);
	  }
	  return resetMsgPtr;
  }
  
/*
  event result_t Clock.fire(){
	  if (wdtCount > 8 && send_pending == 0){
		  while(1){
			  wdt_enable(1);
		  }
	  }else{
		  wdtCount++;
	  }
	  return SUCCESS;
  }
*/
}












