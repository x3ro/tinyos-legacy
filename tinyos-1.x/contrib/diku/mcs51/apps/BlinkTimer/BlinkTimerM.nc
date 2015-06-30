/*
  The Blink application using Timer
  
  Toggles the three LEDs and show counter on P0.0 - P0.3
*/

module BlinkTimerM {
  provides {
     interface StdControl;
  }
  uses {
     interface Leds;
     interface Timer;
  }
}

implementation {
//  uint8_t y=0;

  command result_t StdControl.init() {
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Leds.redOff();
    call Leds.greenOff();
    call Leds.yellowOff();
    return call Timer.start(TIMER_REPEAT, 400);
  }

  command result_t StdControl.stop() {
    return call Timer.stop();
  }

  event result_t Timer.fired() {
    call Leds.yellowToggle();
    return SUCCESS;
  }
}
