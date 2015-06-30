
//!! Config 60 { MagTime_t MagReadingPeriod = MAGTIME_READING_PERIOD; }

module MagReadingM
{
  provides interface StdControl;

  uses interface Timer;

  uses interface MagSensor;
  uses interface MagAxesSpecific;
  uses interface StdControl as MagSensorControl;

  uses interface Config_MagReadingPeriod; // autowired
}
implementation
{
  command result_t StdControl.init()
  {
    G_Config.initial_service = 10;
    call MagSensorControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    MagAxes_t axes = { x:TRUE, y:TRUE };
    call MagSensorControl.start();
    call MagAxesSpecific.enableAxes( axes );
    call Timer.start( TIMER_REPEAT, G_Config.MagReadingPeriod );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop();
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
    call MagSensor.read();
    return SUCCESS;
  }

  event result_t MagSensor.readDone( Mag_t value )
  {
    // XXX FIXME XXX do something with value
    return SUCCESS;
  }
}

