includes Attrs;
includes Events;
#include <nucleusSignal.h>

module TestNucleusM {
  provides {
    interface StdControl;

    interface Event<uint16_t>  as TestEvent @nucleusEvent()
	    @nucleusEventString("This is a test event with seqno (%d)");
  }
  
  uses {
    interface Leds;
    interface Timer;
  }
}

implementation {
  
  uint16_t seqno;

  command result_t StdControl.init() { 
    return SUCCESS;
  }

  command result_t StdControl.start() { 
    call Timer.start(TIMER_REPEAT, 4096);
    return SUCCESS;
  }

  command result_t StdControl.stop() { 
    return SUCCESS;
  }

  event result_t Timer.fired() {
    //    call Leds.yellowToggle();
    //    nucleusSignal( TestEvent.log(LOG_DEBUG, &seqno) );
    seqno++;
    return SUCCESS;
  }
}




