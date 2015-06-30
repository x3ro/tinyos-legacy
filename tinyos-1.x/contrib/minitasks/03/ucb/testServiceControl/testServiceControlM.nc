
module testServiceControlM
{
  provides interface StdControl;
  provides interface StdControl as LambControl;
  provides interface StdControl as WolfControl;
  uses interface StdControl as ServiceControlControl;
  uses interface Config_invoke_service;
  uses interface Timer;
}
implementation
{
  bool mode;

  command result_t StdControl.init()
  {
    mode = FALSE;
    call ServiceControlControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call ServiceControlControl.start();
    call Timer.start( TIMER_REPEAT, 1000 );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop();
    call ServiceControlControl.stop();
    return SUCCESS;
  }

  command result_t LambControl.init()
  {
    dbg( DBG_USR1, "LambControl.init()\n" );
    return SUCCESS;
  }

  command result_t LambControl.start()
  {
    dbg( DBG_USR1, "LambControl.start()\n" );
    return SUCCESS;
  }

  command result_t LambControl.stop()
  {
    dbg( DBG_USR1, "LambControl.stop()\n" );
    return SUCCESS;
  }

  command result_t WolfControl.init()
  {
    dbg( DBG_USR1, "WolfControl.init()\n" );
    return SUCCESS;
  }

  command result_t WolfControl.start()
  {
    dbg( DBG_USR1, "WolfControl.start()\n" );
    return SUCCESS;
  }

  command result_t WolfControl.stop()
  {
    dbg( DBG_USR1, "WolfControl.stop()\n" );
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    dbg( DBG_USR1, "Timer.fired():\n\nStarting service group %d:\n", (mode?1:2) );
    call Config_invoke_service.set(mode?1:2);
    mode = !mode;
    return SUCCESS;
  }

  event void Config_invoke_service.updated()
  {
  }
}

