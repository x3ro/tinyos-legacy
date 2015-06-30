/* "Copyright (c) 2000-2004 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// Authors: Tian He,Su Ping,Miklos Maroti
// $Id: GlobalAbsoluteTimerM.nc,v 1.1.1.1 2005/05/10 23:37:07 rsto99 Exp $

includes TosTime;
includes Timer;
includes GlobalAbsoluteTimer;

#define TIME_SYNC 

module GlobalAbsoluteTimerM {
  provides {
    interface StdControl;
    interface GlobalAbsoluteTimer[uint8_t id];
  }
  uses {
    interface Timer;
    interface TimeUtil;
    interface StdControl as TimerControl; 
    interface Leds; 
       
    #ifdef TIME_SYNC
	  interface GlobalTime;
    #else
     interface LocalTime; 	
    #endif  
      interface Debug;  

  }
}

implementation
{

  tos_time_t current_global_time;
  tos_time_t previous_fire_time;
  
  tos_time_t timeLeftBeforeNexFire;
  tos_time_t GlobleAbsoluteTimer[MAX_NUM_ABS_TIMERS];
  int16_t nextFireTimerIndex;

  void updateGlobalTime();
  
  command result_t StdControl.init(){

    call TimerControl.init();
    
    atomic {
      current_global_time.high32=0; 
      current_global_time.low32 =0;
      timeLeftBeforeNexFire.high32 = 0;
      timeLeftBeforeNexFire.low32 = 0;              
    }
    nextFireTimerIndex = -1;
    
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call TimerControl.start();    
    return SUCCESS ;
  }

  command result_t StdControl.stop() {
    call Timer.stop();
    call TimerControl.stop();
    return SUCCESS;
  }

  command result_t GlobalAbsoluteTimer.set[uint8_t id](tos_time_t in) {

      tos_time_t jiffy_time;
                
	   uint64_t jiffies = in.high32;	        
	   jiffies <<=32;
	   jiffies += in.low32;
	        
	   // change it to jiffies (1/32768 secs)	        
		jiffies <<= 12;
		jiffies += 63;
		jiffies /= 125;
		
		jiffy_time.low32 = jiffies & (uint32_t) 0xffffffff;
		jiffy_time.high32 = jiffies >> 32 & (uint32_t) 0xffffffff;
		
		if(call GlobalAbsoluteTimer.set2[id](jiffy_time) == SUCCESS )
		return SUCCESS;
		return FAIL;		    
  }
  
  command result_t GlobalAbsoluteTimer.set2[uint8_t id](tos_time_t in) {

    if ( id >= (uint8_t)MAX_NUM_ABS_TIMERS ) {
      dbg(DBG_TIME, "GlobalAbsoluteTimer.set: Invalid id=\%d max=%d\n", id, MAX_NUM_ABS_TIMERS);
      return FAIL;
    }
    
    /* obtain latest time form lower ClockM component */        
    updateGlobalTime(); 
    
    if (call TimeUtil.compare(current_global_time, in) > 0)
    {
	  dbg(DBG_TIME, "time has passed, now(%ld,%ld),set:(%ld,%ld)\n",current_global_time.high32,current_global_time.low32,in.high32,in.low32);
	  call Leds.set(0x7);
	  return FAIL;
    } 
              
    GlobleAbsoluteTimer[id] = in;

    if (nextFireTimerIndex == -1 || nextFireTimerIndex == id) {
   
            nextFireTimerIndex = id;
            timeLeftBeforeNexFire = call TimeUtil.subtract(GlobleAbsoluteTimer[nextFireTimerIndex],current_global_time);
            if(timeLeftBeforeNexFire.high32 == 0){  
	            //dbg(DBG_TIME, "Fire next AbsoluteTimer %d in %ld at %ld\n",id,timeLeftBeforeNexFire.low32,current_global_time.low32);                                 
               call Timer.start2(TIMER_ONE_SHOT, timeLeftBeforeNexFire.low32);
            }else{ 
               dbg(DBG_TIME, "Fire1 LONG_DELAY");            
               call Timer.start2(TIMER_ONE_SHOT,LONG_DELAY);
            }                                           
    } else {
            //dbg(DBG_TIME, "Other globalTime is pending.\n");
            if ( call TimeUtil.compare(GlobleAbsoluteTimer[nextFireTimerIndex], in)==1) { 
            
               nextFireTimerIndex=id;
               timeLeftBeforeNexFire = call TimeUtil.subtract(current_global_time, GlobleAbsoluteTimer[nextFireTimerIndex]);
                                
               if(timeLeftBeforeNexFire.high32 == 0){                       
                  call Timer.start2(TIMER_ONE_SHOT, timeLeftBeforeNexFire.low32);
               }else { 
                 dbg(DBG_TIME, "Fire2 LONG_DELAY");              
                 call Timer.start2(TIMER_ONE_SHOT,LONG_DELAY);
               }
            
            }
   }    
            
    return SUCCESS;
  }
       
  command result_t GlobalAbsoluteTimer.cancel[uint8_t id]() {
    if (id >= (uint8_t)MAX_NUM_ABS_TIMERS || (GlobleAbsoluteTimer[id].high32 == 0 && GlobleAbsoluteTimer[id].low32 == 0))
      return FAIL;
      GlobleAbsoluteTimer[id].high32 = 0;
      GlobleAbsoluteTimer[id].low32 = 0;
      return SUCCESS;
  }

  default event result_t GlobalAbsoluteTimer.fired[uint8_t id]() {
    return SUCCESS ;
  }

  event result_t Timer.fired(){
  
    uint8_t i;
        
    updateGlobalTime();
               
    previous_fire_time = current_global_time;
       
    nextFireTimerIndex = -1;
        
    for (i = 0; i < (uint8_t)MAX_NUM_ABS_TIMERS; i++){            
      if ((GlobleAbsoluteTimer[i].low32 || GlobleAbsoluteTimer[i].high32)){ //this timer is active           
      	if( call TimeUtil.compare(current_global_time, GlobleAbsoluteTimer[i]) >= 0)//expire
      	{ 
      	 
      	 /*  
          dbg(DBG_TIME, "Actually Fired at %ld with interval %ld, Error %ld\n",
                         current_global_time.low32,
                         current_global_time.low32 - previous_fire_time.low32,
                         current_global_time.low32 - GlobleAbsoluteTimer[i].low32);     
          */
           
      	  GlobleAbsoluteTimer[i ].high32 = 0;
      	  GlobleAbsoluteTimer[i].low32 = 0;
      	  signal GlobalAbsoluteTimer.fired[i]();	  	  
      	} else {
      	   if(nextFireTimerIndex == -1 ){
      	      nextFireTimerIndex = i;	      	   	   	    
      	   } else{
      	    if(call TimeUtil.compare(GlobleAbsoluteTimer[i], GlobleAbsoluteTimer[nextFireTimerIndex]) <= 0)//near
      	    {
      	      nextFireTimerIndex = i;
      	    }	  
      	   }
      	}		
     }// if timer is active
   }//for
         
    if(nextFireTimerIndex != -1){
            timeLeftBeforeNexFire = call TimeUtil.subtract(GlobleAbsoluteTimer[nextFireTimerIndex],current_global_time);        
            
            if(timeLeftBeforeNexFire.high32 == (uint32_t) 0){                       
               call Timer.start2(TIMER_ONE_SHOT, timeLeftBeforeNexFire.low32);
            } else if(timeLeftBeforeNexFire.high32 >(uint32_t) 0){
               dbg(DBG_TIME, "Fire3 LONG_DELAY");            
               call Timer.start2(TIMER_ONE_SHOT,LONG_DELAY);
            }else {               
               dbg(DBG_TIME, "Error in NexFire %ld,%ld\n",timeLeftBeforeNexFire.high32,timeLeftBeforeNexFire.low32);               
            }         
    } else {
      call Timer.start2(TIMER_ONE_SHOT,LONG_DELAY);
    }	
    return SUCCESS;
  }
  
  /**
   *  read lower 32 bit from ClockM module
   *  
   *
   **/
   
  void updateGlobalTime(){
    atomic{
       uint32_t previous_time_low32 = current_global_time.low32;        
      
      #ifdef TIME_SYNC
        call GlobalTime.getGlobalTime(&current_global_time.low32);
      #else
	     current_global_time.low32 = call LocalTime.read();	 	
      #endif  
              
      if( previous_time_low32 > current_global_time.low32 + LONG_DELAY){
        dbg(DBG_TIME, "overflow at %ld > %ld\n",previous_time_low32,current_global_time.low32);          
        current_global_time.high32++;                     
      }
    }
  }

  /**
   *  @return global time in unit of millisecond;
   *  
   *
   **/
     
  command result_t GlobalAbsoluteTimer.getGlobalTime2[uint8_t id](tos_time_t *t){
  
    updateGlobalTime();              
    t->low32 = current_global_time.low32;
    t->high32 = current_global_time.high32;     
    return SUCCESS;
               
  }
  
  /**
   *  @return global time in unit of millisecond;
   *  
   *
   **/
     
  command result_t GlobalAbsoluteTimer.getGlobalTime[uint8_t id](tos_time_t *t){
 
 
    uint64_t time_in_jiffies = 0;
     
    updateGlobalTime();     
    
    time_in_jiffies = (uint64_t)current_global_time.high32;
        
    time_in_jiffies <<= 32;
    time_in_jiffies += current_global_time.low32;
    
     time_in_jiffies *=125;
	  time_in_jiffies -=63;
	  time_in_jiffies >>=12;	
	  
	  t->low32= time_in_jiffies & 0xffffffff;
	  t->high32 = (time_in_jiffies >> 32)& 0xffffffff; 
	 
    return SUCCESS;               
  }
  
  
  command uint32_t GlobalAbsoluteTimer.jiffy2ms[uint8_t id](uint32_t jiffies){
      
	  uint64_t ms = jiffies;

	  ms *=125;
	  ms -=63;
	  ms >>=12;	  
     return (ms);
  }
  
  command uint32_t GlobalAbsoluteTimer.ms2jiffy[uint8_t id](uint32_t ms){
  
  		// change it to jiffies (1/32768 secs)
		uint64_t jiffies = ms;   		         
		jiffies <<= 12;
		jiffies += 63;	
		jiffies /= 125;		  
      return jiffies;
  } 

  #ifdef TIME_SYNC  
  event result_t GlobalTime.GlobalTimeReady(){return SUCCESS;}
  #endif    
}
