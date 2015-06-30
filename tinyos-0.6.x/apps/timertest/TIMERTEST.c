/*									tab:4
 * 
 *  ===================================================================================
 *
 *  IMPORTANT:  READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  
 *  By downloading, copying, installing or using the software you agree to this license.
 *  If you do not agree to this license, do not download, install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 1996-2000 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without modification,
 *  are permitted provided that the following conditions are met: 
 * 
 *	Redistributions of source code must retain the above copyright notice, this 
 *  list of conditions and the following disclaimer. 
 *	Redistributions in binary form must reproduce the above copyright notice, this
 *  list of conditions and the following disclaimer in the documentation and/or other 
 *  materials provided with the distribution. 
 *	Neither the name of the Intel Corporation nor the names of its contributors may 
 *  be used to endorse or promote products derived from this software without specific 
 *  prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' 
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 *  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
 *  IN NO EVENT SHALL THE INTEL OR ITS  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 *  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
 *  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER 
 *  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 *  POSSIBILITY OF SUCH DAMAGE.
 * 
 * ====================================================================================
 * 
 * Authors:  SU Ping  
 *           Intel Research Berkeley Lab
 * Date:     4/12/2002
 *
 */
 

#include "tos.h"
#include "dbg.h"
#include "TIMERTEST.h"


//Frame Declaration
#define TOS_FRAME_TYPE TIMERTEST_frame
TOS_FRAME_BEGIN(TIMERTEST_frame) {
		long counter0;
        long counter1;
		long counter2;
}
TOS_FRAME_END(TIMERTEST_frame);


/**************************************************************
  commands for testing timer module
  *************************************************************/

char TOS_COMMAND(TIMERTEST_INIT)(){
	// Init LEDs
  TOS_CALL_COMMAND(TIMERTEST_LEDr_OFF)();
  TOS_CALL_COMMAND(TIMERTEST_LEDy_OFF)();
  TOS_CALL_COMMAND(TIMERTEST_LEDg_OFF)();
  // init counters
  VAR(counter0)=3;
  VAR(counter1)=10;
  VAR(counter2)=3;

  // init timer
  TOS_CALL_COMMAND(TIMERTEST_SUB_INIT)();
  TOS_CALL_COMMAND(TIMERTEST_R_FLASH)();
  
  // start a few timers
//  TOS_CALL_COMMAND(TIMERTEST_SUB_START)(0, TIMER_ONE_SHOT , 200);

//  TOS_CALL_COMMAND(TIMERTEST_SUB_START)(1, TIMER_REPEAT, 1500);

  TOS_CALL_COMMAND(TIMERTEST_SUB_START)(2, TIMER_REPEAT, 2000);
  TOS_CALL_COMMAND(TIMERTEST_G_FLASH)();
  TOS_CALL_COMMAND(TIMERTEST_SUB_START)(3, TIMER_ONE_SHOT, 200);

  return 1;
}

char TOS_COMMAND(TIMERTEST_START)(){
  return 1;
}

/* Timer 0 Event Handler : timer 1 is a one-shot timer
   Toggle LED . decrement counter0
   restart the same timer
 */
void TOS_EVENT(TIMERTEST_TIMER_EVENT_0)() {
// 	dbg(DBG_CLOCK, ("timertest evet 0\n"));

    TOS_CALL_COMMAND(TIMERTEST_R_FLASH)();  
	if (--VAR(counter0))
		TOS_CALL_COMMAND(TIMERTEST_SUB_START)(0, TIMER_ONE_SHOT, 100);

}

/* timer 1 event handler : timer 1 is a repeat timer
   Toggle LED . decrement counter1
   if counter1 is 0, stop the timer
   */
void TOS_EVENT(TIMERTEST_TIMER_EVENT_1)() {
 	dbg(DBG_CLOCK, ("timertest evet 1\n"));
    TOS_CALL_COMMAND(TIMERTEST_R_FLASH)(); 
	VAR(counter1)--;
	if (!VAR(counter1))
		TOS_CALL_COMMAND(TIMERTEST_SUB_STOP)(1);

}


// timer 2 event handler
void TOS_EVENT(TIMERTEST_TIMER_EVENT_2)() {
 	dbg(DBG_CLOCK, ("timertest evet 2 \n"));
    TOS_CALL_COMMAND(TIMERTEST_R_FLASH)(); 
	VAR(counter2)--;
	if (!VAR(counter2))
		TOS_CALL_COMMAND(TIMERTEST_SUB_STOP)(2);
}

// timer 3 event handler : toggle LED
void TOS_EVENT(TIMERTEST_TIMER_EVENT_3)() {
	dbg(DBG_CLOCK, ("timertest evet 3\n"));
    TOS_CALL_COMMAND(TIMERTEST_R_FLASH)(); 
}
