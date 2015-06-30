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
 * Author: Steve Ayer
 *         March, 2007
 */

includes PowerSupplyMonitor;

module TestPowerSupplyMonitorM {
  provides{
    interface StdControl;
  }
  uses {
    interface StdControl as PSMStdControl;

    interface PowerSupplyMonitor;

    interface Leds;
    interface Timer;
  }
} 

implementation {
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));

  uint8_t warning_threshold;

  command result_t StdControl.init() {
    call Leds.init();

    /*
     * two useful thresholds here give different amounts of cushion before the 
     * msp430 becomes incoherent:
     * the TWO_9V setting triggers a low-voltage condition almost as soon as the board falls off 
     * the regulator at about 3.06V supply-side, 2.98V to the msp430;
     * the TWO_8V setting gives us until the battery is down to about 2.9V, or about 2.84V at the mcu; 
     * at this level, the margin is very small, and before long a blink of the warning led might trigger a p.o.r.
     * important note: the TWO_65V threshold triggers at the point when the msp430 flash dies (about 2.71V), 
     * and should be used to cause a brownout-reset
     */
    warning_threshold = TWO_8V;

    call PSMStdControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call PowerSupplyMonitor.setVoltageThreshold(warning_threshold);

    /*
     * ten seconds for testing; i'm busy!   
     * 10-15 minutes is probably reasonable for an app, depending upon 
     * the rate of its power consumption
     */
    call PowerSupplyMonitor.setMonitorInterval(10000);    
    call PSMStdControl.start();

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call PSMStdControl.stop();
    return SUCCESS;
  }

  event result_t PowerSupplyMonitor.voltageThresholdReached(uint8_t t) {
    if(t == warning_threshold){
      call PowerSupplyMonitor.setVoltageThreshold(TWO_65V);   // we hit here, we reset; flash is out
      call PowerSupplyMonitor.clearLowVoltageCondition();
      call PowerSupplyMonitor.resetOnLowVoltage(TRUE);
      call PowerSupplyMonitor.setMonitorInterval(60000);   // now check at one minute
      call Timer.start(TIMER_ONE_SHOT, 5000);
    }
    return SUCCESS;
  }
  
  event result_t Timer.fired() {
    static bool on;
    
    call Leds.redToggle();
    if(!on){
      on = TRUE;
      call Timer.start(TIMER_ONE_SHOT, 100);      
    }
    else{
      on = FALSE;
      call Timer.start(TIMER_ONE_SHOT, 5000);      
    }
  }
}

