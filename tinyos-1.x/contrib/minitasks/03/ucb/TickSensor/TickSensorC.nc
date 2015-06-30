
configuration TickSensorC
{
  provides
  {
    interface TickSensor;
    interface StdControl;
  }
}
implementation
{
  components TickSensorM
	   , TimerC
           ;
  
  TickSensor = TickSensorM;
  StdControl = TickSensorM;

  TickSensorM -> TimerC.Timer[unique("Timer")];

  // Autowired. Don't do this. I'm dumb.
  // TickSensorM -> ConfigC.Config_counter_period;
}

