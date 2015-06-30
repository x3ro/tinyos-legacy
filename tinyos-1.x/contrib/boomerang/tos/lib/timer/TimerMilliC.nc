/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#include "Timer.h"
#include "Timer2.h"

/**
 * TinyOS millisecond timer service.
 * <p>
 * Compatible with TinyOS 2.x interfaces and TEP 102.
 * <p>
 * To use TimerMilliC:
 * <pre>
 *  components new TimerMilliC();
 *  components MyAppM;
 *  MyAppM.Timer2 -> TimerMilliC;
 * </pre>
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
generic configuration TimerMilliC()
{
  provides interface Timer2<TMilli> as Timer;
}
implementation
{
  components MainTimerMilliC;
  components HalTimerMilliC;

  // Use the string "Timer" instead of "TimerMilliC" for backward compatibility
  // with TinyOS 1.x when using TimerC.Timer[unique("Timer")].
  enum { TIMER_ID = unique("Timer") };

  Timer = HalTimerMilliC.TimerMilli[ TIMER_ID ];
}

