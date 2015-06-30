/**
 * JDebugTestM
 */

module JDebugTestM {
  provides {
    interface StdControl;
  }
  
  uses {
    interface Leds;
    interface Timer;
    interface JDebug;
  }
}

implementation {
  
  uint32_t dlong;
  uint32_t dint;
  uint32_t dshort;
  
  /***************** StdControl ****************/
  command result_t StdControl.init() {
    call Leds.init();
    dlong = 0;
    dint = 0;
    dshort = 0;
    return SUCCESS;
  }
  
  command result_t StdControl.start() { 
    call Timer.start(TIMER_REPEAT, 512);
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  /***************** Timer ****************/
  event result_t Timer.fired() {
    dlong += 100;
    dint += 10;
    dshort += 1;
    
    if(call JDebug.jdbg("JDebug Test %xl=%l %xi=%i %xs=%s", dlong, dint, dshort)) {
      call Leds.greenToggle();
    } else {
      call Leds.redToggle();
    }
    return SUCCESS;
  }
}

