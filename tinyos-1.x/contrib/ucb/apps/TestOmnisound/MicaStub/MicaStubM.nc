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

module MicaStubM {
	provides interface StdControl;
	uses interface StdControl as CommControl;
	uses interface SendMsg as Chirp;
	uses interface SendMsg as TransmitMode;
	uses interface SendMsg as TimestampSend;
	uses interface ReceiveMsg as Timestamp;
	uses interface Leds;
	uses interface Clock;
//	uses interface HPLUART as UART;
	uses interface StdControl as SignalToAtmega8Control;
	uses interface SignalToAtmega8;
	uses interface RadioCoordinator as RadioSendCoordinator;
	uses interface RadioCoordinator as RadioReceiveCoordinator;

}

implementation {
	uint8_t debugState;
	
	uint8_t radioByteNumber;
	TOS_Msg m_msg[3];
	TransmitModeMsg* transmitMode;
	ChirpMsg* chirpMsg;
	TimestampMsg* timestampMsg;
	uint8_t mode;

	command result_t StdControl.init() {
		mode=TRANSMIT;
		transmitMode=(TransmitModeMsg*)&(m_msg[0].data);
		chirpMsg=(ChirpMsg*)&(m_msg[1].data);
		timestampMsg=(TimestampMsg*)&(m_msg[2].data);
		call SignalToAtmega8Control.init();
		call CommControl.init();
		return SUCCESS;
	}

	command result_t StdControl.start() {
		call CommControl.start();
		return call Clock.setRate(TOS_I2PS, TOS_S2PS);
	}

	command result_t StdControl.stop() {
		call CommControl.stop();
		return call Clock.setRate(TOS_I0PS, TOS_S0PS);
	}
	
	event TOS_MsgPtr Timestamp.receive(TOS_MsgPtr msg){
		TimestampMsg* t=(TimestampMsg*)(&(msg->data));
		call Leds.greenToggle();
		timestampMsg->timestamp=t->timestamp;
		if(call TimestampSend.send(TOS_BCAST_ADDR, LEN_TIMESTAMPMSG, &m_msg[2]))
			 call Leds.redOn();
		return msg;
	}

	task void clock_fire_task()
		{
			call Leds.yellowToggle();
//		call UART.put(0x55);
			if(mode==TRANSMIT){
				transmitMode->mode=mode;
				call TransmitMode.send(TOS_UART_ADDR, LEN_TRANSMITMODEMSG, &m_msg[0]);
//		  call SignalToAtmega8.sendSignal();
			}
		}
	
	event result_t Clock.fire()
	  {
		post clock_fire_task();
	    return SUCCESS;
	  }

  event result_t Chirp.sendDone(TOS_MsgPtr m, result_t success)
  {
    call Leds.redOff();
    return SUCCESS;
  }

  event result_t TimestampSend.sendDone(TOS_MsgPtr m, result_t success)
  {
    call Leds.redOff();
    return SUCCESS;
  }

  task void transmitmode_senddone_task()
	  {
		  chirpMsg->transmitterId = TOS_LOCAL_ADDRESS;
		  if(call Chirp.send(TOS_BCAST_ADDR, LEN_CHIRPMSG, &m_msg[1]) == SUCCESS)
			  call Leds.redOn();
	  }
  
  event result_t TransmitMode.sendDone(TOS_MsgPtr m, result_t success)
  {
	  post transmitmode_senddone_task();
    return SUCCESS;
  }

  event void RadioSendCoordinator.startSymbol()
  {
	  radioByteNumber=0;
  }

  event void RadioSendCoordinator.byte()
  {
	  if(radioByteNumber==5){
		  if(mode==TRANSMIT){
			  call SignalToAtmega8.sendSignal();
 		      radioByteNumber++;
		  }
	  }
	  else if(radioByteNumber<5){
		  radioByteNumber++;
	  }
  }

  event void RadioReceiveCoordinator.startSymbol()
  {
    if(mode==RECEIVE){
       call SignalToAtmega8.sendSignal();
    }
  }

  event void RadioReceiveCoordinator.byte()
  {
	}

/*  event result_t UART.get(uint8_t data){
//	  call Leds.redToggle();
//	  if(data==0x55){
		  if(debugState==0){
			  call Leds.greenToggle();
			  debugState=1;
		  }else{
			  call Leds.greenToggle();
			  debugState=0;
		  }
//	  }
	  return SUCCESS;
  }

  event result_t UART.putDone() {
     call SignalToAtmega8.sendSignal();
     return SUCCESS;
	 }*/


}



