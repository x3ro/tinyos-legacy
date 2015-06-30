
module PollM
{
  provides interface Poll;
  provides interface StdControl;
  uses interface Timer;
}
implementation
{
  command result_t StdControl.init()
  {
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call Timer.start( TIMER_REPEAT, 100 );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop();
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    signal Poll.fired();
    return SUCCESS;
  }
}

