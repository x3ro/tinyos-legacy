/*
 * Copyright (c) 2002, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
*/
/*									tab:4
 * Authors:  Peter Volgyesi, Gabor Pap
 * Date last modified:     03/17/2003
 *
 * The application tries to turn on (full power) all subsystems,
 * and samples the battery voltage regularly (with the help of the ADC)
 * When a sampled data is ready, the app sends it out to the UART.
 * In the idle state it tries to make the MCU working.
 *
 * The RED LED is on while the application is running
 * The GREEN LED is toggled when the application sends out a sample
 *
 * TODO: Turn on all sub-components (drain battery)
 *
 */

includes VoltageAppMsg;

module VoltageAppM{
	provides interface StdControl;
	uses{
		interface Leds;
		interface Timer;
		interface ADC as Voltage;
		interface StdControl as BatteryControl;
	    interface StdControl as UARTControl;
    	interface BareSendMsg as UARTSend;
		interface ReceiveMsg as UARTReceive;
	}
}

implementation{
	TOS_Msg msg;
	TOS_MsgPtr msgPtr;
	uint8_t pending;

	task void workerThread(){
		int i = 0;
		while (1) {
			i = (i + 1) ^ i;
		}
	}

	command result_t StdControl.init(){
		result_t ok1, ok2, ok3;

		msgPtr = &msg;
		msgPtr->addr = TOS_UART_ADDR;
		pending = 0;

		ok1 = call Leds.init();
		ok2 = call UARTControl.init();
		ok3 = call BatteryControl.init();

    	return rcombine3(ok1, ok2, ok3);
	}

	command result_t StdControl.start(){
		result_t ok1, ok2, ok3;

		call Leds.redOn();
		ok1 = call Timer.start(TIMER_REPEAT,SAMPLERATE);
		ok2 = call UARTControl.start();
        ok3 = call BatteryControl.start();
        
		post workerThread();

		return rcombine3(ok1, ok2, ok3);
	}

	command result_t StdControl.stop(){
	    result_t ok1, ok2, ok3;

	    ok1 = call Timer.stop();
	    ok2 = call UARTControl.stop();
	    ok3 = call BatteryControl.stop();

	    return rcombine3(ok1, ok2, ok3);
	}

	event result_t Timer.fired(){
		if (!pending) {
			pending = 1;
			call Voltage.getData();
		}
		return SUCCESS;
	}

	result_t sendDone(TOS_MsgPtr sent, result_t success) {
		if(msgPtr == sent){
			//Battery send buffer free
			if (success == FAIL){
				call Leds.yellowToggle();
			}
			pending = 0;
		}
		return SUCCESS;
	}

	event result_t UARTSend.sendDone(TOS_MsgPtr message, result_t success) {
		return sendDone(message, success);
	}

	event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr data) {
		return data;
	}

	event result_t Voltage.dataReady(uint16_t data){
		VoltageAppMsg* pack = (VoltageAppMsg*) (msg).data;
		pack->batterySample = data;
		call UARTSend.send(msgPtr);
		call Leds.greenToggle();
		
		return SUCCESS;
	}
}
