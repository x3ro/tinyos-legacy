/*
 * Copyright (c) 2004, Intel Corporation
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
 */
 /*
 * This module manages the WatchDogTimer .
 */

module WDTControlM
{
  provides {
    interface StdControl;
    interface WDTControl;
   }

  uses {
  
    interface Timer;
   }
}


implementation
{

int state;
int ForceReset;

 #define TRACE_DEBUG_LEVEL 0ULL

  bool TaskFlag;   // Whether the task context has been entered since the last
                   // timer interrupt

/*
 * Constants which control the period network mechanisms.
 * All times are a function of the periodic timer interval
 */
  #define CHECKWDT_TIMER_INTERVAL 1000 // 1 s clock

 
  command result_t StdControl.init() {
    state = 0;
    ForceReset=0;

    TaskFlag = TRUE; // start out in task context

    return SUCCESS;
  }


  /*
   * WDT Control start
   */
  command result_t StdControl.start() {
  
    TM_SetWdTmrEnable();
//debugging - VEH
#if 0
    TM_SetUpWDTimer();
    return call Timer.start(TIMER_REPEAT, CHECKWDT_TIMER_INTERVAL);
#endif
return SUCCESS;

  }



  // Need to add a call to turn off the inquiry scan
  command result_t StdControl.stop() {
    TM_SetWdTmrDisable();
    return call Timer.stop();
 
   }



  task void ResetTaskFlag() {
    TaskFlag = TRUE;
  }


  event result_t Timer.fired() {
    // if timer fired then reset WDT
    if(ForceReset==0){
      TM_SetUpWDTimer();
    }

    if (TaskFlag == FALSE) {
      trace(TRACE_DEBUG_LEVEL,"Task context skipped for 1 sec\n");
    }
    TaskFlag = FALSE;
    post ResetTaskFlag();
     
    return SUCCESS;
  }
  
  
 
extern int TinyOSDisableWatchdog __attribute__ ((C));
 command result_t WDTControl.AllowForceReset() {
 
// VEH - force a reset
// end of debugging

//     ForceReset = 1;

  // stop the watchdog updates to trigger a watchdog reset
  TinyOSDisableWatchdog = 1;
    TM_SetUpWDTimer();

     return SUCCESS;

 }
  

}
