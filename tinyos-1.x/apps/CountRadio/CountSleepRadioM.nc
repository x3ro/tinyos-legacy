// $Id: CountSleepRadioM.nc,v 1.5 2005/04/11 05:20:18 jpolastre Exp $
// @author Joe Polastre

includes CountMsg;
includes Timer;

module CountSleepRadioM
{
  provides interface StdControl;
  uses interface Timer;
  uses interface Leds;
  uses interface StdControl as CommControl;
  uses interface SendMsg;
// these are only needed for Atmel AVR based platforms
#ifdef __AVR__
  uses interface PowerManagement;
  uses command result_t Enable();
#endif
}
implementation
{

  TOS_Msg m_msg;
  int m_int;
  bool m_sending, start;

  command result_t StdControl.init()
  {
    m_int = 0;
    m_sending = FALSE;
    start = FALSE;
#ifdef __AVR__
    call Enable();
    call PowerManagement.adjustPower();
#endif
    call Leds.init();
    call CommControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call Timer.start( TIMER_ONE_SHOT, 2000 );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    if( ( m_sending == FALSE ) && (start == FALSE) )
    {
      CountMsg_t* body = (CountMsg_t*)m_msg.data;
      body->n = m_int;
      body->src = TOS_LOCAL_ADDRESS;
      call Leds.redOn();
      call CommControl.start();
      start = TRUE;
      call Timer.start(TIMER_ONE_SHOT, 10);
    }
    else if ( ( m_sending == FALSE ) && (start == TRUE) ) {  
      if( call SendMsg.send( TOS_BCAST_ADDR, sizeof(CountMsg_t), &m_msg ) == SUCCESS )
      {
	m_int++;
        call Leds.yellowOn();
        m_sending = TRUE;
      }
    }
    return SUCCESS;
  }

  event result_t SendMsg.sendDone( TOS_MsgPtr msg, result_t success )
  {
    m_sending = FALSE;
    start = FALSE;
    call Timer.start(TIMER_ONE_SHOT, 2000);
    call CommControl.stop();
    call Leds.redOff ();
    call Leds.yellowOff();
    return SUCCESS;
  }

}

