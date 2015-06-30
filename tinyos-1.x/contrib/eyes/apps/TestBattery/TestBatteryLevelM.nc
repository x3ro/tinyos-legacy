/* -*- mode:c++ -*- 
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES {} LOSS OF USE, DATA,
 * OR PROFITS {} OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * Test Application to measure battery level in mV
 * - Author --------------------------------------------------------------
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * ========================================================================
 */

module TestBatteryLevelM {
    provides {
	interface StdControl;
    }
    uses {
	interface BatteryLevel;
	interface TimerMilli as WakeupTimer;
    }
}
implementation {
		
    #define MAX_VALUES 100
    #define TIME_INTERVAL 2000

    uint16_t level[MAX_VALUES]; 
    uint8_t counter; 

    /**************** Tasks ************************/
    task void rescheduleTask();
    task void getLevelTask();

    /**************** StdControl *******************/
    command result_t StdControl.init() {
	atomic counter = 0;
	return SUCCESS;
    }	
   
    command result_t StdControl.start() {
	return call WakeupTimer.setOneShot(TIME_INTERVAL);
	 
    }
   
    command result_t StdControl.stop() {
	return call WakeupTimer.stop();
    }

    /************** Tasks ***************************/
    task void rescheduleTask() {
	call WakeupTimer.setOneShot(TIME_INTERVAL);	
    }
    
    task void getLevelTask() {
	level[counter] = call BatteryLevel.getLevel();
	counter = (counter+1)%MAX_VALUES;
	post rescheduleTask();
    }

    /************** Timer ***************************/
    event result_t WakeupTimer.fired() {
	return post getLevelTask();
    }
}


