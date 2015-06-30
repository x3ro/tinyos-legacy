/*									tab:4
 * 
 *  ===================================================================
 *
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
 *  By downloading, copying, installing or using the software you
 *  agree to this license.  If you do not agree to this license, do
 *  not download, install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 1996-2000 Intel Corporation All rights reserved.
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 * 
 *	Redistributions of source code must retain the above copyright
 *	notice, this * list of conditions and the following
 *	disclaimer.  Redistributions in binary form must reproduce the
 *	above copyright notice, this * list of conditions and the
 *	following disclaimer in the documentation and/or other *
 *	materials provided with the distribution.  Neither the name of
 *	the Intel Corporation nor the names of its contributors may *
 *	be used to endorse or promote products derived from this
 *	software without specific * prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
 *  CONTRIBUTORS ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 *  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *  DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS CONTRIBUTORS BE
 *  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 *  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 *  TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 *  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 *  SUCH DAMAGE.
 *
 * ===============================================================
 * 
 * Authors:  SU Ping  
 *           Intel Research Berkeley Lab
 * Date:     4/12/2002
 *
 */
 

//	Timer Module implementation 
#include "tos.h"
#include "dbg.h"
#include "TIMER.h"

#define TIMER_HIGHEST_RATE 12  // highest clock rate 
#define TIMER_MIN_TICKS    10  
#define TIMER_THRESHOLD    20

#define TOS_FRAME_ticks TIMER
// module static variables
TOS_FRAME_BEGIN(TIMER) {
  UINT8 clockRate;          // current clock setting. see notes below for detail 
  UINT8 minTimer;// the index of the shortest timer
  long minTicks; // shortest timer interval in ticks
  UINT32 state;  // each bit represent a timer state, 1 for running, 0 for stopped 
  struct timer_s {
	UINT8 type; // one-short or repeat
    long ticks; // 0 for repeat timer,  clock ticks for a repeat timer 
    long ticksLeft;  // ticks left before the timer expires
  } timerList[NUM_TIMERS];
}
TOS_FRAME_END(TIMER);

/*
Supported clock rate for our timer module: ( as defined in hardware.h)
#define tick4096ps 1,2
#define tick2048ps 2,2
#define tick1024ps 1,3
#define tick512ps 2,3
#define tick256ps 4,3
#define tick128ps 8,3
#define tick64ps 16,3
#define tick32ps 32,3
#define tick16ps 64,3
#define tick8ps 128,3
#define tick4ps 128,4
#define tick2ps 128,5
#define tick1ps 128,6
 */  

// supported clock rates in the powers of 2 so that we can use shift 
//  clockRate[13]={0,1, 2, 3, 4,5,6,7,8,9,10,11,12};
// because the value are the same as the array index, I only need to use 
// one byte to represent clock rate .


inline void TOS_EVENT(TIMER_NULL_FUNC)() { }


static void initClock(UINT8 setting)
{
	switch(setting) {
		case 0: TOS_CALL_COMMAND(TIMER_SUB_INIT)(tick1ps) ; break;
		case 1: TOS_CALL_COMMAND(TIMER_SUB_INIT)(tick2ps) ; break;
		case 2: TOS_CALL_COMMAND(TIMER_SUB_INIT)(tick4ps) ; break;
		case 3: TOS_CALL_COMMAND(TIMER_SUB_INIT)(tick8ps) ; break;
		case 4: TOS_CALL_COMMAND(TIMER_SUB_INIT)(tick16ps) ; break;
		case 5: TOS_CALL_COMMAND(TIMER_SUB_INIT)(tick32ps) ; break;
		case 6: TOS_CALL_COMMAND(TIMER_SUB_INIT)(tick64ps) ; break;
		case 7: TOS_CALL_COMMAND(TIMER_SUB_INIT)(tick128ps) ; break;
		case 8: TOS_CALL_COMMAND(TIMER_SUB_INIT)(tick256ps) ; break;
		case 9: TOS_CALL_COMMAND(TIMER_SUB_INIT)(tick512ps) ; break;
		case 10: TOS_CALL_COMMAND(TIMER_SUB_INIT)(tick1024ps) ; break;
		case 11: TOS_CALL_COMMAND(TIMER_SUB_INIT)(tick2048ps) ; break;
		case 12: TOS_CALL_COMMAND(TIMER_SUB_INIT)(tick4096ps); break;
	}
}
/******************************************************************
Algorithm to convert time interval in milliseocnds to clock ticks.
=================================================================
    input:     interval, clockrate 
    algorithm: ticks = clockRate(in ticks/sec)*interval/1000 
    return:    ticks for this rate
*******************************************************************/
static inline long convertMStoTicks(long  interval, UINT8 clockRate) {
	return (((interval<<clockRate)+500)/1000);
}


