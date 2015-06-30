// $Id: LedsM.nc,v 1.1.1.1 2007/11/05 19:11:36 jpolastre Exp $
/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 * @author Joe Polastre <info@moteiv.com>
 */
#include "sensorboard.h"

module LedsM {
  provides {
    interface Leds;
    interface SplitControl;
  }
  uses {
    interface StdControl as LowerControl;
    interface Max7315LedsControl as LedsControl;
  } 
}
implementation
{
  uint8_t state;

  enum {
    RED_BIT = 1,
    GREEN_BIT = 2,
    YELLOW_BIT = 4
  };

  enum {
    IDLE = 0,
    READY = 1,
    START = 2,
    INIT = 3,
  };

  task void initDone() {
    signal SplitControl.initDone();
  }

  task void stopDone() {
    signal SplitControl.initDone();
  }

  command result_t SplitControl.init() {
    atomic state = IDLE;
    post initDone();
    return call LowerControl.init();
  }

  command result_t SplitControl.start() {
    atomic state = READY;
    call LowerControl.start();
    return call Leds.init();
  }

  command result_t SplitControl.stop() {
    post stopDone();
    return SUCCESS;
  }

  async command result_t Leds.init() {
    bool _init;
    dbg(DBG_BOOT, "LEDS: initialized.\n");
    atomic {
      if (state == READY) {
        state = INIT;
        _init = TRUE;
      }
      else {
        _init = FALSE;
      }
    }
    return _init ? call LedsControl.setAll(0xF8) : FAIL;
  }

  async command result_t Leds.redOn() {
    dbg(DBG_LED, "LEDS: Red on.\n");
    return call LedsControl.setBlink0(TSB_RED, FALSE);
  }

  async command result_t Leds.redOff() {
    dbg(DBG_LED, "LEDS: Red off.\n");
    return call LedsControl.setBlink0(TSB_RED, TRUE);
  }

  async command result_t Leds.redToggle() {
    uint8_t ledsval = call LedsControl.getBlink0();
    if (ledsval & (1 << TSB_RED)) 
      return call Leds.redOn();
    else
      return call Leds.redOff();
  }

  async command result_t Leds.greenOn() {
    dbg(DBG_LED, "LEDS: Green on.\n");
    return call LedsControl.setBlink0(TSB_GREEN, FALSE);
  }

  async command result_t Leds.greenOff() {
    dbg(DBG_LED, "LEDS: Green off.\n");
    return call LedsControl.setBlink0(TSB_GREEN, TRUE);
  }

  async command result_t Leds.greenToggle() {
    uint8_t ledsval = call LedsControl.getBlink0();
    if (ledsval & (1 << TSB_GREEN)) 
      return call Leds.greenOn();
    else
      return call Leds.greenOff();
  }

  async command result_t Leds.yellowOn() {
    dbg(DBG_LED, "LEDS: Yellow on.\n");
    return call LedsControl.setBlink0(TSB_BLUE, FALSE);
  }

  async command result_t Leds.yellowOff() {
    dbg(DBG_LED, "LEDS: Yellow off.\n");
    return call LedsControl.setBlink0(TSB_BLUE, TRUE);
  }

  async command result_t Leds.yellowToggle() {
    uint8_t ledsval = call LedsControl.getBlink0();
    if (ledsval & (1 << TSB_BLUE)) 
      return call Leds.yellowOn();
    else
      return call Leds.yellowOff();
  }
  
  async command uint8_t Leds.get() {
    return call LedsControl.get();
  }
  
  async command result_t Leds.set(uint8_t ledsNum) {
    ledsNum = ~ledsNum;
    return call LedsControl.setBlinkAll0(ledsNum & 0x07);
  }


  /* default event handlers for LedsControl */
  event void LedsControl.setConfigDone() { }
  event void LedsControl.allOffDone() { }
  event void LedsControl.setDone() { }
  event void LedsControl.setAllDone(uint8_t value) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == INIT) {
      // turn all the LEDs off
      call LedsControl.setBlinkAll0(0xff);
    }
  }
  event void LedsControl.setBlink0Done() { }
  event void LedsControl.setBlinkAll0Done() { 
    bool _done;
    atomic {
      if (state == INIT) {
        state = READY;
        _done = TRUE;
      }
      else {
        _done = FALSE;
      }
    }
    if( _done )
      signal SplitControl.startDone();
  }
  event void LedsControl.setBlink1Done() { }
  event void LedsControl.setBlinkAll1Done() { }
  event void LedsControl.setIntensityDone() { }
  event void LedsControl.setGlobalIntensityDone() { }

}
