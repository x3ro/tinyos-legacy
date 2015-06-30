
//!! Config 60 { MagTime_t MagReadingPeriod = MAGTIME_READING_PERIOD; }
//!! Config 61 { uint16_t MagReadingInvalidCount = 100; }

// XXX FIXME XXX put the invalidate logic BEFORE the mag moving average
//!! Config 62 { uint16_t MagRadioQuellTime = 200; }


module MagReadingM
{
  provides interface StdControl;

  uses interface Timer;
  uses interface Timer as RadioQuellTimer;
  uses interface TickSensor;

  uses interface U16Sensor;
  uses interface MagAxesSpecific;
  uses interface StdControl as MagSensorControl;

  uses interface MagReadingAttr;
  uses interface Valid as MagReadingValid;

  uses interface Config_MagReadingPeriod; // autowired

  uses interface Valid as MagSensorValid;

  uses interface RadioSending;
}
implementation
{
  uint16_t m_invalid_count;
  bool m_radio_quell;

  command result_t StdControl.init()
  {
    call MagSensorControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    MagAxes_t axes = { x:TRUE, y:TRUE };
    m_radio_quell = FALSE;
    call MagSensorControl.start();
    call MagAxesSpecific.enableAxes( axes );
    call MagReadingValid.set( FALSE );
    m_invalid_count = G_Config.MagReadingInvalidCount;
    call Timer.start( TIMER_REPEAT, G_Config.MagReadingPeriod );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop();
    call RadioQuellTimer.stop();
    call MagSensorControl.stop();
    return SUCCESS;
  }

  event void Config_MagReadingPeriod.updated()
  {
    call Timer.stop();
    call Timer.start( TIMER_REPEAT, G_Config.MagReadingPeriod );
  }

  event result_t Timer.fired()
  {
    call U16Sensor.read();
    return SUCCESS;
  }

  event result_t U16Sensor.readDone( uint16_t value )
  {
    MagReading_t reading = { value:value, time:call TickSensor.get() };
    call MagReadingAttr.set( reading );
    if( m_invalid_count > 0 )
    {
      call MagReadingValid.set( FALSE );
      m_invalid_count--;
    }
    else if( m_radio_quell == TRUE )
    {
      call MagReadingValid.set( FALSE );
    }
    else
    {
      call MagReadingValid.set( call MagSensorValid.get() );
    }
    return SUCCESS;
  }

  event void MagReadingAttr.updated()
  {
  }

  event result_t RadioQuellTimer.fired()
  {
    m_radio_quell = FALSE;
    return SUCCESS;
  }

  task void radio_quell()
  {
    call RadioQuellTimer.stop();

    if( call RadioQuellTimer.start( TIMER_ONE_SHOT,
	   G_Config.MagRadioQuellTime ) == SUCCESS )
    {
      m_radio_quell = TRUE;
    }
    else
    {
      m_radio_quell = FALSE;
    }
  }

  event void RadioSending.start()
  {
    if( G_Config.MagRadioQuellTime > 0 )
    {
      if( post radio_quell() )
	m_radio_quell = TRUE;
    }
  }


}