/*******************************************************************
algorithm to adjust clock rate or change clock rate upwards
==============================
    input argument : interval in ms
    output argument: ticks under the new clock rate 
    return new clock rate 

    algorithm decription: 
           new_rate = current clockRate +1
           while new_rate <= TIMER_HIGHEST_RATE
             calculate ticks at new_rate 
             if ticks >=TIMER_MIN_TICKS  break 
	     else new_rate++
	   return new_rate
********************************************************************/
static UINT8  scaleUp(  long interval, long * ticks) {
	long temp;
	UINT8 new_rate = VAR(clockRate) +1;
	while (new_rate<=TIMER_HIGHEST_RATE) {
		temp = convertMStoTicks(interval, new_rate);
		if (temp>=TIMER_MIN_TICKS ) break;
		new_rate++;
	}
	*ticks =  temp ;
	return new_rate;
}
/*******************************************************************
algorithm to adjust clock rate or change clock rate downward
============================================================
    return new clock rate 
	algorithm decription: 
		   find the minimum timer ticks 
		   save its value and index 
		   calculate the number of levels we need to scale down 
		   ( thresthold set at 20 ticks )
           return new_rate 
********************************************************************/
static UINT8  scaleDown( void ) {
	long temp=99999999;
	long state = VAR(state);
	UINT8 i,diff=0, min_timer;
	dbg(DBG_CLOCK, (" TIMER: scale down\n"));
	for(i=0; i<NUM_TIMERS; i++) {
	  if ((state&(0x1<<i)) &&( temp >VAR(timerList[i].ticksLeft))) {
	    temp = VAR(timerList[i].ticksLeft); 
	    min_timer=i;
	  }
	}

	if (temp==99999999) {
	  // no timer left
	  VAR(clockRate)=0;
	  VAR(minTicks)=temp;
	  dbg(DBG_CLOCK, (" TIMER: no timer left\n"));
	}
	else {
	  dbg(DBG_CLOCK, (" TIMER: %i is min timer, has %lx ticks.\n", (int)min_timer, temp));
	  VAR(minTicks) = temp;
	  while (temp > TIMER_THRESHOLD) {
	    temp>>=1; diff++;
	  }
	  VAR(minTimer)=min_timer;
	}
	dbg(DBG_CLOCK, (" TIMER: scaleDown %d levels min ticks=%ld id=%d\n", diff, VAR(minTicks), min_timer));
	
	return (VAR(clockRate)-diff);
}


/********************************************************************
Algorithm to adjust ticks left for all running timers
=====================================================
    input argument: new_rate
    return:  none

    Algorithm description: 
	  if new_rate is lower
        multiple = new clockRate (tickps)/old clockRate (ticksps);
        for every active timer  
			left shift ticksLeft by "multiple" 
      else
	    multiple = old clock rate (ticksps) / new clock rate ( ticksps)
**********************************************************************/
static void adjustTicks(char new_rate) 
{
  short i ; 
  char multiple;

dbg(DBG_CLOCK,("adjustTicks new rate=%d old rate=%d\n", new_rate, VAR(clockRate)));

  if ( new_rate > VAR(clockRate) ) {
    multiple = new_rate-VAR(clockRate);
    for (i=0; i<NUM_TIMERS; i++) { 
      VAR(timerList[i].ticksLeft)<<= multiple;
      VAR(timerList[i].ticks)<<=multiple;
    }
    VAR(minTicks)<<=multiple;
dbg(DBG_CLOCK, ("multiple=%d min ticks=%ld\n", multiple, VAR(minTicks)));
  }
  else {
    multiple = VAR(clockRate)- new_rate;	
    for (i=0; i<NUM_TIMERS; i++) {
      VAR(timerList[i].ticksLeft)>>= multiple;
      VAR(timerList[i].ticks)>>=multiple;
    }
    VAR(minTicks)>>=multiple;
  }

}

