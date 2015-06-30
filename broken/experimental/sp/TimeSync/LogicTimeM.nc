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
 * Authors:		Su Ping  (sping@intel-research.net)

 * Date last modified:  9/25/02
 *
 */

includes TimeSyncMsg;
includes AbsoluteTimer;
module LogicTimeM {
  provides interface LogicTime;
  provides interface AbsoluteTimer[uint8_t id];

  uses 
  {   interface Clock;
      interface Leds;
  }
}
implementation
{
  uint32_t high32; // logic Time counter 
  uint32_t lastUpdate; // time of last time sync update
  uint16_t offset; // clock skew estimated

// follwoing 5 line are temp test code
    char testFlag;
    TOS_Msg buffer;
    TOS_MsgPtr pmsg;
    bool sendPending;
    uint8_t timerCnt ;  // number of running absolute timers
    struct atimer_s {
      uint32_t expireTime;
      uint8_t id;
    } aTimer[MAX_NUM_TIMERS];

  
  // Logic Time interface

  command result_t LogicTime.init() {
    high32=0; 
    testFlag = 0;
    timerCnt = 0;
    
    call Clock.setRate(0,3);// 1 ms for 128 , trouble for 103
                            // So you have to use all 128 motes to test this 
    return SUCCESS ;
  }

// don't change it. If you do, you have to test it. 
   command uint32_t  LogicTime.get()
   {

       uint8_t i;
       uint32_t retval;
       retval = high32;
       i = inp(TCNT0);
       retval += i<<5 ;
       return retval;
   }

   command uint16_t LogicTime.currentTime() {
      return ( (uint16_t)call LogicTime.get());
   }
   //
   command void LogicTime.set( uint32_t t) {
     high32 = t;
     outp(0, TCNT0);
     call Leds.greenToggle();// test
   }


/******************************************************
  // this version support clock rate change at run time
  command uint16_t LogicTime.currentTime() {
    uint8_t i, scale;
    i= inp(TCNT0);
    scale = inp(TCCR0);
    scale &=0x7;
    // convert TCNT0 into ticks at 32768 ticks per second
    return (uint16_t)( (i <<shift[scale-1]) + high32) ;
  }
*************************************************/

  command result_t AbsoluteTimer.init[uint8_t id]() {
    // if CLOCK is not running, set it to run at default rate
    // what is the default rate? should be defined in .h file
    //if (call Clock.getRate()) 
        call Clock.setRate(0, 3); //  for 128L 
        // call Clock.setRate(1, 3); for 103L
    return SUCCESS;
  }

   // insert a new absolute timer into aTimer list which is sorted 
   // from smallest expireTime to largest 
   // Algorithm: 
   //    start from the last element in aTimer list; 
   //    i = N-1; ( a[i+1] is a free slot )
   //    while loop (i>0) 
   //    if (a[i] > in ) 
   //       move a[i] to a[i+1];  
   //       i--;
   //    else copy in to a[i+1], break 
   //    end while loop

   void insert( uint32_t in, uint8_t timerId) {
       int i;
       aTimer[timerCnt].expireTime = in;
       aTimer[timerCnt].id = timerId;
       i = timerCnt-1;
       while (i ) {
          if (aTimer[i].expireTime <=in )  {
              aTimer[i+1].expireTime = in;
              aTimer[i+1].id = timerId;
              break;
     
          } else {
              aTimer[i+1].expireTime = aTimer[i].expireTime;
              aTimer[i+1].id = aTimer[i].id;
              i--;
         }
       }
   }
              
       
  // start a timer that expired when logic time high32 is equal to "in"
  command result_t AbsoluteTimer.start[uint8_t id](uint32_t in ) {
    if ( timerCnt>=MAX_NUM_TIMERS ) return FAIL;
    if (timerCnt == 1) {
	aTimer[0].expireTime = in;
        aTimer[0].id = id;
    } else {
        insert(in, id);
    }
    timerCnt++;
    return SUCCESS;
  }

  // remove a timer from timer list
  // argument indicate which element to remove
  // Algorithm:
  //    move a[i+1] to a[i] until end of the list

  void remove( uint8_t i ) {
    uint8_t j;
    for (j = i+1; j<timerCnt; j++) {
      aTimer[j].expireTime = aTimer[j+1].expireTime;
      aTimer[j].id = aTimer[j+1].id;
    }
  }

  command uint32_t AbsoluteTimer.stop[uint8_t id]() {
    uint8_t i;
    uint32_t left; 
    // search for the timer
    for (i=0; i<timerCnt; i++)
        if (aTimer[i].id = id) break;
    if (i==timerCnt) return 0; 
    
    left =  aTimer[i].expireTime - call LogicTime.get();
    remove(i);
    timerCnt--;
    return left;
  }

  default event result_t AbsoluteTimer.expired[uint8_t id]() {
	return SUCCESS ;
  }

  event result_t Clock.fire() { 
    uint8_t i;
    high32 +=1000 ; 
/* test code 
    if (high32>=5000000L)
    {
       high32-=5000000L; 
       //signal AbsoluteTimer.expired();
       //stop the clock
       //call Clock.setRate(128, 0);
       call Leds.greenToggle();
    }
*/


    i =0; 
    while(i<timerCnt) // if any absolute timer is running
    {
       if ( high32 >= aTimer[i].expireTime) {
          signal AbsoluteTimer.expired[aTimer[i].id]();
          remove(i);
          timerCnt--;
       }
       else break;
    }

    return SUCCESS;
  }


}
