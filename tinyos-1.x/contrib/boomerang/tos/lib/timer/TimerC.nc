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
 * Compatible with TinyOS 1.x style timer.
 * <p>
 * TimerC is deprecated; please use TimerMilliC instead.
 * <p>
 * To use TimerC:
 * <pre>
 *  components TimerC;
 *  components MyAppM;
 *  MyAppM.Timer -> TimerC.Timer[unique("Timer")];
 * </pre>
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
configuration TimerC
{
  provides interface StdControl;
  provides interface Timer[ uint8_t id ];
  provides interface TimerMilli[ uint8_t id ];
}
implementation
{
  components HalTimerMilliC;
  components TimerWrapC;
  components NullStdControl;

  StdControl = NullStdControl;
  Timer = TimerWrapC;
  TimerMilli = TimerWrapC;

  TimerWrapC.Timer2 -> HalTimerMilliC.TimerMilli;
}

