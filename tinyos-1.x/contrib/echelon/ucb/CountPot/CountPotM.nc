// $Id: CountPotM.nc,v 1.1 2004/04/25 23:59:07 cssharp Exp $
// @author Cory Sharp <cssharp@eecs.berkeley.edu>

includes sensorboard;

module CountPotM
{
  provides interface StdControl;
  uses interface Timer;
  uses interface I2CPot;
  uses interface Leds;
}
implementation
{
  int m_int;

  command result_t StdControl.init()
  {
    m_int = 0;
    call Leds.init();
    //turn on AD5242 Address 0 (U17) on Echelon (on the mag circuit)
    TOSH_CLR_MAG_CTL_PIN();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call Timer.start( TIMER_REPEAT, 1000 );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    call I2CPot.writePot( 0, 0, (m_int << 5) );
    call Leds.set( m_int );
    m_int++;
    return SUCCESS;
  }

  event result_t I2CPot.writePotDone( bool result )
  {
    return SUCCESS;
  }

  event result_t I2CPot.readPotDone( char data, bool result )
  {
    return SUCCESS;
  }
}

