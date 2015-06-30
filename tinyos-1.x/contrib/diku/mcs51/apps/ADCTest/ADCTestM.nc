/*
  Testing the ADC connection
  
*/

module ADCTestM {
  provides {
     interface StdControl;
  }
  uses {
     interface Timer;
     interface ADC;
     interface ADCControl;
  }
}
implementation {
  
  command result_t StdControl.init() {
    return call ADCControl.init();
  }

  command result_t StdControl.start() {
    call Timer.start(TIMER_REPEAT, 250);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  event result_t Timer.fired() {
    call ADC.getData();
    return SUCCESS;
  }


  async event result_t ADC.dataReady(uint16_t input) {
    int8_t idx;
    input = input>>8;
    atomic{
      P0 = 0;
      for(idx = 7; idx >= 0; idx--) {
        if(input > (32*idx)) P0 |= 1<<idx;
      }
    }
    return SUCCESS;
  }
}