/********************************************************************
Description of logic for TIMER_Init():
=======================================
    if (rate) return 0 // timer already initlized 
    set rate to default value
    if initialize HW timer ok    
       return 0
    else 
       return 1
********************************************************************/

char TOS_COMMAND(TIMER_INIT)() {
	if (VAR(clockRate)) return 0;
	VAR(clockRate)=0;
	VAR(state)=0;
	VAR(minTicks)=99999999;
	dbg(DBG_CLOCK,("minTicks=%ld\n", VAR(minTicks)));

	TOS_CALL_COMMAND(TIMER_SUB_INIT)(tick1ps) ;
//TOS_CALL_COMMAND(TIMER_R_LED_TOGGLE)();
	return 0;// CLOCK_INIT alway return ok
}

char TOS_COMMAND(TIMER_TERMINATE)() {
	VAR(clockRate)=0;
	VAR(state)=0;
	VAR(minTicks)=99999999;
	TOS_CALL_COMMAND(TIMER_SUB_INIT)(128, 0);
	return 0;
}

/*******************************************************************
Description of logic for TIMER_START(timer_id, ticks, interval):
===============================================================

    if timer_id > 31 return 2
    if type is not 0 or 1 return 3
    if the timer is running 
        return 1

    convert interval to clock ticks 
    if ticks < TIMER_MIN_TICKS 
       change rate (output: new_rate, ticks)
       adjust ticksLeft for all running timers
       set rate = new_rate // can not do this before adjust ticksLeft
  
    set ticksLeft for this timer to ticks
    set this timer's runing bit to 1
    set this timer's.type bit to type argument
    return 0
**************************************************************/
char TOS_COMMAND(TIMER_START)(UINT8 timer_id, char type, 
					  UINT32 interval)
{
  //TOS_CALL_COMMAND(TIMER_G_LED_TOGGLE)();
  long ticks;  
  UINT8 new_rate=VAR(clockRate);
  
  if (timer_id>NUM_TIMERS ) return 2;
  if (type>1) return 3;
  if (VAR(state)&(0x1<<timer_id)) return 1;
  ticks = convertMStoTicks(interval, new_rate);
  if (ticks==0 && new_rate==TIMER_HIGHEST_RATE) return 4;
  if (ticks<TIMER_MIN_TICKS && new_rate<TIMER_HIGHEST_RATE ) {
    	new_rate = scaleUp( interval, &ticks);
	dbg(DBG_CLOCK, ("scale up to %d\n", new_rate));
	adjustTicks(new_rate);
	// change clock setting
	initClock(new_rate);
	VAR(clockRate)=new_rate;
  }
 
  VAR(timerList[timer_id].ticksLeft)= ticks; 
  VAR(timerList[timer_id].ticks) = ticks ;
  VAR(timerList[timer_id].type) = type;
  VAR(state)|=(0x1<<timer_id);
  dbg(DBG_CLOCK, ("timer %d started rate=%d ticks=%ld\n", timer_id, VAR(clockRate), ticks));
  if (ticks <VAR(minTicks)) {
	  VAR(minTicks)=ticks;
	  VAR(minTimer)=timer_id;
dbg(DBG_CLOCK,("minTicks=%ld id=%d\n", ticks, timer_id));
  }
  return 0;
}
/**************************************************************
Description of logic for TIMER_STOP(timer_id)
=============================================

    if timer_id >=NUM_TIMERS  return 2
    if timer with id=timer_id is running 
       set the state bit representing this timer to 0 
       return 0
    else
       return 1
***************************************************************/

