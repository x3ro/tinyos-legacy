
module DefaultServiceM
{
  provides interface StdControl;
  uses interface TimedLeds;
}
implementation
{
  command result_t StdControl.init()
  {
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call TimedLeds.intOn( 255, 1000 );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }
}

