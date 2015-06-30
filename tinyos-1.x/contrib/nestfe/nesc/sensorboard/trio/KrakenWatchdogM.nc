//$Id: KrakenWatchdogM.nc,v 1.4 2005/08/11 23:24:51 jwhui Exp $

module KrakenWatchdogM
{
  provides interface StdControl;
  uses interface MSP430TimerControl;
  uses interface MSP430Compare;
  uses interface Timer;
} 
implementation
{ 

  enum {
    MAX_COUNT = 16,
  };

  uint8_t count = MAX_COUNT;

  void touch_watchdog()
  {
    WDTCTL = WDT_ARST_1000;
  }

  command result_t StdControl.init()
  { 
    atomic {
      touch_watchdog();
    }
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call MSP430TimerControl.setControlAsCompare();
    call MSP430TimerControl.enableEvents();
    call MSP430Compare.setEventFromNow(2);
    call Timer.start( TIMER_REPEAT, 1024 );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  async event void MSP430Compare.fired()
  {
    atomic {
      if ( count ) {
	touch_watchdog();
	count--;
      }
    }
    call MSP430TimerControl.clearPendingInterrupt();
    call MSP430Compare.setEventFromNow(16384);
  }

  event result_t Timer.fired() {
    atomic count = MAX_COUNT;
    return SUCCESS;
  }

}