static void stopTimer( UINT8 i) // i is timer id
{
	UINT8  new_rate;
	VAR(state) -= (0x1<<i);
dbg(DBG_CLOCK, ("stop timer %d\n", i));
	if (i==VAR(minTimer)) // we have just stopped our shortest timer 
	{
		// scale down clock rate 
		new_rate = scaleDown();
		if (new_rate!=VAR(clockRate)) {
		  adjustTicks(new_rate);
		  initClock(new_rate);
		}
	}
}   

char  TOS_COMMAND(TIMER_STOP)(UINT8 timer_id) {
//	TOS_CALL_COMMAND(TIMER_Y_LED_TOGGLE)();

	if (timer_id>=NUM_TIMERS) return 2;
	if (VAR(state)&(0x1<<timer_id)) { // if the timer is running 
		stopTimer(timer_id);
		return 0;
	} 
	return 1;
}


static void TIMER_EVENT_DISPATCHER(UINT8 id) 
{
  //	TOS_CALL_COMMAND(TIMER_G_LED_TOGGLE)();
  dbg(DBG_CLOCK, ("timer %d event\n", id));
	switch (id)
	  {
	  case 0: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_0)(); break;
	  case 1: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_1)(); break;
	  case 2: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_2)(); break;
	  case 3: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_3)(); break;
	  case 4: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_4)(); break;
	  case 5: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_5)(); break;
	  case 6: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_6)(); break;
	  case 7: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_7)(); break;
	  case 8: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_8)(); break;
	  case 9: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_9)(); break;
	  case 10: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_10)(); break;
	  case 11: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_11)(); break;
	  case 12: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_12)(); break;
	  case 13: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_13)(); break;
	  case 14: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_14)(); break;
	  case 15: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_15)(); break;
	  case 16: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_16)(); break;
	  case 17: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_17)(); break;
	  case 18: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_18)(); break;
	  case 19: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_19)(); break;
	  case 20: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_20)(); break;
	  case 21: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_21)(); break;
	  case 22: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_22)(); break;
	  case 23: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_23)(); break;
	  case 24: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_24)(); break;
	  case 25: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_25)(); break;
	  case 26: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_26)(); break;
	  case 27: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_27)(); break;
	  case 28: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_28)(); break;
	  case 29: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_29)(); break;
	  case 30: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_30)(); break;
	  case 31: TOS_SIGNAL_EVENT(TIMER_EVENT_HANDLER_31)(); break;
	  }
}


/**************************************************************
Description of logic for Clock Interrup handler 
===============================================
    loop  from i=0 to NUM_TIMERS
        if timer i is running and ticksLeft[i] is non-zero
		  decrement ticksLeft by 1 
		  if timer i expires now       
			call user timer event handler 
			if the timer is one-shot timer   
				stop the timer 
			else reset ticketLeft 
**************************************************************/
void TOS_EVENT(TIMER_CLOCK_EVENT)() {
  UINT8 i=0; 
  UINT32 state = VAR(state);
  dbg(DBG_CLOCK, ("TIMER: Clock event, state: %lx\n", state));
  //	TOS_CALL_COMMAND(TIMER_Y_LED_TOGGLE)();
  dbg(DBG_CLOCK, ("TIMER: Ticks left: "));   
  for (i=0;i<NUM_TIMERS;i++) {
    dbg_clear(DBG_CLOCK, ("%lx ", VAR(timerList[i].ticksLeft)));
    if ((state&(0x1<<i)) && (!(--VAR(timerList[i].ticksLeft)))) {      // reset the ticksLeft if this is a repeat timer 
      if (VAR(timerList[i].type==TIMER_REPEAT)) 
	VAR(timerList[i].ticksLeft)= VAR(timerList[i].ticks);
      else // one shot timer 
	stopTimer(i);

      dbg(DBG_CLOCK, ("TIMER: Dispatch timer %hhx.\n", i));
      TIMER_EVENT_DISPATCHER(i);
    }
  }
  dbg_clear(DBG_CLOCK, ("\n"));
}

