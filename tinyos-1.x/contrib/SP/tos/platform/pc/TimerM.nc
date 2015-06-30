//$Id: TimerM.nc,v 1.1 2006/04/14 00:19:14 binetude Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// @author Cory Sharp <cssharp@eecs.berkeley.edu>

includes Timer;
includes HPLCC2420;
includes MSP430Timer;

module TimerM
{
  provides interface StdControl;
  provides interface LocalTime;
  provides interface Timer[uint8_t timer];
  provides interface TimerMilli[uint8_t timer];
  provides interface TimerJiffy[uint8_t timer];
  provides interface MSP430TimerControl as ControlB5;
  provides interface MSP430Compare as CompareB5;
}

implementation
{
  enum
  {
    COUNT_TIMER_OLD = uniqueCount("Timer"),
    COUNT_TIMER_MILLI = uniqueCount("TimerMilli"),
    COUNT_TIMER_JIFFY = uniqueCount("TimerJiffy"),

    OFFSET_TIMER_OLD = 0,
    OFFSET_TIMER_MILLI = OFFSET_TIMER_OLD   + COUNT_TIMER_OLD,
    OFFSET_TIMER_JIFFY = OFFSET_TIMER_MILLI + COUNT_TIMER_MILLI,
    NUM_TIMERS = OFFSET_TIMER_JIFFY + COUNT_TIMER_JIFFY,

    EMPTY_LIST = 255,
  };

#define MSP_TIMER_NUM 0xFF

  typedef struct Timer_s
  {
    uint32_t seqno;
    bool isperiodic;
    bool isset;
  } Timer_t;

  Timer_t m_timers[NUM_TIMERS];
  int32_t m_period[NUM_TIMERS]; //outside to get struct down to 8 bytes

  // MSP430 timer state

  norace bool msp430TimerEnabled = FALSE;
  norace bool msp430TimerInterruptFlag = FALSE;
  norace uint32_t msp430TimerSeqNo = 0;
  norace uint16_t msp430TimerRegister = 0;

  void createTimerEvent(bool isMSP430Timer, uint8_t num, uint32_t seqno,
      uint64_t ticks);

  command result_t StdControl.init()
  {
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  void signal_timer_fired( uint8_t num )
  {
    // CSS 20040529 - since msp430 is a 16-bit platform, make num a signed
    // 16-bit integer to avoid "warning: comparison is always true due to
    // limited range of data type" if it happens that (num >= 0) is tested.
    const int16_t num16 = num;

    ppp(DBG_TIME, "signal_timer_fired( num = %d, jiffy = %d )", num, call LocalTime.read());

    if( (COUNT_TIMER_JIFFY > 0) && (num16 >= OFFSET_TIMER_JIFFY) )
    {
      signal TimerJiffy.fired[ num - OFFSET_TIMER_JIFFY ]();
    }
    else if( (COUNT_TIMER_MILLI > 0) && (num16 >= OFFSET_TIMER_MILLI) )
    {
      signal TimerMilli.fired[ num - OFFSET_TIMER_MILLI ]();
    }
    else
    {
      signal Timer.fired[ num ]();
    }
  }

  async command uint32_t LocalTime.read()
  {
    return getCurrentTimeInJiffies();
  }

  typedef struct TimerData {
    bool isMSP430Timer;
    uint8_t num;
    uint32_t seqno;
  } TimerData;

  void handleTimerEvent( event_t* ev, struct TOS_state* state ) {
    TimerData* data = ( TimerData* ) ev->data;
    Timer_t* timer = &m_timers[ data->num ];

    if ( data->isMSP430Timer ) {
      assert( data->num == MSP_TIMER_NUM );
      if ( msp430TimerEnabled && ! msp430TimerInterruptFlag
          && msp430TimerSeqNo == data->seqno ) {
        msp430TimerInterruptFlag = TRUE;
        signal CompareB5.fired();
      }
      createTimerEvent( TRUE, data->num, data->seqno,
          jiffiesToTicks( 0xFFFF + 1 ) );
    } else {
      if ( timer->isset && timer->seqno == data->seqno ) {
        signal_timer_fired( data->num );
        if ( timer->isperiodic ) {
          createTimerEvent( FALSE, data->num, data->seqno,
              jiffiesToTicks( m_period[ data->num ] ) );
        }
      }
    }

    event_cleanup(ev);
  }

  void cleanupTimerEvent(event_t* ev) {
    free(ev->data);
    free(ev);
  }

  // TODO optimize by re-using the TimerDatas.
  void createTimerEvent(bool isMSP430Timer, uint8_t num, uint32_t seqno, uint64_t ticks) {
    TimerData* data;
    event_t* ev;

    data = alloc(sizeof(TimerData));
    data->num = num;
    data->seqno = seqno;
    data->isMSP430Timer = isMSP430Timer;

    ev = (event_t*) alloc(sizeof(event_t));
    ev->mote = NODE_NUM;
    ev->data = data;
    ev->handle = handleTimerEvent;
    ev->cleanup = cleanupTimerEvent;
    ev->time = tos_state.tos_time + ticks;
    ev->pause = 0;

    TOS_queue_insert_event(ev);
  }

  result_t setTimer( uint8_t num, int32_t jiffy, bool isperiodic )
  {
    ppp(DBG_TIME, "enter setTimer( jiffy = %ld )", jiffy);
    assert(jiffy > 0);
    atomic
    {
      Timer_t* timer = &m_timers[num];
      uint32_t oldSeqNo = timer->seqno;

      timer->seqno++;
      timer->isset = TRUE;
      timer->isperiodic = isperiodic;
      m_period[num] = jiffy;

      assert( oldSeqNo < timer->seqno );

      createTimerEvent(FALSE, num, timer->seqno, jiffiesToTicks(jiffy));
    }
    return SUCCESS;
  }

  void removeTimer( uint8_t num )
  {
    atomic
    {
      Timer_t* timer = &m_timers[num];
      timer->isset = FALSE;
    }
  }

  // ---
  // --- Wrap the above in the TimerJiffy, TimerMilli, and Timer interfaces
  // ---


  // --- TimerJiffy ---

  uint8_t fromNumJiffy( uint8_t num )
  {
    return num + OFFSET_TIMER_JIFFY;
  }

  command result_t TimerJiffy.start[uint8_t num]( char type, int32_t jiffy )
  {
    num = fromNumJiffy( num );
    switch( type )
    {
      case TIMER_REPEAT:
	return setTimer( num, jiffy, TRUE );

      case TIMER_ONE_SHOT:
	return setTimer( num, jiffy, FALSE );
    }

    return FAIL;
  }

  command result_t TimerJiffy.setOneShot[uint8_t num]( int32_t jiffy )
  {
    return setTimer( fromNumJiffy(num), jiffy, FALSE );
  }

  command result_t TimerJiffy.setPeriodic[uint8_t num]( int32_t jiffy )
  {
    return setTimer( fromNumJiffy(num), jiffy, TRUE );
  }

  command result_t TimerJiffy.stop[uint8_t num]()
  {
    removeTimer( fromNumJiffy(num) );
    return SUCCESS;
  }

  command bool TimerJiffy.isSet[uint8_t num]()
  {
    return m_timers[fromNumJiffy(num)].isset;
  }

  command bool TimerJiffy.isPeriodic[uint8_t num]()
  {
    return m_timers[fromNumJiffy(num)].isperiodic;
  }

  command bool TimerJiffy.isOneShot[uint8_t num]()
  {
    return !m_timers[fromNumJiffy(num)].isperiodic;
  }

  command int32_t TimerJiffy.getPeriod[uint8_t num]()
  {
    return m_period[fromNumJiffy(num)];
  }

  default event result_t TimerJiffy.fired[uint8_t num]()
  {
    return SUCCESS;
  }


  // --- TimerMilli ---

  uint8_t fromNumMilli( uint8_t num )
  {
    return num + OFFSET_TIMER_MILLI;
  }

  command result_t TimerMilli.setOneShot[uint8_t num]( int32_t milli )
  {
    return setTimer( fromNumMilli(num), milli*32, FALSE );
  }

  command result_t TimerMilli.setPeriodic[uint8_t num]( int32_t milli )
  {
    return setTimer( fromNumMilli(num), milli*32, TRUE );
  }

  command result_t TimerMilli.stop[uint8_t num]()
  {
    removeTimer( fromNumMilli(num) );
    return SUCCESS;
  }

  command bool TimerMilli.isSet[uint8_t num]()
  {
    return m_timers[fromNumMilli(num)].isset;
  }

  command bool TimerMilli.isPeriodic[uint8_t num]()
  {
    return m_timers[fromNumMilli(num)].isperiodic;
  }

  command bool TimerMilli.isOneShot[uint8_t num]()
  {
    return !m_timers[fromNumMilli(num)].isperiodic;
  }

  command int32_t TimerMilli.getPeriod[uint8_t num]()
  {
    return m_period[fromNumMilli(num)];
  }

  default event result_t TimerMilli.fired[uint8_t num]()
  {
    return SUCCESS;
  }


  // --- Timer ---

  command result_t Timer.start[uint8_t num]( char type, uint32_t milli )
  {
    switch( type )
    {
      case TIMER_REPEAT:
	return setTimer( num, milli*32, TRUE );

      case TIMER_ONE_SHOT:
	return setTimer( num, milli*32, FALSE );
    }

    return FAIL;
  }

  command result_t Timer.stop[uint8_t num]()
  {
    removeTimer( num );
    return SUCCESS;
  }

  default event result_t Timer.fired[uint8_t num]()
  {
    return SUCCESS;
  }

  // --- MSP430TimerControl ---

  async command void ControlB5.clearPendingInterrupt() {
    msp430TimerInterruptFlag = FALSE;
  }

  async command void ControlB5.enableEvents() {
    msp430TimerEnabled = TRUE;
  }

  // --- MSP430Compare ---

#define period (0xFFFF + 1)

  void setMSP430Timer(uint16_t targetPhase) {
    uint32_t oldMSP430TimerSeqNo = msp430TimerSeqNo;
    uint32_t currTime = getCurrentTimeInJiffies();
    uint32_t currPhase = currTime % period;
    uint32_t currPeriod = currTime / period;
    uint32_t nextPeriod = currTime / period + 1;
    uint32_t targetTime;
    uint32_t targetDelta;
    uint64_t ticks;

    msp430TimerRegister = targetPhase;
    msp430TimerSeqNo++;
    assert( msp430TimerSeqNo > oldMSP430TimerSeqNo );

    if (currPhase < targetPhase) {
      targetTime = period * currPeriod + targetPhase;
    } else {
      targetTime = period * nextPeriod + targetPhase;
    }
    targetDelta = targetTime - currTime;
    assert( targetDelta <= period );
    ticks = jiffiesToTicks( targetDelta );

    createTimerEvent( TRUE, MSP_TIMER_NUM, msp430TimerSeqNo, ticks );
  }

  default async event void CompareB5.fired() { }

  async command uint16_t CompareB5.getEvent() {
    return msp430TimerRegister;
  }

  async command void CompareB5.setEvent( uint16_t x ) {
    fail("this function should work, but we're not supposed to ever call this...");
    setMSP430Timer(x);
  }

  async command void CompareB5.setEventFromPrev( uint16_t x ) {
    setMSP430Timer(msp430TimerRegister + x);
  }

  async command void CompareB5.setEventFromNow( uint16_t x ) {
    setMSP430Timer(getCurrentTimeInJiffies() + x);
  }

}

