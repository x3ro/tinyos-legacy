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
 * Date last modified:  3/22/2003
 *
 */

//includes sensorboard;

/*this component is the high level abstraction of the receiver.  The
TxRxController uses this component to power-on, power-off, enable and
disable the receiver.  This function controls the USoundDetector,
which in this case is a analog comparator but could be substituted by
a digital sampling algorithm, etc.  This file receives a UART message
from the mica2 which sets the pot setting for the analog comparator
and also receives the event from the analog comparator which indicates
the value of the timer 1 clock when the analog compator fired*/
module USoundRxrM {
  provides {
	  interface StdControl;
	  interface UltrasoundReceive;
  }
  uses {
	  interface USoundDetector;
	  interface ReceiveMsg as SetPotLevel;
	  interface Leds;
  }
}
implementation {
	uint8_t debugState;
	uint8_t state;
	//these are basically macros that define the pin names and set
	//them to be inputs or outputs
	command result_t StdControl.init() {
//these should be moved into PotM
		TOSH_MAKE_POT_SELECT_OUTPUT();
		TOSH_MAKE_INC_OUTPUT();
		TOSH_MAKE_UD_OUTPUT();
		TOSH_MAKE_5V_ENABLE_OUTPUT(); //needed for the switch
		TOSH_MAKE_USOUND_SWITCH_OUTPUT();
		TOSH_MAKE_ULTRASOUND_RECV_PWR_OUTPUT();
		cbi(TCCR1B, CS12); // set counter to match system
		cbi(TCCR1B, CS11); // set counter to match system
		sbi(TCCR1B, CS10); // set counter to match system
	//clock (max frequency); this is basically setting the clock
	//prescalar to 1
		
		debugState=0;
		state=NOT_RECEIVING;
		return call USoundDetector.setThreshold(23);
		//initialize the pot; this values seems to be good experimentally
		
	}
	
	//this basically turns off the 5v power supply that the
	//transmit circuit is using and flips the switch so that the
	//ultrasound transceiver is connected to the receiver circuit
	command result_t StdControl.start() {
		
		TOSH_CLR_5V_ENABLE_PIN(); //for switch power
		TOSH_CLR_USOUND_SWITCH_PIN();
		TOSH_SET_ULTRASOUND_RECV_PWR_PIN(); //enables the
		//voltage divider which is setting the virtual ground
		//for the receiver circuit
		return SUCCESS;
	}
	
	//this command disables the analog comparator interrupt
	command result_t StdControl.stop() {
//		TOSH_CLR_5V_ENABLE_PIN();
	        TOSH_CLR_ULTRASOUND_RECV_PWR_PIN(); //disable the virtual
					      //ground to save power
		return call UltrasoundReceive.stopListening();
	}

	//this sets the timer1 value to 0 (so that the time difference
	//can be read when the analog comparator goes off) and enables
	//the analog comparator interrupt.  It also enables the
	//overflow interrupt so we don't get noisy values
	command result_t UltrasoundReceive.startListening() {
		state=RECEIVING;
		outp(0, TCNT1H); // reset TIMER1
		outp(0, TCNT1L); // reset TIMER1
		sbi(TIMSK, TOIE1); //detect timer overflow
		return call USoundDetector.enable();
	}

	//this disables the analog comparator
	command result_t UltrasoundReceive.stopListening() {
	        cbi(TIMSK, TOIE1); //stop detecting timer overflow
		return call USoundDetector.disable();
	}

	//this handles the event from UsoundDetector, which fires when
	//the analog comparator is triggered and the timestamp in
	//timer 1 is read.  
	event result_t USoundDetector.detected(uint16_t timestamp) {
		if(state==RECEIVING){
			signal UltrasoundReceive.TimeOfFlight(timestamp);//(inp(TCNT1L));
			call UltrasoundReceive.stopListening();
			state=NOT_RECEIVING;
		}
//	  else{bug!}
		return SUCCESS;
	}

	//this receives a message from uart (allowing the mica2 to set
	//the pot, presumably according to some user command).
	event TOS_MsgPtr SetPotLevel.receive(TOS_MsgPtr msg) {
		SensitivityMsg* potLevel;
		potLevel = (SensitivityMsg*)(msg->data);
		call USoundDetector.setThreshold(potLevel->potLevel);
		return msg;
	}	

    //this interrupt is triggered when the Timer1 overflows, which
    //means that we have been listening for ultrasound for too long.
    //So, turn off ultrasound listening and turn off the overflow
    //interrupt.
  TOSH_SIGNAL(SIG_OVERFLOW1) {
    call UltrasoundReceive.stopListening();
    __nesc_enable_interrupt();
  }

}









