//$Id: TimerJiffyAsyncM.nc,v 1.1 2005/07/29 18:29:30 adchristian Exp $
// @author Joe Polastre

module TimerJiffyAsyncM
{
  provides interface StdControl;
  provides interface TimerJiffyAsync;
  uses interface C55xxAlarm as Alarm;
}
implementation
{
  uint32_t jiffy;
  bool bSet;

  command result_t StdControl.init()
  {
    call Alarm.disableEvents();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    atomic {
      bSet = FALSE;
      call Alarm.disableEvents();
    }
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    atomic {
      bSet = FALSE;
      call Alarm.disableEvents();
    }
    return SUCCESS;
  }

  async event void Alarm.fired()
  {
    if (jiffy < 0xFFFF) {
      call Alarm.disableEvents();
      bSet = FALSE;
      printf("TimerJiffyAsyncM.Alarm.fired\r\n");
      signal TimerJiffyAsync.fired();
    }
    else {
      jiffy = jiffy >> 16;
      printf("TimerJiffyAsyncM rescheduling\r\n");
      call Alarm.setEventFromNow( jiffy );
      call Alarm.clearPendingInterrupt();
      call Alarm.enableEvents();
    }
  }

  async command result_t TimerJiffyAsync.setOneShot( uint32_t _jiffy )
  {
    call Alarm.disableEvents();
    atomic {
      jiffy = _jiffy;
      bSet = TRUE;
    }
    printf("TimerJiffyAsync.setOneShot %lx\r\n", _jiffy);
    if (_jiffy > 0xFFFF) {
      call Alarm.setEventFromNow( 0xFFFF );
    }
    else {
      call Alarm.setEventFromNow( _jiffy );
    }
    call Alarm.clearPendingInterrupt();
    call Alarm.enableEvents();
    return SUCCESS;
  }

  async command bool TimerJiffyAsync.isSet( )
  {
    return bSet;
  }

  async command result_t TimerJiffyAsync.stop()
  {
    atomic { 
      bSet = FALSE;
      call Alarm.disableEvents();
    }
    return SUCCESS;
  }
}

