// $Id: MicaDotStubM.nc,v 1.2 2003/10/07 21:45:38 idgay Exp $

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
includes Omnisound;

module MicaDotStubM {
	provides interface StdControl;
	uses interface StdControl as CommControl;
	uses interface SendMsg as Chirp;
	uses interface ReceiveMsg as ChirpReceive;
	uses interface SendMsg as TransmitMode;
	uses interface SendMsg as TimestampSend;
	uses interface ReceiveMsg as Timestamp;
	uses interface Leds;
//c	uses interface Clock;
	uses interface Timer;
	uses interface StdControl as SignalToAtmega8Control;
	uses interface SignalToAtmega8;
	uses interface RadioCoordinator as RadioSendCoordinator;
	uses interface RadioCoordinator as RadioReceiveCoordinator;
}

implementation {
	uint8_t debugState;
	
	uint8_t radioByteNumber;
	TOS_Msg m_msg[4];
	TransmitModeMsg* transmitMode;
	ChirpMsg* chirpMsg;
	ChirpMsg* chirpMsgReceive;
	TimestampMsg* timestampMsg;
	uint8_t mode;

	command result_t StdControl.init() {
		mode=RECEIVE;
		transmitMode=(TransmitModeMsg*)(m_msg[0].data);
		chirpMsg=(ChirpMsg*)(m_msg[1].data);
		chirpMsgReceive=(ChirpMsg*)(m_msg[3].data);
		timestampMsg=(TimestampMsg*)(m_msg[2].data);
		call SignalToAtmega8Control.init();
		call CommControl.init();
		return SUCCESS;
	}

	command result_t StdControl.start() {
		call CommControl.start();
		call Leds.redToggle();
//c		return call Clock.setRate(TOS_I1PS, TOS_S1PS);
		return call Timer.start(TIMER_REPEAT, 3000);
	}

	command result_t StdControl.stop() {
		call CommControl.stop();
//c		return call Clock.setRate(TOS_I0PS, TOS_S0PS);
		return call Timer.stop();
	}

	event TOS_MsgPtr ChirpReceive.receive(TOS_MsgPtr msg) {
		ChirpMsg* temp = (ChirpMsg*)(msg->data);
//		call Leds.redToggle();
		chirpMsgReceive->transmitterId = temp->transmitterId;
		// here we assume RadioReceiveCoordinator has been called.
		return msg;
	}
	
	task void TS_send() {
		call TimestampSend.send(TOS_BCAST_ADDR, LEN_TIMESTAMPMSG, &m_msg[2]);
	}
	
	event TOS_MsgPtr Timestamp.receive(TOS_MsgPtr msg){
		TimestampMsg* t = (TimestampMsg*)(msg->data);
//		call Leds.redOn(); 
		call Leds.redToggle();
		timestampMsg->timestamp=t->timestamp;
		timestampMsg->transmitterId=chirpMsgReceive->transmitterId; //pray...
//		post TS_send();
		call TimestampSend.send(TOS_BCAST_ADDR, LEN_TIMESTAMPMSG, &m_msg[2]);
		return msg;
	}

	
	task void clock_fire_task()
		{
			if(mode==TRANSMIT){
				transmitMode->mode=mode;
				call TransmitMode.send(TOS_UART_ADDR, LEN_TRANSMITMODEMSG, &m_msg[0]);
			}
//			call SignalToAtmega8.sendSignal(); // use for debugging. 
		}
	
//c	event result_t Clock.fire()
	event result_t Timer.fired()
	{
			post clock_fire_task();
			return SUCCESS;
		}
	
	event result_t Chirp.sendDone(TOS_MsgPtr m, result_t success)
		{
//zz	  call Leds.redOff(); // <- should be off !
			return SUCCESS;
		}
	
	event result_t TimestampSend.sendDone(TOS_MsgPtr m, result_t success)
		{
//zz	  call Leds.redOff();
			return SUCCESS;
		}
	
	task void transmitmode_senddone_task()
		{
			
//		  if(
//			  call Leds.redOn(); //uncomment
		}
	
	event result_t TransmitMode.sendDone(TOS_MsgPtr m, result_t success)
		{
//l			call Leds.redToggle();
//			post transmitmode_senddone_task();
			chirpMsg->transmitterId = TOS_LOCAL_ADDRESS;
			call Chirp.send(TOS_BCAST_ADDR, LEN_CHIRPMSG, &m_msg[1]);
			return SUCCESS;
		}
		
	event void RadioSendCoordinator.startSymbol() {
		if(mode==TRANSMIT){
			call SignalToAtmega8.sendSignal();
		}
	}
	
	event void RadioSendCoordinator.byte(){}
	event void RadioReceiveCoordinator.startSymbol() {
		if(mode==RECEIVE) {
			call SignalToAtmega8.sendSignal();
//l			call Leds.redToggle();
		}
	}
	event void RadioReceiveCoordinator.byte() { }   	
}








