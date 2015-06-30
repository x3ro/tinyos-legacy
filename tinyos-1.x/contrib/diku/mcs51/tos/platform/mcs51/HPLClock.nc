// $Id: HPLClock.nc,v 1.1 2006/04/07 12:49:54 mleopold Exp $

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
 * Authors:		Jason Hill, David Gay, Philip Levis
 *
 * Ported to 8051 by Sidsel Jensen & Anders Egeskov Petersen, 
 *                   Dept of Computer Science, University of Copenhagen
 * Date last modified:  Dec 2005
 */

// The 8051-specific parts of the hardware presentation layer.


module HPLClock {
  provides interface Clock;
  provides interface StdControl;
}

implementation {
  uint8_t set_flag;
  uint8_t mscale, nextScale;
  uint16_t minterval;

  command result_t StdControl.init() {
    atomic {
      mscale = DEFAULT_SCALE; 
      minterval = DEFAULT_INTERVAL;
    }
    return SUCCESS;
  }

  command result_t StdControl.start() {
    uint8_t ms;
    uint16_t mi;
    atomic {
      mi = minterval;
      ms = mscale;
    }      
    call Clock.setRate(mi, ms);
    TR2 = 1;
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    uint16_t mi;
    atomic {
      mi = minterval;
    }
    call Clock.setRate(mi, 4);
    return SUCCESS;
  }

  async command void Clock.setInterval(uint16_t value) {
    uint16_t reload = 0;
    atomic{
      reload = (2^16) - value;	// Set Interval
      RCAP2L = (uint8_t) reload;
      RCAP2H = (uint8_t) (reload>>8);
    }
  } 

  async command void Clock.setNextInterval(uint16_t value) {
    atomic {
      minterval = value;
      set_flag = 1;
    }
  }

  async command uint16_t Clock.getInterval() {
    uint16_t res;
    res = TL2;
    res |= ((uint16_t)TH2)<<8;
    res = (2^16) - res; 

    return res;
  }

  async command uint8_t Clock.getScale() {
    uint8_t ms;
    atomic {
      ms = mscale;
    }
    return ms;
  }

  async command void Clock.setNextScale(uint8_t scale) {
    atomic {
      nextScale = scale;
      set_flag = 1;
    }
  }       

  async command result_t Clock.setIntervalAndScale(uint16_t interval, uint8_t scale) {

// This method is not implemented!

    return FAIL;
  }
        
  async command uint16_t Clock.readCounter() {
    uint16_t res;
    res = TL2;
    res |= ((uint16_t)TH2)<<8;
    return res;
  }

  async command void Clock.setCounter(uint16_t n) {
    TL2 = (uint8_t)n;
    TH2 = (uint8_t)(n>>8);
  }

  async command void Clock.intDisable() {
    ET2 = 0;
  }

  async command void Clock.intEnable() {
    ET2 = 1;
  }

  async command result_t Clock.setRate(uint16_t interval, char scale) {
    uint16_t reload = 0;
    if(!(scale==4 || scale==12)) return FAIL;
    atomic {
      minterval = interval;
      T2CON &= 0xF0;	// Timer; Reload

      ET2 = 0;		// Disable Interrupts

      if(scale == 4) 	// Set PreScale
        CKCON |= 0x20;	// T2M = 1
      else 
        CKCON &= ~0x20;	// T2M = 0

      reload = (2^16) - minterval;	// Set Interval
      RCAP2L = (uint8_t) reload;
      RCAP2H = (uint8_t) (reload>>8);

      T2 = reload;

      ET2 = 1;		// Enable Interrupts
    }
    return SUCCESS;
  }

#pragma save
#pragma nooverlay
  default async event result_t Clock.fire() { 
    return SUCCESS; 
  }
#pragma restore

  TOSH_INTERRUPT(SIG_TIMER2) {
    uint16_t reload;
    atomic {
      if (set_flag) {
        mscale = nextScale;
        if(mscale == 4)		// Set PreScale
          CKCON |= 0x20;	// T2M = 1
        else 
          CKCON &= ~0x20;	// T2M = 0

        reload = (2^16) - minterval;	// Set Interval
        RCAP2L = (uint8_t) reload;
        RCAP2H = (uint8_t) (reload>>8);

        set_flag=0;
      }
      TF2 = 0;
    }
    signal Clock.fire();
  }
}

