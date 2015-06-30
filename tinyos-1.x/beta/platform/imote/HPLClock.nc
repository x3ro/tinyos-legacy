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

/*modified my krishna - intel SC to get system time,
this system time will wrap around every 10^22 seconds
i.e. every 48.54 days */

// Pick up function prototypes for the hardware's library
includes motelib;

module HPLClock {
  provides interface Clock;
  provides interface SystemTime;
  provides interface StdControl;
}


implementation
{
#include "NewTimer.h"
    
#if USE_NEW_TIMER

#else
    uint8_t gmScale;
    uint8_t gmInterval;
    uint8_t gmCounter;
#endif
    uint32_t systemTime;
    bool clk_init=false;
    bool clk_start=false;
    
    
    void RTOSClockInterrupt() __attribute__ ((C, spontaneous)) {
#if USE_NEW_TIMER
        signal Clock.fire();
#else      
        bool fFireEvent = FALSE;
        atomic{
            gmCounter++;
            systemTime++; //increment system time
            if (gmCounter >= gmInterval) {
                gmCounter =0;
                fFireEvent = TRUE;
            }
        }
        if(fFireEvent) {
            signal Clock.fire();
        }
#endif
    }
    
    command result_t StdControl.init() {
        atomic {
            if(clk_init==false){
	      systemTime = 0; //initialize system time to zero
#if USE_NEW_TIMER
                InitRTOSTimer();

#else
                gmScale = DEFAULT_SCALE;
                gmInterval = DEFAULT_INTERVAL;
                gmCounter = 0;
#endif
                clk_init = true;
            }
        }
        return SUCCESS;
    }
    
    command result_t StdControl.start() {
#if USE_NEW_TIMER
#else
        uint8_t mInt, mScl;
        atomic {
            if(clk_start==false){
                mInt = gmInterval;
                mScl = gmScale;
                gmCounter = 0;
                clk_start=true;
            }
        }

        StartRTOSClock();
        
        call Clock.setRate(mInt,mScl);
#endif
        return SUCCESS;
    }

  command result_t StdControl.stop() {
#if USE_NEW_TIMER
      StopRTOSClock();
#else
      uint8_t mInt;
      
      atomic mInt = gmInterval;
      
      StopRTOSClock();
      
      call Clock.setRate(mInt,0);
#endif
      return SUCCESS;
  }


  async command result_t Clock.setRate(uint32_t interval, char scale) {
      // roughly translate mica's clock since it sits in the common interface 
      // directory.  Base on interfaces/Clock.h the following mapping is ~correct.
      // Arm core has a 12M external clock. Need to move Clock.h to platform
      // specific section and use arm's granularities.
#if USE_NEW_TIMER
      atomic {
          if(clk_init == false){
	    systemTime = 0; //initialize system time to zero              
	    InitRTOSTimer();
	    clk_init=true;
          }
      }
      call Clock.setInterval(interval);
#else
      uint32 rate;
      
      atomic {
          gmScale = scale;
          gmInterval = interval;
          gmCounter = 0;
          if(clk_init == false){
              StartRTOSClock();
              clk_init=true;
          }
      }
      switch (scale) {
      case 0: rate =  (0 << 0); break;
      case 1: rate =  (1 << 0); break;
      case 2: rate =  (1 << 3); break;
      case 3: rate =  (1 << 5); break;
      case 4: rate =  (1 << 6); break;
      case 5: rate =  (1 << 7); break;
      case 6: rate =  (1 << 8); break;
      default: rate = 0;
      }
      
      SetRTOSClockRate(rate);
#endif 
      return SUCCESS;
  }
  
  async command void Clock.setInterval(uint32_t value) {
#if USE_NEW_TIMER
      SetRTOSInterval(value<<5);
      atomic{
	systemTime +=value;
      }
#else      
      atomic {
          gmInterval = value;
      }
#endif
      return;
  }

  async command void Clock.setNextInterval(uint8_t value) {

  }

  async command uint8_t Clock.getInterval() {
    
  }

  async command uint8_t Clock.getScale() {

  }

  async command void Clock.setNextScale(uint8_t scale) {

  }

  async command result_t Clock.setIntervalAndScale(uint8_t interval, uint8_t scale) {

  }

  async command uint32_t Clock.readCounter() {
#if USE_NEW_TIMER
      //return TM_GetRtosTmrCnter();
      return 0;
#else
      uint32_t CntrVal;
      atomic {
          CntrVal = gmCounter;
      }
      return CntrVal;
#endif
  }

  async command void Clock.setCounter(uint32_t n) {

  }

  async command void Clock.intDisable() {

  }

  async command void Clock.intEnable() {

  }

  default async event result_t Clock.fire() { 
      return SUCCESS; }

#if 1
  command uint32_t SystemTime.getSystemTime(){
    uint32_t time;
    atomic{
      time = systemTime + TM_GetRtosTmrCnter();;
    }
    return(time);
  }

  command void SystemTime.setSystemTime(uint32_t time){
     atomic{
       systemTime = time;
     }
  }
#endif
}
