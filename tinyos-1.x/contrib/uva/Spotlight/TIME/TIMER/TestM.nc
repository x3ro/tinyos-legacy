#include "GlobalAbsoluteTimer.h"

module TestM {

  provides interface StdControl;	
  uses interface TimeUtil;
  uses interface Leds;
  uses interface Timer;
  uses interface GlobalAbsoluteTimer;
}
 
implementation
{ 

  uint16_t LedsValue;
  tos_time_t now;
  uint32_t pervious_time;
  
  command result_t StdControl.init()
  { 
    LedsValue = 1;
    return SUCCESS;
  }

  command result_t StdControl.start() {
        
    tos_time_t next_fire = call TimeUtil.create(0,GLOBAL_TIMER_JIFFY-100);
       
  //call Timer.start2(TIMER_REPEAT,32700);

     
   call GlobalAbsoluteTimer.set(next_fire);
    
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }
  

  event   result_t GlobalAbsoluteTimer.fired(){
  
    tos_time_t nowTime,next_fire;
    
    call GlobalAbsoluteTimer.getGlobalTime(&nowTime);
            
    call Leds.set((++LedsValue)%7);   
    next_fire = call TimeUtil.addUint32(now,GLOBAL_TIMER_JIFFY+10*LedsValue);
    dbg(DBG_USR1,"To be fired at %ld, %ld\n",next_fire.high32,next_fire.low32);
    call GlobalAbsoluteTimer.set(next_fire);        
    return SUCCESS;
  }

  
  event result_t Timer.fired(){
    
    call GlobalAbsoluteTimer.getGlobalTime(&now);
    
    dbg(DBG_USR1,"TestM fired !!! at %ld with interval %ld\n",now.low32,now.low32-pervious_time);    
    pervious_time =  now.low32;
               
    call Leds.set((++LedsValue)%7);    
    call Timer.start2(TIMER_ONE_SHOT,32700);    
    return SUCCESS;     
  }


	  
}

