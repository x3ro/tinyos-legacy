// $Id: LedsM.nc,v 1.1 2005/04/19 01:16:12 celaine Exp $

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
/*
 *
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/2/03
 *
 */

/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */


module LedsM {
  provides interface Leds;
  uses interface PowerState;
}
implementation
{
  uint8_t ledsOn;

  enum {
    RED_BIT = 1,
    GREEN_BIT = 2,
    YELLOW_BIT = 4
  };

  //void updateLeds() {
  void updateLeds() {
    LedEvent e;
    e.red    = ((ledsOn & RED_BIT)    > 0); 
    e.green  = ((ledsOn & GREEN_BIT)  > 0);
    e.yellow = ((ledsOn & YELLOW_BIT) > 0);
    sendTossimEvent(NODE_NUM, AM_LEDEVENT, tos_state.tos_time, &e);

    // celaine
    ptII_updateLeds(NODE_NUM, (short)e.red, (short)e.green, (short)e.yellow);
  }

  
  async command result_t Leds.init() {
    atomic {
      ledsOn = 0;
      dbg(DBG_BOOT, "LEDS: initialized.\n");
      updateLeds();
    }
    return SUCCESS;
  }

  async command result_t Leds.redOn() {
    dbg(DBG_LED, "LEDS: Red on.\n");
      call PowerState.redOn();
      atomic {
      if (! (ledsOn & RED_BIT)) {
        ledsOn |= RED_BIT;
        updateLeds();
      }
    }

    return SUCCESS;
  }

  async command result_t Leds.redOff() {
    dbg(DBG_LED, "LEDS: Red off.\n");
      call PowerState.redOff();
      atomic {
       if (ledsOn & RED_BIT) {
         ledsOn &= ~RED_BIT;
         updateLeds();
       }
     }
     return SUCCESS;
  }

  async command result_t Leds.redToggle() {
    result_t rval;
    atomic {
      if (ledsOn & RED_BIT)
	rval = call Leds.redOff();
      else
	rval = call Leds.redOn();
    }
    return rval;
  }

  async command result_t Leds.greenOn() {
    dbg(DBG_LED, "LEDS: Green on.\n");
    call PowerState.greenOn();
    atomic {
      if (! (ledsOn & GREEN_BIT)) {
        ledsOn |= GREEN_BIT;
        updateLeds();
      }
    }
    return SUCCESS;
  }

  async command result_t Leds.greenOff() {
    dbg(DBG_LED, "LEDS: Green off.\n");
    call PowerState.greenOff();
      atomic {
      if (ledsOn & GREEN_BIT) {
        ledsOn &= ~GREEN_BIT;
        updateLeds();
      }
    }
    return SUCCESS;
  }

  async command result_t Leds.greenToggle() {
    result_t rval;
    atomic {
      if (ledsOn & GREEN_BIT)
	rval = call Leds.greenOff();
      else
	rval = call Leds.greenOn();
    }
    return rval;
  }

  async command result_t Leds.yellowOn() {
    dbg(DBG_LED, "LEDS: Yellow on.\n");
    call PowerState.yellowOn();
    atomic {
      if (! (ledsOn & YELLOW_BIT)) {
        ledsOn |= YELLOW_BIT;
        updateLeds();
      }
    }
    return SUCCESS;
  }

  async command result_t Leds.yellowOff() {
    dbg(DBG_LED, "LEDS: Yellow off.\n");
    call PowerState.yellowOff();
    atomic {
      if (ledsOn & YELLOW_BIT) {
        ledsOn &= ~YELLOW_BIT;
        updateLeds();
      }
    }
    return SUCCESS;
  }

  async command result_t Leds.yellowToggle() {
    result_t rval;
    atomic {
      if (ledsOn & YELLOW_BIT)
	rval = call Leds.yellowOff();
      else
	rval = call Leds.yellowOn();
    }
    return rval;
  }
  
  async command uint8_t Leds.get() {
    uint8_t rval;
    atomic {
      rval = ledsOn;
    }
    return rval;
  }
  
  async command result_t Leds.set(uint8_t ledsNum) {
    dbg(DBG_LED, "LEDS: Red %s.\n", (ledsNum & RED_BIT) ? "on" : "off");
    dbg(DBG_LED, "LEDS: Green %s.\n", (ledsNum & GREEN_BIT) ? "on" : "off");
    dbg(DBG_LED, "LEDS: Yellow %s.\n", (ledsNum & YELLOW_BIT) ? "on" : "off");
    
    atomic {
      ledsOn = (ledsNum & 0x7);
      updateLeds();
    }
    return SUCCESS;
  }

}
