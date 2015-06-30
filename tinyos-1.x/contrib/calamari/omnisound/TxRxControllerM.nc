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
/*
 *
 * Authors:		Fred Jiang, Kamin Whitehouse
 * Revision:		$Id: TxRxControllerM.nc,v 1.8 2004/03/25 04:11:36 kaminw Exp $
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
  uses interface Timer;
  uses interface Leds;
  uses interface TimedLeds;
}

implementation {
	uint8_t debugState;
	uint8_t txRxMode;
	uint8_t wdtCount;
	uint8_t send_pending;
	TransmitModeMsg* transmitModeMsg;
	TimestampMsg* timestampMsg;
	TOS_Msg m_msg;
	
	
	command result_t StdControl.init(){
		
	  TOSH_MAKE_UART_TXD_INPUT();//disable UART PINS so it works with the Eperbs
	  TOSH_MAKE_UART_RXD_INPUT();//reenable if you want UART to work (should put this in UART component
	  TOSH_MAKE_PW5_INPUT();//
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
	  send_pending=0;
	  return SUCCESS;
  }

  command result_t StdControl.start(){
          call Leds.redOff();
	  call CommControl.start();
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

  //receives a uart message from the mica and sets the mode
  //accordingly.  the mica sends a uart message before transmitting a
  //chirp to put the atmega8 in transmit mode, but never really
  //explicitly puts the atmega8 in receive mode
  event TOS_MsgPtr SetTxRxMode.receive(TOS_MsgPtr msg){
	  transmitModeMsg = (TransmitModeMsg*)&(msg->data);
	  txRxMode = transmitModeMsg->mode;
	  //change the physical switch to enable one circuit or the other
	  if(txRxMode==TRANSMIT){
		  call TxRxMode.setTransmitMode(); //uncomment
		  call Leds.redOn();
	  }
	  else if(txRxMode==RECEIVE){
		  call TxRxMode.setReceiveMode();
		  call Leds.redOff();//should not be on anyway, but j.i.case
	  }
	  return msg;
  }
  

  //when the time of flight is received from the ultrasound detector,
  //a UART message is sent to the mica to indicate this
  event result_t UltrasoundReceive.TimeOfFlight(uint16_t tof){
          call Leds.redOn();
	  timestampMsg->transmitterId=0xffff;
	  timestampMsg->timestamp=tof;
	  if(send_pending==0){
	    send_pending = call TOF.send(TOS_I2C_BCAST_ADDR, LEN_TIMESTAMPMSG, &m_msg); 
	  }
    //	  call Timer.start(200, TIMER_ONE_SHOT);
	  return SUCCESS;
  }	
  

  event result_t Timer.fired(){
    if(send_pending==0){
      send_pending = call TOF.send(TOS_I2C_BCAST_ADDR, LEN_TIMESTAMPMSG, &m_msg); 
    }
    return SUCCESS;
  }

  event result_t TOF.sendDone(TOS_MsgPtr msg, result_t suc){
          if(suc==SUCCESS){
	    call Leds.redOff();
	  }
	  send_pending = 0;
	  return SUCCESS;
  }

  //this interrupt is triggered by an input pin, which is connected
  //to an output pin on the mica.  the mica pulls the line high
  //whenever a message is received (specifically after the 5th byte is
  //received, or something like that)
  TOSH_SIGNAL(SIG_INTERRUPT0) {
    __nesc_enable_interrupt();
	  if(txRxMode==TRANSMIT){
	    call Leds.redOff();
		  call UltrasoundTransmit.sendUltrasoundPulse(200); // uncomment
		  call TxRxMode.setReceiveMode(); // comment out for transmit
	  }
	  else if(txRxMode==RECEIVE){ 
	    //	          call Leds.redOn();
		  call UltrasoundReceive.startListening();
	  }  
  }

  //this function is here to allow the mica to reset the atmega8
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












