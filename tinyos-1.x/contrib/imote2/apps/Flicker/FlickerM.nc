module FlickerM {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer;
    interface Timer as Timer2;
    interface Timer as Timer3;
    interface Timer as Timer4;
    interface Leds;
  }
}
implementation {

  #define BASE_RATE (40)

  uint32_t timerCount1, timerCount2, timerCount3;
  
  /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
    call Leds.init(); 
    return SUCCESS;
  }


  /**
   * Start things up.  This just sets the rate for the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
    // Start a repeating timer that fires every 1000ms
    call Timer.start(TIMER_REPEAT, BASE_RATE);
    call Timer2.start(TIMER_REPEAT,2*BASE_RATE);
    call Timer3.start(TIMER_REPEAT,3*BASE_RATE);
    return call Timer4.start(TIMER_REPEAT,1000);
  }

  /**
   * Halt execution of the application.
   * This just disables the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop() {
    return call Timer.stop();
  }


  /**
   * Toggle the red LED in response to the <code>Timer.fired</code> event.  
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Timer.fired()
  {
    timerCount1++;
    call Leds.redToggle();
    trace(DBG_USR1,"Timer1\r\n");
    //    call Timer.start(TIMER_ONE_SHOT, BASE_RATE);
    return SUCCESS;
  }
  
  event result_t Timer2.fired()
  {
    timerCount2++;
    trace(DBG_USR1,"Timer2\r\n");
    call Leds.greenToggle();
    return SUCCESS;
  }
  
  event result_t Timer3.fired()
  {
    timerCount3++;
    trace(DBG_USR1,"Timer3\r\n");
    call Leds.yellowToggle();
    return SUCCESS;
  }

  event result_t Timer4.fired()
  {
    
    trace(DBG_USR1,"timerCount1 = %d, timerCount2 = %d, timerCount3 = %d\r\n",timerCount1, timerCount2, timerCount3);
    
    timerCount1 = timerCount2 = timerCount3 = 0;
    
    call Leds.yellowToggle();
    return SUCCESS;
  }
}


