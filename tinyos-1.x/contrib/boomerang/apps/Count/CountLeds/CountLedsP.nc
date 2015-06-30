// $Id: CountLedsP.nc,v 1.1.1.1 2007/11/05 19:08:58 jpolastre Exp $

/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * @author Cory Sharp <info@moteiv.com>
 */

module CountLedsP {
  provides interface StdControl;
  uses interface Timer2<TMilli> as Timer;
  uses interface Leds;
}
implementation {
  uint16_t m_count;

  command result_t StdControl.init() {
    m_count = 0;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Timer.startPeriodic( 200 );
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event void Timer.fired() {
    m_count++;
    call Leds.set( m_count );
  }
}

