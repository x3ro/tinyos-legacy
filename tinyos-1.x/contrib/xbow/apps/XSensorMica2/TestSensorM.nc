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
 */
/******************************************************************************
 * Measure mica2 battery voltage using the on-board voltage reference. 
 * As the battery voltage changes the Atmega ADC's full scale decreases. By
 * measuring a known voltage reference the battery voltage can be computed.
 *-----------------------------------------------------------------------------
 * Output results through mica2 uart port. Connect serial cable from programming
 * board to PC to monitor ouput. Use any terminal monitoring program set for
 * 57600, N,8,1
 *------------------------------------------------------------------------------
 * NOTE The Atmega JTAG fuse should be disabled to get high accuracy voltage 
 * measurements for the reference voltage. The JTAG port shares ADC channel 7
 * which is also used for the voltage ref input to the adc.
 * Using the most recent version of uisp
 * you can turn on/off the JTAG fuse:.
 *      fuse_dis--->"uisp -dprog=dapa --wr_fuse_h=0xD9"
 *      fuse_en --->"uisp -dprog=dapa --wr_fuse_h=0x19"
 *****************************************************************************/

module TestSensorM {
  provides {
    interface StdControl;
  }
  uses {
    interface Clock;
	interface ADC as ADCBATT;;
  	interface ADCControl;
    interface Leds;
  }
}

implementation {

// declare module static variables here 

/******************************************************************************
*  add include file to output uart port debug messages
******************************************************************************/
  #include "SODebug.h"  


void delay() {
    asm volatile  ("nop" ::);
    asm volatile  ("nop" ::);
    asm volatile  ("nop" ::);
    asm volatile  ("nop" ::);
}


 /****************************************************************************
 * Initialize the component. Initialize ADCControl, Leds
 *
 ****************************************************************************/
  command result_t StdControl.init() {
    call ADCControl.init();

//*****************************************************************************
// init debug uart
    init_debug();
//*****************************************************************************
    call Leds.init();
   	return SUCCESS;

  }
 /****************************************************************************
 * Start the component. Start the clock.
 *
 ****************************************************************************/
  command result_t StdControl.start(){
    return call Clock.setRate(TOS_I1PS, TOS_S1PS);
    return SUCCESS;	
  }
 /****************************************************************************
 * Stop the component. Stop the clock
 *
 ****************************************************************************/
  command result_t StdControl.stop() {
    return SUCCESS;    
  }
/****************************************************************************
 * Measure voltage ref  
 *
 ****************************************************************************/
  async event result_t Clock.fire() {
   call Leds.redOn();
   call Leds.greenOff();
   MAKE_BAT_MONITOR_OUTPUT();      //enable power to voltage ref  
   SET_BAT_MONITOR();      
   delay();                        //allow volt ref time to turn on
   call ADCBATT.getData();         //get voltage ref data;
   return SUCCESS;  
  }
/****************************************************************************
 * Battery ref data ready event handler 
 * Compute the battery voltage after measuring the voltage ref:
 * BV = RV*ADC_FS/data
 * where:
 * BV = Battery Voltage
 * ADC_FS = 1024
 * RV = Voltage Reference (1.223 volts)
 * data = data from the adc measurement of channel 7
 * BV (volts) = 1252.352/data
 * BV (mv) = 1252352/data 
 ****************************************************************************/
  async event result_t ADCBATT.dataReady(uint16_t data) {
    float x;
    uint16_t vdata;
    call Leds.redOff();
    call Leds.greenOn();  
    CLEAR_BAT_MONITOR();                   //turn off power to voltage ref     
    SODbg(DBG_USR2, "voltage ref ADC data: %i\n",data); 
    x=(float)data; 
    vdata =  (uint16_t ) (1252352 / x) ;
    SODbg(DBG_USR2, "battery volts(mv): %i\n", vdata); 
    return SUCCESS;
  }


}
