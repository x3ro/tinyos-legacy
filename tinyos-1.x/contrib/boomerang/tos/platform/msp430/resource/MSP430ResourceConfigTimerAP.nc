// $Id: MSP430ResourceConfigTimerAP.nc,v 1.1.1.1 2007/11/05 19:11:33 jpolastre Exp $
/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * @author Cory Sharp <cory@moteiv.com>
 */
module MSP430ResourceConfigTimerAP
{
  provides interface ResourceConfigure as WrapConfigTimerA[uint8_t rh];
  uses interface ResourceConfigure as ConfigTimerA[uint8_t rh];
  uses interface MSP430Timer as TimerA;
  uses interface Arbiter;
}
implementation
{
  void idle() {
    atomic call TimerA.setMode(MSP430TIMER_STOP_MODE);
  }

  async event void Arbiter.idle() {
    idle();
  }

  async event void Arbiter.requested() {
  }

  async command void WrapConfigTimerA.configure[uint8_t rh]() {
    // for each new user of Timer A, first configure to idle mode
    idle();
    call ConfigTimerA.configure[rh]();
  }

  default async command void ConfigTimerA.configure[uint8_t rh]() {
  }

  async event void TimerA.overflow() {
  }
}

