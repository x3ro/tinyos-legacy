// $Id: CountInputP.nc,v 1.1.1.1 2007/11/05 19:08:58 jpolastre Exp $

/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Implementation of CountInput.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
module CountInputP {
  provides interface StdControl;
  uses interface Leds;
  uses interface Button;
}
implementation {
  uint16_t m_count;

  command result_t StdControl.init() {
    m_count = 0;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Button.enable();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  async event void Button.pressed( uint32_t when ) {
    uint16_t count;
    atomic {
      m_count++;
      count = m_count;
    }
    call Leds.set( count );
  }

  async event void Button.released( uint32_t when ) {
  }
}

