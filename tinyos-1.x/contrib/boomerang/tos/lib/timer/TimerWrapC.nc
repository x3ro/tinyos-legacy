//$Id: TimerWrapC.nc,v 1.1.1.1 2007/11/05 19:11:29 jpolastre Exp $
// @author Cory Sharp <cory@moteiv.com>

#include "Timer2.h"

module TimerWrapC
{
  provides interface Timer[ uint8_t id ];
  provides interface TimerMilli[ uint8_t id ];
  uses interface Timer2<TMilli>[ uint8_t id ];
}
implementation
{
  enum
  {
    TIMER_END = uniqueCount("Timer"),
    MILLI_BEGIN = TIMER_END,
    MILLI_END = MILLI_BEGIN + uniqueCount("TimerMilli")
  };


  // Timer commands

  command result_t Timer.start[ uint8_t id ]( char type, uint32_t interval )
  {
    if( type == TIMER_ONE_SHOT )
    {
      call Timer2.startOneShot[id]( interval );
      return SUCCESS;
    }

    if( type == TIMER_REPEAT )
    {
      call Timer2.startPeriodic[id]( interval );
      return SUCCESS;
    }

    return FAIL;
  }

  command result_t Timer.stop[ uint8_t id ]()
  {
    call Timer2.stop[id]();
    return SUCCESS;
  }


  // TimerMilli commands

  command result_t TimerMilli.setPeriodic[ uint8_t id ]( int32_t millis )
  {
    call Timer2.startPeriodic[MILLI_BEGIN+id]( millis );
    return SUCCESS;
  }

  command result_t TimerMilli.setOneShot[ uint8_t id ]( int32_t millis )
  {
    call Timer2.startOneShot[MILLI_BEGIN+id]( millis );
    return SUCCESS;
  }


  command result_t TimerMilli.stop[ uint8_t id ]()
  {
    call Timer2.stop[MILLI_BEGIN+id]();
    return SUCCESS;
  }


  command bool TimerMilli.isSet[ uint8_t id ]()
  {
    return call Timer2.isRunning[MILLI_BEGIN+id]();
  }

  command bool TimerMilli.isPeriodic[ uint8_t id ]()
  {
    return !call Timer2.isOneShot[MILLI_BEGIN+id]();
  }

  command bool TimerMilli.isOneShot[ uint8_t id ]()
  {
    return call Timer2.isOneShot[MILLI_BEGIN+id]();
  }

  command int32_t TimerMilli.getPeriod[ uint8_t id ]()
  {
    return call Timer2.getdt[MILLI_BEGIN+id]();
  }


  
  event void Timer2.fired[ uint8_t id ]()
  {
    int16_t _id = id;
    if( _id < TIMER_END )
      signal Timer.fired[id]();
    else //if( _id < MILLI_END )
      signal TimerMilli.fired[id-MILLI_BEGIN]();
  }


  default event result_t Timer.fired[ uint8_t id ]()
  {
    return SUCCESS;
  }

  default event result_t TimerMilli.fired[ uint8_t id ]()
  {
    return SUCCESS;
  }
}

