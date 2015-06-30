//$Id: TimerJiffyAsyncM.nc,v 1.1.1.1 2007/11/05 19:10:38 jpolastre Exp $
// @author Joe Polastre

module TimerJiffyAsyncM
{
  provides interface StdControl;
  provides interface TimerJiffyAsync;
  uses interface MSP430TimerControl as AlarmControl;
  uses interface MSP430Compare as AlarmCompare;
}
implementation
{
  uint32_t jiffy;
  bool bSet;

  command result_t StdControl.init()
  {
    call AlarmControl.setControlAsCompare();
    call AlarmControl.disableEvents();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    atomic {
      bSet = FALSE;
      call AlarmControl.disableEvents();
    }
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    atomic {
      bSet = FALSE;
      call AlarmControl.disableEvents();
    }
    return SUCCESS;
  }

  async event void AlarmCompare.fired()
  {
    if (jiffy < 0xFFFF) {
      call AlarmControl.disableEvents();
      bSet = FALSE;
      signal TimerJiffyAsync.fired();
    }
    else {
      jiffy = jiffy - 0xFFFF;
      if (jiffy > 0xFFFF)
        call AlarmCompare.setEventFromNow( 0xFFFF );
      else {
	atomic {
	  // bug in MSP430 silicon causes interrupt to get lost if the
	  // next timer event doesn't occur at least 2 ticks in the future
	  // this bug is present on the F15x/F16x/F161x series
	  // see TI SLAZ018 Device Erratasheet
	  if (jiffy > 2)
	    call AlarmCompare.setEventFromNow( jiffy );
	  else
	    call AlarmCompare.setEventFromNow( 2 );
	}
      }

      call AlarmControl.clearPendingInterrupt();
      call AlarmControl.enableEvents();
    }
  }

  async command result_t TimerJiffyAsync.setOneShot( uint32_t _jiffy )
  {
    call AlarmControl.disableEvents();
    atomic {
      jiffy = _jiffy;
      bSet = TRUE;
    }
    if (_jiffy > 0xFFFF) {
      call AlarmCompare.setEventFromNow( 0xFFFF );
    }
    else {
      atomic {
	// bug in MSP430 silicon causes interrupt to get lost if the
	// next timer event doesn't occur at least 2 ticks in the future
	// this bug is present on the F15x/F16x/F161x series
	// see TI SLAZ018 Device Erratasheet
	if (_jiffy > 2)
	  call AlarmCompare.setEventFromNow( _jiffy );
	else
	  call AlarmCompare.setEventFromNow( 2 );
      }
    }
    call AlarmControl.clearPendingInterrupt();
    call AlarmControl.enableEvents();
    return SUCCESS;
  }

  async command bool TimerJiffyAsync.isSet( )
  {
    bool _isSet;
    atomic _isSet = bSet;
    return _isSet;
  }

  async command result_t TimerJiffyAsync.stop()
  {
    atomic { 
      bSet = FALSE;
      call AlarmControl.disableEvents();
    }
    return SUCCESS;
  }
}

