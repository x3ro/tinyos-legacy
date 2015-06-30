
module testMagM
{
  provides interface StdControl;
  uses interface StdControl as TimerControl;
  uses interface StdControl as MagControl;
  uses interface Timer;
  uses interface MagSensor;
}
implementation
{
  command result_t StdControl.init()
  {
    call MagControl.init();
    call TimerControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call MagControl.start();
    call TimerControl.start();
    call Timer.start( TIMER_REPEAT, 500 );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call MagControl.stop();
    call TimerControl.stop();
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    call MagSensor.read();
    return SUCCESS;
  }

  event result_t MagSensor.readDone( Mag_t mag )
  {
    dbg( DBG_USR1,
	 "MagSensor.readDone: axis=(bias,mag) x=(%u,%u) y=(%u,%u)\n",
	 mag.bias.x,
	 mag.val.x,
	 mag.bias.y,
	 mag.val.y
       );
    return SUCCESS;
  }
}

