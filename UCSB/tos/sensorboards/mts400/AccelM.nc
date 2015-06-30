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
 * Authors:	Crossbow
 *
 */

includes sensorboard;
module AccelM {
  provides  {
   interface StdControl;
   interface I2CSwitchCmds as AccelCmd;
 
  }
  uses {
    interface ADCControl;
	interface Timer;
	interface StdControl as SwitchControl;
    interface Switch as Switch1;

  }
}
implementation {

#include "SODebug.h"
#define DBG_USR2  0  
 
 enum {ACCEL_SWITCH_IDLE,                      //I2C switches are not using the I2C bus 
       ACCEL_PWR_SWITCH_WAIT,                  //Couldn't get GPS I2C bus
       ACCEL_PWR_SWITCH,                       //Got I2C bus, power turning on
	   BUSY,  
       POWEROFF,
       TIMER};
 
  uint8_t state_accel;
  uint8_t power_accel;

  command result_t StdControl.init() {
	state_accel = ACCEL_SWITCH_IDLE; 
    power_accel = 0;
//	SODbg(DBG_USR2, "ACCEL initialized.\n");
    call SwitchControl.init();
    return call ADCControl.init();
  }

  command result_t StdControl.start() {
    call SwitchControl.start();
//    SODbg(DBG_USR2, "AccelM: I2C switch init \n");
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

/******************************************************************************
 * Turn Accel power  on/off
 * PowerState = 0 then accel power off, 
 *            = 1 then accel power on
 * ADXL202E has turn on time of 160*Cflt+0.3 ms
 *         Cflt = 0.1 uF
 *         Turn on time = ~16 msec.
 *****************************************************************************/
command result_t AccelCmd.PowerSwitch(uint8_t PowerState){
//    SODbg(DBG_USR2, "AccelM: PowerSwitch \n");
    if (state_accel == ACCEL_SWITCH_IDLE){
	   state_accel = ACCEL_PWR_SWITCH;
       power_accel = PowerState;
       if (!call Switch1.set(MICAWB_ACCEL_POWER,power_accel) == SUCCESS) state_accel = ACCEL_PWR_SWITCH_WAIT;
       return SUCCESS;
    }
    return FAIL;
} 

 event result_t Switch1.getDone(char value) {
    return SUCCESS;
  }

/******************************************************************************
 * Power switch set on or off
 * If turning power on then wait 100 msec for ADXL202 turn-on before returning
 * else return immediately.
 *****************************************************************************/
 event result_t Switch1.setDone(bool local_result) {
//   SODbg(DBG_USR2, "AccelM: setDone: state %i \n", state_accel);
    if (state_accel == ACCEL_PWR_SWITCH_WAIT){        //try again to get I2C bus
//       SODbg(DBG_USR2, "AccelM: setDone: I2C retry \n ");
	   state_accel = ACCEL_PWR_SWITCH;
	   if (!call Switch1.set(MICAWB_ACCEL_POWER,power_accel) == SUCCESS) state_accel = ACCEL_PWR_SWITCH_WAIT;
       return SUCCESS;
	}
	if (state_accel == ACCEL_PWR_SWITCH){
      if (power_accel) {
	    return call Timer.start(TIMER_ONE_SHOT, 100);
      }
	  state_accel = ACCEL_SWITCH_IDLE;
	  signal AccelCmd.SwitchesSet(power_accel);
    }
	return SUCCESS;
  }

 
  event result_t Switch1.setAllDone(bool local_result) {
    return SUCCESS;
  }


 // sensor is now warmed up
 event result_t Timer.fired() {
	state_accel = ACCEL_SWITCH_IDLE;
    signal AccelCmd.SwitchesSet(power_accel);
    return SUCCESS;
  } 


 }

