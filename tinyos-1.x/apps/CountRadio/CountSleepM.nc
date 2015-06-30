// $Id: CountSleepM.nc,v 1.1 2004/05/29 21:07:17 jpolastre Exp $
// @author Cory Sharp <cssharp@eecs.berkeley.edu>

includes CountMsg;
includes Timer;

module CountSleepM
{
  provides interface StdControl;
  uses interface Timer;
  uses interface Leds;
  uses interface PowerManagement;
  uses command result_t Enable();
}
implementation
{
  command result_t StdControl.init()
  {
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call Enable();
    call Timer.start( TIMER_REPEAT, 50 );
    call PowerManagement.adjustPower(); 
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    call Leds.redToggle();
    call PowerManagement.adjustPower();
    return SUCCESS;
  }

}

