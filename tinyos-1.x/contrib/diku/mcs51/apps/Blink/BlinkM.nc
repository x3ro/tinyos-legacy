/*
  The Blink application
  
  Toggles the three LEDs and show counter on P0.0 - P0.3
*/

module BlinkM {
  provides {
     interface StdControl;
  }
  uses {
     interface Leds;
  }
}

implementation {

  command result_t StdControl.init() {
     call Leds.init();
     return SUCCESS;
  }

  command result_t StdControl.start() {
     long int x, y=0;
     while(1) {
       call Leds.redToggle();
       call Leds.greenToggle();
       call Leds.yellowToggle();
       for (x=0; x<25000; x++);
       atomic {
         P0&=240;
         P0|=y++;
       }
       if(y>15) y=0;
     }
     return SUCCESS;
  }

  command result_t StdControl.stop() {
  return SUCCESS;
  }
}
