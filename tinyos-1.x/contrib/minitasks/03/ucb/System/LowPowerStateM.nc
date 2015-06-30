
//!! Config 4 { bool LowPowerStateEnabled = FALSE; }
//!! Config 5 { uint8_t LowPowerStateDefaultService = 255; }

includes DefineCC1000;
includes Config;

module LowPowerStateM
{
  provides interface StdControl;
#if defined(RADIO_CC1000)
  uses interface OnOff;
#endif
  uses interface Config_invoke_service;
  uses interface Timer;
  uses interface Leds;
}
implementation
{
  enum
  {
    LOW_POWER_STATE_SERVICE_NUMBER = 0,
  };

  uint8_t m_previous_service;
  uint8_t m_led_count;

  task void on()
  {
    if( G_Config.running_service == LOW_POWER_STATE_SERVICE_NUMBER )
    {
      if( m_previous_service == LOW_POWER_STATE_SERVICE_NUMBER )
	m_previous_service = G_Config.LowPowerStateDefaultService;
      call Config_invoke_service.set( m_previous_service );
    }
  }

  task void offForReals()
  {
    call Timer.stop();
#if defined(RADIO_CC1000)
    call OnOff.off();
#endif
  }

  event result_t Timer.fired()
  {
    if( m_led_count & 1 ) call Leds.redOn();
    else call Leds.redOff();
    if( m_led_count >= 6 )
      post offForReals();
    m_led_count++;
    return SUCCESS;
  }

  task void offNotify()
  {
    m_led_count = 1;
    call Timer.start( TIMER_REPEAT, 200 );
  }

  command result_t StdControl.init()
  {
    m_previous_service = G_Config.LowPowerStateDefaultService;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    post offNotify();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  task void offService()
  {
    if( G_Config.running_service != LOW_POWER_STATE_SERVICE_NUMBER )
      m_previous_service = G_Config.running_service;
    call Config_invoke_service.set( LOW_POWER_STATE_SERVICE_NUMBER );
  }

  event void Config_invoke_service.updated()
  {
  }

#if defined(RADIO_CC1000)
  event result_t OnOff.on()
  {
    G_Config.LowPowerStateEnabled = FALSE;
    post on();
    return SUCCESS;
  }

  event result_t OnOff.requestOff()
  {
    if( G_Config.LowPowerStateEnabled != TRUE )
    {
      G_Config.LowPowerStateEnabled = TRUE;
      post offService();
    }
    return FAIL; // don't turn off just yet, but in a moment or two.
  }
#endif
}

