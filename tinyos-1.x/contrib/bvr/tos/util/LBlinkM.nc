module LBlinkM
{
  provides {
    interface LBlink;
    interface StdControl;
  }
  uses {
    interface Leds;
    interface Timer;
    interface StdControl as TimerControl;
  }
}

implementation {
  uint16_t rate;
  uint8_t yellow;
  uint8_t red;
  uint8_t green;
  bool timer_on;

  command result_t LBlink.setRate(uint16_t r)
  {
    dbg(DBG_BOOT,"LBlinkM$setRate: interval %d\n",r); 
    rate = r; 
    return SUCCESS;
  }   
   
  command result_t StdControl.init() {
    call TimerControl.init();
    call Leds.init();
    rate = 0;
    timer_on = FALSE;
    yellow = red = green = 0;
    return SUCCESS;
  } 

  command result_t StdControl.start() {
    call TimerControl.start();
    return SUCCESS;
  } 
  command result_t StdControl.stop() {
    call TimerControl.stop();
    return SUCCESS;
  } 

  command result_t LBlink.yellowBlink(uint8_t times)
  {
    dbg(DBG_USR1,"LBLinkM$yellowBlink %d times\n",times);
    yellow += times<<1;
    if (!timer_on) {
      timer_on = TRUE;
      call Timer.start(TIMER_REPEAT,rate);
    }
    return SUCCESS;
  }   
  command result_t LBlink.redBlink(uint8_t times)
  {
    dbg(DBG_USR1,"LBLinkM$redBlink %d times\n",times);
    red += times<<1;
    if (!timer_on) {
      timer_on = TRUE;
      call Timer.start(TIMER_REPEAT,rate);
    }
    return SUCCESS;
  }   
  command result_t LBlink.greenBlink(uint8_t times)
  {
    dbg(DBG_USR1,"LBLinkM$greenBlink %d times\n",times);
    green += times<<1;
    if (!timer_on) {
      timer_on = TRUE;
      call Timer.start(TIMER_REPEAT,rate);
    }
    return SUCCESS;
  }   
  event result_t Timer.fired() {
    if (yellow > 0) {
      call Leds.yellowToggle();
      yellow--;
    }
    if (red > 0) {
      call Leds.redToggle();
      red--;
    }
    if (green > 0) {
      call Leds.greenToggle();
      green--;
    }
    if (yellow + green + red == 0) {
      timer_on = FALSE;
      call Timer.stop();
    }
    return SUCCESS;
  }
}
