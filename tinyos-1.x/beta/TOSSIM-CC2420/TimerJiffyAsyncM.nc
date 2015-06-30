//$Id: TimerJiffyAsyncM.nc,v 1.2 2005/05/16 07:00:51 overbored Exp $
// @author Joe Polastre, Yang Zhang

module TimerJiffyAsyncM {
  provides {
    interface StdControl;
    interface TimerJiffyAsync;
  }
//  uses {
//    interface Timer;
//  }
}

implementation
{
  bool bSet;

  command result_t StdControl.init()
  {
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    atomic bSet = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    atomic bSet = FALSE;
    return SUCCESS;
  }

  void handleTimerJiffyEvent(event_t* ev, struct TOS_state* state) {
    assert(ev->data == NULL);
    signal TimerJiffyAsync.fired();
    event_cleanup(ev);
  }

  void cleanupTimerJiffyEvent(event_t* ev) {
    free(ev);
  }

  void createTimerJiffyEvent(uint32_t jiffies) {
    event_t* ev;

    ev = (event_t*) alloc(sizeof(event_t));
    ev->mote = NODE_NUM;
    ev->data = NULL;
    ev->handle = handleTimerJiffyEvent;
    ev->cleanup = cleanupTimerJiffyEvent;
    ev->time = tos_state.tos_time + jiffiesToTicks(jiffies);
    ev->pause = 0;

    TOS_queue_insert_event(ev);
  }

  async command result_t TimerJiffyAsync.setOneShot( uint32_t jiffy )
  {
    atomic {
      bSet = TRUE;
      createTimerJiffyEvent(jiffy);
    }
    return SUCCESS;
  }

  async command bool TimerJiffyAsync.isSet( )
  {
    bool value;
    atomic value = bSet;
    return value;
  }

  async command result_t TimerJiffyAsync.stop()
  {
    atomic {
      bSet = FALSE;
    }
    return SUCCESS;
  }
}

