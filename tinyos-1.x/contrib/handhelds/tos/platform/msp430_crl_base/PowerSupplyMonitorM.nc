/*
 * Copyright (c) 2007, Intel Corporation
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * Redistributions of source code must retain the above copyright notice, 
 * this list of conditions and the following disclaimer. 
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution. 
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software 
 * without specific prior written permission. 
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * Author:  Steve Ayer
 *          March, 2007
 *
 * support for interface to msp430 SVSCTL functionality
 */

includes PowerSupplyMonitor;

module PowerSupplyMonitorM {
  provides {
    interface PowerSupplyMonitor;
    interface StdControl;
  }
  uses{
    interface Timer;
    interface Leds;
  }
}

implementation {
  uint8_t threshold;
  uint32_t monitor_interval;
  bool started, spurious_check;

  /* 
   * sets svs to first voltage level beneath regulator (2.9v), 
   * no reset, 15 minute polling 
   */
  void init() {
    threshold = THREE_2V;
    monitor_interval = 900000;  

    SVSCTL = 0;
    //    CLR_FLAG(SVSCTL, 0xff);
  }
  
  /* turns on svs to highest voltage level (3.7v), no reset */
  command result_t StdControl.init(){
    started = FALSE;
    spurious_check = FALSE;

    init();
    
    return SUCCESS;
  }

  command result_t StdControl.start(){
    CLR_FLAG(SVSCTL, VLD_EXT);
    SET_FLAG(SVSCTL, threshold);

    started = TRUE;
    return call Timer.start(TIMER_REPEAT, monitor_interval);
  }

  command result_t StdControl.stop(){
    call PowerSupplyMonitor.disable();

    started = FALSE;
    return SUCCESS;
  }


  task void spurious_test(){
    call Timer.stop();
    started = FALSE;

    atomic{
      CLR_FLAG(SVSCTL, VLD_EXT);  // set vld to zero to stop detection
      CLR_FLAG(SVSCTL, SVSFG);
    }

    spurious_check = TRUE;
    call Timer.start(TIMER_ONE_SHOT, 5000);
  }

  task void recheck(){
    spurious_check = FALSE;

    SET_FLAG(SVSCTL, threshold);  // set vld back to threshold, restart detection

    TOSH_uwait(1000);  // wait for svs to settle back down (max time ~ 50us, but hey)

    atomic if(READ_FLAG(SVSCTL, SVSFG)){
      CLR_FLAG(SVSCTL, threshold);  // set vld back to threshold, restart detection
      signal PowerSupplyMonitor.voltageThresholdReached(threshold);
    }
  }
      
  event result_t Timer.fired(){
    if(spurious_check)
      post recheck();
    else{
      atomic if(READ_FLAG(SVSCTL, SVSFG))
	post spurious_test();
    }
    return SUCCESS;
  }

  command void PowerSupplyMonitor.resetOnLowVoltage(bool reset){
    if(reset)
      SET_FLAG(SVSCTL, PORON);
    else
      CLR_FLAG(SVSCTL, PORON);
  }

  /* enum in PowerSupplyVoltage.h for this */
  command void PowerSupplyMonitor.setVoltageThreshold(uint8_t t){
    threshold = t;
    if(started){
      CLR_FLAG(SVSCTL, VLD_EXT);  
      SET_FLAG(SVSCTL, t);
    }
  }

  command result_t PowerSupplyMonitor.isSupplyMonitorEnabled(){
    return READ_FLAG(SVSCTL, SVSON);
  }

  command result_t PowerSupplyMonitor.queryLowVoltageCondition(){
    return READ_FLAG(SVSCTL, SVSFG);
  }


  command result_t PowerSupplyMonitor.setMonitorInterval(uint32_t interval_ms){
    monitor_interval = interval_ms;
    if(started){
      call Timer.stop();
      return call Timer.start(TIMER_REPEAT, monitor_interval);
    }
    else 
      return SUCCESS;
  }

  command void PowerSupplyMonitor.clearLowVoltageCondition(){
    CLR_FLAG(SVSCTL, SVSFG);
  }

  command result_t PowerSupplyMonitor.stopVoltageMonitor() {
    return call Timer.stop();
  }

  command result_t PowerSupplyMonitor.disable(){
    CLR_FLAG(SVSCTL, 0xf0);

    started = FALSE;

    return call Timer.stop();
  }
}
