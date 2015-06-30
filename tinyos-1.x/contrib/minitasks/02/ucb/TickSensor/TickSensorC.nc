
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
	   , ConfigC
	   , TimerC
           ;
  
  TickSensor = TickSensorM;
  StdControl = TickSensorM;

  TickSensorM -> TimerC.Timer[unique("Timer")];
  TickSensorM -> ConfigC.Config_counter_period;
}

