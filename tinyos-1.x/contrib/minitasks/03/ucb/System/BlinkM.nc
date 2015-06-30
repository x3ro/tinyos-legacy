
//!! Config 160 { uint16_t BlinkMillis = 100; }

module BlinkM
{
  provides interface StdControl;
  uses interface Timer;
  uses interface Leds;
  uses interface Config_BlinkMillis;
}
implementation
{
  bool m_running;

  command result_t StdControl.init()
  {
    m_running = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    m_running = TRUE;
    call Leds.redOn();
    call Timer.start( TIMER_REPEAT, G_Config.BlinkMillis );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop();
    call Leds.redOff();
    m_running = FALSE;
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    call Leds.redToggle();
    return SUCCESS;
  }

  event void Config_BlinkMillis.updated()
  {
    if( m_running == TRUE )
    {
      call Timer.stop();
      call Timer.start( TIMER_REPEAT, G_Config.BlinkMillis );
    }
  }
}

